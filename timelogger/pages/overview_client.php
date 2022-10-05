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

require "client_config.php";
require "../scripts/server/systemConfig.php";

if($showChargeDisplayElements)
{
	$hidenChargeDisplayElements="";
	$checkedChargeDisplayElements="checked";
}
else
{
	$hidenChargeDisplayElements="hidden";
	$checkedChargeDisplayElements="";
}

if($showQuantityDisplayElements)
{
	$hidenQuantityDisplayElements="";
	$checkedQuantityDisplayElements="checked";
}
else
{
	$hidenQuantityDisplayElements="hidden";
	$checkedQuantityDisplayElements="";
}


?>
<!DOCTYPE html>
<meta charset="utf-8">
<html>
    <head>
        <script src="../scripts/client/jquery.js"></script>
        <script src="../scripts/client/overview.js"></script>
        <script src="../scripts/client/generate_table_generic.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/js-cookie@rc/dist/js.cookie.min.js"></script>
        <link rel="stylesheet" href="../css/common.css" type="text/css">
        <link rel="stylesheet" href="../css/overview.css" type="text/css">
		<script>
			$(document).ready(function(){
				$("#overview_client_nav_link").addClass("navActive");
			});
		</script>
    </head>
    <body>
        <div class="pageContainer">
            <div id ="commonHeader">
				<?php include "header.html" ?>
			</div>
            <div class="pageMainBody">                                
                <div id="currentJobsDisplay">
                    <h1 id="currentJobsTitle">Current Jobs</h1>
					<div id="hideControlsToggleContainer">
						<input type="checkbox" id="showControlsCheckbox" checked onchange="setControlVisibility()"/>
						<label for="showControlsCheckbox">Show Controls</label>
					</div>
                    <div id="currentJobsDisplayControls" class="controls">
						<div id="sortingOptions">
							<h2>Sorting options</h2>
							<input type="radio" id="sortByCreatedNewest" name="tableOrdering" value="createdNewestFirst" class="tableControl" onchange="sortRadioChange(); onTableDataOptionsChange()">
							<label for="sortByCreatedNewest">Sort by when jobs were added (newest first)</label>
							<br>
							<input type="radio" id="sortByCreatedOldest" name="tableOrdering" value="createdOldestFirst" class="tableControl" onchange="sortRadioChange(); onTableDataOptionsChange()">
							<label for="sortByCreatedOldest">Sort by when jobs were added (oldest first)</label>
							<br>
							<input type="radio" id="sortByDueSoonest" name="tableOrdering" value="dueSoonestFirst" class="tableControl" onchange="sortRadioChange(); onTableDataOptionsChange()">
							<label for="sortByDueSoonest">Sort by when jobs are due (soonest first)</label>
							<br>
							<input type="radio" id="sortByDueLatest" name="tableOrdering" value="dueLatestFirst" class="tableControl" onchange="sortRadioChange(); onTableDataOptionsChange()">
							<label for="sortByDueLatest">Sort by when jobs are due (latest first)</label>
							<br>
							<input type="radio" id="sortAlphabetic" name="tableOrdering" value="alphabetic" class="tableControl" onchange="sortRadioChange(); onTableDataOptionsChange()">
							<label for="sortAlphabetic">Sort alphabetically by job ID</label>
							<br>
							<input type="radio" id="sortByPriority" name="tableOrdering" value="priority" class="tableControl" onchange="sortRadioChange(); onTableDataOptionsChange()">
							<label for="sortByPriority">Sort by priority</label>
							<br>
							<br>
							<input type="checkbox" id="showUrgentJobsFirst" class="tableControl" onchange="onTableDataOptionsChange()">
							<label id="showUrgentJobsFirstLabel" for="showUrgentJobsFirst">Show urgent jobs first</label>
							<br>
							<input type="checkbox" id="subSortByPriority" class="tableControl" onchange="onTableDataOptionsChange()">
							<label id="subSortByPriorityLabel" for="subSortByPriority">Sub-sort by priority</label>
						</div>
						
						<div id="searchOptions">
							<h2>Search jobs</h2>
							<div id="dateCreatedRangeSelection">
								<input type="checkbox" id="useDateCreatedRange" class="tableControl searchDateCheckBox" onchange="enableTimePeriod('Created', updateTable=true)">
								<label for="useDateCreatedRange">Display jobs created within selected time period</label>
								<br>
								<div class="searchDateDiv">
									<label for="dateCreatedStartInput">Start date:</label>
									<input type="date" id="dateCreatedStartInput" class="tableControl" onchange="onTableDataOptionsChange()">
								</div>
								<div class="searchDateDiv">
									<label for="dateCreatedEndInput">End date:</label>
									<input type="date" id="dateCreatedEndInput" class="tableControl" onchange="onTableDataOptionsChange()">
								</div>
							</div>
							<br>
							<div id=dateDueRangeSelection>
								<input type="checkbox" id="useDateDueRange" class="tableControl searchDateCheckBox" onchange="enableTimePeriod('Due', updateTable=true)">
								<label for="useDateDueRange">Display jobs due within selected time period</label>
								<br>
								<div class="searchDateDiv">
									<label for="dateDueStartInput">Start date:</label>
									<input type="date" id="dateDueStartInput" class="tableControl" onchange="onTableDataOptionsChange()">
								</div>
								<div class="searchDateDiv">
									<label for="dateDueEndInput">End date:</label>
									<input type="date" id="dateDueEndInput" class="tableControl" onchange="onTableDataOptionsChange()">
								</div>
							</div>
							<br>
							<div id=dateTimeWorkedRangeSelection>
								<input type="checkbox" id="useDateTimeWorkedRange" class="tableControl searchDateCheckBox" onchange="enableTimePeriod('TimeWork', updateTable=true)">
								<label for="useDateTimeWorkedRange">Display time worked within selected time period</label>
								<br>
								<div class="searchDateDiv">
									<label for="dateTimeWorkStartInput">Start date:</label>
									<input type="date" id="dateTimeWorkStartInput" class="tableControl" onchange="onTableDataOptionsChange()">
								</div>
								<div class="searchDateDiv">
									<label for="dateTimeWorkEndInput">End date:</label>
									<input type="date" id="dateTimeWorkEndInput" class="tableControl" onchange="onTableDataOptionsChange()">
								</div>
								<input type="checkbox" id="excludeUnworkedJobs" class="tableControl" onchange="onTableDataOptionsChange()">
								<label for="excludeUnworkedJobs">Exclude Jobs unworked in this selected time period</label>
							</div>
							<div id="searchText">
								<!--<input type="checkbox" id="useSearchPhrase" class="tableControl">
								<label for="useSearchPhrase">Display jobs containing the specified text</label>-->
								<br>
								<label for="searchPhrase">Search Phrase:</label>
								<input type="text" id="searchPhrase" class="tableControl" placeholder="enter search phrase" oninput="onTableDataOptionsChange()"/>
							</div>
							<br>
							<input type="checkbox" id="showOnlyUrgentJobs" class="tableControl" onchange="onTableDataOptionsChange()">
							<label for="showOnlyUrgentJobs">Only show urgent jobs</label>
							<br>
							<br>
							<input type="checkbox" id="showPendingJobs" class="tableControl" onchange="onTableDataOptionsChange()">
							<label for="showPendingJobs">Show Pending Jobs</label>
							<br>
							<input type="checkbox" id="showWorkInProgressJobs" class="tableControl" onchange="onTableDataOptionsChange()">
							<label for="showWorkInProgressJobs">Show Work In Progress Jobs</label>
							<br>
							<input type="checkbox" id="showCompletedJobs" class="tableControl" onchange="onTableDataOptionsChange()">
							<label for="showCompletedJobs">Show Completed Jobs</label>
						</div>
						
						<div id="displayOptions">
							<h2>Display options</h2>
							<div id="displayOptionsListContainer">
								<label for="warningHighlightDaysCount">Close to due date count:</label>
								<input id="warningHighlightDaysCount" type="number" onchange="onDisplayOptionsChange()" min="0"/>

								<label for="showDeadlineWarningHighlight">Highlight jobs with close/overdue deadline</label>
								<input type="checkbox" id="showDeadlineWarningHighlight" onchange="onDisplayOptionsChange()"/>

								<label for="highlightPriority">Highlight Priority</label>
								<input type="checkbox" id="highlightPriority"  onchange="onDisplayOptionsChange()"/>
								
								<label for="showProductId">Show product ID</label>
								<input type="checkbox" id="showProductId" onchange="onDisplayOptionsChange()"/>

								<label for="showCustomerName">Show customer Name</label>
								<input type="checkbox" id="showCustomerName" onchange="onDisplayOptionsChange()"/>

								<label for="showDescription">Show description</label>
								<input type="checkbox" id="showDescription" onchange="onDisplayOptionsChange()"/>
								
								<label for="showNumberOfUnits">Show number of units</label>
								<input type="checkbox" id="showNumberOfUnits" onchange="onDisplayOptionsChange()"/>
								
								<label for="showTotalParts">Show total parts</label>
								<input type="checkbox" id="showTotalParts" onchange="onDisplayOptionsChange()"/>
								
								<label for="showCurrentStatus">Show current status</label>
								<input type="checkbox" id="showCurrentStatus" onchange="onDisplayOptionsChange()"/>
								
								<label for="showRouteStage">Show stage of production</label>
								<input type="checkbox" id="showRouteStage" onchange="onDisplayOptionsChange()"/>		
								
								<label for="showJobCreated">Show job created timestamp</label>
								<input type="checkbox" id="showJobCreated" onchange="onDisplayOptionsChange()"/>

								<label for="showDueDate">Show due date</label>
								<input type="checkbox" id="showDueDate" onchange="onDisplayOptionsChange()"/>

								<label for="showExpectedDuration">Show expected duration</label>
								<input type="checkbox" id="showExpectedDuration" onchange="onDisplayOptionsChange()"/>

								<label for="showWorkedTime">Show total worked time</label>
								<input type="checkbox" id="showWorkedTime" onchange="onDisplayOptionsChange()"/>

								<label for="showOvertime">Show total overtime</label>
								<input type="checkbox" id="showOvertime" onchange="onDisplayOptionsChange()"/>

								<label for="showEfficiency">Show job efficiency</label>
								<input type="checkbox" id="showEfficiency" onchange="onDisplayOptionsChange()"/>

								<label for="showStoppages">Show problems</label>
								<input type="checkbox" id="showStoppages" onchange="onDisplayOptionsChange()"/>
								
								<label for="showChargePerMinute" <?php echo($hidenChargeDisplayElements); ?>>Show Charge Per Minute</label>
								<input type="checkbox" id="showChargePerMinute" onchange="onDisplayOptionsChange()" <?php echo($hidenChargeDisplayElements); ?> <?php echo($checkedChargeDisplayElements); ?>/>
								
								<label for="showTotalChargeToCustomer" <?php echo($hidenChargeDisplayElements); ?>>Show Total Charge To Customer</label>
								<input type="checkbox" id="showTotalChargeToCustomer" onchange="onDisplayOptionsChange()" <?php echo($hidenChargeDisplayElements); ?> <?php echo($checkedChargeDisplayElements); ?>/>
								
								<label for="showNotes">Show Notes</label>
								<input type="checkbox" id="showNotes" onchange="onDisplayOptionsChange()"/>

								<label for="showQuantityComplete" <?php if(showQuantityComplete()==false){ echo("hidden"); } ?> >Show Quantity Completed</label>
								<input type="checkbox" id="showQuantityComplete" onchange="onDisplayOptionsChange()" <?php if(showQuantityComplete()==false){ echo("hidden"); } ?>/>
								
								<label for="retainDisplayOptions">Retain Display Options</label>
								<input type="checkbox" id="retainDisplayOptions" onchange="onDisplayOptionsChange()"/>


							</div>
						</div>

						<div id="tableKey">
							<h2>Key</h2>
							<table>
								<tr class="row_overdue highlight">
									<td>Overdue</td>
								</tr>
								<tr class="row_late_risk highlight">
									<td>Close to Overdue</td>
								</tr>
								<tr class="priority_Urgent highlight">
									<td>Urgent</td>
								</tr>
								<tr class="priority_High highlight">
									<td>Hight Priority</td>
								</tr>
								<tr class="priority_Medium highlight">
									<td>Medium Priority</td>
								</tr>
								<tr class="priority_Low highlight">
									<td>Low Priority</td>
								</tr>
							</table>
							
						</div>						
						
						<div id="tableControls">
							<a id="csvDownloadLink" href="" download type="text/css" class="tableControl" >Click here to download current data as CSV</a>
							<br>
							<input type="button" id="updateJobsTableButton" onclick="onUpdateTableButtonClick()" class="tableControl" value="Update table">
						</div>
                        
                    </div>
					<br>
                    <div id=currentJobsTableContainer>
                        <span id="tablePlaceholder">Loading...</span>
                    </div>
                </div>
            </div>
        </div>
		<div id ="commonFooter">
			<?php include "footer.html" ?>
		</div>
    </body>
</html>