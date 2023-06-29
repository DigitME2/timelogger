<?php

//  Copyright 2023 DigitME2

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
require_once "db_params.php";
require_once "common.php";
require_once "kafka.php";

$Debug = false;

function getLocationNames($DbConn)
{
    $query = "SELECT `name` FROM extraScannerNames ORDER BY `name` ASC";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    $res = $statement->get_result();
    $names = array();
    for($i = 0; $i < $res->num_rows; $i++)
    {
        $row = $res->fetch_row();
        array_push($names, $row[0]);
    }

	return $names;
}

function getUserNames($DbConn, $SearchTerm)
{
    $SearchTerm = "%".$SearchTerm."%";
    $query = "SELECT userId, userName FROM users WHERE LOWER(userName) LIKE LOWER(?) AND userId != 'noName' AND userId != 'user_Delt' AND userId != 'office' ORDER BY userName ASC";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $SearchTerm)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    $res = $statement->get_result();
    $names = array();
    for($i = 0; $i < $res->num_rows; $i++)
    {
        $row = $res->fetch_row();
        array_push($names, array("userId" => $row[0], "userName" => $row[1]));
    }

	return $names;
}

function getJobNames($DbConn, $SearchTerm)
{
    // uncomment the two commented lines below and remove the ones above them to use job names
    $SearchTerm = "%".$SearchTerm."%";
    // $query = "SELECT jobId FROM jobs WHERE LOWER(jobId) LIKE LOWER(?) ORDER BY jobId ASC";
    $query = "SELECT jobId, jobName FROM jobs WHERE LOWER(jobName) LIKE LOWER(?) ORDER BY jobName ASC";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $SearchTerm)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    $res = $statement->get_result();
    $names = array();
    for($i = 0; $i < $res->num_rows; $i++)
    {
        $row = $res->fetch_row();
        // array_push($names, array("jobId" => $row[0], "jobName" => $row[0]));
        array_push($names, array("jobId" => $row[0], "jobName" => $row[1]));
    }

	return $names;
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
        case "getLocationNames":
            $locationNames = getLocationNames($dbConn);
            sendResponseToClient("success", $locationNames);
            break;

        case "getUserNames":
            $searchTerm = "";
            if(array_key_exists("searchTerm", $_GET))
                $searchTerm = $_GET["searchTerm"];
            $userNames = getUserNames($dbConn, $searchTerm);
            sendResponseToClient("success", $userNames);
            break;

        case "getJobNames":
            $searchTerm = "";
            if(array_key_exists("searchTerm", $_GET))
                $searchTerm = $_GET["searchTerm"];
            $jobNames = getJobNames($dbConn, $searchTerm);
            sendResponseToClient("success", $jobNames);
            break;
    }
}

main();

?>
