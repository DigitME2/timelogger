<?php
// Note that the database conenction is implicitly released when this script 
// terminates
require "db_params.php";
require "common.php";

$Debug = false;

function getClockedOnUsers($DbConn)
{
    $query = "SELECT ref, jobId, userName, stationId, clockOnTime FROM timeLog LEFT JOIN users ON timeLog.userId = users.userId WHERE clockOffTime IS NULL ORDER BY timeLog.clockOnTime ASC";
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
		
		if(!($statement->bind_result($result, $timelogref)))
		    errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
		
		$statement->fetch();
	}
	else
		$result = "Already Clocked Off";
    
    return $result;
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

		case "clockOffUser":
			printDebug("Clocking off User");
			$ref = $_GET["ref"];
            $result = clockOffUser($dbConn, $ref);
			if ($result == "clockedOff")
            	sendResponseToClient("success", $result);
			else
				sendResponseToClient("error", $result);
            break;
    }
}

main();

?>
