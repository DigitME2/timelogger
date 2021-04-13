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