<?php

require "client_config.php";
$jobId = $_GET["jobId"]; 
 
//use config variables
if($showChargeDisplayElements)
{
	$hidenChargeDisplayElements="";
}
else
{
	$hidenChargeDisplayElements="hidden";
}
if($showQuantityDisplayElements)
{
	$hidenQuantityDisplayElements="";	
}
else
{
	$hidenQuantityDisplayElements="hidden";
}
?>
<!DOCTYPE html>
<meta charset="utf-8">
<html>
    <head>
		<!-- //  Copyright 2022 DigitME2

		//  Licensed under the Apache License, Version 2.0 (the "License");
		//  you may not use this file except in compliance with the License.
		//  You may obtain a copy of the License at

		//      http://www.apache.org/licenses/LICENSE-2.0

		//  Unless required by applicable law or agreed to in writing, software
		//  distributed under the License is distributed on an "AS IS" BASIS,
		//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
		//  See the License for the specific language governing permissions and
		//  limitations under the License. -->
		<title>DigitME2 - PTT</title>
		<link rel="icon" type="image/x-icon" href="favicon.ico">
        <script src="../scripts/client/jquery.js"></script>
        <script src="../scripts/client/job_details.js"></script>
        <script src="../scripts/client/generate_table_generic.js"></script>
        <script>
			var includeQuantity = <?php echo("'$showQuantityDisplayElements'"); ?>;

            $(document).ready(function(){
				enableTimePeriod()
                loadJobRecord(<?php echo("'$jobId'"); ?>);
				checkIdChanged();
				updateJobLogTable(<?php echo("'$jobId'"); ?>);
				updateStoppagesLogTable(<?php echo("'$jobId'"); ?>);
				setUpKeyPress(<?php echo("'$jobId'"); ?>);

            });
        </script>
        <link rel="stylesheet" href="../css/common.css" type="text/css">
		<link rel="stylesheet" href="../css/job_details.css" type="text/css">
    </head>
    <body>
		<div class="pageContainer">
		    <div id ="commonHeader">
					<?php include "header.html" ?>
			</div>
			<h1>Job Record</h1>
		    <div id="pageMainBody">                
				<div id="jobDetails">
					<label for="jobName" class="jobDetailLabel">Job Name</label>
					<input id="jobName" type="text" class="jobDetail" pattern="^[a-zA-Z0-9_]{1,20}$"/>
					<span id="jobNameCounter" class="inputWidthCounter"></span>

					<label for="jobId" class="jobDetailLabel">Job ID</label>
					<input id="jobId" class="jobDetail" pattern="^[a-zA-Z0-9_]{1,20}$" value=<?php echo($jobId); ?>></input>
					<span id="jobIdCounter" class="inputWidthCounter"></span>
					
					<label for="currentStatusLabel" class="jobDetailLabel">Current Status</label>
					<span id="currentStatus" class="jobDetail"></span>

					<label for="productId" class="jobDetailLabel">Product</label>
					<span id="productId" class="jobDetail"></span>
					
					<label for="routeName" class="jobDetailLabel">Production Route Name</label>
					<select id="routeName" class="jobDetail" onchange="updateRouteDescription()"></select>
					
					<label for="routeStage" class="jobDetailLabel">Production Route Stage</label>
					<select id="routeStage" class="jobDetail"></select>
					
					<label for="customerName" class="jobDetailLabel">Customer Name</label>
					<input id="customerName" type="text" class="jobDetail" pattern="^.{0,120}$"/>
					<span id="customerNameCounter" class="inputWidthCounter"></span>
					
					<label for="description" class="jobDetailLabel">Description</label>
					<input id="description" type="text" class="jobDetail" pattern="^.{0,200}$"/>
					<span id="descriptionCounter" class="inputWidthCounter"></span>
					
					<label for="numUnits" class="jobDetailLabel">Number of units</label>
					<input id="numUnits" type="number" class="jobDetail" min="0"/>
					
					<label for="totalParts" class="jobDetailLabel">Total Parts</label>
					<input id="totalParts" type="number" class="jobDetail" min="0"/>
					
					<label for="dueDate" class="jobDetailLabel">Due Date</label>
					<input id="dueDate" type="date" class="jobDetail"/>
					
					<label for="expectedDuration" class="jobDetailLabel">Expected Duration</label>
					<input id="expectedDuration" type="text" class="jobDetail" pattern="^\d+:[0-5][0-9]?$" placeholder="HH:MM"/>	
					
					<label for="workedTime" class="jobDetailLabel">Total Worked Time</label>
					<span id="workedTime" class="jobDetail"></span>
					
					<label for="overtime" class="jobDetailLabel">Total Overtime</label>
					<span id="overtime" class="jobDetail"></span>
					
					<label for="chargeToCustomer" class="jobDetailLabel" >Charge to Customer (£)</label>
					<input id="chargeToCustomer" class="jobDetail" type="number" step="0.01" min="0" />
					
					<label for="chargeGenerated" class="jobDetailLabel" <?php echo($hidenChargeDisplayElements); ?>>Generated Value per Minute (£)</label>
					<span id="chargeGenerated" class="jobDetail" <?php echo($hidenChargeDisplayElements); ?>></span>
					
					<label for="priority" class="jobDetailLabel">Priority</label>
					<select id="priority"class="jobDetail">
						<option value=0>None</option>
						<option value=1>Low</option>
						<option value=2>Medium</option>
						<option value=3>High</option>
						<option value=4>Urgent</option>
					</select>

					<label for="recordAdded" class="jobDetailLabel">Job Created</label>
					<span id="recordAdded" class="jobDetail"></span>

					<div id="notesContainer" class="jobDetailsHeader">
						<label for="notesField" class="jobDetailLabel">Notes:</label>
						<br>
						<textarea id="notesField" class="jobDetail" rows="10" cols="50" wrap="hard"></textarea>
						<br>
					</div>

					<span id="adminControls">
						<input type="button" id="btnMarkComplete" disabled="true" value="Mark Job Complete" onclick="markJobComplete(<?php echo("'$jobId'"); ?>)"/>
						<input type="button" id="btnDelete" disabled="true" value="Delete Job" onclick="deleteJob(<?php echo(("'$jobId'"))?>)"/>
					</span>

					<input id="btnSaveChanges" type="button" value="Save Changes" onclick=<?php echo('saveRecord("' . $jobId . '")'); ?> />
					<br>
					<div id="downloadLinkContainer" class="jobDetailsHeader">
							<span>Loading...</span>
					</div>
					
					<span id="saveChangesFeedback"></span>
				</div>			
				
				<div id="stoppagesContainer">
					<h2>Problems:</h2>
					<div id="addStoppageInputContainer">
						<select id="addStoppageStationDropDown" class="addStoppageInput"></select>
						<select id="addStoppageReasonDropDown" class="addStoppageInput"></select>
						<textarea id="stoppageDescription" class="addStoppageInput" rows="2" wrap="hard" placeholder="Description" maxlength="2000"></textarea>
						<input type="button" id="btnAddStoppage" disabled="true" value="Add Problem" onclick="addStoppageBtnPress(<?php echo(("'$jobId'"))?>)"/>
					</div>					
					<br>
					<span id="addStoppageFeedback"></span>
					<div id=stoppagesLogTableDisplay>
		            	<div id=stoppagesLogTableContainer></div>
		            </div>
					<br>
				</div>

		        <div id="timeLogContainer">
					<h2>Work Log</h2>
					<div id="workLogOptions">
						<div id="useDateRangeSelectArea">
					        <input type="checkbox" id="useDateRange" class="tableControl" onchange="enableTimePeriod()" >
					        <label id="useDateRangeLabel" for="useDateRange">Display records between start and end dates</label>
						</div>

			            <label id="dateStartInputLabel" for="dateStartInput" >Start date:</label>
			            <input type="date" id="dateStartInput" class="tableControl">
			            <label id="dateEndInputLabel" for="dateEndInput" >End date:</label>
			            <input type="date" id="dateEndInput" class="tableControl">

						<input type="button" id="updateJobsTable" class="tableControl" value="Update table"  onclick=<?php echo('updateJobLogTable("' . $jobId . '")'); ?>>
						<div id="collapseRecordsSelectArea">
							<input type="checkbox" id="collapseRecords" class="tableControl"  onclick=<?php echo('updateJobLogTable("' . $jobId . '")'); ?> />
							<label id="collapseRecordsLabel" for="collapseRecords">Collapse Records</label>
						</div>

						<label id="timeLogWorkedTimeLabel" for="timeLogWorkedTime" hidden>Worked time in the selected date range</label>
						<span id="timeLogWorkedTime"></span>
						<label id="timeLogOvertimeLabel" for="timeLogOvertime" hidden>Overtime in the selected date range</label>
						<span id="timeLogOvertime"></span>

			            <a id="csvDownloadLink" href="" download type="text/plain" class="tableControl" hidden>Click here to download the currently displayed table as CSV</a>
						
						<input type="button" id="addWorkLogbtn" value="Add new work log" onclick="addWorkLog();">

							<button id=transferWorkLogbtn type="button" onclick="window.location.href='../pages/transfer_work_log_client.php?jobId=<?php echo($jobId); ?>'">Transfer work log</button>
					
						</div>

					<div id=tableDisplay>
		            	<div id=recordsTableContainer></div>
		            </div>
		        </div>
		    </div>
	    </div>
		<div id ="commonFooter">
			<?php include "footer.html" ?>
		</div>
    </body>
</html>
