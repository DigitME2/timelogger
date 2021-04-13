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