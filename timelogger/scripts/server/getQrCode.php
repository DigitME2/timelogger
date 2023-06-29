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
require_once "phpqrcode/qrlib.php";
require "common.php";


 
function generatesQrCode($DataToEncode, $DownloadFileName)
{
    QRcode::png($DataToEncode, $DownloadFileName, 'H', 5, 5);
}

function getDownloadQrCode($DataToEncode, $DownloadFileName) 
{
    $tempFile = "QrCode.png";
    header('Content: image/png');
    header('Content-Description: File Transfer');
    header('Content-Type: application/octet-stream'); //octet-stream is used as 'force-download' is restricted with some browsers.
    header("Content-Transfer-Encoding: binary");
    header('Content-Disposition:attachment;filename="'.$DownloadFileName.'"');
    generatesQrCode($DataToEncode, $tempFile);
    readfile($tempFile);
}

function getActualNamesforIds($DbConn, $UserInputId)
{
    if(str_starts_with($UserInputId, "user_"))
    {
        $query = "SELECT userName from users WHERE userId = ? "; 
        
        if(!($statement = $DbConn->prepare($query)))
            errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
        if(!($statement->bind_param('s', $UserInputId)))
            errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
        if(!$statement->execute())
            errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
		
	    $res = $statement->get_result();
	    $row = $res->fetch_assoc();
        $userName = $row["userName"];
        return $userName;
    }
    if(str_starts_with($UserInputId, "stpg_"))
    {
        $query = "SELECT stoppageReasonName from stoppageReasons WHERE stoppageReasonId = ? "; 
        
        if(!($statement = $DbConn->prepare($query)))
            errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
        if(!($statement->bind_param('s', $UserInputId)))
            errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
        if(!$statement->execute())
            errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
		
	    $res = $statement->get_result();
	    $row = $res->fetch_assoc();
        $stoppageReasonName = $row["stoppageReasonName"];
        return $stoppageReasonName;
    }
    if(str_starts_with($UserInputId, "job_"))
    {
        $query = "SELECT jobName from jobs WHERE jobId = ? "; 
        
        if(!($statement = $DbConn->prepare($query)))
            errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
        if(!($statement->bind_param('s', $UserInputId)))
            errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
        if(!$statement->execute())
            errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
		
	    $res = $statement->get_result();
	    $row = $res->fetch_assoc();
        $jobName = $row["jobName"];
        return $jobName;
    }
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
        case "getDownloadUserIdQrCode":
            $DataToEncode = $_GET["userId"];
            $UserName = getActualNamesforIds($dbConn, $DataToEncode);
            getDownloadQrCode($DataToEncode, $UserName.'-ID-QRCode.png');
            sendResponseToClient("success");
            break;

        case "getDownloadJobIdQrCode":
            $DataToEncode = $_GET["jobId"];
            $jobName = getActualNamesforIds($dbConn, $DataToEncode);
            getDownloadQrCode($DataToEncode, $jobName.'-ID-QRCode.png');
            sendResponseToClient("success");
            break;

        case "getDownloadProductIdQrCode":
            $DataToEncode = $_GET["productId"];
            $requiredQrCode = 'pdrt_' . $DataToEncode;
            getDownloadQrCode($requiredQrCode, $DataToEncode.'-ID-QRCode.png');
            sendResponseToClient("success");
            break;

        case "getDownloadstoppageIdQrCode":
            $DataToEncode = $_GET["stoppagereasonId"];
            $StoppageReasonName = getActualNamesforIds($dbConn, $DataToEncode);
            getDownloadQrCode($DataToEncode, $StoppageReasonName.'-ID-QRCode.png');
            sendResponseToClient("success");
            break;
    
    }

}

main();


?>