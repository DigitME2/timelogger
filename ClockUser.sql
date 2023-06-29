DELIMITER $$

DROP PROCEDURE IF EXISTS `ClockUser`$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ClockUser` (IN `JobId` VARCHAR(20), IN `UserId` VARCHAR(20), IN `StationId` VARCHAR(50), IN `StationStatus` VARCHAR(20))  MODIFIES SQL DATA
BEGIN

    
    DECLARE inputComboOpenRecordRef INT DEFAULT -1;
    DECLARE userOtherOpenRecordRef INT DEFAULT -1;
    DECLARE newlyClosedRecordRef INT DEFAULT -1;
    DECLARE newlyOpenRecordRef INT DEFAULT -1;
    
    DECLARE newlyClosedDuration INT DEFAULT 0;
    DECLARE newlyClosedOvertime INT DEFAULT 0;
	
	DECLARE userIdValid INT DEFAULT 0;
	DECLARE jobIDValid INT DEFAULT 0;

    SELECT "" INTO @outputLogRef;
    SELECT "" INTO @outputUserState;
    SELECT "workInProgress" INTO @outputWorkState;
    SELECT "" INTO @outputRouteName;
    SELECT "" INTO @outputRouteStageIndex;
	
	CREATE TEMPORARY TABLE routeStages (stageIndex INT PRIMARY KEY AUTO_INCREMENT, stageName VARCHAR(50));
    
    START TRANSACTION;
    
        SELECT timeLog.ref INTO inputComboOpenRecordRef FROM timeLog
        WHERE timeLog.clockOffTime IS NULL 
        AND timeLog.userId=UserId 
        AND timeLog.jobId=JobId
        AND timeLog.stationId=StationId
        ORDER BY timeLog.recordTimestamp DESC LIMIT 1;
    
		-- Check that user and job ID are present in relevant tables
		SELECT COUNT(userId) INTO userIdValid FROM users WHERE users.userId=UserId LIMIT 1;
		SELECT COUNT(jobId) INTO jobIDValid FROM jobs WHERE jobs.jobId=JobId LIMIT 1;
		
		-- Confirm that both user and job ID are valid
		IF userIdValid > 0 AND jobIDValid > 0 THEN
			-- Create a new record
			IF inputComboOpenRecordRef = -1 OR inputComboOpenRecordRef IS NULL THEN
			
				-- An open record for another station or job may exist if the
				-- user has not clocked off a previous job. This should be
				-- closed before a new record is created. Only applies if
				-- allowMultipleClockOn is set to false in config.
				SELECT paramValue INTO @allowMultipleClockOn 
				FROM config WHERE paramName = "allowMultipleClockOn" LIMIT 1;

				IF @allowMultipleClockOn = "false" THEN            
					SELECT ref INTO userOtherOpenRecordRef FROM timeLog 
					WHERE timeLog.userId=UserId AND timeLog.clockOffTime IS NULL 
					ORDER BY timeLog.recordTimestamp DESC LIMIT 1;

					IF userOtherOpenRecordRef != -1 THEN
						UPDATE timeLog SET clockOffTime = CURRENT_TIME, workStatus='unknown' WHERE ref = userOtherOpenRecordRef;
						SET newlyClosedRecordRef = userOtherOpenRecordRef;
					END IF;
				END IF;

				-- Create a new record in the time log and set the status of the job to "workInProgress".
				-- The job status is assumed to be either pending, workInProgress, or complete.
				INSERT INTO timeLog (jobId, stationId, userId, clockOnTime, recordDate, workStatus)
				VALUES (JobId, StationId, UserId, CURRENT_TIME, CURRENT_DATE, 'workInProgress');
				
				UPDATE jobs SET currentStatus='workInProgress' WHERE jobs.jobId=JobId;

				SELECT timeLog.ref INTO newlyOpenRecordRef FROM timeLog 
					WHERE timeLog.clockOffTime IS NULL 
					AND timeLog.userId=UserId 
					AND timeLog.jobId=JobId
					AND timeLog.stationId=StationId
					ORDER BY timeLog.recordTimestamp DESC LIMIT 1;

				SELECT "clockedOn", newlyOpenRecordRef into @outputUserState, @outputLogRef;

			
			-- or close an open one
			ELSE
				SELECT ref INTO newlyClosedRecordRef FROM timeLog
				WHERE timeLog.userId=UserId AND clockOffTime IS NULL AND timeLog.jobId=JobId
				ORDER BY recordTimestamp DESC LIMIT 1;
				
				UPDATE timeLog SET clockOffTime=CURRENT_TIME, workStatus=StationStatus WHERE ref = newlyClosedRecordRef;
				
                SELECT "clockedOff", newlyClosedRecordRef into @outputUserState, @outputLogRef;

				-- Get lunch config options
				SELECT paramValue INTO @addLunchBreak 
				FROM config WHERE paramName = "addLunchBreak" LIMIT 1;

				IF @addLunchBreak = "true" THEN
					SELECT paramValue INTO @trimLunch
					FROM config WHERE paramName = "trimLunch" LIMIT 1;

					SELECT clockOffTime, clockOnTime INTO @jobClockOffTime, @jobClockOnTime FROM timeLog
					WHERE ref = newlyClosedRecordRef;

					CALL addLunch(newlyClosedRecordRef, @jobClockOnTime, @jobClockOffTime, CURRENT_DATE, @trimLunch);
				END IF;
			END IF;
			
			
			-- Update the jobs table. This is most easily done here, as references to the
			-- rows updated in this procedure are required.        
			IF newlyClosedRecordRef != -1 THEN
			
				SELECT clockOnTime, clockOffTime INTO @clockOnTime, @clockOffTime 
				FROM timeLog
				WHERE timeLog.ref=newlyClosedRecordRef;
				
				-- find the newly closed total duration
				SET newlyClosedDuration = TIME_TO_SEC(TIMEDIFF(@clockOffTime, @clockOnTime));
				
				-- find the newly closed overtime duration
				SET newlyClosedOvertime = CalcOvertimeDuration(@clockOnTime, @clockOffTime, CURRENT_DATE);
				
				-- update records
				UPDATE jobs 
				SET closedWorkedDuration = closedWorkedDuration + newlyClosedDuration,
				closedOvertimeDuration = closedOvertimeDuration + newlyClosedOvertime
				WHERE jobs.jobId=(SELECT timeLog.jobId FROM timeLog WHERE timeLog.ref=newlyClosedRecordRef LIMIT 1);
				
				UPDATE timeLog
				SET workedDuration = newlyClosedDuration,
				overtimeDuration = newlyClosedOvertime
				WHERE timeLog.ref=newlyClosedRecordRef;

				IF StationStatus = "complete" THEN
					CALL MarkJobComplete(JobId);
					UPDATE timeLog 
					SET clockOffTime=CURRENT_TIME, workStatus=StationStatus 
					WHERE timeLog.ref = newlyClosedRecordRef;

                    SELECT "complete" INTO @outputWorkState;

                END IF;
			   
			END IF;
			
			-- If the route name for this job is defined, create a list of station names from the comma-separated list
			-- in the routes table, and then determine where in this list the current station is. If its position is
			-- greater than the index of the current, update the index and route stage in the job record to reflect
			-- this. Note that the stage of the route can only ever move forward here. If the station is not listed on
			-- the route, it is simply ignored. This is assumed to be a mistake on the part of the end user, but isn't
			-- something we can correct here.

			
			SELECT routeName, routeCurrentStageIndex
			INTO @routeName, @routeCurrentStageIndex 
			FROM jobs 
			WHERE jobs.jobId = JobId LIMIT 1;

            SELECT -1 INTO @outputRouteStageIndex;
			
			IF @routeName IS NOT NULL AND @routeName != "" THEN
				
				SELECT routeDescription INTO @routeDescription FROM routes WHERE routes.routeName = @routeName;

				-- use a loop to parse the routeDescription, adding each stage name to the routeStages table
				REPEAT
					SELECT INSTR(@routeDescription,",") INTO @index;					

					IF @index != 0 THEN
						INSERT INTO routeStages (stageName) SELECT SUBSTR(@routeDescription, 1, @index-1);
						SELECT SUBSTR(@routeDescription, @index+1) INTO @routeDescription;
					ELSE
						INSERT INTO routeStages (stageName) VALUES (@routeDescription);
					END IF;
				UNTIL @index = 0
				END REPEAT;

				-- check if the station being clocked clocked on at is the current route stage or further in the route
				SELECT stageIndex, stageName 
				INTO @stageIndex, @stageName
				FROM routeStages 
				WHERE routeStages.stageIndex >= @routeCurrentStageIndex
				AND routeStages.stageName = StationId 
				LIMIT 1;
				
				-- SELECT @stageIndex, @stageName;

				-- if station is current route stage or futher in route
				IF @stageIndex IS NOT NULL THEN
					-- get config option for if a stage complete is required for route progression
					SELECT paramValue INTO @requireStageComplete 
					FROM config WHERE paramName = "requireStageComplete" LIMIT 1;

					-- Set route stage index for work log record if new record
					IF newlyOpenRecordRef != -1 THEN
						UPDATE timeLog SET timeLog.routeStageIndex = @stageIndex WHERE timeLog.ref = newlyOpenRecordRef;
					END IF;

					IF @requireStageComplete = "false" OR (@routeCurrentStageIndex  <= 1 AND @stageIndex = 1) THEN
						-- update current route stage to station being clocked on at
						UPDATE jobs 
						SET routeCurrentStageIndex = @stageIndex, routeCurrentStageName = StationId 
						WHERE jobs.jobId = JobId;
					ELSE
						-- get previous stage name
						SELECT stageName INTO @prevStageName FROM routeStages 
						WHERE routeStages.stageIndex = @stageIndex - 1
						LIMIT 1;

						-- check if previous stage has a stage complete time log entry or is first stage
						SELECT count(jobId) 
						INTO @prevComplete FROM timeLog 
						WHERE timeLog.jobId=JobId AND timeLog.stationId=@prevStageName AND timeLog.workStatus="stageComplete";

						IF @prevComplete > 0 THEN
							UPDATE jobs 
							SET routeCurrentStageIndex = @stageIndex, routeCurrentStageName = StationId 
							WHERE jobs.jobId = JobId;
						END IF;

					END IF;

					-- 
					SELECT MAX(stageIndex) INTO @maxStageIndex FROM routeStages;
					
					-- if last current station last in route and stage complete pressed mark job as complete
					IF @maxStageIndex = @stageIndex AND StationStatus = "stageComplete" AND newlyClosedRecordRef != -1 THEN
						CALL MarkJobComplete(JobId);
						UPDATE jobs 
						SET routeCurrentStageIndex = -1, routeCurrentStageName = Null 
						WHERE jobs.jobId = JobId;

                        SELECT "complete" INTO @outputWorkState;
                    
                    ELSEIF StationStatus = "complete" AND newlyClosedRecordRef != -1 THEN
						CALL MarkJobComplete(JobId);
						UPDATE jobs 
                        SET routeCurrentStageIndex = -1, routeCurrentStageName = Null, currentStatus = StationStatus
						WHERE jobs.jobId = JobId;

                        SELECT "complete" INTO @outputWorkState;

                    END IF;

                    SELECT @stageIndex INTO @outputRouteStageIndex;
					

				ELSE
					-- if no possible change to current route stage index check if station included in route at at any point                                                                                                        
					-- SELECT 'HERE';
					
					SELECT stageIndex 
					INTO @stageIndex
					FROM routeStages 
					WHERE routeStages.stageName = StationId
					ORDER BY stageIndex DESC
					LIMIT 1;

					-- select @stageIndex;

					-- Set route stage index for work log record if new record
					IF @stageIndex IS NOT NULL AND newlyOpenRecordRef != -1 THEN
						UPDATE timeLog SET timeLog.routeStageIndex = @stageIndex WHERE timeLog.ref = newlyOpenRecordRef;
					END IF;

                    SELECT @stageIndex INTO @outputRouteStageIndex;

				END IF;
			END IF;
            SELECT @routeName INTO @outputRouteName;
            SELECT @outputUserState as "result", @outputLogRef as "logRef", @outputWorkState as "workState", @outputRouteName as "routeName", @outputRouteStageIndex as "routeStageIndex";
		ELSE
			-- error message returned
			SELECT "unknownId" as result;
		END IF;
        
    COMMIT;
	
	END$$

DELIMITER ;;