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

require "db_params.php";
require "common.php";

$debug = false;

function getConnectedClients($DbConn, $includePlaceholderNames = true)
{
	if($includePlaceholderNames)
		$query = "SELECT stationId, lastSeen, version, isApp, nameType FROM connectedClients WHERE TIME_TO_SEC(TIMEDIFF(CURRENT_TIMESTAMP, lastSeen)) < 10 ORDER BY stationId ASC";
	else
		$query = "SELECT stationId, lastSeen, version, isApp FROM connectedClients WHERE TIME_TO_SEC(TIMEDIFF(CURRENT_TIMESTAMP, lastSeen)) < 10 AND nameType='location' ORDER BY stationId ASC";
	
    if(!($queryResult = $DbConn->query($query)))
		errorHandler("Error executing query: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    $clientList = array();
    for($i = 0; $i < $queryResult->num_rows; $i++)
    {
        $row = $queryResult->fetch_assoc();
        if($row['isApp'] == "0")
        	$row['isApp'] = "false";
        else
	        $row['isApp'] = "true";
        
        array_push($clientList,$row);
    }
    
    return $clientList;
}

function startRenameClient($DbConn, $CurrentName, $NewName)
{
	$query = "INSERT INTO clientNames (currentName, newName) VALUES (?,?)";
    if(!($stmt = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
	if(!($stmt->bind_param('ss', $CurrentName, $NewName)))
		errorHandler("Error executing statement: ($stmt->errno) $stmt->error, line " . __LINE__);
		
    if(!($stmt->execute()))
        errorHandler("Error executing statement: ($stmt->errno) $stmt->error, line " . __LINE__);
    
	$stmt->close();
    
}

function getExtraScannerNames($DbConn)
{
	$query = "SELECT name FROM extraScannerNames ORDER BY name ASC";
    if(!($queryResult = $DbConn->query($query)))
            errorHandler("Error executing query: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    $names = array();
    if($queryResult->num_rows > 0)
    {
		for($i = 0; $i < $queryResult->num_rows; $i++)
		{
		    $row = $queryResult->fetch_assoc();
		    
		    array_push($names,$row["name"]);
		}
	}
    
    return $names;
}

function getExtraScannersTable($DbConn)
{
	$query = "SELECT name FROM extraScannerNames ORDER BY name ASC";
	if(!($queryResult = $DbConn->query($query)))
		errorHandler("Error executing query: ($DbConn->errno) $DbConn->error, line " . __LINE__);

	$scannerNames = array();
	if($queryResult->num_rows > 0)
    {
		for($i = 0; $i < $queryResult->num_rows; $i++)
		{
		    $row = $queryResult->fetch_assoc();
			$dataRow = array("scannerName"  =>$row["name"]);
			array_push($scannerNames, $dataRow);
		}
	}
    
	return $scannerNames;
}

function getAllScannerNames($DbConn)
{
	$connectedClients = getConnectedClients($DbConn, false);
	$extraNames = getExtraScannerNames($DbConn);
	
	$allNames = array();
	
	for($i = 0; $i < count($connectedClients); $i++)
	{
		array_push($allNames, $connectedClients[$i]["stationId"]);
	}
	
	if((count($allNames) > 0) or (count($extraNames) > 0))
	{
		$allNames = array_merge($allNames,$extraNames);
		$allNames = array_unique($allNames);
		sort($allNames);
	}
	return $allNames;
}

function checkExtraScannerNamesExists($DbConn, $newName) 
{

	$query = "SELECT COUNT(name) FROM extraScannerNames WHERE extraScannerNames.name = ?";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $newName)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    $res = $statement->get_result();
    $row = $res->fetch_row();
    if($row[0] != 0)
    {
        printDebug("Error: Location Name already exists");
        return false;
    }
	else 
	{
		return true;
	}

}
function addNewExtraName($DbConn, $newName)
{
	printDebug("Adding new Scanner Location $newName");

	$query = "INSERT INTO extraScannerNames (name) VALUES (?)";
    if(!($stmt = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
	if(!($stmt->bind_param('s', $newName)))
		errorHandler("Error executing statement: ($stmt->errno) $stmt->error, line " . __LINE__);
		
    if(!($stmt->execute()))
        errorHandler("Error executing statement: ($stmt->errno) $stmt->error, line " . __LINE__);
    
	$stmt->close();
}

function deleteExtraScannerName($DbConn, $nameToDelete)
{
	$query = "DELETE FROM extraScannerNames WHERE name = ?";
    if(!($stmt = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
	if(!($stmt->bind_param('s', $nameToDelete)))
		errorHandler("Error executing statement: ($stmt->errno) $stmt->error, line " . __LINE__);
		
    if(!($stmt->execute()))
        errorHandler("Error executing statement: ($stmt->errno) $stmt->error, line " . __LINE__);
    
	$stmt->close();
}

function main()
{
    global $debug;
        
    global $dbParamsServerName;
    global $dbParamsUserName;
    global $dbParamsPassword;
    global $dbParamsDbName;
    
    $dbConn = initDbConn($dbParamsServerName, $dbParamsUserName, $dbParamsPassword, $dbParamsDbName);
    $dbConn->autocommit(TRUE);

    $request = $_GET["request"];
   
    switch($request)
    {
        case "getConnectedClients":
            printDebug("FetchingConnectedClients");
            $connectedClientData = getConnectedClients($dbConn);
            sendResponseToClient("success",$connectedClientData);
            break;
            
        case "getExtraScannerNames":
        	printDebug("Fetching extra scanner names");
        	$extraScannerNames = getExtraScannerNames($dbConn);
        	sendResponseToClient("success",$extraScannerNames);
        	break;
		
		case "getExtraScannersTable":
			printDebug("Fetching extra scanner names");
			$extraScannersTable = getExtraScannersTable($dbConn);
			sendResponseToClient("success",$extraScannersTable);
			break;
        	
        case "getAllScannerNames":
        	printDebug("Fetching all scanner names");
			$allNames = getAllScannerNames($dbConn);        	
        	sendResponseToClient("success",$allNames);
        	break;
        	
        case "addExtraScannerName":
        	printDebug("Adding new extra scanner name");
        	$newName = $_GET["newName"];
			if(checkExtraScannerNamesExists($dbConn, $newName))
			{
				addNewExtraName($dbConn, $newName);
				sendResponseToClient("success");
			}
			else{
				sendResponseToClient("Error", "Scanner Location Name Already Exists!");
			}
        	break;
        	
        case "deleteExtraScannerName":
        	printDebug("Deleting extra scanner name");
        	$nameToDelete = $_GET["name"];
        	deleteExtraScannerName($dbConn, $nameToDelete);
        	sendResponseToClient("success");        	
        	break;
        	
			
		case "startRenameClient":
			printDebug("Recording new name for scanner client");
			$currentName = $_GET["currentName"];
			$newName = $_GET["newName"];
			startRenameClient($dbConn, $currentName, $newName);
			sendResponseToClient("success");
			break;
            
        default:
            sendResponseToClient("error","Unknown command: $request");
    }
}

main();

?>
