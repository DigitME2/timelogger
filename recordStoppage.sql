DELIMITER $$

DROP PROCEDURE IF EXISTS `recordStoppage`$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `recordStoppage` (IN `TargetedRecordref` BIGINT(20), IN `JobId` VARCHAR(20), IN `StoppageReasonId` VARCHAR(20), IN `StationId` VARCHAR(50), IN `Description` TEXT, IN `StationStatus` VARCHAR(20))  MODIFIES SQL DATA
BEGIN


    DECLARE inputComboOpenRecordRef INT DEFAULT -1;
	DECLARE newlyOpenRecordRef INT DEFAULT -1;
    DECLARE newlyClosedRecordRef INT DEFAULT -1;
    
    DECLARE newlyClosedDuration INT DEFAULT 0;
	
	DECLARE stoppageReasonIdValid INT DEFAULT 0;
	DECLARE jobIDValid INT DEFAULT 0;

	DECLARE startDate DATE;
	DECLARE startTime TIME;

	DECLARE endDate DATE;
	DECLARE endTime TIME;

	DECLARE dateDifference INT DEFAULT 0;
	DECLARE dateDifferenceInSeconds INT DEFAULT 0;
	DECLARE calculatedDuration INT DEFAULT 0;
    
    START TRANSACTION;

		IF TargetedRecordref != -1 THEN
			SET inputComboOpenRecordRef = TargetedRecordref;
		ELSE
			SELECT stoppagesLog.ref INTO inputComboOpenRecordRef FROM stoppagesLog
			WHERE stoppagesLog.endTime IS NULL 
			AND stoppagesLog.stoppageReasonId=StoppageReasonId 
			AND stoppagesLog.jobId=JobId
			AND stoppagesLog.stationId=StationId
			ORDER BY stoppagesLog.recordTimestamp ASC LIMIT 1;
			-- Check that Stoppage Reason ID and job ID are present in relevant tables
			SELECT COUNT(stoppageReasonId) INTO stoppageReasonIdValid FROM stoppageReasons WHERE stoppageReasons.stoppageReasonId=StoppageReasonId LIMIT 1;
			SELECT COUNT(jobId) INTO jobIDValid FROM jobs WHERE jobs.jobId=JobId LIMIT 1;
		END IF;
		
		-- Confirm that both stoppage ID and Job ID are valid 
		IF (stoppageReasonIdValid > 0 AND jobIDValid > 0) OR TargetedRecordref != -1 THEN
			-- Create a new record
			IF inputComboOpenRecordRef = -1 OR inputComboOpenRecordRef IS NULL OR StationStatus='unresolved' THEN
			
				-- Create a new record in the stoppage log.
				-- The job status is required to be unresolved.
				INSERT INTO stoppagesLog (jobId, stationId, stoppageReasonId, description, startTime, startDate, status)
				VALUES (JobId, StationId, StoppageReasonId, Description, CURRENT_TIME, CURRENT_DATE, 'unresolved');
				
				SELECT "stoppageOn" as result, inputComboOpenRecordRef as logRef;

			
			-- or close an open one
			ELSE

				-- SELECT ref INTO inputComboOpenRecordRef FROM stoppagesLog
				-- WHERE stoppagesLog.stoppageReasonId=StoppageReasonId AND endTime IS NULL AND stoppagesLog.jobId=JobId
				-- ORDER BY stoppagesLog.recordTimestamp ASC LIMIT 1;
				
				
				IF inputComboOpenRecordRef != -1 THEN
					-- SELECT * FROM stoppagesLog WHERE stoppagesLog.ref = inputComboOpenRecordRef;
					UPDATE stoppagesLog SET endTime=CURRENT_TIME, endDate=CURRENT_DATE, status=StationStatus WHERE stoppagesLog.ref = inputComboOpenRecordRef;
					-- INSERT INTO stoppagesLog (jobId, stationId, stoppageReasonId, description, endTime, endDate, status)
					-- VALUES (JobId, StationId, StoppageReasonId, Description, CURRENT_TIME, CURRENT_DATE, 'resolved');
					SET newlyClosedRecordRef = inputComboOpenRecordRef;
				
					SELECT stoppagesLog.startTime, stoppagesLog.startDate, stoppagesLog.endTime, stoppagesLog.endDate INTO startTime, startDate, endTime, endDate 
					FROM stoppagesLog
					WHERE stoppagesLog.ref=newlyClosedRecordRef;
					
					-- find the newly closed total duration
					SET dateDifference = DATEDIFF(endDate, startDate);
					-- SELECT endDate;
					-- SELECT startDate;
					-- SELECT endTime;
					-- SELECT endDate;
					SET dateDifferenceInSeconds = (dateDifference*24*60*60); -- to seconds
					SET calculatedDuration = TIME_TO_SEC(TIMEDIFF(endTime, startTime));
					SET newlyClosedDuration = calculatedDuration + dateDifferenceInSeconds;
					-- SELECT newlyClosedDuration;
					-- update records
					UPDATE stoppagesLog
					SET duration = newlyClosedDuration
					WHERE stoppagesLog.ref=newlyClosedRecordRef;
					-- SELECT newlyClosedRecordRef;
					SELECT "stoppageOff" as result, newlyClosedRecordRef as logRef;
				END IF;

			END IF;
			
		ELSE
			-- error message returned
			SELECT "unknownId" as result;
		END IF;
        
    COMMIT;
	END$$

DELIMITER ;;