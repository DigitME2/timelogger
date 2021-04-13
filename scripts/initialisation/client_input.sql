DELIMITER ;;

DROP PROCEDURE IF EXISTS ClockUser;;
CREATE DEFINER=`root`@`localhost` PROCEDURE ClockUser( 
    IN JobId VARCHAR(20),
    IN UserId VARCHAR(20),
    IN StationId VARCHAR(50), 
    IN StationStatus VARCHAR(20)
    )
    MODIFIES SQL DATA
BEGIN

    
    DECLARE inputComboOpenRecordRef INT DEFAULT -1;
    DECLARE userOtherOpenRecordRef INT DEFAULT -1;
    DECLARE newlyClosedRecordRef INT DEFAULT -1;
    DECLARE newlyOpenRecordRef INT DEFAULT -1;
    
    DECLARE newlyClosedDuration INT DEFAULT 0;
    DECLARE newlyClosedOvertime INT DEFAULT 0;
	
	DECLARE userIdValid INT DEFAULT 0;
	DECLARE jobIDValid INT DEFAULT 0;
	
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
				
				-- get jobID with correct case
				SELECT jobs.jobId INTO @caseCorrectedJobId FROM jobs WHERE jobs.jobId=JobId LIMIT 1;

				-- Create a new record in the time log and set the status of the job to "workInProgress".
				-- The job status is assumed to be either pending, workInProgress, or complete.
				INSERT INTO timeLog (jobId, stationId, userId, clockOnTime, recordDate, workStatus)
				VALUES (@caseCorrectedJobId, StationId, UserId, CURRENT_TIME, CURRENT_DATE, 'workInProgress');
				
				UPDATE jobs SET currentStatus='workInProgress' WHERE jobs.jobId=JobId;

				SELECT timeLog.ref INTO newlyOpenRecordRef FROM timeLog 
					WHERE timeLog.clockOffTime IS NULL 
					AND timeLog.userId=UserId 
					AND timeLog.jobId=JobId
					AND timeLog.stationId=StationId
					ORDER BY timeLog.recordTimestamp DESC LIMIT 1;

				SELECT "clockedOn" as result, newlyOpenRecordRef as logRef;

			
			-- or close an open one
			ELSE
				SELECT ref INTO newlyClosedRecordRef FROM timeLog
				WHERE timeLog.userId=UserId AND clockOffTime IS NULL AND timeLog.jobId=JobId
				ORDER BY recordTimestamp DESC LIMIT 1;
				
				UPDATE timeLog SET clockOffTime=CURRENT_TIME, workStatus=StationStatus WHERE ref = newlyClosedRecordRef;
				
				SELECT "clockedOff" as result, newlyClosedRecordRef as logRef;

				-- Get lunch config options
				SELECT paramValue INTO @addLunchBreak 
				FROM config WHERE paramName = "addLunchBreak" LIMIT 1;
				
				-- set as complete then mark job as complete in job record
				IF StationStatus = "complete" THEN
					CALL MarkJobComplete(JobId);
				END IF;

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
				
				SELECT @stageIndex, @stageName;

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

						SELECT @prevComplete;

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
					END IF;
				ELSE
					-- if no possible change to current route stage index check if station included in route at at any point                                                                                                        
					SELECT 'HERE';
					
					SELECT stageIndex 
					INTO @stageIndex
					FROM routeStages 
					WHERE routeStages.stageName = StationId
					ORDER BY stageIndex DESC
					LIMIT 1;

					select @stageIndex;

					-- Set route stage index for work log record if new record
					IF @stageIndex IS NOT NULL AND newlyOpenRecordRef != -1 THEN
						UPDATE timeLog SET timeLog.routeStageIndex = @stageIndex WHERE timeLog.ref = newlyOpenRecordRef;
					END IF;
				END IF;
			END IF;
		ELSE
			IF userIdValid < 1 && jobIDValid < 1 THEN
				SELECT "Unknown UserId & JobId" as result;
			ELSE
				IF userIdValid < 1 THEN
					SELECT "Unknown UserId" as result;
				ELSE 
					IF jobIDValid < 1 THEN
						SELECT "Unknown JobId" as result;
					ELSE
						SELECT "Unknown Id" as result;
					END IF;
				END IF;
			END IF;
		END IF;
        
    COMMIT;
END;;


DROP PROCEDURE IF EXISTS addLunch;;
CREATE DEFINER=`root`@`localhost` PROCEDURE addLunch( 
	IN workLogRef INT(11),		
	IN jobClockOnTime TIME,
	IN jobClockOffTime TIME,
	IN RecordDate DATE,
	IN configTrimLunch VARCHAR(100)
	)
    MODIFIES SQL DATA
BEGIN

    DECLARE startLunch TIME;
    DECLARE endLunch TIME;

	SELECT lunchTimes.startTime
    INTO startLunch
    FROM lunchTimes
    WHERE DAYNAME(dayDate) = DAYNAME(RecordDate);
    
    SELECT lunchTimes.endTime
    INTO endLunch
    FROM lunchTimes
    WHERE DAYNAME(dayDate) = DAYNAME(RecordDate);

	IF jobClockOnTime < startLunch and endLunch < jobClockOffTime THEN
		-- clock on period covers entire lunch
		-- insert break
		CALL insertBreak(workLogRef, startLunch, endLunch);
		
	ELSEIF configTrimLunch = "true" THEN

		IF startLunch < jobClockOnTime and jobClockOffTime < endLunch THEN
			-- clock on and off within lunch period
			-- set end time equal to start time
			UPDATE timeLog
			SET timeLog.clockOffTime = jobClockOnTime
			WHERE ref = workLogRef;

		-- Should clocking off or on be trimmed to lunch start or end if clocked off or on in lunch 
		ELSEIF jobClockOnTime < startLunch AND startLunch < jobClockOffTime AND jobClockOffTime < endLunch THEN
			-- Clocked off in lunch, Set clock off time to start of lunch
			UPDATE timeLog
			SET timeLog.clockOffTime = startLunch
			WHERE ref = workLogRef;
			
		ELSEIF startLunch < jobClockOnTime AND jobClockOnTime < endLunch AND endLunch < jobClockOffTime THEN
			-- Clocked on in lunch, Set clock on time to end of lunch
			UPDATE timeLog
			SET timeLog.clockOnTime = endLunch
			WHERE ref = workLogRef;

		END IF;
			
	END IF;

END;;

DROP PROCEDURE IF EXISTS recordStoppage;;
CREATE DEFINER=`root`@`localhost` PROCEDURE recordStoppage( 
    IN JobId VARCHAR(20),
    IN StoppageReasonId VARCHAR(20),
    IN StationId VARCHAR(50),
	IN Description text,
    IN StationStatus VARCHAR(20)
    )
    MODIFIES SQL DATA
BEGIN
	-- stoppageReasonId
	-- StoppageReasonId
    -- stoppageReasonIdValid
    DECLARE inputComboOpenRecordRef INT DEFAULT -1;
    DECLARE userOtherOpenRecordRef INT DEFAULT -1;
    DECLARE newlyClosedRecordRef INT DEFAULT -1;
    
    DECLARE newlyClosedDuration INT DEFAULT 0;
    DECLARE newlyClosedOvertime INT DEFAULT 0;
	
	DECLARE stoppageReasonIdValid INT DEFAULT 0;
	DECLARE jobIDValid INT DEFAULT 0;

	DECLARE clockOffTime TIME;
	
	CREATE TEMPORARY TABLE routeStages (stageIndex INT PRIMARY KEY AUTO_INCREMENT, stageName VARCHAR(50));
    
    START TRANSACTION;
    
        SELECT stoppagesLog.ref INTO inputComboOpenRecordRef FROM stoppagesLog
        WHERE stoppagesLog.endTime IS NULL 
        AND stoppagesLog.stoppageReasonId=StoppageReasonId 
        AND stoppagesLog.jobId=JobId
        AND stoppagesLog.stationId=StationId
        ORDER BY stoppagesLog.recordTimestamp DESC LIMIT 1;
    
		-- Check that user and job ID are present in relevant tables
		SELECT COUNT(stoppageReasonId) INTO stoppageReasonIdValid FROM stoppageReasons WHERE stoppageReasons.stoppageReasonId=StoppageReasonId LIMIT 1;
		SELECT COUNT(jobId) INTO jobIDValid FROM jobs WHERE jobs.jobId=JobId LIMIT 1;
		
		-- Confirm that both user and job ID are valid
		IF stoppageReasonIdValid > 0 AND jobIDValid > 0 THEN
			-- Create a new record
			IF inputComboOpenRecordRef = -1 OR inputComboOpenRecordRef IS NULL or StationStatus='unresolved' THEN
			
				-- Create a new record in the stoppage log.
				-- The job status is assumed to be either pending, workInProgress, or complete.
				INSERT INTO stoppagesLog (jobId, stationId, stoppageReasonId, description, startTime, startDate, status)
				VALUES (JobId, StationId, StoppageReasonId, Description, CURRENT_TIME, CURRENT_DATE, 'unresolved');
				
				SELECT "stoppageOn" as result;

			
			-- or close an open one
			ELSE

				SELECT ref INTO newlyClosedRecordRef FROM stoppagesLog
				WHERE stoppagesLog.stoppageReasonId=StoppageReasonId AND endTime IS NULL AND stoppagesLog.jobId=JobId
				ORDER BY recordTimestamp DESC LIMIT 1;
				
				UPDATE stoppagesLog SET endTime=CURRENT_TIME, endDate=CURRENT_DATE, status=StationStatus WHERE ref = newlyClosedRecordRef;
				
				SELECT "stoppageOff" as result;
			END IF;
			
			
			-- Update the jobs table. This is most easily done here, as references to the
			-- rows updated in this procedure are required.        
--			IF newlyClosedRecordRef != -1 THEN
--			
--				SELECT clockOnTime, clockOffTime INTO @clockOnTime, @clockOffTime 
--				FROM timeLog
--				WHERE timeLog.ref=newlyClosedRecordRef;
--				
--				-- find the newly closed total duration
--				SET newlyClosedDuration = TIME_TO_SEC(TIMEDIFF(@clockOffTime, @clockOnTime));
--				
--				-- find the newly closed overtime duration
--				SET newlyClosedOvertime = CalcOvertimeDuration(@clockOnTime, @clockOffTime, CURRENT_DATE);
--				
--				-- update records
--				UPDATE jobs 
--				SET closedWorkedDuration = closedWorkedDuration + newlyClosedDuration,
--				closedOvertimeDuration = closedOvertimeDuration + newlyClosedOvertime
--				WHERE jobs.jobId=(SELECT timeLog.jobId FROM timeLog WHERE timeLog.ref=newlyClosedRecordRef LIMIT 1);
--				
--				UPDATE timeLog
--				SET workedDuration = newlyClosedDuration,
--				overtimeDuration = newlyClosedOvertime
--				WHERE timeLog.ref=newlyClosedRecordRef;
--			   
--			END IF;
			
		ELSE
			-- error message returned
			SELECT "unknownId" as result;
		END IF;
        
    COMMIT;
END;;

DROP PROCEDURE IF EXISTS CompleteStationRenaming;;
CREATE DEFINER=`root`@`localhost` PROCEDURE CompleteStationRenaming( 
    IN StationNewName VARCHAR(50)
    )
    MODIFIES SQL DATA
BEGIN
	DELETE FROM connectedClients 
	WHERE connectedClients.stationId = (
		SELECT currentName
		FROM clientNames 
		WHERE newName = StationNewName
		LIMIT 1
	);

	DELETE FROM clientNames WHERE newName = StationNewName;
	
	INSERT INTO connectedClients (stationId, lastSeen) VALUES (StationNewName, CURRENT_TIMESTAMP);
	
END;;

DELIMITER ;
