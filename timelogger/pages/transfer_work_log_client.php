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
$jobId = $_GET["jobId"]; 

//use config variables
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
		<title>DigitME2 - PTT</title>
		<link rel="icon" type="image/x-icon" href="favicon.ico">
        <script src="../scripts/client/jquery.js"></script>
        <script src="../scripts/client/transfer_work_log.js"></script>
        <script src="../scripts/client/generate_table_generic.js"></script>
        <script>
            var includeQuantity = <?php echo("'$showQuantityDisplayElements'"); ?>;
            $(document).ready(function(){
				GenerateJobLogTable(<?php echo("'$jobId'"); ?>);
                var JobName = getJobName(<?php echo("'$jobId'"); ?>);
            });
            var JobId = <?php echo("'$jobId'");  ?>
        </script>
        <link rel="stylesheet" href="../css/common.css" type="text/css">
		<link rel="stylesheet" href="../css/transfer_work_log.css" type="text/css">
        <link rel="stylesheet" href="../css/job_details.css" type="text/css">
    </head>
    <body>
        <div class="pageContainer">
            <div id ="commonHeader">
				<?php include "header.html" ?>
			</div>
            <div class="pageMainBody">
                
                <h1>Transfer Work Log</h1>
                <h2>Select New Job ID for work log transfer:</h2>
                <div>

                    <label for="jobSearchLabel">Search for a New Job Name</label>
                    <input type="text" id="searchPhrase" class="jobSearchLabel" placeholder="enter a Job Name" oninput="searchJobs()">
                    <br>
                    <br>
                    <label id="jobIdLabel" for="jobIdDropDown"  class="jobSearchLabel">Select a New Job Name</label>
                    <select class="jobSearchInput" id="jobIdDropDown"></select>
                    <br>
                    <br>
                    <span id="spanFeedback"/>

                </div>
                <hr>
                <div>
                    <h2 id="workLogHeader">The work log of job</h2>
                    <h4 id="jobNameDisplay">Job Name: <span id="jobNameField"/></h4>
                    <h4 id="jobIdDisplay">Job ID:  <?php echo($jobId); ?></h4>
                    <div id=tableDisplay>
		            	<div id=workLogRecordContainer></div>
                        <div id=recordsTableContainer></div>
                        <br>
                        <span id=JobId <?php echo("'$jobId'");  ?> >
                        <input id="transferWorkLogbtn" type="button" disabled="true" value="Transfer Log" onclick="transferWorkLog()">
                        <input id="clearbtn" type="button" value="Clear"  onclick="clearBtn()">
                        <span id="transferWorkLogResponseField"/>
                        <br>
                        <br>
                    </div>
                </div>
            </div>
        </div>
				
		<div id ="commonFooter">
			<?php include "footer.html" ?>
		</div>
    </body>
</html>