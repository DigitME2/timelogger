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
require_once "paths.php";
require_once "kafka.php";

$Debug = false;


function checkUserExists($DbConn, $UserName) 
{
    $query = "SELECT COUNT(UserName) FROM users WHERE users.userName=?";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $UserName)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    $res = $statement->get_result();
    $row = $res->fetch_row();
    if($row[0] != 0)
    {
        printDebug("Error: User Name already exists");
        return false;
    }
    else
    {
        return true;
    }
}
function addUser($DbConn, $UserName)
{
    
	global $userIDPrefix;

    
    $query = "SELECT userIdIndex FROM users ORDER BY userIdIndex DESC LIMIT 1";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    $res = $statement->get_result();
    $row = $res->fetch_row();
    $newUserIdNum = intval($row[0]) + 1;
	$newUserId = sprintf("%s%04d", $userIDPrefix, $newUserIdNum);

    printDebug("Adding new user $UserName");

    $query = "INSERT INTO users (userId, userName, userIdIndex) VALUES (?, ?, ?)";

    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('ssi', $newUserId, $UserName, $newUserIdNum)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    kafkaOutputCreateUser($newUserId, $UserName);
    return $newUserId;    
}

function getUserTabledata($DbConn, $OrderByName){
    // returns an array of user data, ordered either userName or by order
    // added, newest first.
    
    if($OrderByName == true)
        $query = "SELECT userId, userName FROM users WHERE userId != 'office' and userId != 'noName' and userId != 'user_Delt' ORDER BY userName ASC";
    else
        $query = "SELECT userId, userName FROM users WHERE userId != 'office' and userId != 'noName' and userId != 'user_Delt' ORDER BY recordAdded DESC";
    
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
            "userId"        =>$row["userId"],
            "userName"      =>$row["userName"]
        );
        array_push($tableData, $dataRow);
    }
    
    return $tableData;
}

function deleteUser($DbConn, $UserId)
{
    $query = "DELETE FROM users WHERE userId=?";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $UserId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

	//Update user entries in time log so that user is replaced with default deleleted user 'user_delt'
	$query = "UPDATE timeLog SET userId='user_Delt' WHERE userId=?;";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $UserId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

    kafkaOutputDeleteUser($UserId);
}

function userTableInitialised($DbConn)
{
    $query = "SELECT COUNT(*) FROM users";
    if(!($countResult = $DbConn->query($query)))
            errorHandler("Error executing query: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    $row = $countResult->fetch_array();
    
    if($row[0] > 0)
        return true;
    else
        return false;
}

function initUserTable($DbConn)
{
    $query = "INSERT INTO users (userId, userName,userIdIndex) VALUES ('user_Delt', 'User Deleted', -2)";
    if(!($countResult = $DbConn->query($query)))
            errorHandler("Error executing query: ($DbConn->errno) $DbConn->error, line " . __LINE__);
            
    $query = "INSERT INTO users (userId, userName,userIdIndex) VALUES ('office', 'Office', -1)";
    if(!($countResult = $DbConn->query($query)))
            errorHandler("Error executing query: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    $query = "INSERT INTO users (userId, userName,userIdIndex) VALUES ('noName', 'N/A', 0)";
    if(!($countResult = $DbConn->query($query)))
            errorHandler("Error executing query: ($DbConn->errno) $DbConn->error, line " . __LINE__);
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
        case "addUser":
            $userName = $_GET["userName"];
            if(checkUserExists($dbConn, $userName))
            {
                $userId = addUser($dbConn, $userName);
			    sendResponseToClient("success",$userId);
            }
            else
            {
                sendResponseToClient("error","User already exists");
            }
            break;
            
        case "getUserTableData":
            // get an array of data to send to the client.
            $tableOrdering = $_GET["tableOrdering"];
            
            if(!userTableInitialised($dbConn))
                initUserTable($dbConn);
            
            if($tableOrdering == "byAlphabetic")
                $dataArray = getUserTabledata($dbConn, true);
            else
                $dataArray = getUserTabledata($dbConn, false);
                        
            sendResponseToClient("success",$dataArray);
            
            break;
            
        case "deleteUser":
            $userId = $_GET["userId"];
            deleteUser($dbConn, $userId);
            sendResponseToClient("success");
            break;
    }
}

main();

?>
