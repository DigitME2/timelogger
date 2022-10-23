DELIMITER $$

DROP PROCEDURE IF EXISTS `CalcWorkedTimes`$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `CalcWorkedTimes` (IN `JobId` VARCHAR(20), IN `LimitDateRange` TINYINT(1), IN `StartDate` DATE, IN `EndDate` DATE, OUT `WorkedTimeSec` INT, OUT `OvertimeSec` INT)  MODIFIES SQL DATA
BEGIN

    -- Calculates the total worked time and total overtime, including currently open timelog records.
    -- See method used in overview.sql
    
    CREATE TEMPORARY TABLE openTimes (openDuration INT, openOvertimeDuration INT);
    	
	SET @query = 
    CONCAT("INSERT INTO openTimes (openDuration, openOvertimeDuration)
    SELECT
    TIME_TO_SEC(TIMEDIFF(CURRENT_TIME, clockOnTime)),
    CalcOvertimeDuration(clockOnTime, CURRENT_TIME, CURRENT_DATE)
    FROM timeLog WHERE clockOffTime IS NULL AND stationId IS NOT NULL AND userId IS NOT NULL AND clockOnTime IS NOT NULL AND recordDate IS NOT NULL AND timeLog.jobId='",JobId,"' ");
    
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
		SUM(workedDuration),
		SUM(overtimeDuration)
		INTO
		@totalWorkedTime,
		@totalOvertime
		FROM timeLog WHERE
		(NOT (clockOffTime IS NULL))
		AND timeLog.jobId = JobId;	

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

END$$


DELIMITER ;