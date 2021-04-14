<?php
// Takes a request from a browser client and generates a collection of data.
// This data includes the current job status, time, overtime, expected time,
// description, and a collection of reccords indicating where the job has
// been worked on.

// Note that the database conenction is implicitly released when this script 
// terminates
require "db_params.php";
require "common.php";

$debug = false;

function getTimeSheet($DbConn, $UserId, $StartDate, $EndDate)
{
    // Calls a stored procedure to get a time sheet for the
    // specified user. The column names will be the job IDs
    // that the user has worked on.
	//
	// Note that since this query produces multiple results
	// sets, mysqli::multi_query() must be used. This cannot
	// use a prepared statement, so this does produce a 
	// small security risk. Given the context that this
	// software will be used in, I'm opting to simply ignore
	// this, as it isn't realistically likely to be an issue.
	date_default_timezone_set("Europe/London");
	
	$startDateDt = new DateTime($StartDate);
	$endDateDt = new DateTime($EndDate);
	
	if($endDateDt < $startDateDt)
		errorHandler("End date must not be before start date");
	
	
	
    if(!($DbConn->multi_query("CALL GetTimesheet('$UserId', '$StartDate', '$EndDate');")))
        errorHandler("Error calling GetTimesheet: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    $res = $DbConn->store_result();
    
    $timesheet = array();
	$columnNames = array("recordDate");
	
	$blankTimesheetRow = array("recordDate"=>"");
	
	// process initial list of job names. This is required to send to the client or to make a csv file
    for($i = 0; $i < $res->num_rows; $i++)
    {
        $row = $res->fetch_row();
    
        array_push($columnNames, $row[0]);
		$blankTimesheetRow[$row[0]] = "";
    }
	$res->free();
	
	
	
	// get the worked durations from the DB
	$DbConn->next_result();
	$res = $DbConn->store_result();
	
	$row = $res->fetch_assoc();
	
	$rowCount = $startDateDt->diff($endDateDt)->days + 1;
	
	for($i = 0; $i < $rowCount; $i++)
	{
		$timesheetRow = $blankTimesheetRow;
		$rowDate = date('Y-m-d', strtotime($StartDate . " + $i days"));
		$timesheetRow["recordDate"] = $rowDate;
		
		while($row && ($row["recordDate"] == $timesheetRow["recordDate"]))
		{
			$timesheetRow[$row["jobId"]] = durationToTime($row["workedDuration"]);
			$row = $res->fetch_assoc();
		}
		array_push($timesheet, $timesheetRow);
	}
	
	$res->free();
	
	
	
	// get the total duration and total overtime from the DB
	if(!($DbConn->next_result()))
		errorHandler("($DbConn->errno) $DbConn->error, line " . __LINE__);
	if(!($res = $DbConn->store_result()))
		errorHandler("($DbConn->errno) $DbConn->error, line " . __LINE__);
	
	$row = $res->fetch_row();
	$totalDuration = $row[0];
	$overtimeDuration = $row[1];
	
	if($totalDuration == "-1")
	{
		$totalDuration = "Unavailable";
		$overtimeDuration = "Unavailable";
	}
	else
	{
		$totalDuration = durationToTime($totalDuration);
		$overtimeDuration = durationToTime($overtimeDuration);
	}
    
    $timesheetData = array(
        "timesheet" 		=> $timesheet,
		"columnNames"		=> $columnNames,
        "totalWorkedTime" 	=> $totalDuration,
        "totalOvertime" 	=> $overtimeDuration
    );
    
	$DbConn->close();
	
    return $timesheetData;
}

function getUsers($DbConn)
{
    $query = "SELECT userId, userName FROM users";
    if(!($res = $DbConn->query($query)))
            errorHandler("Error executing query: ($DbConn->errno) $DbConn->error, line " . __LINE__);

    $users = array();
    for($i = 0; $i < $res->num_rows; $i++)
    {
        $row = $res->fetch_assoc();
        
        if($row["userId"] != "noName" && $row["userId"] != "office" && $row["userId"] != "user_Delt")
            array_push($users, $row);
    }
    
    return $users;
}

function main()
{
    global $dbParamsServerName;
    global $dbParamsUserName;
    global $dbParamsPassword;
    global $dbParamsDbName;
    
    $dbConn = initDbConn($dbParamsServerName, $dbParamsUserName, $dbParamsPassword, $dbParamsDbName);
    $dbConn->autocommit(TRUE);

    $request = $_GET["request"]; 
   
    switch($request)
    {
        case "getTimesheet":
        case "getTimesheetCSV":
            $userId = $_GET["userId"];
            $startDate = $_GET["startDate"];
            $endDate = $_GET["endDate"];
            
            printDebug("Fetching timesheet for user $userId from $startDate to $endDate");
            
            $timesheetData = getTimeSheet($dbConn, $userId, $startDate, $endDate);
            if($request == "getTimesheet")
                sendResponseToClient("success",$timesheetData);
            else
			{
				$csvFileName = $userId."_timesheetData.csv";
                sendCsvToClient(
					$timesheetData["timesheet"], 
					$timesheetData["columnNames"],
					$timesheetData["columnNames"],
					$csvFileName
				);
			}
            
            break;
            
        case "getUsers":
            printDebug("Fetching list of userIDs and usernames");
            $users = getUsers($dbConn);
            sendResponseToClient("success",$users);
            break;
            
        default:
            echo("Unrecognised request: $request");
    }
}

main();
