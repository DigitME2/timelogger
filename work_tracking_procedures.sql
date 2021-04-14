DELIMITER ;;

-- client_input.sql
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
			-- error message returned
			SELECT "unknownId" as result;
		END IF;
        
    COMMIT;
END;;


-- procedure to add lunch breaks or trim times to set lunch hours
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

-- clock_off_event.sql -------------------------------------------------------

SET GLOBAL event_scheduler = ON;

DELIMITER ;;


DROP EVENT IF EXISTS autoClockOff;;
CREATE EVENT autoClockOff
	ON SCHEDULE
		EVERY 1 DAY
		STARTS '2018-08-13 23:59:00' ON COMPLETION PRESERVE ENABLE 
	DO
		CALL clockOffAllUsers();;


DROP PROCEDURE IF EXISTS clockOffAllUsers;;
CREATE DEFINER=`root`@`localhost` PROCEDURE clockOffAllUsers()
    MODIFIES SQL DATA
BEGIN    
	-- The current time and date are unboxed ensure that all records are 
	-- processed using the correct timestamp, rather than risking a large
	-- enough number being processed that it pushes the current date into
	-- tomorrow and messes up the calculations
	SELECT CURRENT_TIME, CURRENT_DATE INTO @currentTime, @currentDate; 
	
    CREATE TEMPORARY TABLE refs(ref INT PRIMARY KEY, jobId VARCHAR(20));
    
    START TRANSACTION;
		INSERT INTO refs(ref, jobId) 
		SELECT timeLog.ref, timeLog.jobId FROM timeLog
		WHERE clockOffTime IS NULL;
		
		
		SELECT endTime 
		INTO @dayEndTime 
		FROM workHours 
		WHERE DAYNAME(dayDate) = DAYNAME(@currentDate)
		LIMIT 1;
		
		
		UPDATE timeLog
		SET clockOffTime = SEC_TO_TIME(
			GREATEST(
				TIME_TO_SEC(clockOnTime),
				TIME_TO_SEC(@dayEndTime)
			)
		)
		WHERE timeLog.ref IN (SELECT ref FROM refs);
		
		UPDATE timeLog
		SET workedDuration = TIME_TO_SEC(
			TIMEDIFF(
				clockOffTime,
				clockOnTime
			)
		),
		overtimeDuration = CalcOvertimeDuration(
			clockOnTime,
			clockOffTime,
			@currentDate
		),
		workStatus = "unknown"
		WHERE timeLog.ref IN (SELECT ref FROM refs);
        
		-- update jobs table. Loop through the references recorded in the 
		-- temporary table. Definitely not the most efficient way, but I'm
		-- getting a headache and this will work. Runs late at night, so
		-- shouldn't get in the way of normal operations.
		REPEAT
			SELECT ref, jobId 
			INTO @ref, @jobId 
			FROM refs 
			ORDER BY ref LIMIT 1;
			
			SELECT workedDuration, overtimeDuration 
			INTO @workedDuration, @overtimeDuration 
			FROM timeLog
			WHERE timeLog.ref = @ref;
			
			UPDATE jobs SET
			jobs.closedWorkedDuration = jobs.closedWorkedDuration + @workedDuration,
			jobs.closedOvertimeDuration = jobs.closedOvertimeDuration + @overtimeDuration
			WHERE jobs.jobId = @jobId;
			
			DELETE FROM refs WHERE refs.ref = @ref;
			
			SELECT COUNT(*) INTO @countRemaining FROM refs;
			
		UNTIL @countRemaining =  0
		END REPEAT;
		
    COMMIT;
END;;

DELIMITER ;

-- job_details ---------------------------------------------------------------

DELIMITER ;;

DROP PROCEDURE IF EXISTS CalcWorkedTimes;;
CREATE DEFINER=`root`@`localhost` PROCEDURE CalcWorkedTimes(
    IN JobId VARCHAR(20),
    IN LimitDateRange TINYINT(1),
    IN StartDate DATE,
    IN EndDate DATE,
	OUT WorkedTimeSec INT,
	OUT OvertimeSec INT
    )
    MODIFIES SQL DATA
BEGIN

    -- Calculates the total worked time and total overtime, including currently open timelog records.
    -- See method used in overview.sql
    
    CREATE TEMPORARY TABLE openTimes (openDuration INT, openOvertimeDuration INT);
    	
	SET @query = 
    CONCAT("INSERT INTO openTimes (openDuration, openOvertimeDuration)
    SELECT
    TIME_TO_SEC(TIMEDIFF(CURRENT_TIME, clockOnTime)),
    CalcOvertimeDuration(clockOnTime, CURRENT_TIME, CURRENT_DATE)
    FROM timeLog WHERE clockOffTime IS NULL AND timeLog.jobId='",JobId,"' ");
    
    IF LimitDateRange THEN
        SET @query = CONCAT(@query, " AND timeLog.recordDate >= '", StartDate, "' AND timeLog.recordDate <= '", EndDate, "'");
    END IF;
	
    PREPARE stmt FROM @query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    -- dummy value so the table isn't empty
    INSERT INTO openTimes VALUES (0,0);

	IF LimitDateRange THEN

		-- get the duration data from timelog of dates selected
		SELECT
		SUM(workedDuration),
		SUM(overtimeDuration)
		INTO
		@totalWorkedTime,
		@totalOvertime
		FROM timeLog WHERE
		(NOT (clockOffTime IS NULL))
		AND timeLog.jobId = JobId 
		AND timeLog.recordDate >= StartDate
		AND timeLog.recordDate <= EndDate;
		
  	ELSE

		-- get the duration data pre-calculated in jobs table
		SELECT
		closedWorkedDuration,
		closedOvertimeDuration
		INTO
		@totalWorkedTime,
		@totalOvertime
		FROM jobs WHERE jobs.jobId= JobId;	

    END IF;
	
	IF @totalWorkedTime IS NULL THEN
		SET @totalWorkedTime = 0;
	END IF;
	
	IF @totalOvertime IS NULL THEN
		SET @totalOvertime = 0;
	END IF;
	
    SET @totalWorkedTime = @totalWorkedTime + (SELECT SUM(openDuration) FROM openTimes);
    SET @totalOvertime = @totalOvertime + (SELECT SUM(openOvertimeDuration) FROM openTimes);
    
	SELECT @totalWorkedTime, @totalOvertime INTO WorkedTimeSec, OvertimeSec;
END;;


DROP PROCEDURE IF EXISTS GetWorkedTimes;;
CREATE DEFINER=`root`@`localhost` PROCEDURE GetWorkedTimes(
	IN JobId VARCHAR(20),
    IN LimitDateRange TINYINT(1),
    IN StartDate DATE,
    IN EndDate DATE
	)
	MODIFIES SQL DATA
BEGIN
	CALL CalcWorkedTimes(JobId, 0, "", "", @totalWorkedTime, @totalOvertime);
	SELECT @totalWorkedTime, @totalOvertime;
END;;



DROP PROCEDURE IF EXISTS GetJobRecord;;
CREATE DEFINER=`root`@`localhost` PROCEDURE GetJobRecord(
	IN JobId VARCHAR(20)
	)
	MODIFIES SQL DATA
BEGIN
	-- get the total worked time and overtime from a procedure,
	-- then reads the rest of the data directly from the table
	CALL CalcWorkedTimes(JobId, 0, "", "", @totalWorkedTime, @totalOvertime);
	
	SELECT routes.routeDescription INTO @routeDescription FROM routes WHERE routes.routeName = (SELECT jobs.routeName FROM jobs WHERE jobs.jobId = JobId) LIMIT 1;
	
	SELECT
	jobs.expectedDuration,
	@totalWorkedTime,
	@totalOvertime,
	jobs.description,
	jobs.currentStatus,
	jobs.relativePathToQrCode,
	jobs.recordAdded,
	jobs.notes,
	jobs.routeName,
	jobs.routeCurrentStageName,
	jobs.routeCurrentStageIndex,
	@routeDescription,
	jobs.priority,
	jobs.dueDate,
	jobs.stoppages,
	jobs.numberOfUnits,
	jobs.totalChargeToCustomer,
	jobs.productId
	FROM jobs
	WHERE jobs.jobId = JobId
	LIMIT 1;
	
	
	
END;;
	

DROP PROCEDURE IF EXISTS GetCollapsedJobTimeLog;;
CREATE DEFINER=`root`@`localhost` PROCEDURE GetCollapsedJobTimeLog(
    IN JobId VARCHAR(20),
    IN LimitDateRange TINYINT(1),
    IN StartDate DATE,
    IN EndDate DATE
    )
    MODIFIES SQL DATA
BEGIN

	SELECT numberOfUnits INTO @num_units FROM jobs WHERE jobs.jobId=JobId LIMIT 1;

	-- create temporary tables to hold records for this
    -- job, then find the collapsed form of the records.
    CREATE TEMPORARY TABLE collapsedTimeRecords(stationId VARCHAR(50), recordStartDate DATE, recordEndDate DATE, workedDuration INT, overtimeDuration INT, workStatus VARCHAR(20), quantityComplete INT, outstanding INT);
    
	IF LimitDateRange THEN
    	CREATE TEMPORARY TABLE timeRecords AS SELECT * FROM timeLog WHERE timeLog.jobId=JobId AND recordDate >= StartDate AND recordDate <= EndDate;
	ELSE
    	CREATE TEMPORARY TABLE timeRecords AS SELECT * FROM timeLog WHERE timeLog.jobId=JobId;
    END IF;
    
    -- close off and update the local copy of any open records.
    SET @query = 
    "UPDATE timeRecords
    SET workedDuration = TIME_TO_SEC(TIMEDIFF(CURRENT_TIME, clockOnTime)),
    overtimeDuration = CalcOvertimeDuration(clockOnTime, CURRENT_TIME, CURRENT_DATE)
    WHERE clockOffTime IS NULL ";
    
    PREPARE stmt FROM @query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    CREATE INDEX IDX_date_status ON timeRecords (recordDate, workStatus);
    
    -- loop search condition
	
    SET @remainingCount = 0;
    
    SET @stationId = "";
	SET @startDate = NULL;
	SET @endDate = NULL;
    
    CREATE TEMPORARY TABLE stations AS SELECT DISTINCT stationId FROM timeRecords;

	SELECT COUNT(*) INTO @remainingCount FROM stations;
    
    REPEAT

		SET @stationId = '';
		SET @startDate = NULL;
		SET @endDate = NULL;

		SELECT stationId INTO @stationId FROM stations LIMIT 1;
		
		-- Get the earliest remaining record in our copy of timeLog.
	    SELECT recordDate INTO @startDate 
	    FROM timeRecords
		WHERE stationId = @stationId
	    ORDER BY recordTimestamp ASC LIMIT 1;	    
	    
	    -- Attempt to find the latest corresponding record, where the status is 'stageComplete'. May return null.
	    SELECT recordDate, workStatus
	    INTO @endDate, @workStatus
	    FROM timeRecords 
	    WHERE stationId = @stationId
	    ORDER BY recordDate DESC LIMIT 1;

		SELECT sum(quantityComplete) INTO @stationQuantityComplete
		FROM timeRecords WHERE stationId=@stationId AND recordDate >= @startDate;
        
        INSERT INTO collapsedTimeRecords(stationId, recordStartDate, recordEndDate, workedDuration, overtimeDuration, workStatus, quantityComplete, outstanding)
        SELECT @stationId, @startDate, @endDate, SUM(workedDuration), SUM(overtimeDuration), @workStatus, @stationQuantityComplete, (@num_units - @stationQuantityComplete)
        FROM timeRecords WHERE stationId=@stationId AND recordDate >= @startDate;

		DELETE FROM stations WHERE stationId=@stationId;
        
        SELECT COUNT(*) INTO @remainingCount FROM stations;
        
    UNTIL @remainingCount = 0
    END REPEAT;
    
    SELECT
    stationId,
    recordStartDate,
    recordEndDate,
    workedDuration,
    overtimeDuration,
	workStatus,
	quantityComplete,
	outstanding
    FROM collapsedTimeRecords
    ORDER BY recordStartDate DESC;
 
 END;;
 
 
DROP PROCEDURE IF EXISTS GetCollapsedJobTimeLog;;
CREATE DEFINER=`root`@`localhost` PROCEDURE GetCollapsedJobTimeLog(
    IN JobId VARCHAR(20),
    IN LimitDateRange TINYINT(1),
    IN StartDate DATE,
    IN EndDate DATE
    )
    MODIFIES SQL DATA
BEGIN

	SELECT numberOfUnits INTO @num_units FROM jobs WHERE jobs.jobId=JobId LIMIT 1;

	-- create temporary tables to hold records for this
    -- job, then find the collapsed form of the records.
    CREATE TEMPORARY TABLE collapsedTimeRecords(stationId VARCHAR(50), recordStartDate DATE, recordEndDate DATE, workedDuration INT, overtimeDuration INT, workStatus VARCHAR(20), quantityComplete INT, outstanding INT, routeStageIndex INT(11));
    
	IF LimitDateRange THEN
    	CREATE TEMPORARY TABLE timeRecords AS SELECT * FROM timeLog WHERE timeLog.jobId=JobId AND recordDate >= StartDate AND recordDate <= EndDate;
	ELSE
    	CREATE TEMPORARY TABLE timeRecords AS SELECT * FROM timeLog WHERE timeLog.jobId=JobId;
    END IF;
    
    -- close off and update the local copy of any open records.
    SET @query = 
    "UPDATE timeRecords
    SET workedDuration = TIME_TO_SEC(TIMEDIFF(CURRENT_TIME, clockOnTime)),
    overtimeDuration = CalcOvertimeDuration(clockOnTime, CURRENT_TIME, CURRENT_DATE)
    WHERE clockOffTime IS NULL ";
    
    PREPARE stmt FROM @query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    CREATE INDEX IDX_date_status ON timeRecords (recordDate, workStatus);
    
    -- loop search condition
	
    SET @remainingCount = 0;
    
    SET @stationId = "";
	SET @startDate = NULL;
	SET @endDate = NULL;
    
    CREATE TEMPORARY TABLE stations AS SELECT DISTINCT stationId, routeStageIndex FROM timeRecords;

	SELECT COUNT(*) INTO @remainingCount FROM stations;
    
    REPEAT

		SET @stationId = '';
		SET @startDate = NULL;
		SET @endDate = NULL;

		SELECT stationId, routeStageIndex INTO @stationId, @routeStageIndex FROM stations LIMIT 1;
		
		-- Get the earliest remaining record in our copy of timeLog.
	    SELECT recordDate INTO @startDate 
	    FROM timeRecords
		WHERE stationId = @stationId AND routeStageIndex = @routeStageIndex
	    ORDER BY recordTimestamp ASC LIMIT 1;	    
	    
	    -- Attempt to find the latest corresponding record, where the status is 'stageComplete'. May return null.
	    SELECT recordDate, workStatus
	    INTO @endDate, @workStatus
	    FROM timeRecords 
	    WHERE stationId = @stationId AND routeStageIndex = @routeStageIndex
	    ORDER BY recordDate DESC LIMIT 1;

		SELECT sum(quantityComplete) INTO @stationQuantityComplete
		FROM timeRecords WHERE stationId=@stationId AND routeStageIndex = @routeStageIndex AND recordDate >= @startDate;
        
        INSERT INTO collapsedTimeRecords(stationId, recordStartDate, recordEndDate, workedDuration, overtimeDuration, workStatus, quantityComplete, outstanding, routeStageIndex)
        SELECT @stationId, @startDate, @endDate, SUM(workedDuration), SUM(overtimeDuration), @workStatus, @stationQuantityComplete, (@num_units - @stationQuantityComplete), @routeStageIndex
        FROM timeRecords WHERE stationId=@stationId AND routeStageIndex = @routeStageIndex AND recordDate >= @startDate;

		DELETE FROM stations WHERE stationId=@stationId AND routeStageIndex = @routeStageIndex;
        
        SELECT COUNT(*) INTO @remainingCount FROM stations;
        
    UNTIL @remainingCount = 0
    END REPEAT;
    
    SELECT
    stationId,
    recordStartDate,
    recordEndDate,
    workedDuration,
    overtimeDuration,
	workStatus,
	quantityComplete,
	outstanding,
	routeStageIndex
    FROM collapsedTimeRecords
    ORDER BY recordStartDate DESC;
 
 END;;
 
 
DROP PROCEDURE IF EXISTS MarkJobComplete;;
CREATE DEFINER=`root`@`localhost` PROCEDURE MarkJobComplete(
    IN JobId VARCHAR(20)
    )
    MODIFIES SQL DATA
BEGIN
    -- Get references to any open records, close them,
    -- update the jobs table with the new times, then 
    -- sets the status of the job to complete.
    
    CREATE TEMPORARY TABLE jobRefs(ref BIGINT);
    
    INSERT INTO jobRefs(ref) SELECT ref FROM timeLog WHERE timeLog.jobId=JobId AND clockOffTime IS NULL;
    
    UPDATE timeLog SET clockOffTime = CURRENT_TIME WHERE timeLog.ref IN (SELECT ref FROM jobRefs);
    
    SELECT COUNT(ref) INTO @refCount FROM jobRefs;
    IF @refCount > 0 THEN
        UPDATE timeLog SET 
        workedDuration = TIME_TO_SEC(TIMEDIFF(clockOffTime, clockOnTime)),
        overtimeDuration = CalcOvertimeDuration(clockOnTime, clockOffTime, recordDate),
        workStatus = "stageComplete"
        WHERE timeLog.ref in (SELECT ref FROM jobRefs);
        
        UPDATE jobs SET
        closedWorkedDuration = closedWorkedDuration + (SELECT SUM(workedDuration) FROM timeLog WHERE timeLog.ref IN (SELECT ref FROM jobRefs))
        WHERE jobs.jobId=JobId;

	UPDATE jobs SET
        closedOvertimeDuration = closedOvertimeDuration + (SELECT SUM(overtimeDuration) FROM timeLog WHERE timeLog.ref IN (SELECT ref FROM jobRefs))
        WHERE jobs.jobId=JobId;
    END IF;
    
    UPDATE jobs SET currentStatus = "complete", routeCurrentStageName = Null, routeCurrentStageIndex=-1 WHERE jobs.jobId = JobId;
END;;

DROP PROCEDURE IF EXISTS GetStoppagesLog;;
CREATE DEFINER=`root`@`localhost` PROCEDURE GetStoppagesLog(
    IN JobId VARCHAR(20)
    )
    MODIFIES SQL DATA
BEGIN
	CREATE TEMPORARY TABLE stoppagesLogData AS SELECT * FROM stoppagesLog WHERE stoppagesLog.jobId=JobId;
	
--	SET @now = CURRENT_TIME;
	
--    UPDATE timeLogData 
--	SET workedDuration = TIME_TO_SEC(TIMEDIFF(@now, clockOnTime)),
--	overtimeDuration = CalcOvertimeDuration(clockOnTime, @now, recordDate)
--	WHERE workedDuration IS NULL;
	
	-- control selection within date range
	SELECT
	ref,
	jobId,
	stationId,
	stoppageReasonName,
	description,
	startTime,
	endTime,
	startDate,
	endDate,
	duration,
	status
	FROM stoppagesLogData
	JOIN stoppageReasons ON stoppagesLogData.stoppageReasonId = stoppageReasons.stoppageReasonId
	ORDER BY recordTimeStamp DESC;

 END;;

-- check if the route has changed by comparing the provided routeNane and jobs current routeName
-- If routeName has changed change all routeStageIndex's in timelog to -1  for the job
DROP PROCEDURE IF EXISTS CheckChangeOfRoute;;
CREATE DEFINER=`root`@`localhost` PROCEDURE CheckChangeOfRoute(
	IN JobId VARCHAR(20),
    IN InputRouteName varchar(100)
	)
	MODIFIES SQL DATA
BEGIN

	SELECT jobs.routeName into @ExistingRouteName FROM jobs WHERE jobs.jobId = JobId;

	IF @ExistingRouteName != InputRouteName THEN
		UPDATE timeLog SET routeStageIndex = -1 WHERE timeLog.jobId = JobId;
	END IF;
END;;

DELIMITER ;
-- overtime_calc_func.sql -------------------------------------------------------

DELIMITER ;;

DROP FUNCTION IF EXISTS CalcOvertimeDuration;;
CREATE FUNCTION CalcOvertimeDuration(
    JobStartTime TIME,
    JobEndTime TIME,
    RecordDate DATE
) 
    RETURNS INT
    MODIFIES SQL DATA
BEGIN
    DECLARE startTimeSec INT DEFAULT 9999999;
    DECLARE endTimeSec INT DEFAULT 9999999;
    DECLARE startWorkDaySec INT DEFAULT 9999999;
    DECLARE endWorkDaySec INT DEFAULT 9999999;
    DECLARE calcualtedOvertime INT DEFAULT 9999999;
    
	SET startTimeSec = TIME_TO_SEC(JobStartTime);
    SET endTimeSec = TIME_TO_SEC(JobEndTime);
    
    SELECT TIME_TO_SEC(workHours.startTime)
    INTO startWorkDaySec
    FROM workHours
    WHERE DAYNAME(dayDate) = DAYNAME(RecordDate);
    
    SELECT TIME_TO_SEC(workHours.endTime)
    INTO endWorkDaySec
    FROM workHours
    WHERE DAYNAME(dayDate) = DAYNAME(RecordDate);
        
    -- SELECT startTimeSec, endTimeSec, startWorkDaySec, endWorkDaySec;
        
    -- If both the start and end times are within the normal workday,
    -- overtime is zero
	IF 	(startTimeSec BETWEEN startWorkDaySec AND endWorkDaySec) AND 
    	(endTimeSec BETWEEN startWorkDaySec AND endWorkDaySec) THEN
    	SET calcualtedOvertime = 0;
        
    -- If the start time is before the day start and the end time is
    -- after the day end, return the total time minus the normal workday
    -- duration
    ELSEIF startTimeSec < startWorkDaySec 
    AND endTimeSec > endWorkDaySec THEN
        SET calcualtedOvertime =
        	(endTimeSec - startTimeSec) 
            - (endWorkDaySec - startWorkDaySec);
            
	-- if the times are both outside work hours (by this point both must
    -- be at the start or the end of the day), return the difference
    ELSEIF (startTimeSec NOT BETWEEN 
             startWorkDaySec AND endWorkDaySec) 
    AND (endTimeSec NOT BETWEEN 
         startWorkDaySec AND endWorkDaySec) THEN
    	SET calcualtedOvertime = endTimeSec - startTimeSec;
       
       
    -- If the start is before the start of the normal day, return the 
    -- difference between the two
	ELSEIF (startTimeSec < startWorkDaySec) THEN
    	SET calcualtedOvertime = startWorkDaySec - startTimeSec;
    
    -- If the end is after the end of the normal day, return the 
    -- difference between the two
    ELSEIF (endTimeSec > endWorkDaySec) THEN
    	SET calcualtedOvertime = endTimeSec - endWorkDaySec;
    
    END IF;
        
    RETURN calcualtedOvertime;
    -- SELECT calcualtedOvertime;
    
END;;
DELIMITER ;

-- overview.sql --------------------------------------------------------------

DELIMITER ;;

DROP PROCEDURE IF EXISTS GetOverviewData;;
-- Selects jobId, description, currentStatus, timestamp, current total worked
-- duration, of which current overtime worked, efficiency (total time / expected,
-- maximum of 1), expectedDuration. Times are in seconds.
CREATE DEFINER=`root`@`localhost` PROCEDURE GetOverviewData(
	IN UseSearchKey TINYINT(1),
	IN SearchKey VARCHAR(200),
	IN HideCompletedJobs TINYINT(1),
	IN LimitDateCreatedRange TINYINT(1),
	IN DateCreatedStart DATE,
	IN DateCreatedEnd DATE,
	IN LimitDateDueRange TINYINT(1),
	IN DateDueStart DATE,
	IN DateDueEnd DATE,
	IN ShowOnlyUrgentJobs TINYINT(1),
	IN ShowOnlyNonurgentJobs TINYINT(1),
	IN OrderByCreatedAsc TINYINT(1),
	IN OrderByCreatedDesc TINYINT(1),
	IN OrderByDueAsc TINYINT(1),
	IN OrderByDueDesc TINYINT(1),
	IN OrerByJobId TINYINT(1),
	IN OrderBypriority TINYINT(1),
	IN SubOrderByPriority TINYINT(1)
	)
BEGIN


    CREATE TEMPORARY TABLE openTimes (jobId VARCHAR(20), openDuration INT, openOvertimeDuration INT);
    CREATE TEMPORARY TABLE selectedJobIds (counter INT PRIMARY KEY AUTO_INCREMENT, jobId VARCHAR(20));

	-- Construct a query to select the job IDs meeting the required selection criteria (completed or not, date range, etc)...
	SET @selectionQuery = "INSERT INTO selectedJobIds (jobId) SELECT jobId FROM jobs ";
	
	IF UseSearchKey THEN
		SET @searchPattern = CONCAT("%", SearchKey, "%");
	END IF;
	
	SET @conditionPrecederTerm = " WHERE "; 

	-- ...appending the relevant selection options...
	IF UseSearchKey IS TRUE THEN
		SET @selectionQuery = CONCAT(@selectionQuery, " WHERE (description LIKE '", @searchPattern, "' OR jobId LIKE '", @searchPattern, "' or  productId LIKE '", @searchPattern, "')");
		
		-- this is set to " WHERE ", then changed to " AND " after the first condition is set.
		SET @conditionPrecederTerm = " AND "; 
	END IF;
		
		
	IF HideCompletedJobs IS TRUE THEN
		SET @selectionQuery = CONCAT(@selectionQuery, @conditionPrecederTerm, "currentStatus != 'complete'");
		SET @conditionPrecederTerm = " AND ";
	END IF;
		
		
	IF LimitDateCreatedRange IS TRUE THEN
		SET @selectionQuery = CONCAT(@selectionQuery, @conditionPrecederTerm,
			 "DATE(recordAdded) >= '", DateCreatedStart, "' AND DATE(recordAdded) <= '", DateCreatedEnd, "' "
		);
		SET @conditionPrecederTerm = " AND ";
	END IF;
		
		
	IF LimitDateDueRange IS TRUE THEN
		SET @selectionQuery = CONCAT(@selectionQuery, @conditionPrecederTerm,
			 "dueDate >= '", DateDueStart, "' AND dueDate <= '", DateDueEnd, "' "
		);
		SET @conditionPrecederTerm = " AND ";
	END IF;
		
		
	IF ShowOnlyUrgentJobs IS TRUE THEN
			SET @selectionQuery = CONCAT(@selectionQuery, @conditionPrecederTerm,
				 "priority=4"
			);
	ELSEIF ShowOnlyNonurgentJobs IS TRUE THEN
			SET @selectionQuery = CONCAT(@selectionQuery, @conditionPrecederTerm,
				 "priority<>4"
			);
	END IF;

	-- test
	-- SELECT @selectionQuery;

	-- ... and run the query
	PREPARE jobSelectionStmt FROM @selectionQuery;
	EXECUTE jobSelectionStmt;
	DEALLOCATE PREPARE jobSelectionStmt;

	-- test
	-- SELECT * FROM selectedJobIds;

	-- Perform a few actions to produce a create a list of times for open records. This is required to get an accurate time
    -- if a job is currently being worked on.
    -- Get the relevant jobs
    INSERT INTO openTimes(jobId, openDuration, openOvertimeDuration)
    SELECT 
    timeLog.jobId,
    TIME_TO_SEC(TIMEDIFF(CURRENT_TIME, clockOnTime)),
    CalcOvertimeDuration(clockOnTime, CURRENT_TIME, CURRENT_DATE)
    FROM timeLog
    WHERE clockOffTime IS NULL AND timeLog.jobId IN (SELECT jobId FROM selectedJobIds);
    
    -- test
    -- SELECT * FROM openTimes;
    
    -- Create dummy entries to simplify things a little later on. These are used to ensure that there
    -- is at least one entry for each job.
    INSERT INTO openTimes (jobId, openDuration, openOvertimeDuration)
    SELECT jobId, 0, 0 FROM selectedJobIds;
    
    CREATE INDEX idx_openTimes_jobIds ON openTimes(jobId);
    
    
    -- test
    -- SELECT * FROM openTimes;
    
    
    
    -- Create and run the final query to select the data from the timeLog and combine
    -- it with the calculated durations for jobs that are still open. Efficiency is
    -- also calculated here, to minimise post processing required in PHP or JS.
    -- Selects jobId, description, currentStatus, timestamp, current total worked
    -- duration, of which current overtime worked, efficiency (total time / expected,
    -- maximum of 1), expectedDuration
	SET @finalSelectorQuery = 
    "SELECT
    jobs.jobId AS jobId,
    description,
    currentStatus,
    recordAdded,
    closedWorkedDuration + SUM(openDuration) AS totalWorkedDuration,
    closedOvertimeDuration + SUM(openOvertimeDuration) AS totalOvertimeDuration,
    LEAST((expectedDuration/(closedWorkedDuration + SUM(openDuration))),1) AS efficiency,
    expectedDuration,
	routeCurrentStageName,
	priority,
	dueDate,
	stoppages,
	numberOfUnits,
	totalChargeToCustomer,
	productId
    FROM jobs LEFT JOIN openTimes ON jobs.jobId = openTimes.jobId
    WHERE jobs.jobId IN (SELECT jobId FROM selectedJobIds ORDER BY counter ASC)
    GROUP BY jobs.jobId ";
	
	
	-- ... and the ordering constraint...
	IF OrderBycreatedAsc IS TRUE THEN
		SET @finalSelectorQuery = CONCAT(@finalSelectorQuery, " ORDER BY recordAdded ASC ");
	ELSEIF OrderByCreatedDesc IS TRUE THEN
		SET @finalSelectorQuery = CONCAT(@finalSelectorQuery, " ORDER BY recordAdded DESC ");
	ELSEIF OrderByDueAsc IS TRUE THEN
		SET @finalSelectorQuery = CONCAT(@finalSelectorQuery, " ORDER BY dueDate ASC ");
	ELSEIF OrderByDueDesc IS TRUE THEN
		SET @finalSelectorQuery = CONCAT(@finalSelectorQuery, " ORDER BY dueDate DESC ");
	ELSEIF OrerByJobId IS TRUE THEN
		SET @finalSelectorQuery = CONCAT(@finalSelectorQuery, " ORDER BY jobs.jobId ASC ");
	ELSEIF OrderBypriority IS TRUE THEN
		SET @finalSelectorQuery = CONCAT(@finalSelectorQuery, " ORDER BY jobs.priority DESC ");
	END IF;

	IF SubOrderByPriority IS TRUE THEN
		SET @finalSelectorQuery = CONCAT(@finalSelectorQuery, ", priority DESC ");
	END IF;
    
	PREPARE jobSelectionStmt FROM @finalSelectorQuery;
	EXECUTE jobSelectionStmt;
	DEALLOCATE PREPARE jobSelectionStmt;
	
    DROP TABLE openTimes;
    DROP TABLE selectedJobIds;
END;;

DELIMITER ;

-- recalculate_durartions_func -----------------------------------------------

DELIMITER ;;

DROP PROCEDURE IF EXISTS recalculateDurartions;;
CREATE DEFINER=`root`@`localhost` PROCEDURE recalculateDurartions(
	IN clockOffUsers TINYINT(1)
	)
    MODIFIES SQL DATA
BEGIN
	-- clock off all users if clockOffUsers set to true, 
    -- calculate workduration and overtime for all timelog records
	-- Add all time log records for a particular job
    
	IF clockOffUsers THEN
		-- Clock off any users currently clocked on
		CALL clockOffAllUsers();

		SET @numActiveUsers = 0;
	ELSE
		-- get number of users curently clocked on
		SELECT COUNT(ref) INTO @numActiveUsers FROM timeLog WHERE clockOffTime IS NULL;
	END IF;

	IF @numActiveUsers != 0 THEN
		-- if any users clocked on give and error msg
		SELECT 'Error: Users clocked on' as result;
	ELSE

		UPDATE timeLog SET 
		workedDuration = TIME_TO_SEC(TIMEDIFF(clockOffTime, clockOnTime)),
		overtimeDuration = CalcOvertimeDuration(clockOnTime, clockOffTime, recordDate);

		UPDATE jobs SET
		closedWorkedDuration = (SELECT COALESCE(SUM(workedDuration),0) FROM timeLog WHERE timeLog.jobId=jobs.jobId),
		closedOvertimeDuration = (SELECT COALESCE(SUM(overtimeDuration),0) FROM timeLog WHERE timeLog.jobId=jobs.jobId);

		SELECT 'Success' as result;
    END IF;
END;;

DELIMITER ;

-- timesheet -----------------------------------------------------------------

DELIMITER ;;

DROP PROCEDURE IF EXISTS GetTimesheet;;
CREATE DEFINER=`root`@`localhost` PROCEDURE GetTimesheet(
    IN UserId VARCHAR(20),
    IN StartDate DATE,
    IN EndDate DATE
    )
    MODIFIES SQL DATA
BEGIN
    -- Calculates the total worked time and total overtime, including currently open jobs.
    -- See method used in overview.sql
    
	-- DROP TABLE IF EXISTS jobDurations;
    CREATE TEMPORARY TABLE jobDurations (recordDate DATE, jobId VARCHAR(20), duration INT, overtimeDuration INT);
    
	-- test
	-- SELECT * FROM jobDurations;
	
    -- handle open records first
    INSERT INTO jobDurations (recordDate, jobId, duration, overtimeDuration)
    SELECT
    recordDate,
    timeLog.jobId,
    TIME_TO_SEC(TIMEDIFF(CURRENT_TIME, clockOnTime)),
    CalcOvertimeDuration(clockOnTime, CURRENT_TIME, CURRENT_DATE)
    FROM timeLog WHERE clockOffTime IS NULL 
    AND timeLog.userId=UserId
    AND recordDate >= StartDate
    AND recordDate <= EndDate;
	
	-- test
	-- SELECT * FROM jobDurations;
	
    -- Then the rest of the records
    INSERT INTO jobDurations (recordDate, jobId, duration, overtimeDuration)
    SELECT
    recordDate,
    timeLog.jobId,
    TIME_TO_SEC(TIMEDIFF(clockOffTime, clockOnTime)),
    CalcOvertimeDuration(clockOnTime, clockOffTime, recordDate)
    FROM timeLog WHERE clockOffTime IS NOT NULL 
    AND timeLog.userId=UserId
    AND recordDate >= StartDate
    AND recordDate <= EndDate;
	
	-- test
	-- SELECT * FROM jobDurations;
	
	CREATE INDEX IDX_durations_date_jobId ON jobDurations(recordDate, jobId);
    
    SELECT paramValue INTO @allowMultipleClockOn 
    FROM config WHERE paramName = "allowMultipleClockOn" LIMIT 1;
    
	-- Note that if multiple jobs may be clocked onto simultaneously by a 
	-- single user, then the total worked time and overtime is considered
	-- to be undefined.
    IF @allowMultipleClockOn = "true" THEN
        SET @totalDuration = -1;
        SET @totalOvertimeDuration = -1;
    ELSE
        SELECT SUM(duration) INTO @totalDuration FROM jobDurations;
        SELECT SUM(overtimeDuration) INTO @totalOvertimeDuration FROM jobDurations;
    END IF;
	
	-- Create a list of unique IDs. This is returned as the first of two results sets.
    SELECT DISTINCT jobId FROM jobDurations ORDER BY jobId ASC;
	
    -- select the times from the table, ordered appropriately. This second result set is 
	-- processed into the rows and columns of a time sheet in the PHP code that called 
	-- this procedure.
	SELECT recordDate, jobId, SUM(duration) AS workedDuration, SUM(overtimeDuration) AS overtimeDuration FROM jobDurations GROUP BY recordDate, jobId ORDER BY recordDate;
	
	SELECT @totalDuration, @totalOvertimeDuration;
	
END;;

DELIMITER ;

-- work_log_event ------------------------------------------------------------

DELIMITER ;;

DROP PROCEDURE IF EXISTS changeWorkLogRecord;;
CREATE DEFINER=`root`@`localhost` PROCEDURE changeWorkLogRecord(
	IN workLogRef VARCHAR(20),
	IN station VARCHAR(50),
	IN clockOnTime TIME,
	IN clockOffTime TIME,
	IN workStatus VARCHAR(20),
	IN quantityComplete INT(11)
	)
	MODIFIES SQL DATA
BEGIN
	
	DECLARE orgDuration INT DEFAULT 0;
	DECLARE orgOvertime INT DEFAULT 0;

	DECLARE orgClockOffTime TIME;

	DECLARE newDuration INT DEFAULT 0;
	DECLARE newOvertime INT DEFAULT 0;
	
	DECLARE durationDifference INT DEFAULT 0;
	DECLARE overtimeDifference INT DEFAULT 0;

	DECLARE eventDate DATE;
	DECLARE eventJobId VARCHAR(20);

	SELECT workedDuration, overtimeDuration, recordDate, jobId, clockOffTime INTO orgDuration, orgOvertime, eventDate, eventJobId, orgClockOffTime
	FROM timeLog
	WHERE timeLog.ref=workLogRef;
	
	IF (orgClockOffTime <> '00:00:00') THEN
		-- find the new total duration
		SET newDuration = TIME_TO_SEC(TIMEDIFF(clockOffTime, clockOnTime));
		
		-- find the new overtime duration
		SET newOvertime = CalcOvertimeDuration(clockOnTime, clockOffTime, eventDate);

		set durationDifference = newDuration - orgDuration;

		set overtimeDifference = newOvertime - orgOvertime;
		
		-- update records
		UPDATE jobs 
		SET closedWorkedDuration = closedWorkedDuration + durationDifference,
		closedOvertimeDuration = closedOvertimeDuration + overtimeDifference
		WHERE jobs.jobId=eventJobId;
		
		UPDATE timeLog
		SET clockOnTime = clockOnTime,
		clockOffTime = clockOffTime,
		workedDuration = newDuration,
		overtimeDuration = newOvertime,
		stationId = station,
		workStatus = workStatus,
		quantityComplete = quantityComplete
		WHERE timeLog.ref=workLogRef;

		SELECT "success" as result;
	ELSE
		IF not (clockOnTime > CURRENT_TIME) THEN
			UPDATE timeLog
			SET clockOnTime = clockOnTime,
			stationId = station
			WHERE timeLog.ref=workLogRef;

			SELECT "success" as result;
		ELSE
			SELECT "Start Time in future" as result;
		END IF;
	END IF;

END;;

DELIMITER ;;

DROP PROCEDURE IF EXISTS insertBreak;;
CREATE DEFINER=`root`@`localhost` PROCEDURE insertBreak(
	IN workLogRef VARCHAR(20),
	IN breakStart TIME,
	IN breakEnd TIME
	)
	MODIFIES SQL DATA
BEGIN
	-- Split time log event into 2 seperate events: P1 Time before Break, P2 Time After Break. Update existing record to act as P1 and create new record for P2
	DECLARE orgStartTime TIME;
	DECLARE orgEndTime TIME;

	DECLARE p1Duration INT DEFAULT 0;
	DECLARE p1Overtime INT DEFAULT 0;

	DECLARE p2Duration INT DEFAULT 0;
	DECLARE p2Overtime INT DEFAULT 0;
	
	DECLARE breakDuration INT DEFAULT 0;
	DECLARE breakOvertime INT DEFAULT 0;

	DECLARE eventDate DATE;
	DECLARE eventJobId VARCHAR(20);
	

	-- Get Work Log Event Information
	SELECT clockOnTime, clockOffTime, recordDate, jobId, userId, stationId, workStatus, recordTimeStamp INTO orgStartTime, orgEndTime, eventDate, eventJobId, @eventUser, @eventStation, @eventStatus, @recordTimeStamp
	FROM timeLog
	WHERE timeLog.ref=workLogRef;
	
	IF (orgEndTime <> '00:00:00') THEN
		if NOT(breakStart < orgStartTime OR breakEnd > orgEndTime OR breakStart >= breakEnd) THEN
		
			-- find the newly closed total duration
			SET breakDuration = TIME_TO_SEC(TIMEDIFF(breakEnd, breakStart));

			-- find the newly closed overtime duration
			SET breakOvertime = CalcOvertimeDuration(breakStart, breakEnd, eventDate);

			-- update Job record of duration and overtime
			UPDATE jobs 
			SET closedWorkedDuration = closedWorkedDuration - breakDuration,
			closedOvertimeDuration = closedOvertimeDuration - breakOvertime
			WHERE jobs.jobId=eventJobId;


			-- Find duration and overtime for P1
			SET p1Duration = TIME_TO_SEC(TIMEDIFF(breakStart, orgStartTime));
			SET p1Overtime = CalcOvertimeDuration(orgStartTime, breakStart, eventDate);

			UPDATE timeLog
			SET clockOffTime = breakStart,
			workedDuration = p1Duration,
			overtimeDuration = p1Overtime,
			workStatus = 'workInProgress'
			WHERE timeLog.ref=workLogRef;

			-- Find duration and overtime for P2 and add record
			SET p2Duration = TIME_TO_SEC(TIMEDIFF(orgEndTime, breakEnd));
			SET p2Overtime = CalcOvertimeDuration(breakEnd, orgEndTime, eventDate);

			INSERT INTO timeLog (jobId, stationId, userId, clockOnTime, clockOffTime, recordDate, workedDuration, overtimeDuration, workStatus, recordTimeStamp)
			VALUES (eventJobId, @eventStation, @eventUser, breakEnd, orgEndTime, eventDate, p2Duration, p2Overtime, @eventStatus, @recordTimeStamp);

			SELECT "success" as result;

		ELSE
			SELECT "Break not within clock in period" as result;
		END IF;
	ELSE
		if NOT(breakStart < orgStartTime OR breakStart > CURRENT_TIME OR breakEnd > CURRENT_TIME OR breakStart >= breakEnd) THEN
			-- Find duration and overtime for P1
			SET p1Duration = TIME_TO_SEC(TIMEDIFF(breakStart, orgStartTime));
			SET p1Overtime = CalcOvertimeDuration(orgStartTime, breakStart, eventDate);

			UPDATE timeLog
			SET clockOffTime = breakStart,
			workedDuration = p1Duration,
			overtimeDuration = p1Overtime,
			workStatus = 'workInProgress'
			WHERE timeLog.ref=workLogRef;

			-- update Job record of duration and overtime
			UPDATE jobs 
			SET closedWorkedDuration = closedWorkedDuration + p1Duration,
			closedOvertimeDuration = closedOvertimeDuration + p1Overtime
			WHERE jobs.jobId=eventJobId;

			-- Create a new record in the time log and set the status of the job to "workInProgress".
			-- The job status is assumed to be either pending, workInProgress, or complete.
			INSERT INTO timeLog (jobId, stationId, userId, clockOnTime, recordDate, workStatus)
			VALUES (eventJobId, @eventStation, @eventUser, breakEnd, eventDate, 'workInProgress');

			SELECT "success" as result;

		ELSE
			SELECT "Break not within clock in period" as result;
		END IF;
	END IF;
END;;



