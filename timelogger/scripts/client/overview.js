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

var TableData = null;
var updateRequestNumber = 0;
var showQuantityComplete;

$(document).ready(function(){
	sortRadioChange();	

	initDisplayOptions();

	setShowQuantityCompleteVisibilityFromConfig();
	
    updateJobsData();
    setInterval(function(){updateJobsData();}, 60000);
});

function initDisplayOptions(){
	
	if(localStorage.getItem("retainDisplayOptions") == "true"){
		// ---------- LOAD PREVIOUS SETTINGS ----------
		
		$('#showControlsCheckbox').prop("checked",localStorage.getItem("showControlsCheckbox") == "true");

		if(localStorage.getItem("sorting")=="sortByCreatedNewest")
		{
			$("#sortByCreatedNewest").prop("checked", true);
			// $('#showUrgentJobsFirst').prop("checked",localStorage.getItem("showUrgentJobsFirst") == "true");
			sortRadioChange();
		}
		else if(localStorage.getItem("sorting")=="sortByCreatedOldest")
		{
			$("#sortByCreatedOldest").prop("checked", true);
			// $('#showUrgentJobsFirst').prop("checked",localStorage.getItem("showUrgentJobsFirst") == "true");
			sortRadioChange();
		}
		else if(localStorage.getItem("sorting")=="sortByDueSoonest")
		{	
			$("#sortByDueSoonest").prop("checked", true);
			// $('#showUrgentJobsFirst').prop("checked",localStorage.getItem("showUrgentJobsFirst") == "true");
			$('#subSortByPriority').prop("checked",localStorage.getItem("subSortByPriority") == "true");
			sortRadioChange();
		}
		else if(localStorage.getItem("sorting")=="sortByDueLatest")
		{
			$("#sortByDueLatest").prop("checked", true);
			// $('#showUrgentJobsFirst').prop("checked",localStorage.getItem("showUrgentJobsFirst") == "true");
			$('#subSortByPriority').prop("checked",localStorage.getItem("subSortByPriority") == "true");
			sortRadioChange();
		}
		else if(localStorage.getItem("sorting")=="sortAlphabetic")
		{
			$("#sortAlphabetic").prop("checked", true);
			// $('#showUrgentJobsFirst').prop("checked",localStorage.getItem("showUrgentJobsFirst") == "true");
			sortRadioChange();
		}
		else if(localStorage.getItem("sorting")=="sortByPriority")
			$("#sortByPriority").prop("checked", true);

		$('#useDateCreatedRange').prop("checked",localStorage.getItem("useDateCreatedRange") == "true");
		$('#dateCreatedStartInput').val(localStorage.getItem("dateCreatedStartInput"));
		$('#dateCreatedEndInput').val(localStorage.getItem("dateCreatedEndInput"));

		$('#useDateDueRange').prop("checked",localStorage.getItem("useDateDueRange") == "true");
		$('#dateDueStartInput').val(localStorage.getItem("dateDueStartInput"));
		$('#dateDueEndInput').val(localStorage.getItem("dateDueEndInput"));

		$('#useDateTimeWorkedRange').prop("checked",localStorage.getItem("useDateTimeWorkedRange") == "true");
		$('#dateTimeWorkStartInput').val(localStorage.getItem("dateTimeWorkStartInput"));
		$('#dateTimeWorkEndInput').val(localStorage.getItem("dateTimeWorkEndInput"));
		$('#excludeUnworkedJobs').prop("checked",localStorage.getItem("excludeUnworkedJobs") == "true");

		$('#searchPhrase').val(localStorage.getItem("searchPhrase"));
		$('#showOnlyUrgentJobs').prop("checked",localStorage.getItem("showOnlyUrgentJobs") == "true");
		
		$('#showPendingJobs').prop("checked",localStorage.getItem("showPendingJobs") == "true");
		$('#showWorkInProgressJobs').prop("checked",localStorage.getItem("showWorkInProgressJobs") == "true");
		$('#showCompletedJobs').prop("checked",localStorage.getItem("showCompletedJobs") == "true");
		
		$('#warningHighlightDaysCount').val(localStorage.getItem("warningHighlightDaysCount"));
		$('#showDeadlineWarningHighlight').prop("checked",localStorage.getItem("showDeadlineWarningHighlight") == "true");
		$('#highlightPriority').prop("checked",localStorage.getItem("highlightPriority") == "true");
		$('#showCustomerName').prop("checked",localStorage.getItem("showCustomerName") == "true");
		$('#showJobId').prop("checked",localStorage.getItem("showJobId") == "true");
		$('#showProductId').prop("checked",localStorage.getItem("showProductId") == "true");
		$('#showDescription').prop("checked",localStorage.getItem("showDescription") == "true");
		$('#showNumberOfUnits').prop("checked",localStorage.getItem("showNumberOfUnits") == "true");
		$('#showTotalParts').prop("checked",localStorage.getItem("showTotalParts") == "true");
		$('#showCurrentStatus').prop("checked",localStorage.getItem("showCurrentStatus") == "true");
		$('#showRouteStage').prop("checked",localStorage.getItem("showRouteStage") == "true");
		$('#showJobCreated').prop("checked",localStorage.getItem("showJobCreated") == "true");
		$('#showDueDate').prop("checked",localStorage.getItem("showDueDate") == "true");
		$('#showExpectedDuration').prop("checked",localStorage.getItem("showExpectedDuration") == "true");
		$('#showWorkedTime').prop("checked",localStorage.getItem("showWorkedTime") == "true");
		$('#showOvertime').prop("checked",localStorage.getItem("showOvertime") == "true");
		$('#showEfficiency').prop("checked",localStorage.getItem("showEfficiency") == "true");
		$('#showStoppages').prop("checked",localStorage.getItem("showStoppages") == "true");
		$('#showChargePerMinute').prop("checked",localStorage.getItem("showChargePerMinute") == "true");
		$('#showTotalChargeToCustomer').prop("checked",localStorage.getItem("showTotalChargeToCustomer") == "true");
		$('#showNotes').prop("checked",localStorage.getItem("showNotes") == "true");
		$('#showQuantityComplete').prop("checked",localStorage.getItem("showQuantityComplete") == "true");
		$('#retainDisplayOptions').prop("checked",localStorage.getItem("retainDisplayOptions") == "true");
	}
	else{
		// ---------- SET INPUTS TO DEFAULT ----------
		$('#showControlsCheckbox').prop("checked",true);

		if($('#sortByCreatedNewest').prop("checked", true))
		{
			// $('#showUrgentJobsFirst').prop("checked", false);
			sortRadioChange();
		}
		if($('#sortByCreatedOldest').prop("checked", false))
		{
			// $('#showUrgentJobsFirst').prop("checked", false);
			sortRadioChange();
		}
		if($('#sortByDueSoonest').prop("checked", false))
		{
			// $('#showUrgentJobsFirst').prop("checked", false);
			$('#subSortByPriority').prop("checked", false);
			sortRadioChange();
		}
		if($('#sortByDueLatest').prop("checked", false))
		{
			// $('#showUrgentJobsFirst').prop("checked", false);
			$('#subSortByPriority').prop("checked", false);
			sortRadioChange();
		}
		if($('#sortAlphabetic').prop("checked", false))
		{
			// $('#showUrgentJobsFirst').prop("checked", false);
			sortRadioChange();
		}
		$('#sortByPriority').prop("checked", false);

		$("#useDateCreatedRange").prop("checked",true)
		setDefaultDateRange(7, "Created");

		$("#useDateDueRange").prop("checked",false)
		setDefaultDateRange(7, "Due");

		$('#useDateTimeWorkedRange').prop("checked", false);
		setDefaultDateRange(7, "TimeWork");

		$('#excludeUnworkedJobs').prop("checked", false);
		$('#searchPhrase').val("");
		$('#showOnlyUrgentJobs').prop("checked", false);
		$('#showPendingJobs').prop("checked", true);
		$('#showWorkInProgressJobs').prop("checked", true);
		$('#showCompletedJobs').prop("checked", true);
		$('#warningHighlightDaysCount').val(5);
		$('#showDeadlineWarningHighlight').prop("checked", true);
		$('#highlightPriority').prop("checked", true);
		$('#showCustomerName').prop("checked", true);
		$('#showJobId').prop("checked", true);
		$('#showProductId').prop("checked", true);
		$('#showDescription').prop("checked", true);
		$('#showNumberOfUnits').prop("checked", true);
		$('#showTotalParts').prop("checked", true);
		$('#showCurrentStatus').prop("checked", true);
		$('#showRouteStage').prop("checked", true);
		$('#showJobCreated').prop("checked", true);
		$('#showDueDate').prop("checked", true);
		$('#showExpectedDuration').prop("checked", true);
		$('#showWorkedTime').prop("checked", true);
		$('#showOvertime').prop("checked", true);
		$('#showEfficiency').prop("checked", true);
		$('#showStoppages').prop("checked", true);
		$('#showChargePerMinute').prop("checked", true);
		$('#showTotalChargeToCustomer').prop("checked", true);
		$('#showNotes').prop("checked", true);
		$('#showQuantityComplete').prop("checked", true);
		$('#retainDisplayOptions').prop("checked", false);	
	}
	setControlVisibility(fade=false);
}

function setDefaultDateRange(period, filterName)
{

	var startDate = new Date(Date.now() - (period * 24 * 60 *60 *1000)); // one week ago, in milliseconds
	var endDate = new Date(Date.now());

	var startDateString = startDate.getFullYear() + "-" + ("0"+(startDate.getMonth()+1)).slice(-2)  + "-" + ("0" + startDate.getDate()).slice(-2);
	var endDateString =   endDate.getFullYear()   + "-" + ("0"+(endDate.getMonth()+1)).slice(-2)    + "-" + ("0" + endDate.getDate()).slice(-2);
    
	$("#date" + filterName + "StartInput").val(startDateString);
	$("#date" + filterName + "EndInput").val(endDateString);
}

function enableTimePeriod(name, updateTable=false)
{
	if($("#useDate" + name + "Range").is(':checked'))
	{
		$("#date" + name + "StartInput").prop("disabled",false)
		$("#date" + name + "EndInput").prop("disabled",false)
	}
	else
	{
		$("#date" + name + "StartInput").prop("disabled",true)
		$("#date" + name + "EndInput").prop("disabled",true)
	}

	if(updateTable)
		onTableDataOptionsChange();
}


//detect enter key press and update table if enter pressed
$(document).keypress(function(e) {
	var keycode = (e.keycode ? e.keycode : e.which)
	if (keycode == 13){
		onUpdateTableButtonClick();
	}
});

function onUpdateTableButtonClick(){
	$("#updateJobsTableButton").prop("disabled",true).val("Working...");
	updateJobsData();
}

//update the size of the body to the correct width for the table that has been added
function updateBodySize(){	
	if($("#currentJobsTable").length)//check table exists
	{
		$("Body").width($("#currentJobsTable").width());
	}
}

// update the display and then save the display options settings
function onDisplayOptionsChange(){
	updateTableDisplay();

	localStorage.setItem("showControlsCheckbox", $("#showControlsCheckbox").is(":checked"));

	if($("#sortByCreatedNewest").is(":checked"))
	{
		localStorage.setItem("sorting", "sortByCreatedNewest");
		// localStorage.setItem("showUrgentJobsFirst", $("#showUrgentJobsFirst").is(":checked"));
		sortRadioChange();
	}
	else if($("#sortByCreatedOldest").is(":checked"))
	{
		localStorage.setItem("sorting", "sortByCreatedOldest");
		// localStorage.setItem("showUrgentJobsFirst", $("#showUrgentJobsFirst").is(":checked"));
		sortRadioChange();
	}
	else if($("#sortByDueSoonest").is(":checked"))
	{
		localStorage.setItem("sorting", "sortByDueSoonest");
		// localStorage.setItem("showUrgentJobsFirst", $("#showUrgentJobsFirst").is(":checked"));
		localStorage.setItem("subSortByPriority", $("#subSortByPriority").is(":checked"));
		sortRadioChange();
	}
	else if($("#sortByDueLatest").is(":checked"))
	{
		localStorage.setItem("sorting", "sortByDueLatest");
		// localStorage.setItem("showUrgentJobsFirst", $("#showUrgentJobsFirst").is(":checked"));
		localStorage.setItem("subSortByPriority", $("#subSortByPriority").is(":checked"));
		sortRadioChange();
	}
	else if($("#sortAlphabetic").is(":checked"))
	{
		localStorage.setItem("sorting", "sortAlphabetic");
		// localStorage.setItem("showUrgentJobsFirst", $("#showUrgentJobsFirst").is(":checked"));
		sortRadioChange();
	}
	else if($("#sortByPriority").is(":checked"))
		localStorage.setItem("sorting", "sortByPriority");

	localStorage.setItem("useDateCreatedRange", $("#useDateCreatedRange").is(":checked"));
	localStorage.setItem("dateCreatedStartInput", $("#dateCreatedStartInput").val());
	localStorage.setItem("dateCreatedEndInput", $("#dateCreatedEndInput").val());

	localStorage.setItem("useDateDueRange", $("#useDateDueRange").is(":checked"));
	localStorage.setItem("dateDueStartInput", $("#dateDueStartInput").val());
	localStorage.setItem("dateDueEndInput", $("#dateDueEndInput").val());

	localStorage.setItem("useDateTimeWorkedRange", $("#useDateTimeWorkedRange").is(":checked"));
	localStorage.setItem("dateTimeWorkStartInput", $('#dateTimeWorkStartInput').val());
	localStorage.setItem("dateTimeWorkEndInput", $('#dateTimeWorkEndInput').val());
	localStorage.setItem("excludeUnworkedJobs", $("#excludeUnworkedJobs").is(":checked"));

	localStorage.setItem("searchPhrase", $('#searchPhrase').val());

	localStorage.setItem("showOnlyUrgentJobs", $("#showOnlyUrgentJobs").is(":checked"));
	localStorage.setItem("showPendingJobs", $("#showPendingJobs").is(":checked"));
	localStorage.setItem("showWorkInProgressJobs", $("#showWorkInProgressJobs").is(":checked"));
	localStorage.setItem("showCompletedJobs", $("#showCompletedJobs").is(":checked"));
	localStorage.setItem("warningHighlightDaysCount", $('#warningHighlightDaysCount').val());
	localStorage.setItem("showDeadlineWarningHighlight", $('#showDeadlineWarningHighlight').is(":checked"));
	localStorage.setItem("highlightPriority", $("#highlightPriority").is(":checked"));
	localStorage.setItem("showCustomerName", $("#showCustomerName").is(":checked"));
	localStorage.setItem("showJobId", $("#showJobId").is(":checked"));
	localStorage.setItem("showProductId", $("#showProductId").is(":checked"));
	localStorage.setItem("showDescription", $("#showDescription").is(":checked"));
	localStorage.setItem("showNumberOfUnits", $("#showNumberOfUnits").is(":checked"));
	localStorage.setItem("showTotalParts", $("#showTotalParts").is(":checked"));
	localStorage.setItem("showCurrentStatus", $("#showCurrentStatus").is(":checked"));
	localStorage.setItem("showRouteStage", $("#showRouteStage").is(":checked"));
	localStorage.setItem("showJobCreated", $("#showJobCreated").is(":checked"));
	localStorage.setItem("showDueDate", $("#showDueDate").is(":checked"));
	localStorage.setItem("showExpectedDuration", $("#showExpectedDuration").is(":checked"));
	localStorage.setItem("showWorkedTime", $("#showWorkedTime").is(":checked"));
	localStorage.setItem("showOvertime", $("#showOvertime").is(":checked"));
	localStorage.setItem("showEfficiency", $("#showEfficiency").is(":checked"));
	localStorage.setItem("showStoppages", $("#showStoppages").is(":checked"));
	localStorage.setItem("showChargePerMinute", $("#showChargePerMinute").is(":checked"));
	localStorage.setItem("showTotalChargeToCustomer", $("#showTotalChargeToCustomer").is(":checked"));
	localStorage.setItem("showNotes", $("#showNotes").is(":checked"));
	localStorage.setItem("showQuantityComplete", $("#showQuantityComplete").is(":checked"));
	localStorage.setItem("retainDisplayOptions", $("#retainDisplayOptions").is(":checked"));
	
	console.log(localStorage);
}

function updateJobsData(){
	// get user data, ordered by selected option
    // generate table
    // drop old table and append new one

	var searchPhrase = $('#searchPhrase').val();
	var useSearchPhrase = false;

	if(searchPhrase != "")
		useSearchPhrase = true;

	
	var dateCreatedStart = $('#dateCreatedStartInput').val()
	var dateCreatedEnd = $('#dateCreatedEndInput').val()	
	var useDateCreatedRange = $('#useDateCreatedRange').is(':checked')

	if(dateCreatedStart == '' && dateCreatedEnd == '')
		useDateCreatedRange=false

	var dateDueStartInput = $('#dateDueStartInput').val()
	var dateDueEndInput = $('#dateDueEndInput').val()
	var useDataDueRange = $('#useDateDueRange').is(':checked')

	console.log(useDataDueRange)

	if(dateDueStartInput == '' && dateDueEndInput == '')
		useDataDueRange=false

	console.log(useDataDueRange)

	if($("#useDateDueRange").is(':checked')) 
	{
		$('#dateDueStartInput').prop("disabled", false);
		$('#dateDueEndInput').prop("disabled", false);
	}
	else
	{
		$('#dateDueStartInput').prop("disabled", true);
		$('#dateDueEndInput').prop("disabled", true);
	}

	if($("#useDateTimeWorkedRange").is(':checked'))
	{
		$("#dateTimeWorkStartInput").prop("disabled",false);
		$("#dateTimeWorkEndInput").prop("disabled",false);
		$("#excludeUnworkedJobs").prop("disabled",false);
	}
	else
	{
		$("#dateTimeWorkStartInput").prop("disabled",true);
		$("#dateTimeWorkEndInput").prop("disabled",true);
		$("#excludeUnworkedJobs").prop("disabled",true);
		$("#excludeUnworkedJobs").prop(':checked', true);
	}

	if($("#useDateCreatedRange").is(':checked'))
	{
		$("#dateCreatedStartInput").prop("disabled",false);
		$("#dateCreatedEndInput").prop("disabled",false);
	}
	else
	{
		$("#dateCreatedStartInput").prop("disabled",true);
		$("#dateCreatedEndInput").prop("disabled",true);
	}

	var dateTimeWorkStartInput = $('#dateTimeWorkStartInput').val()
	var dateTimeWorkEndInput = $('#dateTimeWorkEndInput').val()
	var excludeUnworkedJobs = $('#excludeUnworkedJobs').is(':checked')
	var useDateTimeWorkedRange = $('#useDateTimeWorkedRange').is(':checked')

	$("#showQuantityComplete").prop("hidden", false);
	$("#showQuantityCompleteLabel").prop("hidden", false);	
	

	if(dateTimeWorkStartInput == '' && dateTimeWorkEndInput == ''){
		useDateTimeWorkedRange=false
		excludeUnworkedJobs=false
	}
	
	console.log(useDateTimeWorkedRange)
	console.log(excludeUnworkedJobs)

	var showPendingJobs = $('#showPendingJobs').is(':checked')
	var showWorkInProgressJobs = $('#showWorkInProgressJobs').is(':checked')
	var showCompletedJobs = $('#showCompletedJobs').is(':checked')

	requestParameters = {
			"request":"getOverviewData",
			"tableOrdering":$('input[name="tableOrdering"]').filter(':checked').val(),
			"showPendingJobs":showPendingJobs,
			"showWorkInProgressJobs":showWorkInProgressJobs,
			"showCompletedJobs":showCompletedJobs,
			"useDateCreatedRange":useDateCreatedRange,
			"dateCreatedStart":dateCreatedStart,
			"dateCreatedEnd":dateCreatedEnd,
			"useDateDueRange":useDataDueRange,
			"dateDueStart":dateDueStartInput,
			"dateDueEnd":dateDueEndInput,
			"useDateTimeWorkedRange":useDateTimeWorkedRange,
			"dateTimeWorkStart":dateTimeWorkStartInput,
			"dateTimeWorkEnd":dateTimeWorkEndInput,
			"excludeUnworkedJobs":excludeUnworkedJobs,
			"useSearchKey":useSearchPhrase,
			"searchKey":searchPhrase,
			"showOnlyUrgentJobs":$('#showOnlyUrgentJobs').is(':checked'),
			// "showUrgentJobsFirst":$('#showUrgentJobsFirst').is(':checked'),
			"subSortByPriority":$('#subSortByPriority').is(':checked'),
			"updateRequestNumber":++updateRequestNumber
		};
    
    $.ajax({
        url:"../scripts/server/overview.php",
        type:"GET",
        dataType:"text",
        data:requestParameters,
        success:function(result){
            console.log(result);
            resultJson = $.parseJSON(result);
            
            if(resultJson["status"] != "success"){
                console.log("Failed to update table: " + resultJson["result"]);
                $("#tablePlaceholder").html(resultJson["result"]);
            }
            else{
				//console.log(resultJson["result"]["updateRequestNumber"]);

				if(resultJson["result"]["updateRequestNumber"] == updateRequestNumber){
		            TableData = resultJson["result"]["overviewData"];
		            updateTableDisplay();
		            
		            // update where the CSV link points to, including params
		            requestParameters.request = "getOverviewDataCSV";
		            var csvUrl = "../scripts/server/overview.php?" + $.param(requestParameters);
		            $("#csvDownloadLink").attr("href",csvUrl);
		            
		            $("#updateJobsTableButton").prop("disabled",false).val("Update Table");
				}
				
            }
        }
    });

}

function setShowQuantityCompleteVisibilityFromConfig(){
	
	requestParameter = { "request" : "getConfigShowQtyComplete"};
	$.ajax({
		url:"../scripts/server/overview.php",
		type:"GET",
		dataType:"text",
		data:requestParameter,
		success:function(result){
			console.log(result);
			resultJson = $.parseJSON(result);
			if(resultJson["status"] != "success"){
				console.log("Failed to get Qty Complete: " + resultJson["result"]);
				$("#tablePlaceholder").html(resultJson["result"]);
			}
			else{
				if (resultJson["result"] == "true"){
					showQuantityComplete = true;
					$("#showQuantityComplete").prop("hidden", false);
					$("#showQuantityCompleteLabel").prop("hidden", false);					
				} else {
					showQuantityComplete = false;
					$("#showQuantityComplete").prop("hidden", true);
					$("#showQuantityCompleteLabel").prop("hidden", true);
				}
				updateTableDisplay();
				initDisplayOptions();
				onDisplayOptionsChange();
			}
		}
	});
}


function updateTableDisplay(){
	if(TableData == null)
		return;
	
	
	var tableStructure = {
		"rows":{
			"linksToPage":true,
			"link":"job_details_client.php",
			"linkParamLabel":"jobId",
			"linkParamDataName":"jobId",
			"classDeciderFunction":function(RowData){
					if("urgent" in RowData 
					   && RowData.urgent 
					   && $("#highlightUrgent").is(":checked"))
						return "highlight row_urgent";
					if(RowData.currentStatus != "Complete"){
						if("dueDate" in RowData && RowData.dueDate != ""){
							var dueDateMillis = new Date(RowData.dueDate).getTime();
							var nowMillis = Date.now();
							var daysDiff = Math.floor((dueDateMillis - nowMillis) / (1000 * 60 * 60 * 24));
							
							if($("#showDeadlineWarningHighlight").is(":checked")){
								if(daysDiff < $("#warningHighlightDaysCount").val() && daysDiff >= 0)
									return "highlight row_late_risk";
								else if(daysDiff < 0)
									return "highlight row_overdue";
							}
						}

						if(("priority" in RowData) && $("#highlightPriority").is(":checked"))
						{
							switch(RowData.priority){
								case 1:
									return "highlight priority_Low";
									break;
								case 2:
									return "highlight priority_Medium";
									break;
								case 3:
									return "highlight priority_High";
									break;
								case 4:
									return "highlight priority_Urgent";
									break;
							}
						}
					}
				
					return "noHighlight";
				}
		},
		"columns":[
			{
				"headingName":"Job Name",
				"dataName":"jobName"
			}
		]
	};

	if($("#showJobId").is(":checked")){
		tableStructure.columns.push(
			{
				"headingName":"Job ID",
				"dataName":"jobId"
			}
		);
	}

	if($("#showProductId").is(":checked")){
		tableStructure.columns.push(
			{
				"headingName":"Product ID",
				"dataName":"productId"
			}
		);
	}
	
	if($("#showCustomerName").is(":checked")){
		tableStructure.columns.push(
			{
				"headingName":"Customer Name",
				"dataName":"customerName"
			}
		);
	}
	
	if($("#showDescription").is(":checked")){
		tableStructure.columns.push(
			{
				"headingName":"Description",
				"dataName":"description"
			}
		);
	}
	
	if($("#showNumberOfUnits").is(":checked")){
		tableStructure.columns.push(
			{
				"headingName":"Number of Units",
				"dataName":"numberOfUnits"
			}
		);
	}
	
	if($("#showTotalParts").is(":checked")){
		tableStructure.columns.push(
			{
				"headingName":"Total Parts",
				"dataName":"totalParts"
			}
		);
	}
	
	if($("#showCurrentStatus").is(":checked")){
		tableStructure.columns.push(
			{
				"headingName":"Job Status",
				"dataName":"currentStatus"
			}
		);
	}
	
	if($("#showRouteStage").is(":checked")){
		tableStructure.columns.push(
			{
				"headingName":"Production Stage",
				"dataName":"routeStageName"
			}
		);
	}
	
	if($("#showJobCreated").is(":checked")){
		tableStructure.columns.push(
			{
				"headingName":"Job Added",
				"dataName":"recordAdded"
			}
		);
	}
	
	if($("#showDueDate").is(":checked")){
		tableStructure.columns.push(
			{
				"headingName":"Job Due",
				"dataName":"dueDate"
			}
		);
	}
	
	if($("#showExpectedDuration").is(":checked")){
		tableStructure.columns.push(
			{
				"headingName":"Expected Duration (HH:MM)",
				"dataName":"expectedTime"
			}
		);
	}
	
	
	if($("#showWorkedTime").is(":checked")){
		tableStructure.columns.push(
			{
				"headingName":"Total Worked Time (HH:MM)",
				"dataName":"workedTime"
			}
		);
	}
	
	if($("#showOvertime").is(":checked")){
		tableStructure.columns.push(
			{
				"headingName":"Total Overtime (HH:MM)",
				"dataName":"overtime"
			}
		);
	}
	
	if($("#showEfficiency").is(":checked")){
		tableStructure.columns.push(
			{
				"headingName":"Efficiency (max 1)",
				"dataName":"efficiency"
			}
		);
	}
	
	if($("#showStoppages").is(":checked")){
		tableStructure.columns.push(
			{
				"headingName":"Problems",
				"dataName":"problems"
			}
		);
	}
	
	if($("#showChargePerMinute").is(":visible")){
		if($("#showChargePerMinute").is(":checked")){
			tableStructure.columns.push(
				{
					"headingName":"Value Per Minute",
					"dataName":"chargePerMin"
				}
			);
		}
		
		if($("#showTotalChargeToCustomer").is(":checked")){
			tableStructure.columns.push(
				{
					"headingName":"Total Charge To Customer (£)",
					"dataName":"totalCharge"
				}
			);
		}
	}

	if($("#showOutstandingUnits").is(":checked")){
		tableStructure.columns.push(
			{
				"headingName":"Qty Outstanding",
				"dataName":"stageOutstandingUnits"
			}
		);
	}

	if($("#showNotes").is(":checked")){
		tableStructure.columns.push(
			{
				"headingName":"Notes",
				"dataName":"notes"
			}
		);
	}
	
	if(showQuantityComplete){
		if($("#showQuantityComplete").is(":checked")){
			tableStructure.columns.push(
				{
					"headingName":"Quantity Completed",
					"dataName":"quantityComplete"
				}
			);
		}
	}
	
	var table = generateTable("currentJobsTable", TableData, tableStructure);
	$("#currentJobsTableContainer").empty().append(table);
	updateBodySize();
}




// function setControlVisibility(){
// 	if($('#showControlsCheckbox').is(':checked')){
		
// 			$('#currentJobsDisplayControls').fadeIn();
// 			$('#navbar').fadeIn();
// 		}
// 		else{
			
// 		}
// 	}else{
// 		if(fade=true){
// 			$('#navbar').fadeOut();
// 			$('#currentJobsDisplayControls').fadeOut();
// 		}
// 		else{
			
// 		}
// 	}
// }

function setControlVisibility(){
	if($('#showControlsCheckbox').is(':checked')){
		$('.controls').fadeIn();
		$('#navbar').fadeIn();
		$('#currentJobsDisplayControls').prop("hidden", false);
		$('#navbar').prop("hidden", false);
	}else{
		$('#navbar').fadeOut();
		$('.controls').fadeOut();
		$('#currentJobsDisplayControls').prop("hidden", true);
		$('#navbar').prop("hidden", true);
	}
}

function sortRadioChange(){
	sortingOption = $('input[name="tableOrdering"]').filter(':checked').val();

	if(sortingOption=="dueSoonestFirst" || sortingOption=="dueLatestFirst")
	{
		$('#subSortByPriority').fadeIn();
		$('#subSortByPriorityLabel').fadeIn();
	}
	else
	{
		$('#subSortByPriority').fadeOut();
		$('#subSortByPriorityLabel').fadeOut();
	}

	// if(sortingOption=="priority")
	// {
	// 	$('#showUrgentJobsFirst').fadeOut();
	// 	$('#showUrgentJobsFirstLabel').fadeOut();
	// }
	// else
	// {

	// 	$('#showUrgentJobsFirst').fadeIn();
	// 	$('#showUrgentJobsFirstLabel').fadeIn();
	// }
}

function onTableDataOptionsChange(){
	onUpdateTableButtonClick();
	onDisplayOptionsChange();
}
