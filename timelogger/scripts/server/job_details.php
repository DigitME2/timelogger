<?php
// Takes a request from a browser client and generates a collection of data.
// This data includes the current job status, time, overtime, expected time,
// description, and a collection of records indicating where the job has
// been worked on.
//
// The majority of the code used is in "job_details_computation_scripts.php"
//
// Note that the database connection is implicitly released when this script 
// terminates
require "db_params.php";
require "common.php";

// client page config
require "./../../pages/client_config.php";

$debug = false;

function markJobIncomplete($DbConn, $JobId)
{
    // Updates current status of job record for job
    $query = "UPDATE jobs SET currentStatus = 'workInProgress' WHERE jobs.jobId = ?;";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $JobId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

}

function markJobComplete($DbConn, $JobId)
{
    // Call a stored procedure to do the magic. Closes any open records and
    // updates contents of jobs table record for this job.
    $query = "CALL MarkJobComplete(?)";
    if(!($stmt = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($stmt->bind_param('s', $JobId)))
        errorHandler("Error binding parameters: ($stmt->errno) $stmt->error, line " . __LINE__);
    
    if(!($stmt->execute()))
        errorHandler("Error executing statement: ($stmt->errno) $stmt->error, line " . __LINE__);

}

function deleteJob($DbConn, $JobId)
{
    // get the abs path to the relevant QR code first, delete the QR code,     
	// remove from any products
	// then remove the job from the database.
    
    $query = "SELECT absolutePathToQrCode FROM jobs WHERE jobId=?";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $JobId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    $res = $statement->get_result();
    $row = $res->fetch_row();
    
    $qrCodePath = $row[0];
    
	//delete QR code file
    if($qrCodePath != null)
        exec("rm $qrCodePath");

    //Set any products which have this as their current job, current job to Null
	$query = "UPDATE products SET currentJobId=NULL WHERE currentJobId=?";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $JobId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

    //remove from jobs table
    $query = "DELETE FROM jobs WHERE jobId=?";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $JobId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    //remove from timelog
    $query = "DELETE FROM timeLog WHERE jobId=?";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $JobId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

	//remove from stoppageLog
    $query = "DELETE FROM stoppagesLog WHERE jobId=?";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $JobId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
}


function changeJobId($DbConn, $NewJobId, $OriginalJobId)
{

	//check if new jobID is alread in use
	$query = "SELECT COUNT(*) FROM jobs WHERE jobId=?";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $NewJobId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    $res = $statement->get_result();
    $row = $res->fetch_row();
    if($row[0] != 0)
    {
        printDebug("Error: Job ID already exists");
        return false;
    }

	//Update job details entries so new origional job id is replaced with new one but all other details unaffected 
	$query = "UPDATE jobs SET jobId=? WHERE jobId=?;";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('ss', $NewJobId, $OriginalJobId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);


	//Update jobid entries in time log so that jobid is replaced with new id
	$query = "UPDATE timeLog SET jobId=? WHERE jobId=?;";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('ss', $NewJobId, $OriginalJobId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

	//Update jobid entries in time log so that jobid is replaced with new id
	$query = "UPDATE stoppagesLog SET jobId=? WHERE jobId=?;";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('ss', $NewJobId, $OriginalJobId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

	//Detlete old QR code file
	// get the abs path to the relevant QR code first, delete the QR code, 
    
    $query = "SELECT absolutePathToQrCode FROM jobs WHERE jobId=?";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $NewJobId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    $res = $statement->get_result();
    $row = $res->fetch_row();
    
    $qrCodePath = $row[0];
    
    if($qrCodePath != null)
        exec("rm $qrCodePath");

	//Create QR code for new ID
	generateJobQrCode($DbConn, $NewJobId);

	return $NewJobId;
}


function getJobRecord($DbConn, $JobId)
{
    // call the stored procedure    
    if(!($statement = $DbConn->prepare("CALL GetJobRecord(?)")))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $JobId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
	
    if(!($statement->bind_result(
		$expectedDuration, $workedDuration, $overtimeDuration,
		$description,
		$currentStatus,
		$qrCodePath,
		$recordAdded,
		$notes,
		$routeName,
		$routeCurrentStageName,
		$routeCurrentStageIndex,
		$routeDescription,
		$priority,
		$dueDate,
		$stoppages,
		$numberOfUnits,
		$totalCharge,
		$productId
	)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    $statement->fetch();
    
    $statement->close();
	
    
    $expectedTime =     durationToTime($expectedDuration);
    $totalWorkedTime =  durationToTime($workedDuration);
    $totalOvertime =    durationToTime($overtimeDuration);
    $currentStatus =    makePrettyStatus($currentStatus);
	
	$charge 	 	=	intval($totalCharge);
	$durationSec		=	intval($workedDuration);
	if($durationSec != 0)
	{
		$timeMin		=	floor($durationSec)/60.0;
		$chargePerMinVal 	=	floatval($charge / $timeMin);
	}
	else
	{
		$chargePerMinVal 	=	0;
	}
	//$chargeString =	sprintf("%.01d.%.02d", floor($charge/100.0), floor($charge % 100));
	$chargePerMinStr 	=	sprintf("%.01d.%.02d", floor($chargePerMinVal/100.0), floor($chargePerMinVal % 100));

//	if($workedDuration != 0)
//	{
//		$chargePerMinVal =	floatval($totalCharge) / floor(intval($workedDuration)/60.0);
//	}
//	else
//	{
//		$chargePerMinVal = 0;
//	}	
//	$chargePerMinStr =	sprintf("%.01d.%.02d", floor($chargePerMinVal/100.0), floor($chargePerMinVal % 100));
    $jobRecord = array(
		"expectedDuration"		=> $expectedTime,
		"workedDuration"		=> $totalWorkedTime,
		"overtimeDuration"		=> $totalOvertime,
		"description"			=> $description,
		"currentStatus"			=> $currentStatus,
		"qrCodePath"			=> $qrCodePath,
		"recordAdded"			=> $recordAdded,
		"notes"					=> $notes,
		"routeName"				=> $routeName,
		"routeCurrentStageName"	=> $routeCurrentStageName,
		"routeCurrentStageIndex"=> $routeCurrentStageIndex,
		"routeDescription"		=> $routeDescription,
		"priority"				=> $priority,
		"dueDate"				=> $dueDate,
		"stoppages"				=> $stoppages,
		"numberOfUnits"			=> $numberOfUnits,
		"chargeToCustomer"		=> $totalCharge,
		"chargePerMinute"		=> $chargePerMinStr,
		"productId"				=> $productId
    );
	
	return $jobRecord;
}

function getAllRouteNames($DbConn)
{
	$query = "SELECT routeName FROM routes ORDER BY routeName ASC";
    
	if(!($queryResult = $DbConn->query($query)))
            errorHandler("Error executing query: ($DbConn->errno) $DbConn->error, line " . __LINE__);
	
	$routes = array();
    for($i = 0; $i < $queryResult->num_rows; $i++)
    {
        $row = $queryResult->fetch_row();
        array_push($routes,$row[0]);
    }
	return $routes;
}

function getRouteDescription($DbConn, $RouteName)
{
	 $query = "SELECT routeDescription FROM routes WHERE routeName=?";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $RouteName)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    $res = $statement->get_result();
    $row = $res->fetch_row();
    
    $routeDescription = $row[0];
	
	return $routeDescription;
}

function getTimelog($DbConn, $JobId, $IsCollapsed, $UseDateRange, $StartDate, $EndDate)
{
    if($IsCollapsed)
    {
        $query = "CALL GetCollapsedJobTimeLog(?,?,?,?)";
        if(!($statement = $DbConn->prepare($query)))
            errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);

        if(!($statement->bind_param('siss', $JobId, $UseDateRange, $StartDate, $EndDate)))
            errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);

        if(!$statement->execute())
            errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

        $res = $statement->get_result();

        $timeLog = array();

        for($i = 0; $i < $res->num_rows; $i++)
        {
            $row = $res->fetch_assoc();
			if($row["recordEndDate"] == "0000-00-00")
				$endDate = "";
			else
				$endDate = $row["recordEndDate"];

			$dataRow = array(
				"stationId" =>			$row["stationId"],
				"recordStartDate" =>	$row["recordStartDate"],
				"recordEndDate" =>		$endDate,
				"workedTime" => 		durationToTime($row['workedDuration']),
				"overtime" => 			durationToTime($row['overtimeDuration']),
				"workStatus" =>			$row["workStatus"],
				"quantityComplete"=>	$row["quantityComplete"],
				"outstanding"=>	$row["outstanding"],
				"routeStageIndex"=>$row["routeStageIndex"]
			);

            array_push($timeLog, $dataRow);
        }
    
        $statement->close();
    }
    else
    {
        $query = "CALL GetFullJobTimeLog(?,?,?,?)";
        if(!($statement = $DbConn->prepare($query)))
            errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);

        if(!($statement->bind_param('siss', $JobId, $UseDateRange, $StartDate, $EndDate)))
            errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);

        if(!$statement->execute())
            errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

        $res = $statement->get_result();

        $timeLog = array();

        for($i = 0; $i < $res->num_rows; $i++)
        {
            $row = $res->fetch_assoc();

            $row['workedTime'] = durationToTime($row['workedTime']);
            $row['overtime'] = durationToTime($row['overtime']);
            $row['workStatus'] = makePrettyStatus($row['workStatus']);

            array_push($timeLog, $row);
        }
    
        $statement->close();
    }
    
    $query = "CALL GetWorkedTimes(?,?,?,?)";
	if(!($statement = $DbConn->prepare($query)))
		errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);

	if(!($statement->bind_param('siss', $JobId, $UseDateRange, $StartDate, $EndDate)))
		errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);

	if(!$statement->execute())
		errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
	
	if(!$statement->bind_result($workedTime, $overtime))
		errorHandler("Error binding result: ($statement->errno) $statement->error, line " . __LINE__);
	
	$statement->fetch();
	
	$timeLog = array(
		"timeLogTableData"	=> $timeLog,
		"workedTime"		=> durationToTime($workedTime),
		"overtime"			=> durationToTime($overtime)
	);
    
    return $timeLog;
}

function getStoppagesLog($DbConn, $JobId)
{
    $query = "CALL GetStoppagesLog(?)";
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);

    if(!($statement->bind_param('s', $JobId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);

    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

    $res = $statement->get_result();

    $stoppagesLog = array();

    for($i = 0; $i < $res->num_rows; $i++)
    {
        $row = $res->fetch_assoc();

        array_push($stoppagesLog, $row);
    }

    $statement->close();


	$query = "SELECT stoppageReasonId, stoppageReasonName FROM stoppageReasons ORDER BY stoppageReasonId DESC";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    $res = $statement->get_result();
    
    $stoppageReasons = array();
    
    for($i = 0; $i < $res->num_rows; $i++)
    {
        $row = $res->fetch_assoc();
        $dataRow = array(
            "stoppageReasonId"        =>$row["stoppageReasonId"],
            "stoppageReasonName"      =>$row["stoppageReasonName"],
        );
        array_push($stoppageReasons, $dataRow);
    }

	$query = "SELECT stationId FROM connectedClients WHERE TIME_TO_SEC(TIMEDIFF(CURRENT_TIMESTAMP, lastSeen)) < 60 ORDER BY stationId ASC";
    if(!($queryResult = $DbConn->query($query)))
            errorHandler("Error executing query: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    $clientList = array();
    for($i = 0; $i < $queryResult->num_rows; $i++)
    {
        $row = $queryResult->fetch_assoc();
        
        array_push($clientList,$row["stationId"]);
    }
    
    return array("stoppagesLog"=>$stoppagesLog, "stoppageReasons"=>$stoppageReasons, "clientList"=>$clientList);
}

function resolveStoppage($DbConn, $stoppageRef)
{
	$query = "UPDATE `stoppagesLog` SET status='resolved' WHERE ref=?";
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);

    if(!($statement->bind_param('s', $stoppageRef)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);

    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

    $res = $statement->get_result();

	return "";
}

function saveRecordDetails($DbConn, $DetailsArray)
{			
	global $debug;

	$returnVal = "";

	if($DetailsArray["jobId"] != $DetailsArray["inputjobId"])
	{
		$newJobId = $DetailsArray["inputjobId"];

		//blank JobId generating a new ID was removed as this caused issues as the job ID
		// was not changed so any further generated ID had already had there name taken		
/*	    if($newJobId == "")
		{
			$newJobId = generateJobId($DbConn);
		}*/

		//Set any products which have original jobID as their current job, current job to  new jobID
		$query = "UPDATE products SET currentJobId=? WHERE currentJobId=?";
		
		if(!($statement = $DbConn->prepare($query)))
		    errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
		
		if(!($statement->bind_param('ss', $newJobId, $DetailsArray["jobId"])))
		    errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
		
		if(!$statement->execute())
		    errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

		if(changeJobId($DbConn, $newJobId, $DetailsArray["jobId"]))
		{
			$DetailsArray["jobId"] = $newJobId;
			$returnVal = $newJobId;
		}
		else
			return false;
	}

	$DetailsArray["totalChargeToCustomer"] = round($DetailsArray["totalChargeToCustomer"] * 100);

	if($DetailsArray["routeName"] != "")
	{
		$query = "CALL CheckChangeOfRoute(?, ?)";

		if(!($statement = $DbConn->prepare($query)))
		    errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);

		if(!($statement->bind_param(
			'ss',
			$DetailsArray["jobId"],
			$DetailsArray["routeName"]					
		)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
		if(!$statement->execute())
		    errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
	}

	$query = "
	UPDATE jobs SET
	expectedDuration = ?, 
	description = ?,
	notes = ?,
	routeName = ?,
	routeCurrentStageName = ?,
	routeCurrentStageIndex = ?,
	priority = ?,
	dueDate = ?,
	numberOfUnits = ?,
	totalChargeToCustomer = ?
	WHERE jobId = ?
	";
	
	
	printDebug("Params:");
	if($debug)
		print_r($DetailsArray);
	
	printDebug("Prepare query: $query");
	
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param(
			'issssiisiis',
			$DetailsArray["expectedDuration"],
			$DetailsArray["description"],
			$DetailsArray["notes"],
			$DetailsArray["routeName"],
			$DetailsArray["routeCurrentStageName"],
			$DetailsArray["routeCurrentStageIndex"],
			$DetailsArray["priority"],
			$DetailsArray["dueDate"],
			$DetailsArray["numberOfUnits"],
			$DetailsArray["totalChargeToCustomer"],
			$DetailsArray["jobId"]		
		)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

	return $returnVal;
}

//check that all required parameters are present and validate them
function getSaveRecordDetailsParameters($DbConn)
{
	$result = "";

	$requiredParameters = array("jobId",
								"inputjobId",
								"routeName",
								"routeCurrentStageName",
								"routeCurrentStageIndex",
								"description",
								"dueDate",
								"priority",
								"notes",
								"expectedDuration",
								"numberOfUnits",
								"totalChargeToCustomer"
							);

	$jobDetails = array();
	foreach($requiredParameters as $parameter)
	{
		if(isset($_REQUEST[$parameter]))
			$jobDetails[$parameter]= $_REQUEST[$parameter];
		else
		{
			$result= $parameter." missing";
			break;
		}
	}

	if($result == "")
	{
		$result = validateJobDetails($DbConn, 
									$jobDetails["jobId"], 
									$jobDetails["description"], 
									$jobDetails["expectedDuration"], 
									$jobDetails["routeName"], 
									$jobDetails["dueDate"], 
									$jobDetails["totalChargeToCustomer"], 
									$jobDetails["numberOfUnits"], 
									null, 
									$jobDetails["priority"]
									);
	}

	return array($jobDetails, $result);
}


function main()
{
    global $dbParamsServerName;
    global $dbParamsUserName;
    global $dbParamsPassword;
    global $dbParamsDbName;
	global $showQuantityDisplayElements;
    
    $dbConn = initDbConn($dbParamsServerName, $dbParamsUserName, $dbParamsPassword, $dbParamsDbName);
    $dbConn->autocommit(TRUE);
	
	if($_SERVER["REQUEST_METHOD"] === "GET")
	{
		$request = $_GET["request"]; 

		switch($request)
		{
			case "getJobRecord":
				// fetch details from the jobs table. Only expected to be called once per page load.
				$jobId = $_GET["jobId"];
				$record = getJobRecord($dbConn,$jobId);
				sendResponseToClient("success",$record);
				break;

			case "getAllRouteNames":
				$routes = getAllRouteNames($dbConn);
				sendResponseToClient("success",$routes);
				break;

			case "getRouteDescription":
				$routeName = $_GET["routeName"];
				$routeDescription = getRouteDescription($dbConn, $routeName);
				sendResponseToClient("success",$routeDescription);
				break;

			case "getTimeLog":
			case "getTimeLogCSV":
				$jobId = $_GET["jobId"];
				$isCollapsed = (isset($_GET["collapseRecords"]) && $_GET["collapseRecords"] == "true");
				$useDateRange = (isset($_GET["useDateRange"]) && $_GET["useDateRange"] == "true");
				if($useDateRange)
				{
					$startDate = $_GET["startDate"];
					$endDate = $_GET["endDate"];
				}
				else
				{
					$startDate = "";
					$endDate = "";
				}

				printDebug("Fetching records for job $jobId");
				$records = getTimelog($dbConn, $jobId, $isCollapsed, $useDateRange, $startDate, $endDate);
				if($request == "getTimeLog")
					sendResponseToClient("success",$records);
				else
				{
					// This is a bit inefficient, as a fair amount of unneeded
					// computation is carried out, but it'll do temporarily.
					if(!$isCollapsed)
					{
						$dataNames = array(
							"stationId",
							"userName",
							"recordDate",
							"clockOnTime",
							"clockOffTime",
							"workedTime",
							"overtime",
							"workStatus"
						);
						$columnNames = array(
							"Station Name",
							"User Name",
							"Date",
							"Start Time",
							"End Time",
							"Duration",
							"Overtime",
							"Job Status at End of Record"
						);

						if($showQuantityDisplayElements){
							array_push($dataNames,"quantityComplete");
							array_push($columnNames,"Quantity");
						}

						if($useDateRange)
							$fileName = $jobId . "_records_" . $_GET["startDate"] . "_to_" . $_GET["endDate"] . ".csv";
						else
							$fileName = $jobId . "_records.csv";
					}
					else
					{
						$dataNames = array(
							"stationId",
							"recordStartDate",
							"recordEndDate",
							"workedTime",
							"overtime",
							"workStatus"
						);
						$columnNames = array(
							"Station Name",
							"Record Start Date",
							"record End Date",
							"Worked Duration",
							"Overtime Duration",
							"Last Status at Station"
						);

						if($showQuantityDisplayElements){
							array_push($dataNames,"quantityComplete");
							array_push($columnNames,"Quantity");
							array_push($dataNames,"outstanding");
							array_push($columnNames,"Outstanding");
						}

						// include route stage intex for collapsed records
						// condition should be placed to only incude if all bellow 0
						array_push($dataNames,"routeStageIndex");
						array_push($columnNames,"Route Index");

						if($useDateRange)
							$fileName = $jobId . "_records_" . $_GET["startDate"] . "_to_" . $_GET["endDate"] . "_collapsed.csv";
						else
							$fileName = $jobId . "_records_collapsed.csv";
					}

					sendCsvToClient($records["timeLogTableData"], $dataNames, $columnNames, $fileName);
				}
				break;
			case "getStoppagesLog":
				$jobId = $_GET["jobId"];
				printDebug("Fetching stoppage records for job $jobId");
				$records = getStoppagesLog($dbConn, $jobId);
				sendResponseToClient("success",$records);
				break;
			case "resolveStoppage":
				$stoppageRef = $_GET["stoppageRef"];
				printDebug("resolving Stoppage $stoppageRef");
				$responce = resolveStoppage($dbConn, $stoppageRef);
				sendResponseToClient("success",$responce);
				updateJobStoppagesFromStoppageRef($dbConn, $stoppageRef);
				break;
			case "markJobComplete":
				$jobId = $_GET["jobId"];
				printDebug("Marking job $jobId as complete");
				markJobComplete($dbConn, $jobId);
				printDebug("Done");
				sendResponseToClient("success");
				break;
			case "markJobIncomplete":
				$jobId = $_GET["jobId"];
				printDebug("Marking job $jobId as incomplete");
				markJobIncomplete($dbConn, $jobId);
				printDebug("Done");
				sendResponseToClient("success");
				break;
			case "deleteJob":
				$jobId = $_GET["jobId"];
				printDebug("Deleting job $jobId");
				deleteJob($dbConn, $jobId);
				printDebug("Done");
				sendResponseToClient("success");
				break;
			case "updateJobStoppages":
				$jobId = $_GET["jobId"];
				printDebug("updateJobStoppages $jobId");
				$result = updateJobStoppages($dbConn, $jobId);
				printDebug("Done");
				sendResponseToClient("success", $result);
				break;
			case "updateJobStoppagesFromStoppageRef":
				$ref = $_GET["ref"];
				printDebug("updateJobStoppages $ref");
				$result = updateJobStoppagesFromStoppageRef($dbConn, $ref);
				printDebug("Done");
				sendResponseToClient("success", $result);
				break;

			default:
				sendResponseToClient("error", "Unknown command: $request");
		}
	}
	elseif($_SERVER["REQUEST_METHOD"] === "POST")
	{
		$request = $_REQUEST["request"];
		printDebug("request: $request");
		
		switch($request)
		{
			case "saveRecordDetails":
				list($recordDetails, $validationResult) = getSaveRecordDetailsParameters($dbConn);
				printDebug("Saving new record details");
				if ($validationResult == "")
				{
					$jobId = saveRecordDetails($dbConn, $recordDetails);
					if($jobId != false || $jobId === "")
					{
						printDebug("Done");
						sendResponseToClient("success", $jobId);
					}
					else
						sendResponseToClient("error","job ID already exists");
				}
				else
				{
					sendResponseToClient("error",$validationResult);
				}

				break;

			case "changeJobId":
				printDebug("Changing Job ID");
				$newID = changeJobId($dbConn, $_REQUEST["newJobId"], $_REQUEST["orgJobId"]);
				if($newID)
				{
					printDebug("Done");
					sendResponseToClient("success", $newID);
				}
				else
					sendResponseToClient("error","job ID already exists");

				break;

			default:
				sendResponseToClient("error", "Unknown command: $request");
				break;
		}
	}
}

main();
