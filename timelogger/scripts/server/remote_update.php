<?php
require "db_params.php";
require "common.php";

$debug = false;

function getConfigVersion($DbConn)
{
    $query = "SELECT paramValue FROM config WHERE paramName = 'configVersion'";
    if(!($res = $DbConn->query($query)))
            errorHandler("Error executing query: ($DbConn->errno) $DbConn->error, line " . __LINE__);

	$row = $res->fetch_assoc();

	return $row["paramValue"];
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
        case "getConfigVersion":
            printDebug("Fetching config ID");
            $configVersion = getConfigVersion($dbConn);
            sendResponseToClient("success",$configVersion);
            break;
            
        default:
            echo("Unrecognised request: $request");
    }
}

main();
