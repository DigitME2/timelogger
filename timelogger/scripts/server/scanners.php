<?php
require "db_params.php";
require "common.php";

$debug = false;

function getConnectedClients($DbConn)
{
    $query = "SELECT stationId, lastSeen, version FROM connectedClients WHERE TIME_TO_SEC(TIMEDIFF(CURRENT_TIMESTAMP, lastSeen)) < 60 ORDER BY stationId ASC";
    if(!($queryResult = $DbConn->query($query)))
            errorHandler("Error executing query: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    $clientList = array();
    for($i = 0; $i < $queryResult->num_rows; $i++)
    {
        $row = $queryResult->fetch_assoc();
        
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
    for($i = 0; $i < $queryResult->num_rows; $i++)
    {
        $row = $queryResult->fetch_assoc();
        
        array_push($names,$row[0]);
    }
    
    return $names;
}

function getAllScannerNames($DbConn)
{
	$connectedClients = getConnectedClients($DbConn);
	$extraNames = getExtraScannerNames($DbConn);
	
	$allNames = array();
	
	for($i = 0; $i < count($connectedClients); $i++)
	{
		array_push($allNames, $connectedClients[0]);
	}
	
	$allNames = sort(array_unique(array_merge($allNames,$extraNames);
}

function addNewExtraName($DbConn, $newName)
{
	$query = "INSERT INTO extraScannerNames (name) VALUES (?)";
    if(!($stmt = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
	if(!($stmt->bind_param('s', $NewName)))
		errorHandler("Error executing statement: ($stmt->errno) $stmt->error, line " . __LINE__);
		
    if(!($stmt->execute()))
        errorHandler("Error executing statement: ($stmt->errno) $stmt->error, line " . __LINE__);
    
	$stmt->close();
}

function deleteExtraScannerName($dbConn, $nameToDelete)
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
        	
        case "getAllScannerNames":
        	printDebug("Fetching all scanner names");
			$allNames = getAllScannerNames($dbConn);        	
        	sendResponseToClient("success",$allNames);
        	
        case "addExtraScannerName":
        	printDebug("Adding new extra scanner name");
        	$newName = $_GET["newName"];
        	addNewExtraName($dbConn, $newName);
        	sendResponseToClient("success");
        	
        case "deleteExtraScannerName":
        	printDebug("Deleting extra scanner name");
        	$nameToDelete = $_GET["name"];
        	deleteExtraScannerName($dbConn, $nameToDelete);
        	sendResponseToClient("success");        	
        	
			
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
