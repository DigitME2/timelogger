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
require_once "paths.php";
require_once "kafka.php";

$Debug = false;

function addProduct($DbConn, $ProductID)
{
    printDebug("Adding new product $ProductID");

	$query = "SELECT COUNT(*) FROM products WHERE productId=?";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $ProductID)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    $res = $statement->get_result();
    $row = $res->fetch_row();
    if($row[0] != 0)
    {
        printDebug("Error: products ID already exists");
        return false;
    }
    
    $query = "INSERT INTO products (productId) VALUES (?)";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $ProductID)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

    kafkaOutputAddProductType($ProductID);
    
    return $ProductID;
}

function getProductTabledata($DbConn, $searchPhrase){
    // returns an array of user data, ordered either userName or by order
    // added, newest first.
    
    if($searchPhrase == "")
	{
        $query = "SELECT productId, currentJobId FROM products ORDER BY productId ASC";

		if(!($statement = $DbConn->prepare($query)))
        	errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
	}
    else
	{
		$searchPhrase = "%".$searchPhrase."%";
        $query = "SELECT productId, currentJobId FROM products WHERE productId LIKE ? OR currentJobId LIKE ? ORDER BY productId ASC";

		if(!($statement = $DbConn->prepare($query)))
			errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
		if(!($statement->bind_param('ss', $searchPhrase, $searchPhrase)))
		    errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    }
    
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    $res = $statement->get_result();
    
    $tableData = array();
    
    for($i = 0; $i < $res->num_rows; $i++)
    {
        $row = $res->fetch_assoc();
        $dataRow = array(
            "productId"     =>$row["productId"],
            "currentJobId"  =>$row["currentJobId"]
        );
        array_push($tableData, $dataRow);
    }
    
    return $tableData;
}

function deleteProduct($DbConn, $ProductId)
{   
    $query = "DELETE FROM products WHERE productId=?";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $ProductId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

    kafkaOutputDeleteProductType($ProductId);
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
        case "addProduct":
            $ProductId = $_GET["productId"];
            
			if(addProduct($dbConn, $ProductId))
			{	
				// $qrCodePath = generateProductQrCode($dbConn, $ProductId);
				sendResponseToClient("success");
			}				
			else
				sendResponseToClient("error","Product already exists");
            
            break;
            
        // case "getQrCode":
        //     $ProductId = $_GET["ProductId"];

		// 	$downloadPath = generateProductQrCode($dbConn, $ProductId);
        //     sendResponseToClient("success",$downloadPath);
        //     break;
            
        case "getProductTableData":
            // get an array of data to send to the client.
            $searchPhrase = $_GET["searchPhrase"];
            
            $dataArray = getProductTabledata($dbConn, $searchPhrase);
                        
            sendResponseToClient("success",$dataArray);
            
            break;
            
        case "deleteProduct":
            $ProductId = $_GET["productId"];
            deleteProduct($dbConn, $ProductId);
            sendResponseToClient("success");
            break;

		case "getProductsList":
			$productsArray = getProductsList($dbConn);
            sendResponseToClient("success",$productsArray); 
			break;
    }
}

main();

?>
