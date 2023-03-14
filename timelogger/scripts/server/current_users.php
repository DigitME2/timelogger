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

$Debug = false;

function getClockedOnUsers($DbConn)
{
    $query = "SELECT ref, jobId, userName, stationId, clockOnTime FROM timeLog LEFT JOIN users ON timeLog.userId = users.userId WHERE clockOffTime IS NULL AND userName IS NOT NULL AND stationId IS NOT NULL ORDER BY timeLog.clockOnTime ASC";
    if(!($getUsersRes = $DbConn->query($query)))
            errorHandler("Error executing query: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    $userList = array();
    for($i = 0; $i < $getUsersRes->num_rows; $i++)
    {
        $row = $getUsersRes->fetch_assoc();

		$productId = getProductID($DbConn, $row["jobId"]);
        
        $userLog = array(
			"ref" => $row["ref"],
            "jobId" => $row["jobId"],
			"productId" => $productId,
            "userName" => $row["userName"],
			"stationId" => $row["stationId"],
			"clockOnTime" => $row["clockOnTime"]
        );
        
        array_push($userList, $userLog);
    }
    
    return $userList;
    
}

function getProductID($DbConn, $jobId)
{
	//check if new jobID is alread in use
	$query = "SELECT productId FROM jobs WHERE jobId=?";
    
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

function clockOffUser($DbConn, $ref)
{
	$query = "SELECT jobId, userId, stationId, clockOffTime FROM timeLog WHERE ref=? LIMIT 1;";    

	if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $ref)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    $res = $statement->get_result();

	$row = $res->fetch_assoc();

	$jobId = $row["jobId"];
	$userId = $row["userId"];
	$stationId = $row["stationId"];
	$jobStatus = "unknown";

	$clockOffTime = $row["clockOffTime"];

	if ($clockOffTime == NULL)
	{
		// call the stored procedure, putting the result into a session-local variable
		$query = "CALL ClockUser(?, ?, ?, ?)";
		
		if(!($statement = $DbConn->prepare($query)))
		    errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
		
		if(!($statement->bind_param('ssss', $jobId, $userId, $stationId, $jobStatus)))
		    errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
		
		if(!$statement->execute())
		    errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
            
		if(!($statement->bind_result($userState, $logRef, $workState, $routeName, $routeStageIndex)))
		    errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);

		$statement->fetch();
        
        $result = $userState;
        kafkaOutputClockUser($userId, $userState, $jobId, $stationId, $jobStatus, $logRef);
	}
	else
		$result = "Already Clocked Off";
    
    return $result;
}

function getClockedOffUsersList($DbConn){ 

    $query = "CALL getClockedOffUsers()";
    if(!($getUsersList = $DbConn->query($query)))
            errorHandler("Error executing query: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    $clockOffuserList = array();
    for($i = 0; $i < $getUsersList->num_rows; $i++)
    {
        $row = $getUsersList->fetch_assoc();
        
        $clockedOffUserList = array(
			"userName" => $row["userName"],
            "jobId" => $row["jobId"],
            "stationId" => $row["stationId"],
            "clockOffTime" => $row["clockOffTime"],
            "recordDate" => $row["recordDate"]
        );
        
        array_push($clockOffuserList, $clockedOffUserList);
    }

    return $clockOffuserList;
}

function GetUserStatus($DbConn, $userId) 
{

    $query = "SELECT jobId, stationId FROM `timeLog` WHERE clockOffTime IS NULL AND userId=?;";
    $statement =  $DbConn->prepare($query);
    $statement->bind_param('s', $userId);
    $statement->execute();
    $res = $statement->get_result();
    if ($res->num_rows == 0)
        $response = array("status"=>"clockedOff");
    else
    {
        $row = $res->fetch_assoc();
        $jobId = $row["jobId"];
        $productId = getProductID($DbConn, $row["jobId"]);
        $stationId = $row["stationId"];
        $response = array(
            "status"=>"clockedOn",
            "jobId"=>$jobId,
            "productId"=>$productId,
            "stationId"=>$stationId
        );
    }
    return $response;
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
        case "getClockedOnUsers":
            printDebug("Fetching clocked on users");
            $clockOnUserData = getClockedOnUsers($dbConn);
            sendResponseToClient("success", $clockOnUserData);
            break;

        case "getClockedOffUsersList":
            printDebug("Fetching clocked off users");
            $clockOffUserData = getClockedOffUsersList($dbConn);
            sendResponseToClient("success", $clockOffUserData);
            break;

		case "clockOffUser":
			printDebug("Clocking off User");
			$ref = $_GET["ref"];
            $result = clockOffUser($dbConn, $ref);
			if ($result == "clockedOff")
            	sendResponseToClient("success", $result);
			else
				sendResponseToClient("error", $result);
            break;
        case "GetUserStatus":
            printDebug("Getting the user status..");
            $userId = $_GET["userId"];
            $response = GetUserStatus($dbConn, $userId);
            if ($response == "clockedOff" || "clockedOn")
                sendResponseToClient("success", $response);
            break;
    }
}

main();

?>
