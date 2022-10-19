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

if($showLunchTimesElements)
{
	$hidenLunchTimesElements="";
	$columnTemplateStyle="\"--work-hours-number-columns: var(--work-hours-number-columns-lunch);\"";
}
else
{
	$hidenLunchTimesElements="hidden";
	$columnTemplateStyle="\"--work-hours-number-columns: var(--work-hours-number-columns-normal);\"";
}
?>

<!DOCTYPE html>
<meta charset="utf-8">
<html>
    <head>
        <title>digitME2 - PTT</title>
		<link rel="icon" type="image/x-icon" href="favicon.ico">
        <script src="../scripts/client/jquery.js"></script>
        <script src="../scripts/client/work_hours.js"></script>
		<script>
		$(function(){
			$("#commonHeader").load("header.html", function activePage(){
					var pageName = window.location.pathname.split("/").pop().split(".")[0];
					$("#" + pageName + "_nav_link").addClass("navActive");
				});
			$("#commonFooter").load("footer.html");
		});
		</script>
        <link rel="stylesheet" href="../css/common.css" type="text/css">
        <link rel="stylesheet" href="../css/work_hours.css" type="text/css">
    </head>
    <body>
        <div class="pageContainer">
            <div id ="commonHeader"></div>
            <br>
            <div class="pageMainBody">
				<h1 id="workHoursHeader">Work Hours</h1>
                <div id="timeDisplay">					
                    <span>Start and end times for each day (24 hr)</span>
                   
                    <div id="timeSettingContainer" style=<?php echo($columnTemplateStyle); ?> >


							<label for="mondayStart" class="headerLabel"></label>
							<label for="mondayStart" class="headerLabel">Day Start</label>
							<label for="mondayStart" class="headerLabel" <?php echo($hidenLunchTimesElements); ?>>Lunch Start</label>
							<label for="mondayStart" class="headerLabel" <?php echo($hidenLunchTimesElements); ?>>Lunch Finish</label>
							<label for="mondayStart" class="headerLabel">Day Finish</label>

                            <label for="mondayStart" class="dayLabel">Monday:</label>
                            <input type="time" id="mondayStart" class="timeDisplayStart">
							<input type="time" id="mondayLunchtimeStart" class="lunchtimeDisplayStart" <?php echo($hidenLunchTimesElements); ?>>
							<input type="time" id="mondayLunchtimeFinish" class="lunchtimeDisplayEnd" <?php echo($hidenLunchTimesElements); ?>>
                            <input type="time" id="mondayFinish" class="timeDisplayEnd">
						
                            <label for="tuesdayStart" class="dayLabel">Tuesday:</label>
                            <input type="time" id="tuesdayStart" class="timeDisplayStart">
							<input type="time" id="tuesdayLunchtimeStart" class="lunchtimeDisplayStart" <?php echo($hidenLunchTimesElements); ?>>
							<input type="time" id="tuesdayLunchtimeFinish" class="lunchtimeDisplayEnd" <?php echo($hidenLunchTimesElements); ?>>
                            <input type="time" id="tuesdayFinish" class="timeDisplayEnd">
						
                            <label for="wednesdayStart" class="dayLabel">Wednesday:</label>
                            <input type="time" id="wednesdayStart" class="timeDisplayStart">
							<input type="time" id="wednesdayLunchtimeStart" class="lunchtimeDisplayStart" <?php echo($hidenLunchTimesElements); ?>>
							<input type="time" id="wednesdayLunchtimeFinish" class="lunchtimeDisplayEnd" <?php echo($hidenLunchTimesElements); ?>>
                            <input type="time" id="wednesdayFinish" class="timeDisplayEnd">
						
                            <label for="thursdayStart" class="dayLabel">Thursday:</label>
                            <input type="time" id="thursdayStart" class="timeDisplayStart">
							<input type="time" id="thursdayLunchtimeStart" class="lunchtimeDisplayStart" <?php echo($hidenLunchTimesElements); ?>>
							<input type="time" id="thursdayLunchtimeFinish" class="lunchtimeDisplayEnd" <?php echo($hidenLunchTimesElements); ?>>
                            <input type="time" id="thursdayFinish" class="timeDisplayEnd">
						
                            <label for="fridayStart" class="dayLabel">Friday</label>
                            <input type="time" id="fridayStart" class="timeDisplayStart">
							<input type="time" id="fridayLunchtimeStart" class="lunchtimeDisplayStart" <?php echo($hidenLunchTimesElements); ?>>
							<input type="time" id="fridayLunchtimeFinish" class="lunchtimeDisplayEnd" <?php echo($hidenLunchTimesElements); ?>>
                            <input type="time" id="fridayFinish" class="timeDisplayEnd">
						
                            <label for="saturdayStart" class="dayLabel">Saturday:</label>
                            <input type="time" id="saturdayStart" class="timeDisplayStart">
							<input type="time" id="saturdayLunchtimeStart" class="lunchtimeDisplayStart" <?php echo($hidenLunchTimesElements); ?>>
							<input type="time" id="saturdayLunchtimeFinish" class="lunchtimeDisplayEnd" <?php echo($hidenLunchTimesElements); ?>>
                            <input type="time" id="saturdayFinish" class="timeDisplayEnd">
						
                            <label for="sundayStart" class="dayLabel">Sunday:</label>
                            <input type="time" id="sundayStart" class="timeDisplayStart">
							<input type="time" id="sundayLunchtimeStart" class="lunchtimeDisplayStart" <?php echo($hidenLunchTimesElements); ?>>
							<input type="time" id="sundayLunchtimeFinish" class="lunchtimeDisplayEnd" <?php echo($hidenLunchTimesElements); ?>>
                            <input type="time" id="sundayFinish" class="timeDisplayEnd">
                    </div>
                    <!-- multiple clock on has been disabled, but left in case of future use
					<input type="checkbox" id="allowMultipleClockOn">
					<label for="allowMultipleClockOn">Allow users to clock onto multiple jobs simultaneously</label>
					<br>
					-->
					
                    <input type="button" id="saveButton" value="Save" onclick="setWorkHours()">
                    <br>
                    <span id="saveResponseField"></span>
                    
                </div>
            </div>
        </div>
		<div id ="commonFooter"></div>
    </body>
</html>
