DELIMITER $$

DROP PROCEDURE IF EXISTS `GetJobRecord`$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GetJobRecord` (IN `JobId` VARCHAR(20))  MODIFIES SQL DATA
BEGIN
	-- get the total worked time and overtime from a procedure,
	-- then reads the rest of the data directly from the table
	CALL CalcWorkedTimes(JobId, 0, "2000-01-01", "3000-01-01", @totalWorkedTime, @totalOvertime);
	
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
    jobs.customerName,
    jobs.jobName
	FROM jobs
	WHERE jobs.jobId = JobId
	LIMIT 1;
	
    END$$

DELIMITER ;;