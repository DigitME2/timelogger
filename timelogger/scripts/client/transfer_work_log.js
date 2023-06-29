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

// Note: This page don't use table generator to get the work log table.

$(document).ready(function(){
	searchJobs();
});

function getJobName(jobId){
	$.ajax({
		url:"../scripts/server/transfer_work_log.php",
		type:"GET",
		dataType:"text",
		data:{
			"request":"getJobName",
			"jobId":jobId
		},
		success:function(result){
			console.log(result);
			var resultJson = $.parseJSON(result);
		if(resultJson.status == "success") {
				$("#jobNameField").html(resultJson.result);
		}
	}
	})
}

function loadJobs(){
	$.ajax({
		url:"../scripts/server/transfer_work_log.php",
		type:"GET",
		dataTtype:"text",
		data:{
			"request":"getJobsList"
		},
		success:function(result){
			console.log(result);
			var resultJson = $.parseJSON(result);
			
			if(resultJson.status != "success"){
				$("#spanFeedback").empty().html(resultJson.result);
			}
			else
			{
				var jobsList = resultJson["result"];
				$("#jobIdDropDown").empty();
				var placeHolder = $("<option>")
						.text("Select a Job Name...")
						.attr("value", "");
				$("#jobIdDropDown").append(placeHolder);
				for(var i = 0; i < jobsList.length; i++){
					var newOption = $("<option>")
						.text(jobsList[i]['jobName'])
						.attr("value", jobsList[i]['jobId']);
					$("#jobIdDropDown").append(newOption);
				}
			}
		}
	});
}

function updateJobIdsList(){
    // get job data, through search phrase by entered text
    // show up the searched job Id in job Drop Down
	var searchPhrase = $("#searchPhrase").val();
	if(searchPhrase == ""){
		$("#jobIdDropDown").empty();
		var placeHolder = $("<option>")
				.text("Select a Job Name...")
				.attr("value", "");
		$("#jobIdDropDown").append(placeHolder);
		loadJobs();
	}
	else{
		$.ajax({
			url:"../scripts/server/transfer_work_log.php",
			type:"GET",
			dataType:"text",
			data:{
				"request":"getJobId",
				"searchPhrase":searchPhrase
			},
			success:function(result){
				console.log(result);
				resultJson = $.parseJSON(result);
				
				if(resultJson["status"] != "success"){
					console.log("Failed to get Job Id: " + resultJson["result"]);
					$("#jobIdDropDown").empty();
					var ErrorMsg = resultJson["result"];
					newOption = $("<option>")
						.text(ErrorMsg)
						.attr("value", ErrorMsg);
					$("#jobIdDropDown").append(newOption);
				}
				else{
					let jobIdList = [];
					let result_len = resultJson["result"].length
					if(!(result_len == "")){
						for (let l = 0; l<result_len; l++)
						{
							jobIdList.push(resultJson["result"][l]);
						}
						console.log(jobIdList);
						$("#jobIdDropDown").empty();
						for(var i = 0; i < jobIdList.length; i++){
							let newOption = $("<option>")
								.text(jobIdList[i]['jobName'])
								.attr("value", jobIdList[i]['jobId']);
							$("#jobIdDropDown").append(newOption);
						}
					}
				}
			}
		});
	}
}

function GenerateJobLogTable(JobId){
    // get user data, ordered by selected option
    // generate table
    // drop old table and append new one
    
	var startDate = $('#dateStartInput').val();
	var endDate = $('#dateEndInput').val();
	
    $.ajax({
        url:"../scripts/server/job_details.php",
        type:"GET",
        dataType:"text",
        data:{
            "request":"getTimeLog",
            "collapseRecords":$('#collapseRecords').is(':checked'),
            "jobId":JobId,
            "useDateRange":$('#useDateRange').is(':checked'),
            "startDate":startDate,
            "endDate":endDate
        },
        success:function(result){
            console.log(result);
            resultJson = $.parseJSON(result);
            
            if(resultJson["status"] != "success"){
                console.log("Failed to update table: " + resultJson["result"]);
            }
            else{
                var tableData = resultJson.result.timeLogTableData;
                
				if((tableData.length > 0)){
					// var notNull = function(element){
					// 	//checks whether an element is null
					// 	return element(tableData.clockOffTime) != null;
					// };
					// tableData.some(notNull);
					tableData.clockOffTime != null;
					var table = $("<table id='workLogTable' class='table'>")
					var thead = $("<thead/>");
					var tr = $("<tr/>");
					var selectAllCheckbox = $("<input type='checkbox' class='form-check-input' id='selectAllCheckbox'>");
    				selectAllCheckbox.on("click", function(){onSelectAllCheckboxClicked();});
					tr.append($("<th>").append(selectAllCheckbox));
					tr.append($("<th scope='col'>Location Name</th>"));
					tr.append($("<th scope='col'>User Name</th>"));
					tr.append($("<th scope='col'>Record Date</th>"));
					tr.append($("<th scope='col'>Start Time</th>"));
					tr.append($("<th scope='col'>Finish Time</th>"));
					tr.append($("<th scope='col'>Duration(HH:MM)</th>"));
					tr.append($("<th scope='col'>Overtime(HH:MM)</th>"));
					tr.append($("<th scope='col'>Job Status</th>"));
					thead.append(tr);
					table.append(thead);
					var tbody = $("<tbody>");
					table.append(tbody);
					for(i = 0; i < tableData.length; i++){
						if(tableData[i].clockOffTime === "" || tableData[i].clockOffTime === null){
							tableData[i].clockOffTime === " ";
						}
						else{
							tableData[i].clockOffTime === tableData[i].clockOffTime;
						}
						tr = $("<tr>");
						var checkbox = $("<input type='checkbox' class='form-check-input workLogSelectCheckbox'>");
						checkbox.on("click", function(e){
							e.stopPropagation();
							onTimeLogSelectCheckboxClicked();
						});
						checkbox.data("WorkLogId", tableData[i].ref);
						tr.append($("<td/>").append(checkbox));
						tr.append($("<td>" + tableData[i].stationId  + "</td>"));
						tr.append($("<td>" + tableData[i].userName  + "</td>"));
						tr.append($("<td>" + tableData[i].recordDate  + "</td>"));
						tr.append($("<td>" + tableData[i].clockOnTime  + "</td>"));
						if( tableData[i].clockOffTime == null)
						{
							tr.append($("<td></td>"));
						} else
						{
							tr.append($("<td>" + tableData[i].clockOffTime  + "</td>"));
						}
						tr.append($("<td>" + tableData[i].workedTime  + "</td>"));
						tr.append($("<td>" + tableData[i].overtime  + "</td>"));
						tr.append($("<td>" + tableData[i].workStatus  + "</td>"));

						tbody.append(tr);
					}

					$("#workLogRecordContainer").append(table);
				}
				else {
					var messageSpan = $("<span id='noWorkMessage'>").html('! There is no work record for this job !');
					$("#recordsTableContainer").empty().append(messageSpan);
				}
			}
		}
	});
}

function onTimeLogSelectCheckboxClicked(){
	if(($(".workLogSelectCheckbox").length) == ($(".workLogSelectCheckbox:checked").length)){
		$("#selectAllCheckbox").prop("checked", true);
	}
    else{
        $("#selectAllCheckbox").prop("checked", false);
	}
	if($(".workLogSelectCheckbox:checked").length > 0){
        $("#transferWorkLogbtn").prop("disabled", false);
	}
    else{
        $("#transferWorkLogbtn").prop("disabled", true);
	}
}

function onSelectAllCheckboxClicked(){
	if(($("#selectAllCheckbox").is(":checked"))){
		$("#transferWorkLogbtn").prop("disabled", false);
		$(".workLogSelectCheckbox").prop("checked", true);
	}
	else{
		$("#transferWorkLogbtn").prop("disabled", true);
		$(".workLogSelectCheckbox").prop("checked", false);
	}
}

function searchJobs(){
	if($('#searchPhrase')){
		var searchPhrase = $('#searchPhrase').val();
		updateJobIdsList();
	}
	if(!($('#searchPhrase'))){
		loadJobs();
	}
}

function updateScreen(){
	console.log(JobId);
	$("#searchPhrase").val("");
	$(".workLogSelectCheckbox").prop("checked", false);
	$("#jobIdDropDown").empty();
		var placeHolder = $("<option>")
				.text("Select a Job Id...")
				.attr("value", "");
		$("#jobIdDropDown").append(placeHolder);
		$("#transferWorkLogResponseField").html("");
		$("#recordsTableContainer").empty();
		$("#workLogRecordContainer").empty();
		GenerateJobLogTable(JobId);
		searchJobs();
}

function clearBtn(){
	console.log(JobId);
	$("#searchPhrase").val("");
	$("#selectAllCheckbox").prop("checked", false);
	$(".workLogSelectCheckbox").prop("checked", false);
	$("#transferWorkLogbtn").prop("disabled", true);
	$("#jobIdDropDown").empty();
		var placeHolder = $("<option>")
				.text("Select a Job Id...")
				.attr("value", "");
		$("#jobIdDropDown").append(placeHolder);
		$("#transferWorkLogResponseField").html("");
		searchJobs();
}

function transferWorkLog(){

	var requiredJobId = $("#jobIdDropDown").val();
	console.log(requiredJobId);
	if(requiredJobId == ""){
		$("#transferWorkLogResponseField").html("Please select a new Job Id");
	}
	else{
		var selectedCheckBoxesList = [];
		var selectedCheckBoxes = $(".workLogSelectCheckbox:checked");
		console.log(selectedCheckBoxes);
		if(selectedCheckBoxes.length == 0 ) {
			$("#transferWorkLogResponseField").html("Please check the work log which needs to be transferred!");
		}
		else{
			for(i=0; i < selectedCheckBoxes.length; i++){
				console.log($(selectedCheckBoxes[i]).data("WorkLogId"));
				selectedCheckBoxesList.push($(selectedCheckBoxes[i]).data("WorkLogId"));
			TransferData = {
				"newJobId" : requiredJobId,
				"timeLog" : selectedCheckBoxesList
			}
			TransferData = JSON.stringify(TransferData);
			console.log(TransferData);
			// disabled the submit button
			$("#transferWorkLogbtn").prop("disabled", true);
			$("#transferWorkLogResponseField").html("Processing. Please wait...");
			}
			$.ajax({
				url:"../scripts/server/transfer_work_log.php",
				type: "POST",
				dataType:"json",
				data:{
					"request":"transferWorkLogs",
					"TransferData": TransferData
				},
				success: function(result) {
					console.log(result);
					var resultJson = JSON.parse(JSON.stringify(result));
					if(resultJson["status"] != "success"){
						console.log("Failed to Transfer Work Log: " + resultJson["result"]);
						$("#transferWorkLogResponseField").empty().html(resultJson["result"]);
					}
					else
					{
						$("#transferWorkLogResponseField").empty().html(resultJson["result"]);
						updateScreen();
					}
				},
			});
		}
	}
}