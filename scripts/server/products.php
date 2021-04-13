<?php
// Note that the database conenction is implicitly released when this script 
// terminates
require "db_params.php";
require "common.php";

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
    
    return $ProductID;
}

function getProductTabledata($DbConn, $searchPhrase){
    // returns an array of user data, ordered either userName or by order
    // added, newest first.
    
    if($searchPhrase == "")
	{
        $query = "SELECT productId, currentJobId, relativePathToQrCode FROM products ORDER BY productId ASC";

		if(!($statement = $DbConn->prepare($query)))
        	errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
	}
    else
	{
		$searchPhrase = "%".$searchPhrase."%";
        $query = "SELECT productId, currentJobId, relativePathToQrCode FROM products WHERE productId LIKE ? OR currentJobId LIKE ? ORDER BY productId ASC";

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
            "currentJobId"  =>$row["currentJobId"],
            "pathToQrCode"  =>$row["relativePathToQrCode"]
        );
        array_push($tableData, $dataRow);
    }
    
    return $tableData;
}

function deleteProduct($DbConn, $ProductId)
{
    // get the abs path to the relevant QR code first, delete the QR code, 
    // then remove the product from the database.
    
    $query = "SELECT absolutePathToQrCode FROM products WHERE productId=?";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $ProductId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    $res = $statement->get_result();
    $row = $res->fetch_row();
    
    $qrCodePath = $row[0];
    
    if($qrCodePath != null)
        exec("rm $qrCodePath");
    
    $query = "DELETE FROM products WHERE productId=?";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $ProductId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
}


// generate a QR code, log the path to the database, and return said path for download
function generateProductQrCode($DbConn, $ProductId)
{
    global $ProductQrCodeDirAbs;
    global $ProductQrCodeDirRelativeToPage;
	global $productIDCodePrefix;
        
    $webPath = $ProductQrCodeDirRelativeToPage . $ProductId . ".png";
    $actualpath = $ProductQrCodeDirAbs . $ProductId . ".png";

	$QRCodeText = $productIDCodePrefix.$ProductId;//join product prefix with ID to creat text that will be displayed in code
    
    generateQrCode($QRCodeText, $actualpath);
    printDebug("Generated QR code at $actualpath");
    
    $query = "UPDATE products SET relativePathToQrCode=?, absolutePathToQrCode=? WHERE productId=?";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('sss', $webPath, $actualpath, $ProductId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    return $webPath;
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
				$qrCodePath = generateProductQrCode($dbConn, $ProductId);
				sendResponseToClient("success",$qrCodePath);
			}				
			else
				sendResponseToClient("error","Product already exists");
            
            break;
            
        case "getQrCode":
            $ProductId = $_GET["ProductId"];

			$downloadPath = generateProductQrCode($dbConn, $ProductId);
            sendResponseToClient("success",$downloadPath);
            break;
            
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
