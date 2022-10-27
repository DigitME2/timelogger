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


// Various functions used throughout the server software.
require_once "phpqrcode/qrlib.php";

$JobQrCodeDirAbs = "C:/xampp/htdocs/timelogger/generatedJobQrCodes/";
$JobQrCodeDirRelativeToPage = "../generatedJobQrCodes/";

$ProductQrCodeDirAbs = "C:/xampp/htdocs/timelogger/generatedProductQrCodes/";
$ProductQrCodeDirRelativeToPage = "../generatedProductQrCodes/";

$StoppageReasonQrCodeDirAbs = "C:/xampp/htdocs/timelogger/generatedStoppageReasonQrCodes/";
$StoppageReasonQrCodeDirRelativeToPage = "../generatedStoppageReasonQrCodes/";

$productIDCodePrefix = 'pdrt_';
$stoppageReasonIDCodePrefix = 'stpg_';
$userIDPrefix = 'user_';
$jobAutoGeneratePrefix = 'Job_';

$systemPrefixes = ['user'=>$userIDPrefix, 'product'=>$productIDCodePrefix, 'stoppage'=>$stoppageReasonIDCodePrefix, 'job'=>$jobAutoGeneratePrefix];

if(!function_exists("printDebug")){
    function printDebug($Message)
    {
        global $debug;
            
        if($debug)
            echo($Message."<br>");
    }
}
if(!function_exists("errorHandler")){
    function errorHandler($ErrorMessage)
    {
        sendResponseToClient("error", $ErrorMessage);

        error_log($ErrorMessage);
    
        exit(1);
    }
}

if(!function_exists("sendResponseToClient")){
    function sendResponseToClient($Status, $Result = "", ...$otherResponce)
    {
        $resArray = array(
            "status"=>$Status,
            "result"=>$Result
        );    
    
        print(json_encode($resArray));
    }
}

if(!function_exists("initDbConn")){
    function initDbConn($ServerName, $UserName, $Password, $DbName)
    {
        $conn = new mysqli(
            $ServerName,
            $UserName,
            $Password,
            $DbName
        );

        if($conn->connect_errno)
            errorHandler("Error connecting to database: ($conn->connect_errno) $conn->connect_error, line " . __LINE__);
    
        return $conn;
    }
}

if(!function_exists("generateQrCode")){
    function generateQrCode($DataToEncode, $GeneratedCodePath)
    {
        QRcode::png($DataToEncode, $GeneratedCodePath, 'H', 5, 5);
        printDebug("Generated QR code $GeneratedCodePath");
    }
}


/* Prints out an array of data as a CSV file.
 *
 * If $Headings is not provided, the keys of the first element of the data
 * array will be used. Otherwise, $Headings may take one of two forms:
 *
 * The $DataNames parameter is used to specify the order of the data columns.
 * If this parameter is null, the keys from $DataToSend will be used, in
 * the order they are present.
 *
 * The $ColumnHeadings parameter is used to specify the names of the columns in
 * the CSV data. If this is null, the $DataNames parameter will be used.
 */
if(!function_exists("sendCsvToClient")){
    function sendCsvToClient($DataToSend, $DataNames = null, $ColumnHeadings = null, $fileName = null)
    {
        if(is_null($fileName))
            $fileName = "csvData.csv";
        header('Content-Disposition: attachment; filename="'.$fileName.'"');
        //header("Content-Length: " . filesize($file));
        //header('Content-Type: application/octet-stream;');
        header('Content-Type: text/csv;');
    
        if(count($DataToSend) == 0)
            return;
    
        if($DataNames == null)
            $DataNames = array_keys($DataToSend[0]);
    
        if($ColumnHeadings == null)
            $ColumnHeadings = $DataNames;
        
        // first print the headings...
        for($i = 0; $i < count($ColumnHeadings) - 1; $i++)
            echo("$ColumnHeadings[$i],");
        $lastHeading = end($ColumnHeadings);
        echo("$lastHeading\n");
    
        // ...then print rows of data
        foreach($DataToSend as $dataRow)
        {
            for($i = 0; $i < count($DataNames) - 1; $i++)
            {
                $data = $dataRow[$DataNames[$i]];
                echo("\"$data\"" . ",");
            }
            $lastData = $dataRow[end($DataNames)];
            echo("$lastData\n");
        }
    }
}

// converts a number of seconds (as a string) to hours and minutes

if(!function_exists("durationToTime")){
    function durationToTime($DurationString)
    {
        $hours = intval($DurationString / 3600);
        $minutes = intval($DurationString/60.0) % 60;
        $seconds = intval($DurationString) % 60;
    
        return sprintf("%'.02d:%'.02d",$hours,$minutes);
    }
}

//convert a a time in HH:MM:SS into seconds
if(!function_exists("timeToDuration")){
    function timeToDuration($TimeString)
    {
	
	    sscanf($TimeString, "%d:%d:%d", $hours, $minuts, $seconds);
	
	    $duration = $hours * 3600 + $minuts * 60 + $seconds;

	    return $duration;
    }
}

// Converts a status string to a slightly nicer formatted one.
// Works for pending, workInProgress, stageComplete, unknown and complete
if(!function_exists("makePrettyStatus")){
    function makePrettyStatus($StatusStr)
    {
        switch($StatusStr)
        {
            case "pending":
                $StatusStr = "Pending";
                break;
            
            case "workInProgress":
                $StatusStr = "Work in Progress";
                break;
            
            case "stageComplete":
                $StatusStr = "Stage Complete";
                break;
            
            case "unknown":
                $StatusStr = "Unknown";
                break;
            
            case "complete":
                $StatusStr = "Complete";
                break;        
        }
    
        return $StatusStr;
    }
}

// Return Job id string genrated using the greatest current unique index in the job table

if(!function_exists("generateJobId")){
    function generateJobId($DbConn)
    {
	    global $jobAutoGeneratePrefix;

        $query = "SELECT `jobIdIndex` FROM `jobs` ORDER BY `jobIdIndex` DESC LIMIT 1";

        if(!($statement = $DbConn->prepare($query)))
    	    errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
        if(!$statement->execute())
            errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
        $res = $statement->get_result();
        $row = $res->fetch_row();
        if($row[0] == NULL)
        {
            $index = 1;
        }
        else
        {
            $index = ((int)$row[0]) + 1;
        }

	    $formatString = $jobAutoGeneratePrefix."%015u";

	    $id = sprintf($formatString, $index);

        return $id;
    }

}

// generate a QR code, log the path to the database, and return said path for download

if(!function_exists("generateJobQrCode")){
    function generateJobQrCode($DbConn, $JobId)
    {
        global $JobQrCodeDirAbs;
        global $JobQrCodeDirRelativeToPage;
        
        $webPath = $JobQrCodeDirRelativeToPage . $JobId . ".png";
        $actualpath = $JobQrCodeDirAbs . $JobId . ".png";
    
        generateQrCode($JobId, $actualpath);
        printDebug("Generated QR code at $actualpath");
    
        $query = "UPDATE jobs SET relativePathToQrCode=?, absolutePathToQrCode=? WHERE jobId=?";
    
        if(!($statement = $DbConn->prepare($query)))
            errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
        if(!($statement->bind_param('sss', $webPath, $actualpath, $JobId)))
            errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
        if(!$statement->execute())
            errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
        return $webPath;
    }
}

if(!function_exists("updateJobStoppages")){
    function updateJobStoppages($DbConn, $JobId)
    {

	    $query = "SELECT stoppageReasonName, stationId FROM stoppagesLog JOIN stoppageReasons ON stoppagesLog.stoppageReasonId = stoppageReasons.stoppageReasonId WHERE jobId=? AND status='unresolved' ORDER BY recordTimeStamp DESC LIMIT 2;";

        if(!($statement = $DbConn->prepare($query)))
    	    errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
	    if(!($statement->bind_param('s', $JobId)))
            errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);

        if(!$statement->execute())
            errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
        $queryResult = $statement->get_result();
    
	    $stoppageList =  "";	
	    for($i = 0; $i < $queryResult->num_rows; $i++)
        {
            $row = $queryResult->fetch_assoc();
        
            $stoppageList = $stoppageList.$row["stoppageReasonName"]."-".$row["stationId"].",\n";
        }

	    $query = "UPDATE jobs SET stoppages=? WHERE jobId=?";

	    if(!($statement = $DbConn->prepare($query)))
            errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
        if(!($statement->bind_param('ss', $stoppageList, $JobId)))
            errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
        if(!$statement->execute())
            errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

	    $updateResult = $statement->get_result();

        return $stoppageList;
    }
}

if(!function_exists("updateJobStoppagesFromStoppageRef")){
    function updateJobStoppagesFromStoppageRef($DbConn, $ref)
    {
        $query = "SELECT jobId FROM stoppagesLog WHERE ref=? LIMIT 1";

        if(!($statement = $DbConn->prepare($query)))
            errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);

        if(!($statement->bind_param('s', $ref)))
            errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);

        if(!$statement->execute())
            errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

        $res = $statement->get_result();
        $row = $res->fetch_assoc();

        $JobId = $row["jobId"];

        if ($JobId != NULL)
        {		
            return updateJobStoppages($DbConn, $JobId);
        }
        else
            return $false;
    }
}
//check if a productId is present as a product in the database
if(!function_exists("productIdExists")){
    function productIdExists($DbConn, $productId)
    {
        $query = "SELECT productId FROM `products` WHERE products.productId = ? limit 1";

        if(!($statement = $DbConn->prepare($query)))
            errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);

        if(!($statement->bind_param('s', $productId)))
            errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);

        if(!$statement->execute())
            errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

        $res = $statement->get_result();

        if(($res->num_rows) > 0)
            return true;
        else
            return false;
    }
}
//check if a Route is defined as a product in the database
if(!function_exists("routeExists")){
    function routeExists($DbConn, $routeName)
    {
        $query = "SELECT routeName FROM `routes` WHERE routes.routeName = ? limit 1";

        if(!($statement = $DbConn->prepare($query)))
            errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);

        if(!($statement->bind_param('s', $routeName)))
            errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);

        if(!$statement->execute())
            errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

        $res = $statement->get_result();

        if(($res->num_rows) > 0)
            return true;
        else
            return false;
    }
}

if(!function_exists("validDate")){
    function validDate($date)
    {
        $result = false;

        if(preg_match('/^(([12]\d)?\d{2}(\/|-)(0[1-9]|1[0-2])(\/|-)(0[1-9]|[12]\d|3[01]))$/', $date))
        {	
            if(($date[4] == '/' && $date[7] == '/') || ($date[2] == '/' && $date[5] == '/'))
            {
                $splitDate = explode("/", $date);
            }
            elseif(($date[4] == '-' && $date[7] == '-') || ($date[2] == '-' && $date[5] == '-'))
            {
                $splitDate = explode("-", $date);
            }
            else
            {
                return $result;
            }
            
            if($splitDate[0] == "00")
                $splitDate[0] = "01";
            if(checkdate($splitDate[1], $splitDate[2], $splitDate[0]))
                $result = true;

        }

        return $result;
    }
}
if(!function_exists("checkStartsWithPrefix")){
    function checkStartsWithPrefix($id)
    {
        global $systemPrefixes;

        $result = false;

        foreach($systemPrefixes as $prefix)
        {
            if(substr($id, 0, strlen($prefix))==$prefix)
            {
                $result = true;
                break;
            }
        }

        return $result;
    }
}

if(!function_exists("validateJobDetails")){
    function validateJobDetails($DbConn, $JobId, $Description, $ExpectedDuration, $RouteName, $DueDate, $TotalJobCharge, $NumberOfUnits, $TotalParts, $productId, $priority, $customerName)
    {
        if(! preg_match('/^[a-z0-9_]+$/i', $JobId))
            $validationMessage = "Job ID contains invalid chars";

        elseif (strlen($JobId) > 20)
            $validationMessage = "Job ID greater than 20 chars";

        elseif (strlen($Description) > 200)
            $validationMessage = "Description more than 200 chars";

        elseif ($ExpectedDuration != "" && $ExpectedDuration !== 0 && ! preg_match('/^((\d+:[0-5][0-9]?)|(\d+))$/', $ExpectedDuration))
            $validationMessage = "Expected Duration format incorrect";

        elseif ($RouteName != "" && (routeExists($DbConn, $RouteName) == false))
            $validationMessage = "Route does not exist";

        elseif ($DueDate != "9999-12-31" && ! validDate($DueDate))
            $validationMessage = "Due Date Invalid";

        elseif ($TotalJobCharge != "" && $TotalJobCharge !== 0 && ! preg_match('/^((\d+.\d{1,4})|(\d+))$/', $TotalJobCharge))//accept four didgets for pence although it will be rounded down when convering to pence
            $validationMessage = "Total charge format incorrect";

        elseif ($NumberOfUnits != "" && $NumberOfUnits !== 0 && ! preg_match('/^\d+$/', $NumberOfUnits))
            $validationMessage = "Number of units invalid";
        
        elseif ($TotalParts != "" && $TotalParts !== 0 && ! preg_match('/^\d+$/', $TotalParts))
            $validationMessage = "Total parts invalid";

        elseif ($productId != '' && (productIdExists($DbConn, $productId) == false))
            $validationMessage = "Product does not exist";

        elseif (! preg_match('/^[0-4]$/', $priority))
            $validationMessage = "Priority not 0-4";
            
        elseif (strlen($customerName) > 50)
            $validationMessage = "Customer name more than 50 chars";

        else
            $validationMessage = "";

        return $validationMessage;
    }
}