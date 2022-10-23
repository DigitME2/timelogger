-- '''

-- Copyright 2022 DigitME2

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- '''

-- phpMyAdmin SQL Dump
-- version 4.8.3
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: May 10, 2021 at 10:58 AM
-- Server version: 10.1.37-MariaDB
-- PHP Version: 7.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `work_tracking`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `addLunch` (IN `workLogRef` INT(11), IN `jobClockOnTime` TIME, IN `jobClockOffTime` TIME, IN `RecordDate` DATE, IN `configTrimLunch` VARCHAR(100))  MODIFIES SQL DATA
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

END$$

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

CREATE DEFINER=`root`@`localhost` PROCEDURE `changeWorkLogRecord` (IN `workLogRef` VARCHAR(20), IN `station` VARCHAR(50), IN `userId` VARCHAR(20), IN `recordDate` DATE, IN `clockOnTime` TIME, IN `clockOffTime` TIME, IN `clockOffTimeValid` TINYINT(1), IN `workStatus` VARCHAR(20), IN `quantityComplete` INT(11))  MODIFIES SQL DATA
BEGIN
	
	DECLARE newDuration INT DEFAULT 0;
	DECLARE newOvertime INT DEFAULT 0;
	
	DECLARE newClockOffTime TIME DEFAULT NULL;

	IF clockOffTimeValid IS TRUE THEN -- this represents an open record.
		-- find the new total duration
		SET newDuration = TIME_TO_SEC(TIMEDIFF(clockOffTime, clockOnTime));
		
		-- find the new overtime duration
		SET newOvertime = CalcOvertimeDuration(clockOnTime, clockOffTime, recordDate);
		SET newClockOffTime = clockOffTime;
	END IF;

		
		
	UPDATE timeLog
	SET clockOnTime = clockOnTime,
	clockOffTime = newClockOffTime,
	workedDuration = newDuration,
	overtimeDuration = newOvertime,
	recordDate = recordDate,
	userId = userId,
	stationId = station,
	workStatus = workStatus,
	quantityComplete = quantityComplete
	WHERE timeLog.ref=workLogRef;

	SELECT "success" as result;
	
	
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `addWorkLogRecord` (IN `JobId` VARCHAR(20))  MODIFIES SQL DATA
BEGIN
	
	INSERT INTO `timeLog` (`jobId`, `workStatus`) VALUES (JobId, 'workInProgress');
    SELECT ref FROM timeLog WHERE jobId = JobId ORDER BY ref DESC LIMIT 1; 
	
END$$

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
 END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `CheckChangeOfRoute` (IN `JobId` VARCHAR(20), IN `InputRouteName` VARCHAR(100))  MODIFIES SQL DATA
BEGIN

	SELECT jobs.routeName into @ExistingRouteName FROM jobs WHERE jobs.jobId = JobId;

	IF @ExistingRouteName != InputRouteName THEN
		UPDATE timeLog SET routeStageIndex = -1 WHERE timeLog.jobId = JobId;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `clockOffAllUsers` ()  MODIFIES SQL DATA
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
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ClockUser` (IN `JobId` VARCHAR(20), IN `UserId` VARCHAR(20), IN `StationId` VARCHAR(50), IN `StationStatus` VARCHAR(20))  MODIFIES SQL DATA
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
				
				-- SELECT @stageIndex, @stageName;

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
					-- SELECT 'HERE';
					
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
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `CompleteStationRenaming` (IN `StationNewName` VARCHAR(50))  MODIFIES SQL DATA
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
	
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GetCollapsedJobTimeLog` (IN `JobId` VARCHAR(20), IN `LimitDateRange` TINYINT(1), IN `StartDate` DATE, IN `EndDate` DATE)  MODIFIES SQL DATA
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
 
 END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GetJobRecord` (IN `JobId` VARCHAR(20))  MODIFIES SQL DATA
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
    jobs.totalParts,
	jobs.totalChargeToCustomer,
	jobs.productId,
    jobs.customerName
	FROM jobs
	WHERE jobs.jobId = JobId
	LIMIT 1;
	
	
	
END$$

CREATE PROCEDURE `GetOverviewData` (IN `UseSearchKey` TINYINT(1), IN `SearchKey` VARCHAR(200), IN `ShowPendingJobs` TINYINT(1), IN `ShowWorkInProgressJobs` TINYINT(1), IN `ShowCompletedJobs` TINYINT(1), IN `LimitDateCreatedRange` TINYINT(1), IN `DateCreatedStart` DATE, IN `DateCreatedEnd` DATE, IN `LimitDateDueRange` TINYINT(1), IN `DateDueStart` DATE, IN `DateDueEnd` DATE, IN `LimitDateTimeWorkedRange` TINYINT(1), IN `DateTimeWorkStart` DATE, IN `DateTimeWorkEnd` DATE, IN `ExcludeUnworkedJobs` TINYINT(1), IN `ShowOnlyUrgentJobs` TINYINT(1), IN `ShowOnlyNonurgentJobs` TINYINT(1), IN `OrderByCreatedAsc` TINYINT(1), IN `OrderByCreatedDesc` TINYINT(1), IN `OrderByDueAsc` TINYINT(1), IN `OrderByDueDesc` TINYINT(1), IN `OrderByJobId` TINYINT(1), IN `OrderBypriority` TINYINT(1), IN `SubOrderByPriority` TINYINT(1)) MODIFIES SQL DATA 
BEGIN
    CREATE TEMPORARY TABLE openTimes (jobId VARCHAR(20), openDuration INT, openOvertimeDuration INT);
    CREATE TEMPORARY TABLE selectedJobIds (counter INT PRIMARY KEY AUTO_INCREMENT, jobId VARCHAR(20));
	CREATE TEMPORARY TABLE closedRecords (jobId VARCHAR(20), closedDuration INT, closedOvertimeDuration INT, quantityComplete INT);
	CREATE TEMPORARY TABLE totalDurations (jobId VARCHAR(20), totalWorkedDuration INT, totalOvertimeDuration INT);
	CREATE TEMPORARY TABLE quantities(jobId VARCHAR(20), quantityComplete INT);


	-- Construct a query to select the job IDs meeting the required selection criteria (completed or not, date range, etc)...
	SET @selectionQuery = "INSERT INTO selectedJobIds (jobId) SELECT jobId FROM jobs ";
	
	IF UseSearchKey THEN
		SET @searchPattern = CONCAT("%", SearchKey, "%"); 
	END IF;
	
	SET @conditionPrecederTerm = " WHERE "; 

	-- ...appending the relevant selection options...
	IF UseSearchKey IS TRUE THEN
		SET @selectionQuery = CONCAT(@selectionQuery, " WHERE (description LIKE '", @searchPattern, "' OR jobId LIKE '", @searchPattern, "' OR customerName LIKE '", @searchPattern, "' or  productId LIKE '", @searchPattern, "')");
		
		-- this is set to " WHERE ", then changed to " AND " after the first condition is set.
		SET @conditionPrecederTerm = " AND "; 
	END IF;		
		
	IF ShowPendingJobs IS TRUE AND ShowWorkInProgressJobs IS TRUE AND ShowCompletedJobs IS TRUE THEN
		SET @selectionQuery = CONCAT(@selectionQuery, @conditionPrecederTerm, "(currentStatus = 'pending' OR currentStatus = 'workInProgress' OR currentStatus = 'complete')");
		SET @conditionPrecederTerm = " AND "; 

	ELSEIF ShowPendingJobs IS TRUE AND ShowWorkInProgressJobs IS TRUE AND ShowCompletedJobs IS FALSE THEN
		SET @selectionQuery = CONCAT(@selectionQuery, @conditionPrecederTerm, "(currentStatus = 'pending' OR currentStatus = 'workInProgress')");
		SET @conditionPrecederTerm = " AND "; 
	
	ELSEIF ShowPendingJobs IS TRUE AND ShowWorkInProgressJobs IS FALSE AND ShowCompletedJobs IS TRUE THEN
		SET @selectionQuery = CONCAT(@selectionQuery, @conditionPrecederTerm, "(currentStatus = 'pending' OR currentStatus = 'complete')");
		SET @conditionPrecederTerm = " AND "; 

	ELSEIF ShowPendingJobs IS FALSE AND ShowWorkInProgressJobs IS TRUE AND ShowCompletedJobs IS TRUE THEN
		SET @selectionQuery = CONCAT(@selectionQuery, @conditionPrecederTerm, "(currentStatus = 'workInProgress' OR currentStatus = 'complete')");
		SET @conditionPrecederTerm = " AND ";

	ELSEIF ShowPendingJobs IS TRUE AND ShowWorkInProgressJobs IS FALSE AND ShowCompletedJobs IS FALSE THEN
		SET @selectionQuery = CONCAT(@selectionQuery, @conditionPrecederTerm, "(currentStatus = 'pending')");

		SET @conditionPrecederTerm = " AND ";
	
	ELSEIF ShowPendingJobs IS FALSE AND ShowWorkInProgressJobs IS FALSE AND ShowCompletedJobs IS TRUE THEN
		SET @selectionQuery = CONCAT(@selectionQuery, @conditionPrecederTerm, "(currentStatus = 'complete')");
		SET @conditionPrecederTerm = " AND ";

	ELSEIF ShowPendingJobs IS FALSE AND ShowWorkInProgressJobs IS TRUE AND ShowCompletedJobs IS FALSE THEN
		SET @selectionQuery = CONCAT(@selectionQuery, @conditionPrecederTerm, "(currentStatus = 'workInProgress')");
		SET @conditionPrecederTerm = " AND ";
	END IF;

	IF LimitDateCreatedRange IS TRUE THEN
		SET @selectionQuery = CONCAT(@selectionQuery, @conditionPrecederTerm,
			 "DATE(recordAdded) >= '", DateCreatedStart, "' AND DATE(recordAdded) <= '", DateCreatedEnd, "' ");
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
	-- SELECT LimitDateTimeWorkedRange;
	-- Perform a few actions to produce a create a list of times for open records. This is required to get an accurate time
    -- if a job is currently being worked on.
    -- Get the relevant jobs

	-- if display time in date range is false ...
	IF LimitDateTimeWorkedRange IS FALSE THEN
		INSERT INTO openTimes(jobId, openDuration, openOvertimeDuration)
		SELECT 
		timeLog.jobId,
		TIME_TO_SEC(TIMEDIFF(CURRENT_TIME, clockOnTime)),
		CalcOvertimeDuration(clockOnTime, CURRENT_TIME, CURRENT_DATE)
		FROM timeLog
		WHERE clockOffTime IS NULL AND timeLog.jobId IN (SELECT jobId FROM selectedJobIds) AND (timeLog.stationId IS NOT NULL)
		AND (timeLog.userId IS NOT NULL) AND (timeLog.clockOnTime IS NOT NULL) AND (timelog.recordDate IS NOT NULL);

		INSERT INTO closedRecords(jobId, closedDuration, closedOvertimeDuration, quantityComplete)
		SELECT 
		timeLog.jobId,
		timeLog.workedDuration,
		timeLog.overtimeDuration,
		timeLog.quantityComplete
		FROM timeLog
		WHERE clockOffTime IS NOT NULL AND timeLog.jobId IN (SELECT jobId FROM selectedJobIds);
		-- timelog.quantitycomplete add to the above tble
		-- remove the below

	ELSEIF LimitDateTimeWorkedRange IS TRUE THEN 
		INSERT INTO openTimes(jobId, openDuration, openOvertimeDuration)
		SELECT 
		timeLog.jobId,
		TIME_TO_SEC(TIMEDIFF(CURRENT_TIME, clockOnTime)),
		CalcOvertimeDuration(clockOnTime, CURRENT_TIME, CURRENT_DATE)
		FROM timeLog
		WHERE clockOffTime IS NULL AND timeLog.jobId IN (SELECT jobId FROM selectedJobIds) AND (timeLog.recordDate >= DateTimeWorkStart AND timeLog.recordDate <= DateTimeWorkEnd) AND (timeLog.stationId IS NOT NULL)
		AND (timeLog.userId IS NOT NULL) AND (timeLog.clockOnTime IS NOT NULL) AND (timelog.recordDate IS NOT NULL);

		INSERT INTO closedRecords(jobId, closedDuration, closedOvertimeDuration, quantityComplete)
		SELECT 
		timeLog.jobId,
		timeLog.workedDuration,
		timeLog.overtimeDuration,
		timeLog.quantityComplete
		FROM timeLog
		WHERE clockOffTime IS NOT NULL AND timeLog.jobId IN (SELECT jobId FROM selectedJobIds) AND (timeLog.recordDate >= DateTimeWorkStart AND timeLog.recordDate <= DateTimeWorkEnd);

	END IF;
	--  ... else if true
	--  same insert statements, plus AND tiemlog.recordDate >= startDate AND timelog.recordDAte <= endDate

	-- 
	    
    -- test


	-- SELECT * FROM openTimes;
	-- SELECT * FROM closedRecords;
--	SELECT * FROM recordQuantityComplete;
	-- -- SELECT ExcludeUnworkedJobs;

	IF LimitDateTimeWorkedRange IS TRUE AND ExcludeUnworkedJobs IS TRUE THEN
		DELETE FROM selectedJobIds
		WHERE selectedJobIds.jobId NOT IN (SELECT jobId FROM openTimes)
		AND selectedJobIds.jobId NOT IN (SELECT jobId FROM closedRecords);
	END IF;
	-- SELECT * FROM selectedJobIds;
    
    -- Create dummy entries to simplify things a little later on. These are used to ensure that there
    -- is at least one entry for each job.
    INSERT INTO openTimes (jobId, openDuration, openOvertimeDuration)
    SELECT jobId, 0, 0 FROM selectedJobIds;
    
    CREATE INDEX idx_openTimes_jobIds ON openTimes(jobId);
    
	INSERT INTO closedRecords (jobId, closedDuration, closedOvertimeDuration, quantityComplete)
    SELECT jobId, 0, 0, 0 FROM selectedJobIds;
    
    CREATE INDEX idx_closedRecords_jobIds ON closedRecords(jobId);
    
    
--    SELECT * FROM openTimes;
--	SELECT * FROM closedRecords;
    

	-- ...appending the relevant selection options...
	IF UseSearchKey IS TRUE THEN
		SET @selectionQuery = CONCAT(@selectionQuery, " WHERE (description LIKE '", @searchPattern, "' OR jobId LIKE '", @searchPattern, "' OR customerName LIKE '", @searchPattern, "' or  productId LIKE '", @searchPattern, "')");
		
		-- this is set to " WHERE ", then changed to " AND " after the first condition is set.
		SET @conditionPrecederTerm = " AND "; 
	END IF;	
	
	INSERT INTO totalDurations (jobId, totalWorkedDuration, totalOvertimeDuration) SELECT jobId, SUM(openDuration), SUM(openOvertimeDuration) FROM openTimes GROUP BY jobId;
	INSERT INTO totalDurations (jobId, totalWorkedDuration, totalOvertimeDuration) SELECT jobId, SUM(closedDuration), SUM(closedOvertimeDuration) FROM closedRecords GROUP BY jobId;
	
--	SELECT * FROM totalDurations;
--	SELECT jobs.jobId, SUM(totalDurations.totalWorkedDuration) FROM jobs LEFT JOIN totalDurations on jobs.jobId = totalDurations.jobId;
    
    INSERT INTO quantities(jobId, quantityComplete) SELECT jobId, SUM(quantityComplete) FROM closedRecords GROUP BY jobId;
--    SELECT "Inserted into quantities";
--    SELECT * FROM quantities;
    
    
    -- Create and run the final query to select the data from the timeLog and combine
    -- it with the calculated durations for jobs that are still open. Efficiency is
    -- also calculated here, to minimise post processing required in PHP or JS.
	SET @finalSelectorQuery = 
    "SELECT
    jobs.jobId AS jobId,
    description,
    currentStatus,
    recordAdded,
    SUM(totalDurations.totalWorkedDuration) AS totalWorkedDuration,
    SUM(totalDurations.totalOvertimeDuration) AS totalOvertimeDuration,
	quantities.quantityComplete AS quantityComplete,
    LEAST((expectedDuration/(SUM(totalDurations.totalWorkedDuration))),1) AS efficiency,
    expectedDuration,
    routeCurrentStageName,
    priority,
    dueDate,
    stoppages,
    numberOfUnits,
    totalParts,
   	totalChargeToCustomer,
   	productId,
   	stageQuantityComplete,
   	stageOutstandingUnits,
   	customerName,
   	notes
   	FROM jobs
   	LEFT JOIN totalDurations ON jobs.jobId = totalDurations.jobId
	LEFT JOIN quantities ON jobs.jobId = quantities.jobId
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
	ELSEIF OrderByJobId IS TRUE THEN
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
	DROP TABLE closedRecords;
    DROP TABLE selectedJobIds;
	
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GetTimesheet` (IN `UserId` VARCHAR(20), IN `StartDate` DATE, IN `EndDate` DATE)  MODIFIES SQL DATA
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

     -- This is for getting Product Ids

    SELECT 
        jobDurations.jobId, 
        jobs.productId
    FROM jobDurations
    LEFT JOIN jobs
    ON jobDurations.jobId = jobs.jobId
    GROUP BY jobId;

	  -- This is for getting Aggregate Times 
    SELECT jobId, SUM(duration) AS workedDuration, SUM(overtimeDuration) AS overtimeDuration FROM jobDurations GROUP BY jobId;

    -- select the times from the table, ordered appropriately. This following result set is 
	-- processed into the rows and columns of a time sheet in the PHP code that called 
	-- this procedure.
	SELECT recordDate, jobId, SUM(duration) AS workedDuration, SUM(overtimeDuration) AS overtimeDuration FROM jobDurations GROUP BY recordDate, jobId ORDER BY recordDate;
	
	SELECT @totalDuration, @totalOvertimeDuration;

    	
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GetWorkedTimes` (IN `JobId` VARCHAR(20), IN `LimitDateRange` TINYINT(1), IN `StartDate` DATE, IN `EndDate` DATE)  MODIFIES SQL DATA
BEGIN
	CALL CalcWorkedTimes(JobId, LimitDateRange, StartDate, EndDate, @totalWorkedTime, @totalOvertime);
	SELECT @totalWorkedTime, @totalOvertime;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `insertBreak` (IN `workLogRef` VARCHAR(20), IN `breakStart` TIME, IN `breakEnd` TIME)  MODIFIES SQL DATA
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
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `MarkJobComplete` (IN `JobId` VARCHAR(20))  MODIFIES SQL DATA
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
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `recalculateDurartions` (IN `clockOffUsers` TINYINT(1))  MODIFIES SQL DATA
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
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `recordStoppage` (IN `JobId` VARCHAR(20), IN `StoppageReasonId` VARCHAR(20), IN `StationId` VARCHAR(50), IN `Description` TEXT, IN `StationStatus` VARCHAR(20))  MODIFIES SQL DATA
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
END$$

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `CalcOvertimeDuration` (`JobStartTime` TIME, `JobEndTime` TIME, `RecordDate` DATE) RETURNS INT(11) MODIFIES SQL DATA
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
    
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `clientNames`
--

CREATE TABLE `clientNames` (
  `currentName` varchar(50) DEFAULT NULL,
  `newName` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `extraScannerNames`
--

CREATE TABLE `extraScannerNames` (
  `name` varchar(50) DEFAULT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- --------------------------------------------------------

--
-- Table structure for table `config`
--

CREATE TABLE `config` (
  `paramName` varchar(100) NOT NULL,
  `paramValue` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `config`
--

INSERT INTO `config` (`paramName`, `paramValue`) VALUES
('addLunchBreak', 'false'),
('allowMultipleClockOn', 'false'),
('quantityComplete', 'true'),
('configVersion', '1'),
('requireStageComplete', 'true'),
('showQuantityComplete', 'true'),
('trimLunch', 'false');

-- --------------------------------------------------------

--
-- Table structure for table `connectedClients`
--

CREATE TABLE `connectedClients` (
  `stationId` varchar(50) NOT NULL,
  `lastSeen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `version` varchar(50) DEFAULT NULL,
  `isApp` tinyint(1) DEFAULT 0,
  `nameType` varchar(20)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `jobs`
--

CREATE TABLE `jobs` (
  `jobId` varchar(20) NOT NULL,
  `expectedDuration` int(11) DEFAULT NULL,
  `closedWorkedDuration` int(11) NOT NULL DEFAULT '0',
  `closedOvertimeDuration` int(11) NOT NULL DEFAULT '0',
  `description` varchar(200) DEFAULT NULL,
  `currentStatus` varchar(50) DEFAULT NULL,
  `absolutePathToQrCode` varchar(200) DEFAULT NULL,
  `relativePathToQrCode` varchar(200) DEFAULT NULL,
  `recordAdded` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `notes` text,
  `routeName` varchar(100) CHARACTER SET utf8 DEFAULT NULL,
  `routeCurrentStageName` varchar(50) DEFAULT NULL,
  `routeCurrentStageIndex` int(11) NOT NULL DEFAULT '-1',
  `dueDate` date DEFAULT '9999-12-31',
  `stoppages` text,
  `numberOfUnits` int(11) DEFAULT NULL,
  `totalChargeToCustomer` int(11) DEFAULT NULL,
  `jobIdIndex` int(15) NOT NULL,
  `productId` varchar(20) DEFAULT '',
  `priority` int(1) DEFAULT '0',
  `stageQuantityComplete` int(11) DEFAULT NULL,
  `stageOutstandingUnits` int(11) DEFAULT NULL,
  `totalParts` int(11) DEFAULT NULL,
  `customerName` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `lunchTimes`
--

CREATE TABLE `lunchTimes` (
  `ref` int(11) NOT NULL,
  `dayDate` date DEFAULT NULL,
  `startTime` time DEFAULT NULL,
  `endTime` time DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `lunchTimes`
--

INSERT INTO `lunchTimes` (`ref`, `dayDate`, `startTime`, `endTime`) VALUES
(1, '2021-03-17', '00:00:00', '00:00:00'),
(2, '2021-03-18', '00:00:00', '00:00:00'),
(3, '2021-03-19', '00:00:00', '00:00:00'),
(4, '2021-03-20', '00:00:00', '00:00:00'),
(5, '2021-03-21', '00:00:00', '00:00:00'),
(6, '2021-03-22', '00:00:00', '00:00:00'),
(7, '2021-03-23', '00:00:00', '00:00:00');

-- --------------------------------------------------------

--
-- Table structure for table `products`
--

CREATE TABLE `products` (
  `productId` varchar(20) NOT NULL,
  `description` varchar(200) DEFAULT NULL,
  `absolutePathToQrCode` varchar(200) DEFAULT NULL,
  `relativePathToQrCode` varchar(200) DEFAULT NULL,
  `currentJobId` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `routes`
--

CREATE TABLE `routes` (
  `routeName` varchar(50) NOT NULL,
  `routeDescription` varchar(1000) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- --------------------------------------------------------

--
-- Table structure for table `stoppageReasons`
--

CREATE TABLE `stoppageReasons` (
  `stoppageReasonId` varchar(20) NOT NULL,
  `stoppageReasonName` varchar(200) DEFAULT NULL,
  `absolutePathToQrCode` varchar(200) DEFAULT NULL,
  `relativePathToQrCode` varchar(200) DEFAULT NULL,
  `stoppageReasonIdIndex` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `stoppagesLog`
--

CREATE TABLE `stoppagesLog` (
  `ref` bigint(20) NOT NULL,
  `jobId` varchar(20) DEFAULT NULL,
  `stationId` varchar(50) DEFAULT NULL,
  `stoppageReasonId` varchar(20) DEFAULT NULL,
  `description` text,
  `startTime` time DEFAULT NULL,
  `endTime` time DEFAULT NULL,
  `startDate` date DEFAULT NULL,
  `endDate` date DEFAULT NULL,
  `recordTimestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `duration` int(11) DEFAULT NULL,
  `status` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `timeLog`
--

CREATE TABLE `timeLog` (
  `ref` bigint(20) NOT NULL,
  `jobId` varchar(20) DEFAULT NULL,
  `stationId` varchar(50) DEFAULT NULL,
  `userId` varchar(20) DEFAULT NULL,
  `clockOnTime` time DEFAULT NULL,
  `clockOffTime` time DEFAULT NULL,
  `recordDate` date DEFAULT NULL,
  `recordTimestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `workedDuration` int(11) DEFAULT NULL,
  `overtimeDuration` int(11) DEFAULT NULL,
  `workStatus` varchar(20) NOT NULL,
  `quantityComplete` int(11) DEFAULT NULL,
  `routeStageIndex` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `userId` varchar(20) DEFAULT NULL,
  `userName` varchar(50) DEFAULT NULL,
  `relativePathToQrCode` varchar(200) DEFAULT NULL,
  `absolutePathToQrCode` varchar(200) DEFAULT NULL,
  `recordAdded` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `userIdIndex` int(11) DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`userId`, `userName`, `relativePathToQrCode`, `absolutePathToQrCode`, `recordAdded`, `userIdIndex`) VALUES
('user_Delt', 'User Deleted', NULL, NULL, '2021-04-15 16:59:34', -2),
('office', 'Office', NULL, NULL, '2021-04-15 16:59:34', -1),
('noName', 'N/A', NULL, NULL, '2021-04-15 16:59:34', 0);

-- --------------------------------------------------------

--
-- Table structure for table `workHours`
--

CREATE TABLE `workHours` (
  `ref` int(11) NOT NULL,
  `dayDate` date DEFAULT NULL,
  `startTime` time DEFAULT NULL,
  `endTime` time DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `workHours`
--

INSERT INTO `workHours` (`ref`, `dayDate`, `startTime`, `endTime`) VALUES
(1, '2021-03-17', '00:00:00', '00:00:00'),
(2, '2021-03-18', '00:00:00', '00:00:00'),
(3, '2021-03-19', '00:00:00', '00:00:00'),
(4, '2021-03-20', '00:00:00', '00:00:00'),
(5, '2021-03-21', '00:00:00', '00:00:00'),
(6, '2021-03-22', '00:00:00', '00:00:00'),
(7, '2021-03-23', '00:00:00', '00:00:00');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `config`
--
ALTER TABLE `config`
  ADD PRIMARY KEY (`paramName`);

--
-- Indexes for table `connectedClients`
--
ALTER TABLE `connectedClients`
  ADD PRIMARY KEY (`stationId`);

--
-- Indexes for table `jobs`
--
ALTER TABLE `jobs`
  ADD PRIMARY KEY (`jobId`),
  ADD KEY `jobIdIndex` (`jobIdIndex`),
  ADD KEY `IDX_jobId_desc` (`jobId`,`description`);

--
-- Indexes for table `lunchTimes`
--
ALTER TABLE `lunchTimes`
  ADD PRIMARY KEY (`ref`);

--
-- Indexes for table `products`
--
ALTER TABLE `products`
  ADD PRIMARY KEY (`productId`);

--
-- Indexes for table `routes`
--
ALTER TABLE `routes`
  ADD PRIMARY KEY (`routeName`);

--
-- Indexes for table `stoppageReasons`
--
ALTER TABLE `stoppageReasons`
  ADD PRIMARY KEY (`stoppageReasonId`),
  ADD KEY `stoppageReasonIdIndex` (`stoppageReasonIdIndex`);

--
-- Indexes for table `stoppagesLog`
--
ALTER TABLE `stoppagesLog`
  ADD PRIMARY KEY (`ref`);

--
-- Indexes for table `timeLog`
--
ALTER TABLE `timeLog`
  ADD PRIMARY KEY (`ref`),
  ADD KEY `IDX_ClockOffTime_JobID` (`clockOffTime`,`jobId`) USING BTREE,
  ADD KEY `IDX_ClockOffTime_UserId` (`clockOffTime`,`userId`),
  ADD KEY `IDX_ClockOffTime_UserId_date` (`clockOffTime`,`userId`,`recordDate`);

--
-- Indexes for table `workHours`
--
ALTER TABLE `workHours`
  ADD PRIMARY KEY (`ref`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `jobs`
--
ALTER TABLE `jobs`
  MODIFY `jobIdIndex` int(15) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `lunchTimes`
--
ALTER TABLE `lunchTimes`
  MODIFY `ref` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `stoppageReasons`
--
ALTER TABLE `stoppageReasons`
  MODIFY `stoppageReasonIdIndex` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `stoppagesLog`
--
ALTER TABLE `stoppagesLog`
  MODIFY `ref` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `timeLog`
--
ALTER TABLE `timeLog`
  MODIFY `ref` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `workHours`
--
ALTER TABLE `workHours`
  MODIFY `ref` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

DELIMITER $$
--
-- Events
--

-- This is to remove the null rows from timeLog 

-- DELETE FROM `timeLog`
-- WHERE `stationId` IS NULL
-- OR `userId` IS NULL
-- OR `recordDate` IS NULL
-- OR `clockOnTime` IS NULL;


CREATE DEFINER=`root`@`localhost` EVENT `autoClockOff` ON SCHEDULE EVERY 1 DAY STARTS '2018-08-13 23:59:00' ON COMPLETION PRESERVE ENABLE DO CALL clockOffAllUsers()$$

DELIMITER ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
