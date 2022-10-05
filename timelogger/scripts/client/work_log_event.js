/* Copyright 2022 DigitME2

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */

$(document).ready(function(){



});

function setUpKeyPress(workLogRef){
	$(".logEventInfo").keypress(function(e) {
		var keycode = (e.keycode ? e.keycode : e.which)
		if (keycode == 13){
			saveRecord(workLogRef);
		}
	});

	$(".insertBreakTime").keypress(function(e) {
		var keycode = (e.keycode ? e.keycode : e.which)
		if (keycode == 13){
			insertBreak(workLogRef);
		}

	});
}

function beginLoad(workLogRef){
	var scannerNamesLoaded = false;
	var userNamesLoaded = false;

	$.ajax({
		url:"../scripts/server/scanners.php",
		type:"GET",
		dataType:"text",
		data:{
			"request":"getAllScannerNames"
		},
		success:function(result){
			console.log(result);
			resultJson = $.parseJSON(result);
			if(resultJson["status"] != "success")
				console.log(resultJson["result"]);
			else{
				scannerNamesLoaded = true;
				var scannerNames = resultJson.result;

				$("#stationId").empty();
				for(var i = 0; i < scannerNames.length; i++){
					var newOption = $("<option>")
						.text(scannerNames[i])
						.attr("value", scannerNames[i]);
					$("#stationId").append(newOption);
				
				}
				if(scannerNamesLoaded && userNamesLoaded){
					loadWorkLogRecord(workLogRef)
				}

			}
		}
	});
	
	$.ajax({
		url:"../scripts/server/users.php",
		type:"GET",
		dataType:"text",
		data:{
			"request":"getUserTableData",
			"tableOrdering": "byAlphabetic"
		},
		success:function(result){
			console.log(result);
			resultJson = $.parseJSON(result);
			if(resultJson["status"] != "success")
				console.log(resultJson["result"]);
			else{
				userNamesLoaded = true;
				var users = resultJson.result;

				$("#userslist").empty();
				for(var i = 0; i < users.length; i++){
					var newOption = $("<option>")
						.html(users[i]["userName"])
						.attr("value", users[i]["userId"]);
					$("#userslist").append(newOption);

				}

				if(scannerNamesLoaded && userNamesLoaded){
					loadWorkLogRecord(workLogRef)
				}
			}
		}
	});
	
}

function loadWorkLogRecord(workLogRef){
	//load the active scanner and information about the work log event and populate page
	disableControls(true);
	$.ajax({
		url:"../scripts/server/work_log_event.php",
		type:"GET",
		dataType:"text",
		data:{
			"request":"getWorkLogRecord",
			"workLogRef":workLogRef
		},
		success:function(result){
			console.log(result);
			resultJson = $.parseJSON(result);
			
			if(resultJson["status"] != "success"){
				console.log("Failed to fetch event record: " + resultJson["result"]);
				$("#saveChangesFeedback").html("Failed to fetch event record");
				disableControls(true);
				return;
			}

			var record = resultJson.result;

			//Check if a record was returned
			if(record.jobId == null){
				disableControls(true);
				$("#btnSaveChanges").attr("disabled", true);
				$("#btnDeleteEvent").attr("disabled", true);
				$("#btnInsertBreak").attr("disabled", true);
				$("#quantityComplete").attr("disabled", true);
				$("#saveChangesFeedback").html("RECORD NOT FOUND");
				console.log("Record not found. stopping");
				return;
			}

			var options = $("#stationId").children();
			if (record.userName !== null){
				for (var i = 0; i < options.length; i++ ){
					var currentOption = $(options[i]);
					console.log(currentOption.val());
					console.log(record.stationId);
					if (currentOption.val() == record.stationId)
					{
						console.log(record.stationId);
						currentOption.prop("selected", true);
						break;
					}
				}	
			}
			var options = $("#userslist").children();
			if (record.userName !== null){
				for (var i = 0; i < options.length; i++ ){
					var currentOption = $(options[i]);
					console.log(currentOption.html());
					console.log(record.userName[0]);
					if (currentOption.html() == record.userName[0])
					{
						console.log(record.userName[0]);
						currentOption.prop("selected", true);
						break;
					}
				}
			}
			disableControls(false);
		
			//Populate Page
			$("#jobId").html(record.jobId);
			$("#recordDate").val(record.recordDate);
			$("#startTime").val(record.clockOnTime);
			$("#endTime").val(record.clockOffTime);
			$("#endTime").attr("disabled", false);
			$("#stationId").attr("disabled", false);
			$("#status").attr("disabled", false);
			$("#quantityComplete").attr("disabled", false);
			$("#duration").html(record.workedDuration);
			$("#overtime").html(record.overtimeDuration);
			$("#status").val(record.workStatus);
			$("#quantityComplete").val(record.quantityComplete);

			$("#btnSaveChanges").attr("disabled", true);
			
			if(inputsFormValidRecord()){
				enableControls();
			}

			// $("#stationId").attr("disabled", true);//Disable ability to edit station Id due to stage index timelog issue
			updateEventTable(record);	

			
		}
	});	
}

function enableControls(){
	if (inputsFormValidRecord() == true){
		$("#btnSaveChanges").attr("disabled", false);
	}
	else{
		console.log("Please fill all the entries!")
	}
}

function inputsFormValidRecord(){	
	if (($("#recordDate").val() !== "") && ($("#startTime").val() !== "")) {
		console.log(true);
		return true;
	}
	else{
		console.log(false);
		return false;
	}
}

function saveRecord(workLogRef){
	//save changes to record
	
	if(!$("#quantityComplete").prop('disabled') && !$("#quantityComplete").is(':valid'))
	{		
        $("#saveChangesFeedback").empty().html("Invalid Quantity!");
        setTimeout(function(){$("#saveChangesFeedback").empty();},10000);
	}
	else
	{
		disableControls(true);
		quantityComplete = $("#quantityComplete").val()

		$.ajax({
		    url:"../scripts/server/work_log_event.php",
		    type:"POST",
		    dataType:"text",
		    data:{
				"request":"saveRecordDetails",
				"workLogRef": workLogRef,
				"jobId": $("#jobId").val(),
				"userId":$("#userslist").val(),
				"recordDate": $("#recordDate").val(),
				"stationId": $("#stationId").val(),
				"clockOnTime": $("#startTime").val(),
				"clockOffTime": $("#endTime").val(),
				"workStatus": $("#status").val(),
				"quantityComplete": quantityComplete
		    },	
		    success:function(result, inputJobId){
		        console.log(result);
		        resultJson = $.parseJSON(result);
		        
		        if(resultJson["status"] != "success"){
		            console.log("Failed to save record: " + resultJson["result"]);
		            $("#saveChangesFeedback").empty().html(resultJson["result"]);
		            setTimeout(function(){$("#saveChangesFeedback").empty();},10000);
				}
				else{			
					$("#saveChangesFeedback").empty().html("Changes saved");
					setTimeout(function(){$("#saveChangesFeedback").empty();},10000);

					loadWorkLogRecord(workLogRef);
				}

				disableControls(false);
			}
		});
	}
}

function deleteEvent(workLogRef){

	if(confirm("Are you sure you want to delete Work Log Record?")){
		disableControls(true);
		
		$.ajax({
			url:"../scripts/server/work_log_event.php",
			type:"GET",
			dataType:"text",
			data:{
				"request":"deleteEventRecord",
				"workLogRef":workLogRef
			},
			success:function(result){
				console.log(result);
				var responseJson = $.parseJSON(result);

				if(responseJson['status'] == 'success'){

					$("#saveChangesFeedback").empty().html("Work Log Event Deleted, you should be redirected shortly...");

                    disableControls(true);

					location.href = "job_details_client.php?jobId=" + $("#jobId").html();
				}
				else
				{
					console.log(responseJson['result']);
					disableControls(false);
				}
			}
		});

	}
}

function insertBreak(workLogRef){
	//Insert Break, spliting record into two
	
    breakStartTime = $("#breakStartTime").val();
	breakEndTime = $("#breakEndTime").val();

	if (breakStartTime == "" || breakEndTime == "")
	{
		$("#insertBreakFeedback").empty().html("Enter full times for start and end of break!");
		setTimeout(function(){$("#insertBreakFeedback").empty();},10000);
		console.log("Input Error: Full time values not entered unable to insert break.");
		return;
	}

	disableControls(true, true);

	$.ajax({
        url:"../scripts/server/work_log_event.php",
        type:"POST",
        dataType:"text",
        data:{
			"request":"insertBreak",
			"workLogRef": workLogRef,
			"breakStart": breakStartTime,
			"breakEnd": breakEndTime
        },	
        success:function(result, inputJobId){
            console.log(result);
            resultJson = $.parseJSON(result);
            
            if(resultJson["status"] != "success"){
                console.log("Failed to insert break: " + resultJson["result"]);

                $("#insertBreakFeedback").empty().html(resultJson["result"]);
                setTimeout(function(){$("#insertBreakFeedback").empty();},10000);

				disableControls(false, true);

				return;
			}
			else{			
				$("#insertBreakFeedback").empty().html("Break Inserted");
				setTimeout(function(){$("#insertBreakFeedback").empty();},10000);

				loadWorkLogRecord(workLogRef);

				disableControls(false, true);
				$("#breakStartTime").val(null);
				$("#breakEndTime").val(null);

			}

			
		}
	});
}

function updateEventTable(tableData){
    
    
	var tableStructure = {
	"rows":{
		"linksToPage":false
	},
	"columns":[
		{
		    "headingName":"Station Name",
		    "dataName":"stationId"
		},
		{
		    "headingName":"User Name",
		    "dataName":"userName"
		},
		{
		    "headingName":"Record Date",
		    "dataName":"recordDate"
		},
		{
		    "headingName":"Start Time",
		    "dataName":"clockOnTime"
		},
		{
		    "headingName":"Finish Time",
		    "dataName":"clockOffTime"
		},
		{
		    "headingName":"Duration (HH:MM)",
		    "dataName":"workedDuration"
		},
		{
		    "headingName":"Overtime(HH:MM)",
		    "dataName":"overtimeDuration"
		},
		{
		    "headingName":"Job Status at Station",
		    "dataName":"workStatus"
		}
	]
	}; 

	if(includeQuantity == true)
	{
		tableStructure["columns"].push(
			{
				"headingName":"Quantity",
                "dataName":"quantityComplete"
			});
	}        
                
    var table = generateTable("recordsTable", [tableData], tableStructure);
    $("#recordsTableContainer").empty().append(table);
                
}

function disableControls(disable, insertElementsOnly=false){
	if (insertElementsOnly == false)
	{
		$(".logEventInfo").attr("disabled", disable);
		$(".controlButton").attr("disabled", disable);
	}
	else
		$("#btnInsertBreak").attr("disabled", disable);
		
	$(".insertBreakTime").attr("disabled", disable);

	if($("#endTime").val() == "")
	{
		$("#endTime").attr("disabled", true);
		$("#status").attr("disabled", true);
		$("#quantityComplete").attr("disabled", true);
	}

	$("#stationId").attr("disabled", true);//Disable ability to edit station Id due to stage index timelog issue
}

