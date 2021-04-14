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


