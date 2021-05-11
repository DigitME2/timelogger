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
