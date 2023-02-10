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
