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

// Note that the database conenction is implicitly released when this script 
// terminates
require "db_params.php";
require "common.php";

$Debug = false;

function addStoppageReason($DbConn, $stoppageReason)
{	
	global $stoppageReasonIDCodePrefix;

    $query = "SELECT stoppageReasonIdIndex FROM stoppageReasons ORDER BY stoppageReasonIdIndex DESC LIMIT 1";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    $res = $statement->get_result();
    if($res->num_rows == 0)
        $newStoppageReasonIdNum = 1;
    else
    {
        $row = $res->fetch_row();
        $newStoppageReasonIdNum = intval($row[0]) + 1;
    }    
    $newStoppageReasonId = sprintf("%s%04d", $stoppageReasonIDCodePrefix, $newStoppageReasonIdNum);

    printDebug("Adding new Stoppage Reason $stoppageReason");

    $query = "SELECT COUNT(stoppageReasonName) FROM stoppagereasons WHERE stoppagereasons.stoppageReasonName=?";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $stoppageReason)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    $res = $statement->get_result();
    $row = $res->fetch_row();
    if($row[0] != 0)
    {
        printDebug("Error: Stoppage Reason Name already exists");
        return false;
    }

    $query = "INSERT INTO stoppageReasons (stoppageReasonId, stoppageReasonName, stoppageReasonIdIndex) VALUES (?, ?, ?)";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('ssi', $newStoppageReasonId, $stoppageReason, $newStoppageReasonIdNum)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    return $newStoppageReasonId;
    
}

function getStoppageReasonTableData($DbConn, $OrderByName){
    // returns an array of stoppages data, ordered either name or by order
    // added, newest first.
    
    if($OrderByName == true)
        $query = "SELECT stoppageReasonId, stoppageReasonName FROM stoppageReasons ORDER BY stoppageReasonName ASC";
    else
        $query = "SELECT stoppageReasonId, stoppageReasonName FROM stoppageReasons ORDER BY stoppageReasonId DESC";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    $res = $statement->get_result();
    
    $tableData = array();
    
    for($i = 0; $i < $res->num_rows; $i++)
    {
        $row = $res->fetch_assoc();
        $dataRow = array(
            "stoppageReasonId"        =>$row["stoppageReasonId"],
            "stoppageReasonName"      =>$row["stoppageReasonName"]
        );
        array_push($tableData, $dataRow);
    }
    
    return $tableData;
}

function deleteStoppageReason($DbConn, $StoppageReasonId)
{
    // get the abs path to the relevant QR code first, delete the QR code, 
    // then remove the Stoppage Reason from the database.
    
    // $query = "SELECT absolutePathToQrCode FROM stoppageReasons WHERE stoppageReasonId=?";
    
    // if(!($statement = $DbConn->prepare($query)))
    //     errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    // if(!($statement->bind_param('s', $StoppageReasonId)))
    //     errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    // if(!$statement->execute())
    //     errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    // $res = $statement->get_result();
    // $row = $res->fetch_row();
    
    // $qrCodePath = $row[0];
    
    // if($qrCodePath != null)
    //     exec("rm $qrCodePath");
    
	
    $query = "DELETE FROM stoppageReasons WHERE stoppageReasonId=?";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $StoppageReasonId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
	
	//remove entries from log
	$query = "DELETE FROM stoppagesLog WHERE stoppageReasonId=?";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $StoppageReasonId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
}


// generate a QR code, log the path to the database, and return said path for download
// function generateStoppageReasonQrCode($DbConn, $StoppageReasonId)
// {
//     global $StoppageReasonQrCodeDirAbs;
//     global $StoppageReasonQrCodeDirRelativeToPage;
        
//     $webPath = $StoppageReasonQrCodeDirRelativeToPage . $StoppageReasonId . ".png";
//     $actualpath = $StoppageReasonQrCodeDirAbs . $StoppageReasonId . ".png";

//     generateQrCode($StoppageReasonId, $actualpath);
//     printDebug("Generated QR code at $actualpath");
    
//     $query = "UPDATE stoppageReasons SET relativePathToQrCode=?, absolutePathToQrCode=? WHERE stoppageReasonId=?";
    
//     if(!($statement = $DbConn->prepare($query)))
//         errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
//     if(!($statement->bind_param('sss', $webPath, $actualpath, $StoppageReasonId)))
//         errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
//     if(!$statement->execute())
//         errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
//     return $webPath;
// }

function getIdsfortheStoppageReasonName($DbConn, $stoppageReason)
{
    $query = "SELECT stoppageReasonId FROM stoppagereasons WHERE stoppageReasonName = ? ";

    if(!($statement = $DbConn->prepare($query)))
            errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
        if(!($statement->bind_param('s', $stoppageReason)))
            errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
        if(!$statement->execute())
            errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
		
	    $res = $statement->get_result();
	    $row = $res->fetch_assoc();
        $stoppageReasonId = $row["stoppageReasonId"];
        return $stoppageReasonId;
}

function getProductsList($DbConn)
{
	// fetch current list of ProductIds
    $query = "SELECT productId FROM products ORDER BY productId ASC";
    
	if(!($queryResult = $DbConn->query($query)))
            errorHandler("Error executing query: ($DbConn->errno) $DbConn->error, line " . __LINE__);
	
	$products = array();
    for($i = 0; $i < $queryResult->num_rows; $i++)
    {
        $row = $queryResult->fetch_row();
        array_push($products,$row[0]);
    }
	
	return $products;
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
        case "addStoppageReason":
            $stoppageReason = $_GET["stoppageReason"];

            if(addStoppageReason($dbConn, $stoppageReason))
            {
                $stoppageReasonId = addStoppageReason($dbConn, $stoppageReason);
			    sendResponseToClient("success");
            }
            else
            {
                sendResponseToClient("error","Problem already exists");
            }
			
			            
            break;

            
        // case "getQrCode":
        //     $stoppageReasonId = $_GET["stoppageReasonId"];

		// 	$downloadPath = generatestoppageReasonQrCode($dbConn, $stoppageReasonId);
        //     sendResponseToClient("success",$downloadPath);
        //     break;
            
        case "getStoppageReasonTableData":
            // get an array of data to send to the client.
            $tableOrdering = $_GET["tableOrdering"];
            
            if($tableOrdering == "byAlphabetic")
                $dataArray = getStoppageReasonTableData($dbConn, true);
            else
                $dataArray = getStoppageReasonTableData($dbConn, false);
                        
            sendResponseToClient("success",$dataArray);
            
            break;
            
        case "deleteStoppageReason":
            $stoppageReasonId = $_GET["stoppageReasonId"];
            deleteStoppageReason($dbConn, $stoppageReasonId);
            sendResponseToClient("success");
            break;

		case "getProductsList":
			$productsArray = getProductsList($dbConn);
            sendResponseToClient("success",$productsArray); 
			break;

        case "getStoppageReasonId":
            $stoppageReason = $_GET["stoppageReason"]; 
            $stoppageReasonId = getIdsfortheStoppageReasonName($dbConn, $stoppageReason);
            sendResponseToClient("success",$stoppageReasonId);
            break;
    }
}

main();

?>