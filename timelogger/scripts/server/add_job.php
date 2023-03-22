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

// Accepts a GET request from a web client
// 
// Note that the database conenction is implicitly released when this script 
// terminates
require "db_params.php";
require "common.php";
require_once "kafka.php";

$debug = false;

function addJob($DbConn, $JobId, $Description, $ExpectedDuration, $RouteName, $DueDate, $TotalJobCharge, $NumberOfUnits, $TotalParts, $productId, $priority, $customerName)
{
    printDebug("Adding new job $JobId");
	   
    $query = "SELECT COUNT(jobId) FROM jobs WHERE jobs.jobId=?";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $JobId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    $res = $statement->get_result();
    $row = $res->fetch_row();
    if($row[0] != 0)
    {
        printDebug("Error: Job ID already exists");
        return "Job ID already exists";
    }
    
    $query = "INSERT INTO jobs (jobId, expectedDuration, description, routeName, dueDate, numberOfUnits, totalParts, totalChargeToCustomer, productId, priority, customerName, currentStatus, recordAdded) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', CURRENT_TIMESTAMP)";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('sssssssssss', $JobId, $ExpectedDuration, $Description, $RouteName, $DueDate, $NumberOfUnits, $TotalParts, $TotalJobCharge, $productId, $priority, $customerName)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

	kafkaOutputCreateJob($JobId, $customerName, $ExpectedDuration, $DueDate, $Description, $TotalJobCharge, $NumberOfUnits, $TotalParts, $productId, $RouteName, $priority);
    
    return "Added";
}


//return value array(result, jobId, generatedIdFlag)
//$routePending set to true if route does not exist yet
function attemptToAddJob($DbConn, $jobDetails, $routePending=false)
{
	$result = "";
	$generatedIdFlag = false;

	if(!isset($jobDetails["jobId"]))
	{
		$result = "jobId column must be present, although can be blank.";
		return array($result, "", true);
	}
	
	$jobId = $jobDetails["jobId"];

    if($jobId == "")
	{
		$jobId = generateJobId($DbConn);
		$generatedIdFlag = true;
	}
	else
	{
		$generatedIdFlag = false;
		if(checkStartsWithPrefix($jobId))
			$result = "System prefix present at start of ID";
	}

	// This code extracts expected time from csv, there is a chunk of code bottom which converts this expected time into seconds.
	if (str_contains($jobDetails["expectedDuration"], '.')){

		$expectedDuration = $jobDetails["expectedDuration"];
		
	}
	elseif (isset($jobDetails["expectedDuration"]) && $jobDetails["expectedDuration"] != "" ) {

		$obtainedDuration = $jobDetails["expectedDuration"];
		$splitObtainedDuration = explode(":", $obtainedDuration);
		if (count($splitObtainedDuration) == 1) {
			$expectedDuration = $splitObtainedDuration[0] . ":00";
		} 
		elseif (count($splitObtainedDuration) == 3 || count($splitObtainedDuration) == 2) 
		{
			$expectedDuration = $splitObtainedDuration[0] . ":" . $splitObtainedDuration[1];
		}
	}
	else
		$expectedDuration = 0;
	
	if(isset($jobDetails["description"]))
		$description = $jobDetails["description"];
	else
		$description = "";
	
	if(isset($jobDetails["routeName"]))
		$routeName = $jobDetails["routeName"];
	else
		$routeName = "";
	
	if(isset($jobDetails["dueDate"]) && $jobDetails["dueDate"] != "")
		$dueDate = $jobDetails["dueDate"];
	else
		$dueDate = "9999-12-31";
	
	if(isset($jobDetails["totalChargeToCustomer"]) && $jobDetails["totalChargeToCustomer"] != "")
		$charge = $jobDetails["totalChargeToCustomer"];
	else
		$charge = 0;
	
	if(isset($jobDetails["unitCount"]) && $jobDetails["unitCount"] != "")
		$unitCount = $jobDetails["unitCount"];
	else
		$unitCount = 0;
	
	if(isset($jobDetails["totalParts"]) && $jobDetails["totalParts"] != "")
		$totalParts = $jobDetails["totalParts"];
	else
		$totalParts = 0;

	if(isset($jobDetails["productId"]) && $jobDetails["productId"] !== null)
		$productId = $jobDetails["productId"];
	else
		$productId = '';

	if(isset($jobDetails["priority"]) && $jobDetails["priority"] !== "")
		$priority = $jobDetails["priority"];
	else
		$priority = 0;

	if(isset($jobDetails["customerName"]) && $jobDetails["customerName"] !== null)
		$customerName = $jobDetails["customerName"];
	else
		$customerName = '';		
		

	

	if($result === "")
	{
		if($routePending===true)
			$routeValidateVal = '';
		else
			$routeValidateVal = $routeName;

		$result = validateJobDetails(
			$DbConn, $jobId, $description, $expectedDuration, $routeValidateVal, 
			$dueDate, $charge, $unitCount, $totalParts, $productId, $priority, 
			$customerName
			);
	}
	
	

	if($result === "")
	{
		//convert duration into seconds
		if (str_contains($expectedDuration, ".")){
			$durationParts = explode(".", $expectedDuration);
			if (count($durationParts) == 2){
				$convertingINTtoSTR = (intval($durationParts[1]));
				if (strlen($durationParts[1]) == 1){
					$addingZeroBesideNum = (str_pad($convertingINTtoSTR, 2, '0', STR_PAD_RIGHT));
					$convertingPercentToMin = ($addingZeroBesideNum /100) * 60;
				}
				else{
					$convertingPercentToMin = ((intval($durationParts[1])) /100) * 60;
				}
				if ($convertingPercentToMin < 1)
					$convertingPercentToMin = 1;
					
				$expectedDuration = (intval($durationParts[0]) * 3600) + ($convertingPercentToMin * 60);
			}
		}
		else{
			$durationParts = explode(":", $expectedDuration);
			if (count($durationParts) == 2)
				$expectedDuration = (intval($durationParts[0]) * 3600) + (intval($durationParts[1] * 60));
		}
		//convert total charge into pence
		$charge = round($charge * 100);

		//attempt to add job
		try{
			$result = addJob($DbConn, $jobId, $description, $expectedDuration, $routeName, $dueDate, $charge, $unitCount, $totalParts, $productId, $priority, $customerName);

			if($result === "Added" && $productId != '')
				setProductCurrentJob($DbConn, $jobId, $productId); //set this job as the current job for the product

		} catch (Exception $e){
			$result = $e;
		}
	}

	return array($result, $jobId, $generatedIdFlag);
}

function checkCSVFields($csvRow)
// checks for the empty or duplicate rows, if all rows are empty passed from the csv file and skips the entire row.
{
	$jobId = $csvRow["jobId"];
	$expectedDuration = $csvRow["expectedDuration"];
	$description = $csvRow["description"];
	$routeName = $csvRow["routeName"];
	$dueDate = $csvRow["dueDate"];
	$totalChargeToCustomer = $csvRow["totalChargeToCustomer"];
	$unitCount = $csvRow["unitCount"];
	$totalParts = $csvRow["totalParts"];
	$productId = $csvRow["productId"];
	$priority = $csvRow["priority"];
	$customerName = $csvRow["customerName"];
	if (
		$jobId === "" && 
		$expectedDuration === "" && 
		$description === "" && 
		$routeName === "" && 
		$dueDate === "" && 
		$totalChargeToCustomer === "" &&
		$unitCount === "" && 
		$totalParts === "" && 
		$productId === "" && 
		$priority === "" && 
		$customerName === ""
	)
		return false;
	else
		return true;
}
function processCsvFile($DbConn, $FileName)
{
	$csvJobsAdded = array();
	$failedCsvJobs = array();

	$addJobResult = "";
	$jobResultArray = array();

	$generatedIdFlag = false;

	// borrowed this from the PHP reference material
	$csv = array_map('str_getcsv', file($FileName));
	array_walk($csv, function(&$a) use ($csv) {
	  $a = array_combine($csv[0], $a);
	});
	array_shift($csv); # remove column header

	$rowCounter = 1;
	
	
	foreach($csv as $csvRow)
	{		
		$rowCounter++;

		if (checkCSVFields($csvRow)) {
			list($addJobResult, $jobId, $generatedIdFlag) = attemptToAddJob($DbConn, $csvRow); //sort array, validate values and attempt to add job

			if ($addJobResult === "Added") //if job was added succesfully
			{

				$jobResultArray = array("jobId" => $jobId, "result" => $addJobResult);

				array_push($csvJobsAdded, $jobResultArray); //add job to array of jobs succesfuly added
			} else //if the job was not added
			{
				if ($generatedIdFlag)
					//if no jobId was provided refer to row that could not be added by it's row number
					$jobIdMessage = "Row ".$rowCounter;
				else
					$jobIdMessage = $jobId;

				$jobResultArray = array("jobId" => $jobIdMessage, "result" => $addJobResult);

				array_push($failedCsvJobs, $jobResultArray); //add job to array of jobs that could not be added
			}
		}
	}

	//form message to be returned with number of jobs added / failed to add
	$responceText = "Jobs added: ".sizeof($csvJobsAdded);

	if(sizeof($failedCsvJobs) > 0)
	{
		$responceText = $responceText.", Failed to add: ".sizeof($failedCsvJobs);
	}

	//return message of number of jobs added along with array of jobs that failed to add followed by succesful jobs
	$responceArray = array("responceText"=>$responceText, "jobsAdded"=>array_merge($failedCsvJobs, $csvJobsAdded));

	sendResponseToClient("success", $responceArray);
	return;
}

function setProductCurrentJob($DbConn, $jobId, $productId)
{
	//Set the Current job in the product table for the product the job  is to the added jobs ID

	$query = "UPDATE products SET currentJobId = ? WHERE productId = ?";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('ss', $jobId, $productId)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
}

function main()
{
    global $dbParamsServerName;
    global $dbParamsUserName;
    global $dbParamsPassword;
    global $dbParamsDbName;
    
    $dbConn = initDbConn($dbParamsServerName, $dbParamsUserName, $dbParamsPassword, $dbParamsDbName);
    $dbConn->autocommit(TRUE);

	if($_SERVER["REQUEST_METHOD"] === "GET")
	{
		$request = $_GET["request"];

		printDebug("Processing request " . $request);

		switch($request)
		{
			case "addJob":
				list($addJobResult, $jobId, $generatedIdFlag) = attemptToAddJob($dbConn, $_GET, true);

				if($addJobResult === "Added")
				{
					// $qrWebPath = generateJobQrCode($dbConn, $jobId);
					sendResponseToClient("success", array("jobId"=>$jobId));
					
				}
				else
				{
					sendResponseToClient("error", $addJobResult);
				}
				break;

			default:
				sendResponseToClient("error", "Unknown request: " . $request);
		}
	}
	else if($_SERVER["REQUEST_METHOD"] === "POST")
	{
		if(isset($_REQUEST["request"]))
		{
			$request = $_REQUEST["request"];

			printDebug("Processing request " . $request);
			
			switch($request)
			{
				case "processCsvUpload":
					printDebug("Processing CSV file");
					$fileName = $_FILES["jobsCsv"]["tmp_name"];
					processCsvFile($dbConn,$fileName);
					printDebug("Done");					
					break;
					
					
				default:
					sendResponseToClient("error", "Unknown command: $request");
					break;
			}
		}
		else
		{
			sendResponseToClient("error", "No Request.");
		}
	}
}

main();

?>
