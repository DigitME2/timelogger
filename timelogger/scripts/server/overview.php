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
require "systemconfig.php";

$debug = false;

function getOverviewData($DbConn, $TableOrdering = "createdNewestFirst", $showPendingJobs = true, $showWorkInProgressJobs = true, $showCompletedJobs = true, $UseDateCreatedRange = false, $DateCreatedStart = "", $DateCreatedEnd = "", $UseDateDueRange = false, $DateDueStart = "", $DateDueEnd = "", $useDateTimeWorkedRange = false, $dateTimeWorkStart = "", $dateTimeWorkEnd = "", $excludeUnworkedJobs = false, $UseSearchKey = false, $SearchKey = "", $ShowOnlyUrgentJobs = false, $ShowOnlyNonurgentJobs = false, $subSortByPriority = false)
{
    // Calls a stored procedure to generate a table of data, suitable to use for the overview page of the
    // interface. See GetOverviewData in overview.sql for details.
    
	$orderByCreatedTimestampAsc = false;
	$orderByCreatedTimestampDesc = false;
	$orderByDueSoonestFirst = false;
	$orderByDueLatestFirst = false;
	$orderByAlphabeticJobId = false;
	$orderBypriority = false;
	
    switch($TableOrdering)
    {
        case "createdNewestFirst":
			printDebug("Selected ordering by created, newest first");
			$orderByCreatedTimestampDesc = true;
			break;
			
        case "createdOldestFirst":
		printDebug("Selected ordering by created, oldest first");
			$orderByCreatedTimestampAsc = true;
			break;
			
        case "dueSoonestFirst":
			printDebug("Selected ordering by date due, soonest first");
			$orderByDueSoonestFirst = true;
			break;
			
        case "dueLatestFirst":
			printDebug("Selected ordering by date due, latest first");
			$orderByDueLatestFirst = true;
			break;
			
        case "alphabetic":
			printDebug("Selected ordering alphabetically by job ID");
			$orderByAlphabeticJobId = true;
			break;

		case "priority":
			printDebug("Selected ordering by priority");
			$orderBypriority = true;
			break;
    }
	
	printDebug("$showPendingJobs: $showPendingJobs");
	printDebug("$showWorkInProgressJobs: $showWorkInProgressJobs");
	printDebug("$showCompletedJobs: $showCompletedJobs");
	printDebug("UseDateCreatedRange: $UseDateCreatedRange");
	printDebug("DateCreatedStart: $DateCreatedStart");
	printDebug("DateCreatedEnd: $DateCreatedEnd");
	printDebug("UseDateDueRange: $UseDateDueRange");
	printDebug("DateDueStart: $DateDueStart");
	printDebug("DateDueEnd: $DateDueEnd");
	printDebug("useDateTimeWorkedRange: $useDateTimeWorkedRange");
	printDebug("dateTimeWorkStart: $dateTimeWorkStart");
	printDebug("dateTimeWorkEnd: $dateTimeWorkEnd");
	printDebug("excludeUnworkedJobs: $excludeUnworkedJobs");
	printDebug("UseSearchKey: $UseSearchKey");
	printDebug("SearchKey: $SearchKey");
	printDebug("ShowOnlyUrgentJobs: $ShowOnlyUrgentJobs");
	printDebug("ShowOnlyNonurgentJobs: $ShowOnlyNonurgentJobs");
	printDebug("subSortByPriority: $subSortByPriority");
    
    $query = "CALL GetOverviewData(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
    if(!($stmt = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
	// note: this is different to every other parameter bind in the system because PHP threw an error,
	// and I have no idea why. The command appears to work fine.
	$stmt->bind_param('isiiiissississiiiiiiiiii', 
					   $UseSearchKey, $SearchKey, 
					   $showPendingJobs, $showWorkInProgressJobs, $showCompletedJobs,
					   $UseDateCreatedRange, $DateCreatedStart, $DateCreatedEnd,
					   $UseDateDueRange, $DateDueStart, $DateDueEnd,
					   $useDateTimeWorkedRange, $dateTimeWorkStart, $dateTimeWorkEnd, $excludeUnworkedJobs,
					   $ShowOnlyUrgentJobs, $ShowOnlyNonurgentJobs,
					   $orderByCreatedTimestampAsc,
					   $orderByCreatedTimestampDesc,
					   $orderByDueSoonestFirst,
					   $orderByDueLatestFirst,
					   $orderByAlphabeticJobId,
					   $orderBypriority,
					   $subSortByPriority
					   );
	
	
    if(!$stmt->execute())
        errorHandler("Error executing statement: ($stmt->errno) $stmt->error, line " . __LINE__);
    
    $res = $stmt->get_result();
    
    $fullSearchResults = array();
    
    for($i = 0; $i < $res->num_rows; $i++)
    {
        $row = $res->fetch_assoc();
        
        $totalWorkedTime	= durationToTime($row['totalWorkedDuration']);
        $totalOvertime 		= durationToTime($row['totalOvertimeDuration']);
        $expectedTime 		= durationToTime($row['expectedDuration']);
        $currentStatus 		= makePrettyStatus($row['currentStatus']);
		$dueDate 				= $row["dueDate"];
		if($dueDate == "9999-12-31")
			$dueDate = "";
		
		$charge 	 	=	intval($row['totalChargeToCustomer']);
		$durationSec		=	intval($row['totalWorkedDuration']);
		if($durationSec != 0)
		{
			$timeMin		=	floor($durationSec)/60.0;
			$chargePerMinVal 	=	floatval($charge / $timeMin);
		}
		else
		{
			$chargePerMinVal 	=	0;
		}
		$chargePerMinStr 	=	sprintf("%.01d.%.02d", floor($chargePerMinVal/100.0), floor($chargePerMinVal % 100));
		$chargePounds = $charge/100;

		$productId			= $row['productId'];
		
		$resultRow = array(
			"jobId" 			=> $row["jobId"],
			"description"		=> $row["description"],
			"currentStatus"		=> $currentStatus,
			"recordAdded"		=> $row["recordAdded"],
			"workedTime"		=> $totalWorkedTime,
			"overtime"			=> $totalOvertime,
			"expectedTime"		=> $expectedTime,
			"efficiency"		=> $row["efficiency"],
			"routeStageName"	=> $row["routeCurrentStageName"],
			"priority"			=> $row["priority"],
			"dueDate"			=> $dueDate,
			"problems"			=> $row["stoppages"],
			"numberOfUnits"		=> $row["numberOfUnits"],
			"totalParts"		=> $row["totalParts"],
			"chargePerMin"		=> $chargePerMinStr,
			"totalCharge"		=> $chargePounds,
			"productId"			=> $productId,
			"stageQuantityComplete" => $row["stageQuantityComplete"],
			"stageOutstandingUnits" => $row["stageOutstandingUnits"],
			"customerName"		=> $row["customerName"],
			"notes"				=> $row["notes"],
			"quantityComplete" => $row["quantityComplete"]
		);
    		
        array_push($fullSearchResults, $resultRow);
    }
    
    $stmt->close();
    
    return $fullSearchResults;
}

function getOverviewTable($dbConn)
{
	printDebug("Fetching overview data");

	$tableOrdering = "alphabetic";

	if(isset($_GET["tableOrdering"]))
		$tableOrdering = $_GET["tableOrdering"];
	
	$showPendingJobs = (isset($_GET["showPendingJobs"]) && $_GET["showPendingJobs"] == "true");
	$showWorkInProgressJobs = (isset($_GET["showWorkInProgressJobs"]) && $_GET["showWorkInProgressJobs"] == "true");
	$showCompletedJobs = (isset($_GET["showCompletedJobs"]) && $_GET["showCompletedJobs"] == "true");
	$useDateCreatedRange = (isset($_GET["useDateCreatedRange"]) && $_GET["useDateCreatedRange"] == "true");
	$useDateDueRange = (isset($_GET["useDateDueRange"]) && $_GET["useDateDueRange"] == "true");
	$useDateTimeWorkedRange = (isset($_GET["useDateTimeWorkedRange"]) && $_GET["useDateTimeWorkedRange"] == "true");
	$excludeUnworkedJobs = (isset($_GET["excludeUnworkedJobs"]) && $_GET["excludeUnworkedJobs"] == "true");
	$useSearchKey = (isset($_GET["useSearchKey"]) && $_GET["useSearchKey"] == "true");
	$showUrgentJobsFirst = (isset($_GET["showUrgentJobsFirst"]) && $_GET["showUrgentJobsFirst"] == "true");
	$showOnlyUrgentJobs = (isset($_GET["showOnlyUrgentJobs"]) && $_GET["showOnlyUrgentJobs"] == "true");
	$subSortByPriority = (isset($_GET["subSortByPriority"]) && $_GET["subSortByPriority"] == "true");

	if($useDateCreatedRange)
	{
		printDebug("Using Date Created range");
		$dateCreatedStart = $_GET["dateCreatedStart"];
		$dateCreatedEnd = $_GET["dateCreatedEnd"];
		printDebug("dateCreatedStart: $dateCreatedStart    dateCreatedEnd: $dateCreatedEnd");
	}
	else
	{
		printDebug("Not using date created range");
		$dateCreatedStart = "2000-01-01";
		$dateCreatedEnd = "2002-01-01";
	}


	if($useDateDueRange)
	{
		printDebug("Using Date Due range");
		$dateDueStart = $_GET["dateDueStart"];
		$dateDueEnd = $_GET["dateDueEnd"];
		printDebug("dateDueStart: $dateDueStart    dateDueEnd: $dateDueEnd");
	}
	else
	{
		printDebug("Not using date Due range");
		$dateDueStart = "2000-01-01";
		$dateDueEnd = "2002-01-01";
	}

	if($useDateTimeWorkedRange)
	{
		printDebug("Using Date Time Worked range");
		$dateTimeWorkStart = $_GET["dateTimeWorkStart"];
		$dateTimeWorkEnd = $_GET["dateTimeWorkEnd"];
		printDebug("dateTimeWorkStart: $dateTimeWorkStart    dateTimeWorkEnd: $dateTimeWorkEnd");
	}
	else
	{
		printDebug("Not using date for range");
		$dateTimeWorkStart = "2000-01-01";
		$dateTimeWorkEnd = "2002-01-01";
	}
	
	if($excludeUnworkedJobs)
		printDebug("exclude all unworked jobs");
	else
		printDebug("Not excluding all unworked jobs");

	if($useSearchKey)
	{
		printDebug("Using search key");
		$searchKey = $_GET["searchKey"];
	}
	else
	{
		printDebug("Not using search key");
		$searchKey =  "";
	}

	if($showUrgentJobsFirst)
		printDebug("Showing all jobs, urgent first");
	else
		printDebug("Not prioritising urgent jobs");

	if($showOnlyUrgentJobs)
		printDebug("Showing only the urgent jobs");
	else
		printDebug("Showing all jobs, not limited to urgent");

	if($subSortByPriority)
		printDebug("Sub sorting by priority");
	else
		printDebug("Not sub sorting by priority");

	// If the client wants the urgent jobs listed first, then the data is selected as two arrays and then joined.
	if($showUrgentJobsFirst or $showOnlyUrgentJobs)
	{
		//get just urgent jobs
		$showUrgent = true;
		$showNonurgent = false;
		printDebug("Selecting urgent jobs");
		$urgentOverviewData = getOverviewData(
			$dbConn, 
			$tableOrdering,
			$showPendingJobs, $showWorkInProgressJobs, $showCompletedJobs,
			$useDateCreatedRange, $dateCreatedStart, $dateCreatedEnd,
			$useDateDueRange, $dateDueStart, $dateDueEnd,
			$useDateTimeWorkedRange, $dateTimeWorkStart, $dateTimeWorkEnd, $excludeUnworkedJobs,
			$useSearchKey, $searchKey,
			$showUrgent, $showNonurgent,
			false
		);

		if($showOnlyUrgentJobs)
		{
			//ONLY urgent jobs
			printDebug("Only urgent jobs were requested");
			$overviewData = $urgentOverviewData;
		}
		else
		{
			//Urgent jobs followed by other requested jobs
			printDebug("All jobs were requested. Fetching non-urgent jobs now.");
			$showUrgent = false;
			$showNonurgent = true;
			$otherOverviewData = getOverviewData(
				$dbConn, 
				$tableOrdering,
				$showPendingJobs, $showWorkInProgressJobs, $showCompletedJobs,
				$useDateCreatedRange, $dateCreatedStart, $dateCreatedEnd,
				$useDateDueRange, $dateDueStart, $dateDueEnd,
				$useDateTimeWorkedRange, $dateTimeWorkStart, $dateTimeWorkEnd, $excludeUnworkedJobs,
				$useSearchKey, $searchKey,
				$showUrgent, $showNonurgent,
				$subSortByPriority
			);

			printDebug("Merging data now");
			$overviewData = array_merge($urgentOverviewData, $otherOverviewData);
		}
	}
	else
	{
		printDebug("No sorting based on urgent requested. Fetching data according to other settings.");
		$overviewData = getOverviewData(
			$dbConn, 
			$tableOrdering,
			$showPendingJobs, $showWorkInProgressJobs, $showCompletedJobs,
			$useDateCreatedRange, $dateCreatedStart, $dateCreatedEnd,
			$useDateDueRange, $dateDueStart, $dateDueEnd,
			$useDateTimeWorkedRange, $dateTimeWorkStart, $dateTimeWorkEnd, $excludeUnworkedJobs,
			$useSearchKey, $searchKey,
			false, false,
			$subSortByPriority
		);
	}
	
	return $overviewData;
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
        case "getOverviewData":
        case "getOverviewDataCSV":
			$overviewData = getOverviewTable($dbConn);

			if(isset($_GET["updateRequestNumber"]))
				$updateRequestNumber = $_GET["updateRequestNumber"];
			else
				$updateRequestNumber = 0;
            
            if($request == "getOverviewDataCSV")
            {
                $dataNames = array(
                    "jobId",
					"productId",
					"customerName",
                    "description",
					"numberOfUnits",
					"totalParts",
                    "currentStatus",
					"routeStageName",
                    "recordAdded",
					"dueDate",
                    "expectedTime",
                    "workedTime",
                    "overtime",
                    "efficiency",
					"problems",
					"notes",
					"priority"
                );
				if(showQuantityComplete()){
					array_push($dataNames, "quantityComplete");
				}
                $columnNames = array(
                    "Job ID",
					"Product ID",
					"Customer Name",
                    "Description",
                    "Number of Units",
                    "Total Parts",
                    "Current Status",
                    "Route Stage Name",
                    "Record Added",
                    "Due Date",
                    "Expected Time",                    
                    "Worked Time",
                    "Overtime",
                    "Efficiency",
					"Problems",
					"Notes",
					"Priority"
                );
				if(showQuantityComplete()){
					array_push($columnNames, "Quantity Completed");
				}

				$fileName = "overview_data.csv";

				$numRows = sizeof($overviewData);
				for($i=0; $i<$numRows; $i++)
				{
					$overviewData[$i]["description"] = $overviewData[$i]["description"];
					$overviewData[$i]["problems"] = $overviewData[$i]["problems"];
				}
                    
               sendCsvToClient($overviewData, $dataNames, $columnNames, $fileName);
            }
            else
            {   
				$returnArray = array("overviewData"=>$overviewData, "updateRequestNumber"=>$updateRequestNumber);
                sendResponseToClient("success", $returnArray);
            }
            break;
                
        case "getConnectedClients":
            printDebug("FetchingConnectedClients");
            $connectedClientData = getConnectedClients($dbConn);
            sendResponseToClient("success",$connectedClientData);
            break;
		
		case "getConfigShowQtyComplete":
			printDebug("Fetching response for Qty Complete");
			if(showQuantityComplete($dbConn))
			{
				sendResponseToClient("success", "true");
			}
			else
			{
				sendResponseToClient("success", "false");
			}
			break;

            
        default:
            sendResponseToClient("error","Unknown command: $request");
    }
}

main();

?>
