<?php

require "db_params.php";
require "common.php";

$Debug = false;

function setDefaultWorkHours($DbConn){
    printDebug("Initialising work hours to defaults");
    
    for($i = 0; $i < 7; $i++)
    {
        $query = "REPLACE INTO workHours (dayDate, startTime, endTime) VALUES (DATE_ADD(CURRENT_DATE, INTERVAL $i DAY), '00:00', '00:00')";
        printDebug("query: $query");
        if(!($DbConn->query($query)))
            errorHandler("Error executing query: ($DbConn->errno) $DbConn->error, line " . __LINE__);
		
		
		$query = "REPLACE INTO lunchTimes (dayDate, startTime, endTime) VALUES (DATE_ADD(CURRENT_DATE, INTERVAL $i DAY), '00:00', '00:00')";
        printDebug("query: $query");
        if(!($DbConn->query($query)))
            errorHandler("Error executing query: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    }
}

function getTimes($DbConn)
{
    printDebug("Fetching times");
    
	// get day start and end times
	
    $query = "SELECT DAYNAME(dayDate), DATE_FORMAT(startTime,'%H:%i'), DATE_FORMAT(endTime,'%H:%i') FROM workHours";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
        
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    
    $workTimesArray = array();
	
    $res = $statement->get_result();
    
    for($i = 0; $i < $res->num_rows; $i++)
    {
        $row = $res->fetch_row();

        $times = array(
            "day" => $row[0],
            "startTime" => $row[1],
            "endTime" => $row[2]
        );

        array_push($workTimesArray, $times);
    }
	
	
	// get lunch times
    $query = "SELECT DAYNAME(dayDate), DATE_FORMAT(startTime,'%H:%i'), DATE_FORMAT(endTime,'%H:%i') FROM lunchTimes";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
        
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    
    $lunchTimesArray = array();
	
    $res = $statement->get_result();
    
    for($i = 0; $i < $res->num_rows; $i++)
    {
        $row = $res->fetch_row();

        $times = array(
            "day" => $row[0],
            "startTime" => $row[1],
            "endTime" => $row[2]
        );

        array_push($lunchTimesArray, $times);
    }
	
	$timesArray = array(
		"workTimes" => $workTimesArray,
		"lunchTimes" => $lunchTimesArray
	);

    return $timesArray;
    
}

// expects an associative array of day names, properly capitalised, startTime, and finishTime
function setTimes($DbConn, $WorkTimes, $LunchTimes)
{
    // TODO: implement server-side validation of times
    // note: assumed that the data alerady exists

    printDebug("Settings times...");
    
    $query = "UPDATE workHours SET startTime = ?, endTime = ? WHERE DAYNAME(dayDate) = ?";

    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);

    
    foreach($WorkTimes as $time)
    {        
        if(!($statement->bind_param('sss', $time["startTime"], $time["endTime"], $time["day"])))
            errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);

        if(!$statement->execute())
            errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    }
	
	
	
	$query = "UPDATE lunchTimes SET startTime = ?, endTime = ? WHERE DAYNAME(dayDate) = ?";

    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);

    
    foreach($LunchTimes as $time)
    {        
        if(!($statement->bind_param('sss', $time["startTime"], $time["endTime"], $time["day"])))
            errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);

        if(!$statement->execute())
            errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    }
}

function getAllowMultipleClockOn($DbConn)
{
	$query = "SELECT paramValue FROM config WHERE paramName = 'allowMultipleClockOn' LIMIT 1";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
        
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
	
	if(!($statement->bind_result($allowMultiClockOn)))
            errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
	
	if(!($statement->fetch()))
		errorHandler("Error fetching data: ($statement->errno) $statement->error, line " . __LINE__);
	
	$statement->close();
	
	if($allowMultiClockOn == "true")
		return true;
	
	return false;
}

function setAllowMultipleClockOn($DbConn, $AllowMultipleClockOn)
{
	if($AllowMultipleClockOn == "true")
		$query = "UPDATE config SET paramValue='true'  WHERE paramName = 'allowMultipleClockOn'";
	else
		$query = "UPDATE config SET paramValue='false'  WHERE paramName = 'allowMultipleClockOn'";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
        
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
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
        case "getSettings":
            $times = getTimes($dbConn);
            
            if(count($times["workTimes"]) != 7)
            {
                // if it turns out that this hasn't been set up
                // initialise the DB and try again
                setDefaultWorkHours($dbConn);
                $times = getTimes($dbConn);
            }
			
			$allowMultiClockOn = getAllowMultipleClockOn($dbConn);
			
			$resultArray = array(
				"times"=>$times,
				"allowMultipleClockOn"=>$allowMultiClockOn
			);
            
            sendResponseToClient("success",$resultArray);            
            break;
            
        case "saveSettings":
            $workTimes = json_decode($_GET["workTimes"], true);
			$lunchTimes = json_decode($_GET["lunchTimes"], true);
            setTimes($dbConn, $workTimes, $lunchTimes);
			
			$allowMultiClockOn = $_GET["allowMultipleClockOn"];
			setAllowMultipleClockOn($dbConn, $allowMultiClockOn);
			
            sendResponseToClient("success");
            break;
			
		default:
			sendResponseToClient("error", "unknown command: $request");
            
    }
}

main();
?>