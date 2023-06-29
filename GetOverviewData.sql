DELIMITER $$

DROP PROCEDURE IF EXISTS `GetOverviewData`$$


CREATE PROCEDURE `GetOverviewData` (IN `UseSearchKey` TINYINT(1), IN `SearchKey` VARCHAR(200), IN `ShowPendingJobs` TINYINT(1), IN `ShowWorkInProgressJobs` TINYINT(1), IN `ShowCompletedJobs` TINYINT(1), IN `LimitDateCreatedRange` TINYINT(1), IN `DateCreatedStart` DATE, IN `DateCreatedEnd` DATE, IN `LimitDateDueRange` TINYINT(1), IN `DateDueStart` DATE, IN `DateDueEnd` DATE, IN `LimitDateTimeWorkedRange` TINYINT(1), IN `DateTimeWorkStart` DATE, IN `DateTimeWorkEnd` DATE, IN `ExcludeUnworkedJobs` TINYINT(1), IN `ShowOnlyUrgentJobs` TINYINT(1), IN `ShowOnlyNonurgentJobs` TINYINT(1), IN `OrderByCreatedAsc` TINYINT(1), IN `OrderByCreatedDesc` TINYINT(1), IN `OrderByDueAsc` TINYINT(1), IN `OrderByDueDesc` TINYINT(1), IN `OrderByJobId` TINYINT(1), IN `OrderBypriority` TINYINT(1), IN `SubOrderByPriority` TINYINT(1)) MODIFIES SQL DATA 
BEGIN
    CREATE TEMPORARY TABLE openTimes (jobId VARCHAR(20), openDuration INT, openOvertimeDuration INT);
    CREATE TEMPORARY TABLE selectedJobIds (counter INT PRIMARY KEY AUTO_INCREMENT, jobId VARCHAR(20));
	CREATE TEMPORARY TABLE closedRecords (jobId VARCHAR(20), closedDuration INT, closedOvertimeDuration INT, quantityComplete INT);
	CREATE TEMPORARY TABLE totalDurations (jobId VARCHAR(20), totalWorkedDuration INT, totalOvertimeDuration INT);
	CREATE TEMPORARY TABLE quantities(jobId VARCHAR(20), quantityComplete INT); -- Construct a query to select the job IDs meeting the required selection criteria (completed or not, date range, etc)...
	SET @selectionQuery = "INSERT INTO selectedJobIds (jobId) SELECT jobId FROM jobs ";
	
	IF UseSearchKey THEN
		SET @searchPattern = CONCAT("%", SearchKey, "%"); 
	END IF;
	
	SET @conditionPrecederTerm = " WHERE "; 

	-- ...appending the relevant selection options...
	IF UseSearchKey IS TRUE THEN
		SET @selectionQuery = CONCAT(@selectionQuery, " WHERE (description LIKE '", @searchPattern, "' OR jobName LIKE '", @searchPattern, "' OR jobId LIKE '", @searchPattern, "' OR customerName LIKE '", @searchPattern, "' or  productId LIKE '", @searchPattern, "')");
		
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
		AND (timeLog.userId IS NOT NULL) AND (timeLog.clockOnTime IS NOT NULL) AND (timeLog.recordDate IS NOT NULL);

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
		AND (timeLog.userId IS NOT NULL) AND (timeLog.clockOnTime IS NOT NULL) AND (timeLog.recordDate IS NOT NULL);

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
		SET @selectionQuery = CONCAT(@selectionQuery, " WHERE (description LIKE '", @searchPattern, "' OR jobName LIKE '", @searchPattern, "' OR jobId LIKE '", @searchPattern, "' OR customerName LIKE '", @searchPattern, "' or  productId LIKE '", @searchPattern, "')");
		
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
	jobs.jobName AS jobName,
    description,
    currentStatus,
    recordAdded,
    SUM(totalDurations.totalWorkedDuration) AS totalWorkedDuration,
    SUM(totalDurations.totalOvertimeDuration) AS totalOvertimeDuration,
	SUM(quantities.quantityComplete) AS quantityComplete,
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
	DROP TABLE quantities;
	DROP TABLE totalDurations;
	
	END$$

DELIMITER ;;
