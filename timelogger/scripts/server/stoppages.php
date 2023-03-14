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

// Note that the database conenction is implicitly released when this script 
// terminates
require "db_params.php";
require "common.php";
require "kafka.php";

$Debug = false;

function checkStoppageExists($DbConn, $stoppageReason) 
{
    $query = "SELECT COUNT(stoppageReasonName) FROM stoppageReasons WHERE stoppageReasons.stoppageReasonName=?";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $stoppageReason)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    $res = $statement->get_result();
    $row = $res->fetch_row();
    if($row[0] != 0)
    {
        printDebug("Error: Stoppage Reason Name already exists");
        return false;
    }
    else
    {
        return true;
    }
}

function checkJobIdExists($DbConn, $searchPhrase){

    $searchPhrase = "%".$searchPhrase."%";
    $query = "SELECT jobId FROM stoppagesLog WHERE jobId LIKE ? ORDER BY jobId ASC";

    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);

    if(!($statement->bind_param('s', $searchPhrase)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);

    
    if(!($statement->execute()))
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    $res = $statement->get_result();

    $row = $res->fetch_assoc();

    if($row != "")
    {
        printDebug("Success: jobId exists in Stoppages Log");
        return true;
    }
    else
    {
        printDebug("Error: jobId not exists in Stoppages Log");
        return false;
    }
}

function addStoppageReason($DbConn, $stoppageReason)
{	
	global $stoppageReasonIDCodePrefix;

    $query = "SELECT stoppageReasonIdIndex FROM stoppageReasons ORDER BY stoppageReasonIdIndex DESC LIMIT 1";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    $res = $statement->get_result();
    if($res->num_rows == 0)
        $newStoppageReasonIdNum = 1;
    else
    {
        $row = $res->fetch_row();
        $newStoppageReasonIdNum = intval($row[0]) + 1;
    }    
    $newStoppageReasonId = sprintf("%s%04d", $stoppageReasonIDCodePrefix, $newStoppageReasonIdNum);

    printDebug("Adding new Stoppage Reason $stoppageReason");

    $query = "INSERT INTO stoppageReasons (stoppageReasonId, stoppageReasonName, stoppageReasonIdIndex) VALUES (?, ?, ?)";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('ssi', $newStoppageReasonId, $stoppageReason, $newStoppageReasonIdNum)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

    kafkaOutputCreateProblemReason($newStoppageReasonId, $stoppageReason);
    
    return $newStoppageReasonId;    
}

function getStoppagesLog($DbConn, $useStartDate, $useEndDate, $startDate, $endDate, $searchPhrase){

    date_default_timezone_set("Europe/London");

    $startDateDt = new DateTime($startDate);
	$endDateDt = new DateTime($endDate);

    if($endDateDt < $startDateDt)
		errorHandler("End date must not be before start date");

    $searchPhrase = "%".$searchPhrase."%";

    $query = "SELECT 
    stoppagesLog.jobId, jobs.customerName, stoppageReasonName, 
    stationId, startTime, startDate, endTime, endDate, duration, status 
    FROM stoppagesLog 
    LEFT JOIN jobs on jobs.jobId = stoppagesLog.jobId 
    LEFT JOIN stoppageReasons ON stoppagesLog.stoppageReasonId = stoppageReasons.stoppageReasonId ";

    if(!$useStartDate && !$useEndDate)
    {
        $query = $query . "WHERE (stoppagesLog.jobId LIKE ? OR jobs.customerName LIKE ?)
        ORDER BY stoppagesLog.startDate ASC";

        if(!($statement = $DbConn->prepare($query)))
            errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);

        if(!($statement->bind_param('ss', $searchPhrase, $searchPhrase)))
            errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);

        if(!$statement->execute())
            errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    }
    else if($useStartDate && !$useEndDate)
    {
        $query = $query . "WHERE startDate >= ? AND (stoppagesLog.jobId LIKE ? OR jobs.customerName LIKE ?) 
        ORDER BY stoppagesLog.startDate ASC";

        if(!($statement = $DbConn->prepare($query)))
            errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);

        if(!($statement->bind_param('sss', $startDate, $searchPhrase, $searchPhrase)))
            errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);

        if(!$statement->execute())
            errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    }
    else if(!$useStartDate && $useEndDate)
    {
        $query = $query . "WHERE endDate <= ? AND (stoppagesLog.jobId LIKE ? OR jobs.customerName LIKE ?)
        ORDER BY stoppagesLog.startDate ASC";

        if(!($statement = $DbConn->prepare($query)))
            errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);

        if(!($statement->bind_param('sss', $endDate, $searchPhrase, $searchPhrase)))
            errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);

        if(!$statement->execute())
            errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    }
    else if($useStartDate && $useEndDate)
    {
        $query = $query . "WHERE (startDate >= ? AND endDate <= ?) AND (stoppagesLog.jobId LIKE ? OR jobs.customerName LIKE ?)
        ORDER BY stoppagesLog.startDate ASC";

        if(!($statement = $DbConn->prepare($query)))
            errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);

        if(!($statement->bind_param('ssss', $startDate, $endDate, $searchPhrase, $searchPhrase)))
            errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);

        if(!$statement->execute())
            errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    }



    $res = $statement->get_result();

    $logTableData = array();

    for($i = 0; $i < $res->num_rows; $i++)
    {
        $row = $res->fetch_assoc();
        $dataRow = array(
            "jobId" =>$row["jobId"],
            "customerId" => $row["customerName"],
            "stoppageReasonName" =>$row["stoppageReasonName"],
            "stationId" => $row["stationId"],
            "startTime" => $row["startTime"],
            "startDate" => $row["startDate"],
            "endTime" => $row["endTime"],
            "endDate" => $row["endDate"],
            "duration" => durationToTime($row["duration"]),
            "status" => $row["status"]
        );
        array_push($logTableData, $dataRow);
    }
    
    return $logTableData;
}

function getCustomerId($DbConn, $jobId){
    $query = "SELECT customerName FROM jobs WHERE jobId=?";

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

function getStoppageReasonTableData($DbConn, $OrderByName){
    // returns an array of stoppages data, ordered either name or by order
    // added, newest first.
    
    if($OrderByName == true)
        $query = "SELECT stoppageReasonId, stoppageReasonName FROM stoppageReasons ORDER BY stoppageReasonName ASC";
    else
        $query = "SELECT stoppageReasonId, stoppageReasonName FROM stoppageReasons ORDER BY stoppageReasonId DESC";
    
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
            "stoppageReasonId"        =>$row["stoppageReasonId"],
            "stoppageReasonName"      =>$row["stoppageReasonName"]
        );
        array_push($tableData, $dataRow);
    }
    
    return $tableData;
}

function deleteStoppageReason($DbConn, $StoppageReasonId)
{
    
    $query = "DELETE FROM stoppageReasons WHERE stoppageReasonId=?";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $StoppageReasonId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
	
	//remove entries from log
	$query = "DELETE FROM stoppagesLog WHERE stoppageReasonId=?";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $StoppageReasonId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

    kafkaOutputDeleteProblemReason($StoppageReasonId);
}

function getIdsfortheStoppageReasonName($DbConn, $stoppageReason)
{
    $query = "SELECT stoppageReasonId FROM stoppageReasons WHERE stoppageReasonName = ? ";

    if(!($statement = $DbConn->prepare($query)))
            errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
        if(!($statement->bind_param('s', $stoppageReason)))
            errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
        if(!$statement->execute())
            errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
		
	    $res = $statement->get_result();
	    $row = $res->fetch_assoc();
        $stoppageReasonId = $row["stoppageReasonId"];
        return $stoppageReasonId;
}

function getProductsList($DbConn)
{
	// fetch current list of ProductIds
    $query = "SELECT productId FROM products ORDER BY productId ASC";
    
	if(!($queryResult = $DbConn->query($query)))
            errorHandler("Error executing query: ($DbConn->errno) $DbConn->error, line " . __LINE__);
	
	$products = array();
    for($i = 0; $i < $queryResult->num_rows; $i++)
    {
        $row = $queryResult->fetch_row();
        array_push($products,$row[0]);
    }
	
	return $products;
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
        case "getStoppagesLog":
        case "getStoppagesLogCSV":
            $useStartDate = (isset($_GET["useStartDate"]) && $_GET["useStartDate"] == "true");
            $useEndDate = (isset($_GET["useEndDate"]) && $_GET["useEndDate"] == "true");
            if($useStartDate)
            {
                $startDate = $_GET["startDate"];
            }
            else
            {
                $startDate = "2000-01-01";
            }
            if($useEndDate)
            {
                $endDate = $_GET["endDate"];
            }
            else
            {
                $endDate = "3000-12-31";
            }
            $searchPhrase = $_GET["searchPhrase"];
            $stoppagesLogTable = getStoppagesLog($dbConn, $useStartDate, $useEndDate, $startDate, $endDate, $searchPhrase);
            if($request == "getStoppagesLog")
                sendResponseToClient("success", $stoppagesLogTable);
            else{
                $Object = new DateTime();
                $currentDate = $Object->format("d-m-Y");
                $fileName = $currentDate . "_Problem_Logs_records.csv";
                $dataNames = array(
                    "jobId",
                    "customerId",
                    "stoppageReasonName",
                    "stationId",
                    "startTime",
                    "startDate",
                    "endTime",
                    "endDate",
                    "duration",
                    "status"
                );
                $columnNames = array(
                    "Job ID",
                    "Customer Name",
                    "Problem Name",
                    "Location",
                    "Start Time",
                    "Start Date",
                    "End Time",
                    "End Date",
                    "Duration",
                    "Status"
                );
                sendCsvToClient($stoppagesLogTable, $dataNames, $columnNames, $fileName);
            }
            break;
        case "addStoppageReason":
            $stoppageReason = $_GET["stoppageReason"];

            if(checkStoppageExists($dbConn, $stoppageReason))
            {
                $stoppageReasonId = addStoppageReason($dbConn, $stoppageReason);
			    sendResponseToClient("success");
            }
            else
            {
                sendResponseToClient("error","Problem already exists");
            }
			
			            
            break;
            
        case "getStoppageReasonTableData":
            // get an array of data to send to the client.
            $tableOrdering = $_GET["tableOrdering"];
            
            if($tableOrdering == "byAlphabetic")
                $dataArray = getStoppageReasonTableData($dbConn, true);
            else
                $dataArray = getStoppageReasonTableData($dbConn, false);
                        
            sendResponseToClient("success",$dataArray);
            
            break;
            
        case "deleteStoppageReason":
            $stoppageReasonId = $_GET["stoppageReasonId"];
            deleteStoppageReason($dbConn, $stoppageReasonId);
            sendResponseToClient("success");
            break;

		case "getProductsList":
			$productsArray = getProductsList($dbConn);
            sendResponseToClient("success",$productsArray); 
			break;

        case "getStoppageReasonId":
            $stoppageReason = $_GET["stoppageReason"]; 
            $stoppageReasonId = getIdsfortheStoppageReasonName($dbConn, $stoppageReason);
            sendResponseToClient("success",$stoppageReasonId);
            break;
    }
}

main();

?>