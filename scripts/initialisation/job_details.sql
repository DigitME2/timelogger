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

		IF @num_units != 0 THEN
			SET @outstanding = @num_units - @stationQuantityComplete;
		ELSE
			SET @outstanding = Null;
		END IF;
        
        INSERT INTO collapsedTimeRecords(stationId, recordStartDate, recordEndDate, workedDuration, overtimeDuration, workStatus, quantityComplete, outstanding, routeStageIndex)
        SELECT @stationId, @startDate, @endDate, SUM(workedDuration), SUM(overtimeDuration), @workStatus, @stationQuantityComplete, @outstanding, @routeStageIndex
        FROM timeRecords WHERE stationId=@stationId AND routeStageIndex = @routeStageIndex AND recordDate >= @startDate;

		UPDATE collapsedTimeRecords
		SET routeStageIndex = Null
		WHERE routeStageIndex = -1;

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

 
 
 
DROP PROCEDURE IF EXISTS GetFullJobTimeLog;;
CREATE DEFINER=`root`@`localhost` PROCEDURE GetFullJobTimeLog(
    IN JobId VARCHAR(20),
    IN LimitDateRange TINYINT(1),
    IN StartDate DATE,
    IN EndDate DATE
    )
    MODIFIES SQL DATA
BEGIN
	CREATE TEMPORARY TABLE timeLogData AS SELECT * FROM timeLog WHERE timeLog.jobId=JobId;
	
	SET @now = CURRENT_TIME;
	
    UPDATE timeLogData 
	SET workedDuration = TIME_TO_SEC(TIMEDIFF(@now, clockOnTime)),
	overtimeDuration = CalcOvertimeDuration(clockOnTime, @now, recordDate)
	WHERE workedDuration IS NULL;
	
	-- control selection within date range
	IF LimitDateRange THEN
		SELECT
		ref,
		stationId,
		userName,
		clockOnTime,
		clockOffTime,
		recordDate,
		workedDuration AS workedTime,
		overtimeDuration AS overtime,
		workStatus,
		quantityComplete
		FROM timeLogData
		JOIN users ON timeLogData.userId = users.userId
		WHERE recordDate >= StartDate AND recordDate <= EndDate
		ORDER BY recordTimeStamp DESC;
 	ELSE
		SELECT
		ref,
		stationId,
		userName,
		clockOnTime,
		clockOffTime,
		recordDate,
		workedDuration AS workedTime,
		overtimeDuration AS overtime,
		workStatus,
		quantityComplete
		FROM timeLogData
		JOIN users ON timeLogData.userId = users.userId
		ORDER BY recordTimeStamp DESC;
	END IF;
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
