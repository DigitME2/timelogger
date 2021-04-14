<?php 
require "client_config.php";
$workLogRef = $_GET["workLogRef"]; 

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
        <script src="../scripts/client/jquery.js"></script>
        <script src="../scripts/client/work_log_event.js"></script>
        <script src="../scripts/client/generate_table_generic.js"></script>
        <script>
			var includeQuantity = <?php echo("'$showQuantityDisplayElements'"); ?>;

            $(document).ready(function(){
                loadWorkLogRecord(<?php echo("'$workLogRef'"); ?>);
				setUpKeyPress(<?php echo("'$workLogRef'"); ?>);
            });
        </script>
        <link rel="stylesheet" href="../css/common.css" type="text/css">
		<link rel="stylesheet" href="../css/work_log_event.css" type="text/css">
    </head>
    <body>
        <div class="pageContainer">
            <div id ="commonHeader">
				<?php include "header.html" ?>
			</div>
            <div class="pageMainBody">
                
                <h1>Work Log Record</h1>
				<div id=tableDisplay>
                	<div id=recordsTableContainer></div>
                </div>
                <div id="logEventDetails">
					<label for="jobId" class="logEventLabel">Job ID</label>
					<span id="jobId" class="logEventInfo"></span>

					<label for="stationId" class="logEventLabel">Station</label>
					<select id="stationId" class="logEventInfo" disabled></select>

					<label for="userName" class="logEventLabel">UserName</label>
					<span id="userName" class="logEventInfo"></span>

					<label for="date" class="logEventLabel">Date</label>
					<span id="date" class="logEventInfo"></span>

					<label for="startTime" class="logEventLabel">Start Time</label>
					<input id="startTime" type="time" step=1 class="logEventInfo"/>

					<label for="endTime" class="logEventLabel">End Time</label>
					<input id="endTime" type="time" step=1 class="logEventInfo"/>

					<label for="duration" class="logEventLabel">Duration(HH:MM)</label>
					<span id="duration" class="logEventInfo"></span>

					<label for="overtime" class="logEventLabel">Overtime(HH:MM)</label>
					<span id="overtime" class="logEventInfo"></span>

					<label for="status" class="logEventLabel">Job Status at Station</label>
					<select id="status" class="logEventInfo">
						<option value='pending'>Pending</option>
						<option value='workInProgress'>Work in Progress</option>
						<option value='stageComplete'>Stage Complete</option>
						<option value='unknown'>Unknown</option>
						<option value='complete'>Complete</option>
					</select>

					<label for="quantityComplete" class="logEventLabel" <?php echo($hidenQuantityDisplayElements); ?> >Quantity Complete</label>
					<input type="number" max="999999999" id="quantityComplete" class="logEventInfo" <?php echo($hidenQuantityDisplayElements); ?> ></input>

					<input id="btnSaveChanges" type="button" value="Save Changes" class="controlButton" onclick=<?php echo('saveRecord("' . $workLogRef . '")'); ?> />
					<input id="btnDeleteEvent" type="button" value="Delete"  class="controlButton" onclick=<?php echo('deleteEvent("' . $workLogRef . '")'); ?> />
					<br>
					<span id="saveChangesFeedback"></span>
				</div>

           		<hr>
				
				<div id="divInsertBreak">
					<h2>Insert Break</h1>

					<label for="breakStartTime" class="insertBreakLabel">Start Time</label>
					<input id="breakStartTime" type="time" step=1 class="insertBreakTime"/>

					<label for="breakEndTime" class="insertBreakLabel">End Time</label>
					<input id="breakEndTime" type="time" step=1 class="insertBreakTime"/>

					<input id="btnInsertBreak" type="button" value="Insert" class="controlButton" onclick=<?php echo('insertBreak("' . $workLogRef . '")'); ?> />
					
					<span id="insertBreakFeedback"></span>

				</div>
            </div>
        </div>	
		<div id ="commonFooter">
			<?php include "footer.html" ?>
		</div>
    </body>
</html>
