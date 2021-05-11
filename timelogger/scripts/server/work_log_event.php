<?php
// Takes a request from a browser client and generates all Data about a Work
// log event.
//
// Note that the database connection is implicitly released when this script 
// terminates
require "db_params.php";
require "common.php";

$debug = false;

function deleteEventRecord($DbConn, $workLogRef)
{
	//function to delete work log event record and remove it's contribution to duration and overtime of the job from the job record	


	$query = "SELECT jobId, workedDuration, overtimeDuration FROM timeLog WHERE ref=?";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $workLogRef)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

	if(!($statement->bind_result(
		$jobId,
		$duration,
		$overtime
	)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    $statement->fetch();
    
    $statement->close();

	$query = "UPDATE jobs SET closedWorkedDuration = closedWorkedDuration - ?, closedOvertimeDuration = closedOvertimeDuration - ? WHERE jobId=?";

	if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('iis', $duration, $overtime, $jobId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);



	$query = "DELETE FROM timeLog WHERE ref=?";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $workLogRef)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
}

function getWorkLogRecord($DbConn, $workLogRef)
{
    // call the stored procedure  
	$query = "SELECT jobId, stationId, userId, clockOnTime, clockOffTime, recordDate, workedDuration, overtimeDuration, workStatus, quantityComplete FROM timeLog WHERE ref=?";
  
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $workLogRef)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
	
    if(!($statement->bind_result(
		$jobId,
		$stationId,
		$userId,
		$clockOnTime,
		$clockOffTime,
		$recordDate,
		$workedDuration,
		$overtimeDuration,
		$workStatus,
		$quantityComplete
	)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    $statement->fetch();
    
    $statement->close();

	$workedDuration =  durationToTime($workedDuration);
    $overtimeDuration =    durationToTime($overtimeDuration);

	//get user name from userId
	$query = "SELECT userName FROM users WHERE userId=?";
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);

    if(!($statement->bind_param('s', $userId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);

    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

    $res = $statement->get_result();

	$userName = $res->fetch_row();
	
	//create array of values found to be retuned
    $workLogRecord = array(
		"jobId"					=> $jobId,
		"stationId"				=> $stationId,
		"userName"				=> $userName,
		"clockOnTime"			=> $clockOnTime,
		"clockOffTime"			=> $clockOffTime,
		"recordDate"			=> $recordDate,
		"workedDuration"		=> $workedDuration,
		"overtimeDuration"		=> $overtimeDuration,
		"workStatus"			=> $workStatus,
		"quantityComplete"		=> $quantityComplete
    );
	
	return $workLogRecord;
}


function saveRecordDetails($DbConn, $DetailsArray)
{			
	global $debug;

	if ($DetailsArray["quantityComplete"]=="")
		$DetailsArray["quantityComplete"] = NULL;

	if (timeToDuration($DetailsArray["clockOffTime"]) < timeToDuration($DetailsArray["clockOnTime"])  && timeToDuration($DetailsArray["clockOffTime"]) != null)
	{
		return "Unable to Save: Clock off time after clock on time";
	}
					
	$query = "CALL changeWorkLogRecord(?,?,?,?,?,?);";

	if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param(
			'ssssss',
			$DetailsArray["workLogRef"],
			$DetailsArray["stationId"],
			$DetailsArray["clockOnTime"],
			$DetailsArray["clockOffTime"],
			$DetailsArray["workStatus"],
			$DetailsArray["quantityComplete"]
				
		)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

	$res = $statement->get_result();

	$returnVal = $res->fetch_row();

	if ($returnVal[0] != "success")
		return "Unable to Save: ".$returnVal[0];

	return "Save Complete";
}

function insertBreak($DbConn, $DetailsArray)
{
	global $debug;

	if (timeToDuration($DetailsArray["breakEnd"]) < timeToDuration($DetailsArray["breakStart"]))
	{
		return "Unable to Insert: Break start before break end";
	}
	elseif (timeToDuration($DetailsArray["breakEnd"]) == timeToDuration($DetailsArray["breakStart"]))
	{
		return "Unable to Insert: Break start equal to break end";
	}
					
	$query = "CALL insertBreak(?,?,?);";

	if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param(
			'sss',
			$DetailsArray["workLogRef"],
			$DetailsArray["breakStart"],
			$DetailsArray["breakEnd"]				
		)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

	$res = $statement->get_result();

	$returnVal = $res->fetch_row();

	if ($returnVal[0] != "success")
		return "Unable to Insert: ".$returnVal[0];

	return "Insert Complete";

}

function main()
{
    global $dbParamsServerName;
    global $dbParamsUserName;
    global $dbParamsPassword;
    global $dbParamsDbName;
    
    $dbConn = initDbConn($dbParamsServerName, $dbParamsUserName, $dbParamsPassword, $dbParamsDbName);
    $dbConn->autocommit(TRUE);
	
	if($_SERVER["REQUEST_METHOD"] === "GET")
	{
		$request = $_GET["request"]; 

		switch($request)
		{
			case "getWorkLogRecord":
				// fetch details from the jobs table. Only expected to be called once per page load.
				$workLogRef = $_GET["workLogRef"];
				$record = getWorkLogRecord($dbConn,$workLogRef);
				sendResponseToClient("success",$record);
				break;

			case "deleteEventRecord":
				$workLogRef = $_GET["workLogRef"];
				printDebug("Deleting work event $workLogRef");
				deleteEventRecord($dbConn, $workLogRef);
				printDebug("Done");
				sendResponseToClient("success");
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
				$recordDetails = array(
					"workLogRef"	=> $_REQUEST["workLogRef"],
					"jobId"			=> $_REQUEST["jobId"],
					"stationId" 	=> $_REQUEST["stationId"],				
					"clockOnTime"	=> $_REQUEST["clockOnTime"],						
					"clockOffTime"	=> $_REQUEST["clockOffTime"],				
					"workStatus"	=> $_REQUEST["workStatus"],
					"quantityComplete"	=> $_REQUEST["quantityComplete"]
					);	
				printDebug("Saving new record details");
				$returnVal = saveRecordDetails($dbConn, $recordDetails);
				
				if ($returnVal == "Save Complete")
				{
					printDebug("Done");
					sendResponseToClient("success", $returnVal);
				}
				else
				{	
					printDebug("Error during saving");
					printDebug($returnVal);
					sendResponseToClient("error", $returnVal);
				}
				

				break;

			case "insertBreak":
				$recordDetails = array(
					"workLogRef"	=> $_REQUEST["workLogRef"],
					"breakStart"	=> $_REQUEST["breakStart"],
					"breakEnd" 		=> $_REQUEST["breakEnd"]
					);	
				printDebug("Inserting Break");
				$returnVal = insertBreak($dbConn, $recordDetails);
				
				if ($returnVal == "Insert Complete")
				{
					printDebug("Done");
					sendResponseToClient("success", $returnVal);
				}
				else
				{	
					printDebug("Error during insert");
					printDebug($returnVal);
					sendResponseToClient("error", $returnVal);
				}

				break;

			default:
				sendResponseToClient("error", "Unknown command: $request");
				break;
		}
	}
}

main();
