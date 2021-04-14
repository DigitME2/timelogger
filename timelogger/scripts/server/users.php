<?php
// Note that the database conenction is implicitly released when this script 
// terminates
require "db_params.php";
require "common.php";

$Debug = false;
$UserQrCodeDirAbs = "/opt/lampp/htdocs/timelogger/generatedUserQrCodes/";
$UserQrCodeDirRelativeToPage = "../generatedUserQrCodes/";

function addUser($DbConn, $UserName)
{
	global $userIDPrefix;

    printDebug("Adding new user $UserName");
        
    $query = "SELECT userIdIndex FROM users ORDER BY userIdIndex DESC LIMIT 1";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    $res = $statement->get_result();
    $row = $res->fetch_row();
    $newUserIdNum = intval($row[0]) + 1;
	$newUserId = sprintf("%s%04d", $userIDPrefix, $newUserIdNum);
    
    $query = "INSERT INTO users (userId, userName, userIdIndex) VALUES (?, ?, ?)";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('ssi', $newUserId, $UserName, $newUserIdNum)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    return $newUserId;
}

function getUserTabledata($DbConn, $OrderByName){
    // returns an array of user data, ordered either userName or by order
    // added, newest first.
    
    if($OrderByName == true)
        $query = "SELECT userId, userName, relativePathToQrCode FROM users WHERE userId != 'office' and userId != 'noName' and userId != 'user_Delt' ORDER BY userName ASC";
    else
        $query = "SELECT userId, userName, relativePathToQrCode FROM users WHERE userId != 'office' and userId != 'noName' and userId != 'user_Delt' ORDER BY recordAdded DESC";
    
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
            "userId"        =>$row["userId"],
            "userName"      =>$row["userName"],
            "pathToQrCode"  =>$row["relativePathToQrCode"]
        );
        array_push($tableData, $dataRow);
    }
    
    return $tableData;
}

function deleteUser($DbConn, $UserId)
{
    // get the abs path to the relevant QR code first, delete the QR code, 
    // then remove the user from the database.
    
    $query = "SELECT absolutePathToQrCode FROM users WHERE userId=?";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $UserId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    $res = $statement->get_result();
    $row = $res->fetch_row();
    
    $qrCodePath = $row[0];
    
    if($qrCodePath != null)
        exec("rm $qrCodePath");
    
    $query = "DELETE FROM users WHERE userId=?";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $UserId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

	//Update user entries in time log so that user is replaced with default deleleted user 'user_delt'
	$query = "UPDATE timeLog SET userId='user_Delt' WHERE userId=?;";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $UserId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
}


// generate a QR code, log the path to the database, and return said path for download
function generateUserQrCode($DbConn, $UserId)
{
    global $UserQrCodeDirAbs;
    global $UserQrCodeDirRelativeToPage;
        
    $webPath = $UserQrCodeDirRelativeToPage . $UserId . ".png";
    $actualpath = $UserQrCodeDirAbs . $UserId . ".png";
    
    generateQrCode($UserId, $actualpath);
    printDebug("Generated QR code at $actualpath");
    
    $query = "UPDATE users SET relativePathToQrCode=?, absolutePathToQrCode=? WHERE userId=?";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('sss', $webPath, $actualpath, $UserId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    return $webPath;
}

function userTableInitialised($DbConn)
{
    $query = "SELECT COUNT(*) FROM users";
    if(!($countResult = $DbConn->query($query)))
            errorHandler("Error executing query: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    $row = $countResult->fetch_array();
    
    if($row[0] > 0)
        return true;
    else
        return false;
}

function initUserTable($DbConn)
{
    $query = "INSERT INTO users (userId, userName,userIdIndex) VALUES ('user_Delt', 'User Deleted', -2)";
    if(!($countResult = $DbConn->query($query)))
            errorHandler("Error executing query: ($DbConn->errno) $DbConn->error, line " . __LINE__);
            
    $query = "INSERT INTO users (userId, userName,userIdIndex) VALUES ('office', 'Office', -1)";
    if(!($countResult = $DbConn->query($query)))
            errorHandler("Error executing query: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    $query = "INSERT INTO users (userId, userName,userIdIndex) VALUES ('noName', 'N/A', 0)";
    if(!($countResult = $DbConn->query($query)))
            errorHandler("Error executing query: ($DbConn->errno) $DbConn->error, line " . __LINE__);
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
        case "addUser":
            $userName = $_GET["userName"];
            
            $userId = addUser($dbConn, $userName);
			generateUserQrCode($dbConn, $userId);
			sendResponseToClient("success",$userId);
            
            break;
            
        case "getQrCode":
            $userId = $_GET["userId"];
            $downloadPath = generateUserQrCode($dbConn, $userId);
            sendResponseToClient("success",$downloadPath);
            break;
            
        case "getUserTableData":
            // get an array of data to send to the client.
            $tableOrdering = $_GET["tableOrdering"];
            
            if(!userTableInitialised($dbConn))
                initUserTable($dbConn);
            
            if($tableOrdering == "byAlphabetic")
                $dataArray = getUserTabledata($dbConn, true);
            else
                $dataArray = getUserTabledata($dbConn, false);
                        
            sendResponseToClient("success",$dataArray);
            
            break;
            
        case "deleteUser":
            $userId = $_GET["userId"];
            deleteUser($dbConn, $userId);
            sendResponseToClient("success");
            break;
    }
}

main();

?>
