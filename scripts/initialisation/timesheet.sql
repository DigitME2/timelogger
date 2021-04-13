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