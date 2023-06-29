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
require_once "kafka.php";


function getJobsList($DbConn)
{
	// fetch current list of ProductIds
    $query = "SELECT jobName, jobId FROM jobs ORDER BY jobName ASC";
    
	if(!($queryResult = $DbConn->query($query)))
            errorHandler("Error executing query: ($DbConn->errno) $DbConn->error, line " . __LINE__);
	
	$jobs = array();
    for($i = 0; $i < $queryResult->num_rows; $i++)
    {
        $row = $queryResult->fetch_assoc();
        $dataRow = array(
            "jobName"      =>$row["jobName"],
            "jobId"        =>$row["jobId"]
        );
        array_push($jobs,$dataRow);
    }
	
	return $jobs;
}

function getJobId($DbConn, $searchPhrase){
    // returns an array of JobId 
    // added, newest first.
    
    
    $searchPhrase = "%".$searchPhrase."%";
    $query = "SELECT jobName, jobId FROM jobs WHERE jobName LIKE ? ORDER BY jobName ASC";

    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);

    if(!($statement->bind_param('s', $searchPhrase)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);

    
    if(!($statement->execute()))
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    $res = $statement->get_result();
    
    $JobsData = array();
    
    for($i = 0; $i < $res->num_rows; $i++)
    {
        $row = $res->fetch_assoc();
        if ($row != ""){
            $dataRow = array(
                "jobName"   =>$row["jobName"],
                "jobId"     =>$row["jobId"]
            );
        }
        else {
           $jobIdNotFound = "Search is invalid";
           $dataRow = array("jobName" => $jobIdNotFound); 
        }
        array_push($JobsData, $dataRow);
    }
    
    return $JobsData;
}

function checkJobExists($DbConn, $searchPhrase){

    $searchPhrase = "%".$searchPhrase."%";
    $query = "SELECT jobName FROM jobs WHERE jobName LIKE ? ORDER BY jobName ASC";

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
        printDebug("Success: job exists");
        return true;
    }
    else
    {
        printDebug("Error: job not exists");
        return false;
    }
}

function transfersWorkLogNewJob($DbConn, $requiredJobId, $timeLogRefs) {

    for($i=0; $i<count($timeLogRefs); $i++){
        $query = "UPDATE timeLog SET jobId = ? WHERE ref IN (?)";
        if(!($statement = $DbConn->prepare($query)))
            errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);

        if(!($statement->bind_param('ss', $requiredJobId, $timeLogRefs[$i])))
            errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);

        if(!($statement->execute()))
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

        $result = "Transfer Successfull";
    }
    return $result;
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
            case "getJobsList":
                $jobsArray = getJobsList($dbConn);
                sendResponseToClient("success",$jobsArray); 
                break;
            case "getJobId":
                $SearchPhrase = $_GET["searchPhrase"];
                if(checkJobExists($dbConn, $SearchPhrase)){
                    $dataArray = getJobId($dbConn, $SearchPhrase);        
                    sendResponseToClient("success",$dataArray);
                }
                else{
                    sendResponseToClient("Error", "Job Not Found!");
                }
                break;
        
            case "getJobName":
                $jobId = $_GET["jobId"];
                $jobName = getJobName($dbConn, $jobId);
                sendResponseToClient("success", $jobName);
                break;
        }
    }
    else if($_SERVER["REQUEST_METHOD"] === "POST")
	{
		if(isset($_REQUEST["request"]))
		{
			$request = $_REQUEST["request"];

			printDebug("Processing request " . $request);
			
			switch($request)
			{
				case "transferWorkLogs":
					printDebug("Processing work log transfer");
					$requiredJobId = "";
                    $timeLogRefs = "";
                    $transferData = $_REQUEST["TransferData"];
                    $decodedData = json_decode($transferData);
                    $requiredJobId = $decodedData->newJobId;
                    $timeLogRefs = $decodedData->timeLog;
                    $result = transfersWorkLogNewJob($dbConn, $requiredJobId, $timeLogRefs);
                    if($result === "Transfer Successfull"){
                        sendResponseToClient("success", $result);
                        printDebug($result);
                    }
                    else{
                        sendResponseToClient("error", $result);
                        printDebug($result);
                    }		
					break;
					
				default:
					sendResponseToClient("error", "Unknown command: $request");
					break;
			}
		}
		else
		{
			sendResponseToClient("error", "No Request.");
		}
	}
}

main();

?>