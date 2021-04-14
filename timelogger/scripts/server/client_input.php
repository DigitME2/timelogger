<?php
// Accepts a POST request from a client station. This is expected to include
// 
// Note that the database conenction is implicitly released when this script 
// terminates
require "db_params.php";
require "common.php";

$debug =false;

// Calls a stored procedure in the database to clock the user on or off.
// Whether the user is clocked on or off is determined automatically,
// based on if they already have an open record for this job and station.
function clockUser($DbConn, $UserId, $JobId, $StationId, $JobStatus)
{
	global $productIDCodePrefix;

	//check if the code is a product
	$codePrefixLength = strlen($productIDCodePrefix);
	$productCheck =  substr($JobId, 0, $codePrefixLength);

	if($productCheck == $productIDCodePrefix)
	{
		//if code is a product- remove prefix to get productID then fetch the relevent jobId
		$productId = substr($JobId, $codePrefixLength);
		
		$query = "SELECT currentJobId FROM products WHERE products.productId = ?";
    
		if(!($statement = $DbConn->prepare($query)))
			errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);

		if(!($statement->bind_param('s', $productId)))
			errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);

		if(!$statement->execute())
			errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
			
		$res = $statement->get_result();
		$row = $res->fetch_assoc();

		if($row["currentJobId"] != null)
			$JobId = $row["currentJobId"];
		else
			return 'No Job';

	}

    // call the stored procedure, putting the result into a session-local variable
    $query = "CALL ClockUser(?, ?, ?, ?)";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('ssss', $JobId, $UserId, $StationId, $JobStatus)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    $res = $statement->get_result();
	$row = $res->fetch_assoc();
    
	if(array_key_exists("logRef", $row))
		$return = array("state"=>$row["result"], "logRef"=>$row["logRef"]);
	else
		$return = array("state"=>$row["result"]);

    return $return;
}

// Calls a stored procedure in the database to Record a stoppage.
function recordStoppage($DbConn, $StoppageReasonId, $JobId, $StationId, $JobStatus, $description)
{
	global $productIDCodePrefix;

	//check if the code is a product
	$codePrefixLength = strlen($productIDCodePrefix);
	$productCheck =  substr($JobId, 0, $codePrefixLength);

	if($productCheck == $productIDCodePrefix)
	{
		//if code is a product- remove prefix to get productID then fetch the relevent jobId
		$productId = substr($JobId, $codePrefixLength);
		
		$query = "SELECT currentJobId FROM products WHERE products.productId = ?";
    
		if(!($statement = $DbConn->prepare($query)))
			errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);

		if(!($statement->bind_param('s', $productId)))
			errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);

		if(!$statement->execute())
			errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
			
		$res = $statement->get_result();
		$row = $res->fetch_assoc();

		if($row["currentJobId"] != null)
			$JobId = $row["currentJobId"];
		else
			return 'error';

	}

    // call the stored procedure, putting the result into a session-local variable
    $query = "CALL recordStoppage(?, ?, ?, ?, ?)";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('sssss', $JobId, $StoppageReasonId, $StationId, $description, $JobStatus)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!($statement->bind_result($result)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    $statement->fetch();

    return $result;
}

function updateLastSeen($DbConn, $StationId, $version)
{
	//change to update instead of replace if using with app
    $query = "REPLACE INTO connectedClients (stationId, lastSeen, version) VALUES (?, CURRENT_TIMESTAMP, ?)";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('ss', $StationId, $version)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
}

function checkForNameUpdate($DbConn, $StationId)
{
	$query = "SELECT newName FROM clientNames WHERE currentName = ?";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $StationId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
		
	$res = $statement->get_result();
	$row = $res->fetch_assoc();
	
	if($row["newName"] != null)
		return $row["newName"];
	
	return "noChange";
	
}

function completeNameUpdate($DbConn, $StationId)
{
	$query = "CALL CompleteStationRenaming(?)";
		
	if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $StationId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
}

function recordNumberCompleted($DbConn, $logRef, $numberCompleted)
{

	$query = "UPDATE timeLog SET timeLog.quantityComplete=? WHERE timeLog.ref=?";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('is', $numberCompleted, $logRef)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
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
        case "clockUser":   
            $userId     = $_GET["userId"];
            $jobId      = $_GET["jobId"];
            $stationId  = $_GET["stationId"];
            $jobStatus  = $_GET["jobStatus"];
            $result = clockUser($dbConn, $userId, $jobId, $stationId, $jobStatus);

			if (!is_array($result)){
				sendResponseToClient("error", $result);
			}else if ($result["state"] == "unknownId"){
				sendResponseToClient("error", "Unknown ID");
			}
			else{
            	sendResponseToClient("success", $result);
			}
            break;

		case "recordStoppage":   
		        $userId     = $_GET["stoppageId"];
		        $jobId      = $_GET["jobId"];
		        $stationId  = $_GET["stationId"];
		        $jobStatus  = $_GET["jobStatus"];

				if(isset($_GET["description"]))
					$description = $_GET["description"];
				else
					$description = '';

		        $result = recordStoppage($dbConn, $userId, $jobId, $stationId, $jobStatus, $description);
		        	$unkownIdString = "Unknown";
				if (subtr($result, 0, strlen(unkownIdString)) == unkownIdString){
					sendResponseToClient("error", $result);
				}
				else{
		        	sendResponseToClient("success", $result);
					updateJobStoppages($dbConn, $jobId);
				}				
		        break;
      
        case "heartbeat":
        	
            sendResponseToClient("success");
// 			$stationId = $_GET["stationId"];
// 			$version = $_GET["version"];
//             updateLastSeen($dbConn, $stationId, $version);
            break;
			
		case "checkForNameUpdate":
			$stationId = $_GET["stationId"];
			$response = checkForNameUpdate($dbConn, $stationId);
			sendResponseToClient("success", $response);
            break;
			
		case "completeNameUpdate":
			$stationId = $_GET["stationId"];
			completeNameUpdate($dbConn, $stationId);
			sendResponseToClient("success");
            break;

		case "recordNumberCompleted":			
			$logRef = $_GET["logRef"];
			$numberCompleted = $_GET["numberCompleted"];
			recordNumberCompleted($dbConn, $logRef, $numberCompleted);
			sendResponseToClient("success");
            break;

		case "recordNumberCompleted":
            
        default:
            sendResponseToClient("error","Unknown command: $request");
    }
}

main();

?>
