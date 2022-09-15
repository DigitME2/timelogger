DELIMITER $$

DROP PROCEDURE IF EXISTS `changeWorkLogRecord`$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `changeWorkLogRecord` (IN `workLogRef` VARCHAR(20), IN `station` VARCHAR(50), in `recordDate` DATE, IN `clockOnTime` TIME, IN `clockOffTime` TIME, IN `workStatus` VARCHAR(20), IN `quantityComplete` INT(11))  MODIFIES SQL DATA
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

	SELECT workedDuration, overtimeDuration, recordDate, jobId, clockOffTime INTO orgDuration, orgOvertime, recordDate, eventJobId, orgClockOffTime
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
		recordDate = recordDate,
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
	
    END$$

DELIMITER ;