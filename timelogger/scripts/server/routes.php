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

$Debug = true;

function getInitialRoutes($DbConn)
{
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
	
	return $routes;
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
		case "getInitialRoutes":
			$resultsArray = getInitialRoutes($dbConn);
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
