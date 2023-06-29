<?php

//  Copyright 2022 DigitME2

//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at

//      http://www.apache.org/licenses/LICENSE-2.0

//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

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
require_once "kafka.php";

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

	kafkaOutputSetJobProgressState($JobId, "workInProgress", null, null);

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

	kafkaOutputSetJobProgressState($JobId, "complete", null, null);
}

function deleteJob($DbConn, $JobId)
{
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

	kafkaOutputDeleteJob($JobId);
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

	kafkaOutputChangeJobId($OriginalJobId, $NewJobId);

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
		$totalParts,
		$totalCharge,
		$productId,
		$customerName,
		$jobName
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
	// $chargePerMinStr 	=	sprintf("%.01d.%.02d", floor($chargePerMinVal/100.0), floor($chargePerMinVal % 100));
	$chargePerMinStr = ""; // commented the actual line and wrote this as a temporary fixture.

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
		"totalParts"			=> $totalParts,
		"chargeToCustomer"		=> $totalCharge,
		"chargePerMinute"		=> $chargePerMinStr,
		"productId"				=> $productId,
		"customerName"			=> $customerName,
		"jobName"				=> $jobName
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

function getTimelog($DbConn, $JobId, $IsCollapsed, $UseDateRange, $StartDate, $EndDate, $showSeconds = false)
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
				"workedTime" => 		durationToTime($row['workedDuration'], $showSeconds),
				"overtime" => 			durationToTime($row['overtimeDuration'], $showSeconds),
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

            $row['workedTime'] = durationToTime($row['workedTime'], $showSeconds);
            $row['overtime'] = durationToTime($row['overtime'], $showSeconds);
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
		"workedTime"		=> durationToTime(($workedTime), ($showSeconds)),
		"overtime"			=> durationToTime(($overtime), ($showSeconds))
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
	$JobId = "";
	$StoppageReasonId = "";
	$StationId = "";
	$Description = "";
	$Status = "resolved";

	$query = "CALL recordStoppage(?, ?, ?, ?, ?, ?)";
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);

    if(!($statement->bind_param('isssss', $stoppageRef, $JobId, $StoppageReasonId, $StationId, $Description, $Status)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);

    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

	$res = $statement->get_result();
	$row = $res->fetch_row();
	$result = $row[0];
	$statement->close();

	// get the job ID stoppage type ID for kafka
	$query = "SELECT `jobId`, `stoppageReasonId` FROM `stoppagesLog` WHERE ref=?";
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);

    if(!($statement->bind_param('i', $stoppageRef)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);

    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

    $res = $statement->get_result();
	$row = $res->fetch_assoc();

	kafkaOutputRecordProblemState($row["jobId"], $row["stoppageReasonId"], false);

	return "";
}

function saveRecordDetails($DbConn, $DetailsArray)
{			
	global $debug;

	$returnVal = "";

	if($DetailsArray["jobId"] != $DetailsArray["newJobId"])
	{
		$newJobId = $DetailsArray["newJobId"];

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

	if($DetailsArray["jobName"] != "")
	{
		$query = "SELECT COUNT(jobName) FROM jobs WHERE jobName=? AND jobId != ?";

		if(!($statement = $DbConn->prepare($query)))
		    errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);

		if(!($statement->bind_param(
			'ss',
			$DetailsArray["jobName"],
			$DetailsArray["jobId"]					
		)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
		if(!$statement->execute())
		    errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
		
		$res = $statement->get_result();
		$row = $res->fetch_row();
		if($row[0] != 0) {
			return false;
		}
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
	totalParts = ?,
	totalChargeToCustomer = ?,
	customerName = ?,
	jobName = ?
	WHERE jobId = ?
	";
	
	
	printDebug("Params:");
	if($debug)
		print_r($DetailsArray);
	
	printDebug("Prepare query: $query");
	
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param(
			'issssiisiiisss',
			$DetailsArray["expectedDuration"],
			$DetailsArray["description"],
			$DetailsArray["notes"],
			$DetailsArray["routeName"],
			$DetailsArray["routeCurrentStageName"],
			$DetailsArray["routeCurrentStageIndex"],
			$DetailsArray["priority"],
			$DetailsArray["dueDate"],
			$DetailsArray["numberOfUnits"],
			$DetailsArray["totalParts"],
			$DetailsArray["totalChargeToCustomer"],
			$DetailsArray["customerName"],
			$DetailsArray["jobName"],
			$DetailsArray["jobId"]	
		)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

	kafkaOutputUpdateJobDetails(
		$DetailsArray["jobId"],
		$DetailsArray["customerName"],
		$DetailsArray["expectedDuration"],
		$DetailsArray["dueDate"],
		$DetailsArray["description"],
		$DetailsArray["totalChargeToCustomer"],
		$DetailsArray["numberOfUnits"],
		$DetailsArray["totalParts"],
		$DetailsArray["routeName"],
		$DetailsArray["routeCurrentStageIndex"],
		$DetailsArray["priority"],
		$DetailsArray["notes"],
		$DetailsArray["jobName"]
	);

	return $returnVal;
}

//check that all required parameters are present and validate them
function getSaveRecordDetailsParameters($DbConn)
{
	$result = "";

	$requiredParameters = array("jobId",
								"newJobId",
								"routeName",
								"routeCurrentStageName",
								"routeCurrentStageIndex",
								"description",
								"dueDate",
								"priority",
								"notes",
								"expectedDuration",
								"numberOfUnits",
								"totalParts",
								"totalChargeToCustomer",
								"customerName",
								"jobName"
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
								 	$jobDetails["totalParts"], 
									null, 
									$jobDetails["priority"],
									$jobDetails["customerName"],
									$jobDetails["jobName"]
									);
	}

	return array($jobDetails, $result);
}

function getJobName($DbConn, $jobId)
{
	//to get Job Name for job ID.
	$query = "SELECT jobName FROM jobs WHERE jobId=?";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $jobId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    $res = $statement->get_result();
    $row = $res->fetch_row();

	return $row[0];
}

function getJobList($DbConn) 
{
	//to get Job Name for job ID.
	$query = "SELECT jobId, jobName FROM jobs ORDER BY jobName ASC";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    $res = $statement->get_result();
    
    $tableData = array();
    
    for($i = 0; $i < $res->num_rows; $i++)
    {
        $row = $res->fetch_assoc();
        $dataRow = array(
            "jobId"        =>$row["jobId"],
            "jobName"      =>$row["jobName"]
        );
        array_push($tableData, $dataRow);
    }
    
    return $tableData;
}

function getNewJobName($DbConn, $JobName){
	$indexOfUnderscore = strpos($JobName, "_");
	if($indexOfUnderscore != false)
		$trimmedJobName = substr($JobName, 0, $indexOfUnderscore);
	else
		$trimmedJobName = $JobName;
		
	$searchTerm = $trimmedJobName."%";

	$query = "SELECT COUNT(jobName) FROM jobs WHERE jobName LIKE ? ORDER BY jobName ASC ";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $searchTerm)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    $res = $statement->get_result();
    $row = $res->fetch_row();
	
	$newJobName = $trimmedJobName . "_" . strval($row[0] + 1);

	return $newJobName;
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
			case "getJobList":
				$jobs = getJobList($dbConn);
				sendResponseToClient("success", $jobs);
				break;

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
				$jobName = getJobName($dbConn, $jobId);
				$isCollapsed = (isset($_GET["collapseRecords"]) && $_GET["collapseRecords"] == "true");
				$useDateRange = (isset($_GET["useDateRange"]) && $_GET["useDateRange"] == "true");
				$showSeconds = (isset($_GET["showSeconds"]) && $_GET["showSeconds"] == "true");

				if($useDateRange)
				{
					$startDate = $_GET["startDate"];
					$endDate = $_GET["endDate"];
				}
				else
				{
					$startDate = "2022-01-01";
					$endDate = "2022-06-06";
				}

				printDebug("Fetching records for job $jobId");
				$records = getTimelog($dbConn, $jobId, $isCollapsed, $useDateRange, $startDate, $endDate, $showSeconds);
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
							"Location Name",
							"User Name",
							"Date",
							"Start Time",
							"End Time",
							"Duration",
							"Overtime",
							"Job Status"
						);

						if($showQuantityDisplayElements){
							array_push($dataNames,"quantityComplete");
							array_push($columnNames,"Quantity");
						}

						if($useDateRange)
							$fileName = $jobName . "__'" . $jobId . "'_records_" . $_GET["startDate"] . "_to_" . $_GET["endDate"] . ".csv";
						else
							$fileName = $jobName . "__'" . $jobId . "'_records.csv";
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
							"Location Name",
							"Record Start Date",
							"record End Date",
							"Worked Duration",
							"Overtime Duration",
							"Job Status"
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
							$fileName = $jobName . "__'" . $jobId . "'_records_" . $_GET["startDate"] . "_to_" . $_GET["endDate"] . "_collapsed.csv";
						else
							$fileName = $jobName . "__'" . $jobId . "'_records_collapsed.csv";
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
				resolveStoppage($dbConn, $stoppageRef);
				sendResponseToClient("success", "Stoppage resolved");
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

			case "getNewJobName":
				$jobName = $_GET["jobName"];
				$newJobName = getNewJobName($dbConn, $jobName);
				sendResponseToClient("success", $newJobName);
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
						sendResponseToClient("error","Job ID already exists or new Job ID is not starting with 'job_' at start !");
				}
				else
				{
					sendResponseToClient("error",$validationResult);
				}

				break;

			case "changeJobId":
				printDebug("Changing Job ID");
				$newJobId = $_REQUEST["newJobId"];
				echo(checkStartsWithPrefix($newJobId));
				if((checkStartsWithPrefix($newJobId))){
					$newID = changeJobId($dbConn, $newJobId, $_REQUEST["orgJobId"]);
					printDebug("Done");
					sendResponseToClient("success", $newID);
				}
				else
				{
					sendResponseToClient("error","Job ID already exists or new Job ID is not starting with 'job_' at start !");
				}
				break;

			default:
				sendResponseToClient("error", "Unknown command: $request");
				break;
		}
	}
}

main();
