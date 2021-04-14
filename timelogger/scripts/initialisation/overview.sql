DELIMITER ;;

DROP PROCEDURE IF EXISTS GetOverviewData;;
-- Selects jobId, description, currentStatus, timestamp, current total worked
-- duration, of which current overtime worked, efficiency (total time / expected,
-- maximum of 1), expectedDuration. Times are in seconds.
CREATE DEFINER=`root`@`localhost` PROCEDURE GetOverviewData(
	IN UseSearchKey TINYINT(1),
	IN SearchKey VARCHAR(200),
	IN HideCompletedJobs TINYINT(1),
	IN LimitDateCreatedRange TINYINT(1),
	IN DateCreatedStart DATE,
	IN DateCreatedEnd DATE,
	IN LimitDateDueRange TINYINT(1),
	IN DateDueStart DATE,
	IN DateDueEnd DATE,
	IN ShowOnlyUrgentJobs TINYINT(1),
	IN ShowOnlyNonurgentJobs TINYINT(1),
	IN OrderByCreatedAsc TINYINT(1),
	IN OrderByCreatedDesc TINYINT(1),
	IN OrderByDueAsc TINYINT(1),
	IN OrderByDueDesc TINYINT(1),
	IN OrerByJobId TINYINT(1),
	IN OrderBypriority TINYINT(1),
	IN SubOrderByPriority TINYINT(1)
	)
BEGIN


    CREATE TEMPORARY TABLE openTimes (jobId VARCHAR(20), openDuration INT, openOvertimeDuration INT);
    CREATE TEMPORARY TABLE selectedJobIds (counter INT PRIMARY KEY AUTO_INCREMENT, jobId VARCHAR(20));
	CREATE TEMPORARY TABLE quantityComplete (jobId VARCHAR(20), stageQuantityComplete INT, stageOutstanding INT, numUnits INT DEFAULT Null);

	-- Construct a query to select the job IDs meeting the required selection criteria (completed or not, date range, etc)...
	SET @selectionQuery = "INSERT INTO selectedJobIds (jobId) SELECT jobId FROM jobs ";
	
	IF UseSearchKey THEN
		SET @searchPattern = CONCAT("%", SearchKey, "%");
	END IF;
	
	SET @conditionPrecederTerm = " WHERE "; 

	-- ...appending the relevant selection options...
	IF UseSearchKey IS TRUE THEN
		SET @selectionQuery = CONCAT(@selectionQuery, " WHERE (description LIKE '", @searchPattern, "' OR jobId LIKE '", @searchPattern, "' or  productId LIKE '", @searchPattern, "')");
		
		-- this is set to " WHERE ", then changed to " AND " after the first condition is set.
		SET @conditionPrecederTerm = " AND "; 
	END IF;
		
		
	IF HideCompletedJobs IS TRUE THEN
		SET @selectionQuery = CONCAT(@selectionQuery, @conditionPrecederTerm, "currentStatus != 'complete'");
		SET @conditionPrecederTerm = " AND ";
	END IF;
		
		
	IF LimitDateCreatedRange IS TRUE THEN
		SET @selectionQuery = CONCAT(@selectionQuery, @conditionPrecederTerm,
			 "DATE(recordAdded) >= '", DateCreatedStart, "' AND DATE(recordAdded) <= '", DateCreatedEnd, "' "
		);
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

	-- Perform a few actions to produce a create a list of times for open records. This is required to get an accurate time
    -- if a job is currently being worked on.
    -- Get the relevant jobs
    INSERT INTO openTimes(jobId, openDuration, openOvertimeDuration)
    SELECT 
    timeLog.jobId,
    TIME_TO_SEC(TIMEDIFF(CURRENT_TIME, clockOnTime)),
    CalcOvertimeDuration(clockOnTime, CURRENT_TIME, CURRENT_DATE)
    FROM timeLog
    WHERE clockOffTime IS NULL AND timeLog.jobId IN (SELECT jobId FROM selectedJobIds);
    
    -- test
    -- SELECT * FROM openTimes;
    
    -- Create dummy entries to simplify things a little later on. These are used to ensure that there
    -- is at least one entry for each job.
    INSERT INTO openTimes (jobId, openDuration, openOvertimeDuration)
    SELECT jobId, 0, 0 FROM selectedJobIds;
    
    CREATE INDEX idx_openTimes_jobIds ON openTimes(jobId);
    
    
    -- test
    -- SELECT * FROM openTimes;
    
	
	-- calculate quantity complete for selected jobs
	INSERT INTO quantityComplete (jobId, stageQuantityComplete, numUnits)
	SELECT
	jobs.jobId,
    (Select SUM(quantityComplete) from timeLog WHERE timeLog.jobId = jobs.jobId AND timeLog.routeStageIndex > 0 and timeLog.routeStageIndex = jobs.routeCurrentStageIndex),

	jobs.numberOfUnits
	FROM jobs
	WHERE jobs.jobId IN (SELECT jobId FROM selectedJobIds ORDER BY counter ASC);
	-- FIX and replace -- Select SUM(quantityComplete) from timeLog WHERE timeLog.jobId = jobs.jobId AND timeLog.routeStageIndex > 0 and timeLog.routeStageIndex = jobs.routeCurrentStageIndex),

	UPDATE quantityComplete
	SET stageOutstanding = quantityComplete.numUnits - quantityComplete.stageQuantityComplete
	WHERE quantityComplete.numUnits != 0;
	

    
    -- Create and run the final query to select the data from the timeLog and combine
    -- it with the calculated durations for jobs that are still open. Efficiency is
    -- also calculated here, to minimise post processing required in PHP or JS.
    -- Selects jobId, description, currentStatus, timestamp, current total worked
    -- duration, of which current overtime worked, efficiency (total time / expected,
    -- maximum of 1), expectedDuration
	SET @finalSelectorQuery = 
    "SELECT
    jobs.jobId AS jobId,
    description,
    currentStatus,
    recordAdded,
    closedWorkedDuration + SUM(openDuration) AS totalWorkedDuration,
    closedOvertimeDuration + SUM(openOvertimeDuration) AS totalOvertimeDuration,
    LEAST((expectedDuration/(closedWorkedDuration + SUM(openDuration))),1) AS efficiency,
    expectedDuration,
	routeCurrentStageName,
	priority,
	dueDate,
	stoppages,
	numberOfUnits,
	totalChargeToCustomer,
	productId,
    	stageQuantityComplete,
	stageOutstanding AS stageOutstandingUnits
    FROM jobs 
	LEFT JOIN openTimes ON jobs.jobId = openTimes.jobId 
	LEFT JOIN quantityComplete ON jobs.jobId = quantityComplete.jobId
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
	ELSEIF OrerByJobId IS TRUE THEN
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
    DROP TABLE selectedJobIds;
END;;

DELIMITER ;

