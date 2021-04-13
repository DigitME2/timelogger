<?php
require "db_params.php";
require "common.php";

$debug = false;

function getConnectedClients($DbConn)
{
    $query = "SELECT stationId, lastSeen FROM connectedClients ORDER BY stationId ASC";
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
	$query = "UPDATE connectedClients SET connectedClients.stationId=? WHERE connectedClients.stationId=?";
	
    if(!($stmt = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
	if(!($stmt->bind_param('ss', $NewName, $CurrentName)))
		errorHandler("Error executing statement: ($stmt->errno) $stmt->error, line " . __LINE__);
		
    if(!($stmt->execute()))
        errorHandler("Error executing statement: ($stmt->errno) $stmt->error, line " . __LINE__);
    
	$stmt->close();
    
}

function createStation($DbConn, $NewName)
{
	$query = "INSERT INTO connectedClients (stationId) VALUES (?)";	
	
    if(!($stmt = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
	if(!($stmt->bind_param('s', $NewName)))
		errorHandler("Error executing statement: ($stmt->errno) $stmt->error, line " . __LINE__);
		
    if(!($stmt->execute()))
        errorHandler("Error executing statement: ($stmt->errno) $stmt->error, line " . __LINE__);
    
	$stmt->close();
}

function deleteStation($DbConn, $CurrentName)
{
	$query = "DELETE FROM connectedClients WHERE connectedClients.stationId=?";	
	
    if(!($stmt = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
	if(!($stmt->bind_param('s', $CurrentName)))
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
			
		case "startRenameClient":
			$currentName = $_GET["currentName"];
			$newName = $_GET["newName"];
			if($currentName == null){
				printDebug("Creating new station");
				createStation($dbConn, $newName);
			}else{
				printDebug("Recording new name for station");
				startRenameClient($dbConn, $currentName, $newName);
			}
			sendResponseToClient("success");
			break;
			
		case "deleteStation":
            $currentName = $_GET["currentName"];
			printDebug("Creating new station");
			deleteStation($dbConn, $currentName);
			sendResponseToClient("success");
			break;
        default:
            sendResponseToClient("error","Unknown command: $request");
    }
}

main();

?>
