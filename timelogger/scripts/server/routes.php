<?php

require "db_params.php";
require "common.php";

$Debug = true;

function getInitialData($DbConn)
{
	// fetch current list of clients
	$query = "SELECT stationId FROM connectedClients WHERE TIME_TO_SEC(TIMEDIFF(CURRENT_TIMESTAMP, lastSeen)) < 3600 ORDER BY stationId ASC";
    if(!($queryResult = $DbConn->query($query)))
            errorHandler("Error executing query: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    $stationNames = array();
    for($i = 0; $i < $queryResult->num_rows; $i++)
    {
        $row = $queryResult->fetch_row();
        array_push($stationNames,$row[0]);
    }
	
	// fetch current list of route names
    $query = "SELECT routeName FROM routes ORDER BY routeName ASC";
    
	if(!($queryResult = $DbConn->query($query)))
            errorHandler("Error executing query: ($DbConn->errno) $DbConn->error, line " . __LINE__);
	
	$routes = array();
    for($i = 0; $i < $queryResult->num_rows; $i++)
    {
        $row = $queryResult->fetch_row();
        array_push($routes,$row[0]);
    }
	
	$data = array(
		"stationNames" => $stationNames,
		"routeNames" => $routes
		);
	
	return $data;
}

function getRouteDescription($DbConn, $RouteName)
{
	$query = "SELECT routeDescription FROM routes WHERE routeName=? LIMIT 1";
    if(!($getRouteQuery = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($getRouteQuery->bind_param('s', $RouteName)))
        errorHandler("Error binding parameters: ($getRouteQuery->errno) $RouteQuery->error, line " . __LINE__);
    
    if(!$getRouteQuery->execute())
        errorHandler("Error executing statement: ($getRouteQuery->errno) $getRouteQuery->error, line " . __LINE__);
	
	$res = $getRouteQuery->get_result();

	$row = $res->fetch_row();
    
	return $row[0];
}

function saveRouteDescription($DbConn, $RouteName, $RouteDescription)
{
	$query = "REPLACE INTO routes (routeName, routeDescription) VALUES (?,?)";
    if(!($updateRouteQuery = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($updateRouteQuery->bind_param('ss', $RouteName, $RouteDescription)))
        errorHandler("Error binding parameters: ($updateRouteQuery->errno) $updateRouteQuery->error, line " . __LINE__);
    
    if(!$updateRouteQuery->execute())
        errorHandler("Error executing statement: ($updateRouteQuery->errno) $updateRouteQuery->error, line " . __LINE__);
}

function deleteRoute($DbConn, $RouteName)
{
	$query = "UPDATE jobs SET routeName='', routeCurrentStageName=NULL, routeCurrentStageIndex=-1 WHERE routeName=?";
    if(!($deleteRouteQuery = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($deleteRouteQuery->bind_param('s', $RouteName)))
        errorHandler("Error binding parameters: ($deleteRouteQuery->errno) $deleteRouteQuery->error, line " . __LINE__);
    
    if(!$deleteRouteQuery->execute())
        errorHandler("Error executing statement: ($deleteRouteQuery->errno) $deleteRouteQuery->error, line " . __LINE__);


	$query = "DELETE FROM routes WHERE routeName=?";
    if(!($deleteRouteQuery = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($deleteRouteQuery->bind_param('s', $RouteName)))
        errorHandler("Error binding parameters: ($deleteRouteQuery->errno) $deleteRouteQuery->error, line " . __LINE__);
    
    if(!$deleteRouteQuery->execute())
        errorHandler("Error executing statement: ($deleteRouteQuery->errno) $deleteRouteQuery->error, line " . __LINE__);
}

function doesRouteExist($DbConn, $RouteName)
{
	$query = "SELECT COUNT(routeName) FROM routes WHERE routeName=? LIMIT 1";
    if(!($getRouteQuery = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($getRouteQuery->bind_param('s', $RouteName)))
        errorHandler("Error binding parameters: ($getRouteQuery->errno) $RouteQuery->error, line " . __LINE__);
    
    if(!$getRouteQuery->execute())
        errorHandler("Error executing statement: ($getRouteQuery->errno) $getRouteQuery->error, line " . __LINE__);
	
	$res = $getRouteQuery->get_result();

	$row = $res->fetch_row();
    
	if($row[0] == "0")
		return false;
	return true;
}

function main()
{
    global $dbParamsServerName;
    global $dbParamsUserName;
    global $dbParamsPassword;
    global $dbParamsDbName;
    
    $dbConn = initDbConn(
        $dbParamsServerName,
        $dbParamsUserName,
        $dbParamsPassword,
        $dbParamsDbName
    );
    
    $request = $_GET["request"];
    
    switch($request)
    {
		// fetch the initialisation data for the routes page.
		// feches a list of active stations and a list of route
		// names, both organised alphabetically.
		case "getInitialData":
			$resultsArray = getInitialData($dbConn);
            sendResponseToClient("success",$resultsArray);            
            break;
            
		// Get the description for an existing route
        case "getRoute":
			$routeName = $_GET["routeName"];
			$routeDescription = getRouteDescription($dbConn, $routeName);
            sendResponseToClient("success", $routeDescription);
            break;
			
		// Save a route to the database. Will overwrite any
		// existing route of the same name.
		case "saveRoute":
			$routeName = $_GET["routeName"];
			$routeDescription = $_GET["routeDescription"];
			saveRouteDescription($dbConn, $routeName, $routeDescription);
			sendResponseToClient("success");
            break;
			
		// Delete a route from the database
		case "deleteRoute":
			$routeName = $_GET["routeName"];
			deleteRoute($dbConn, $routeName);
			sendResponseToClient("success");
            break;
						
		// check if a route exists
		case "doesRouteExist":
			$routeName = $_GET["routeName"];
			if(doesRouteExist($dbConn, $routeName))
				sendResponseToClient("success","true");
			else
				sendResponseToClient("success","false");
            break;
			
			
		default:
			sendResponseToClient("error", "unknown command: $request");
            
    }
}

main();
?>
