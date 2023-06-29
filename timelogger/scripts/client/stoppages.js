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
    updateStoppageReasonTable();
    updateStoppageLogsTable();
    $(".stoppageReasonInput").on('keyup', function(){
        var stoppageReasonId = $("#newStoppageReason").val();
        
        var stoppageReasonIdCharsRemaining = 20 - stoppageReasonId.length;
        $("#newStoppageReasonCounter").html(stoppageReasonIdCharsRemaining + "/20");
    });
    $(".stoppageReasonInput").trigger("keyup",null);

	$("#newStoppageReason").keypress(function(e) {
		var keycode = (e.keycode ? e.keycode : e.which)
		if (keycode == 13){
			addNewStoppageReason();
		}
	});	
   
	$("#newStoppageReason").focus();
});

function onUseStartDateCheckbox(){
    
    if(!($("#startDateCheckbox").is(':checked')))
    {
        $('#dateStartInput').prop("disabled", true);
    } 
    else
    {
        $('#dateStartInput').prop("disabled", false);
    }
}

function onUseEndDateCheckbox(){

    if(!($("#endDateCheckbox").is(':checked')))
    {
        $('#dateEndInput').prop("disabled", true);
    } 
    else
    {
        $('#dateEndInput').prop("disabled", false);
    }
}

function validDates(startDate, endDate){
    var isValidDate = true;
    
    if(startDate == ""){
        $("#stoppagesLogTableContainer").empty().html("Invalid start date");
        isValidDate = false;
    }else if(endDate == ""){
        $("#stoppagesLogTableContainer").empty().html("Invalid end date");
        isValidDate = false;
    }else{
        
        var startDateParts = startDate.split("-");
        var endDateParts = endDate.split("-");
        
        var startYear = parseInt(startDateParts[0]);
        var startMonth = parseInt(startDateParts[1]);
        var startDay = parseInt(startDateParts[2]);
        var endYear = parseInt(endDateParts[0]);
        var endMonth = parseInt(endDateParts[1]);
        var endDay = parseInt(endDateParts[2]);
        
        if(startYear > endYear){
            $("#stoppagesLogTableContainer").empty().html("Start date must be before end date");
			isValidDate = false;
        }else if(startYear == endYear && startMonth > endMonth){
            $("#stoppagesLogTableContainer").empty().html("Start date must be before end date");
			isValidDate = false;            
        }else if(startMonth == endMonth && startDay > endDay){
            $("#stoppagesLogTableContainer").empty().html("Start date must be before end date");
			isValidDate = false;
        }

		if(startYear <= 2016){
			$("#stoppagesLogTableContainer").empty().html("Start date prior to system initialization");
			isValidDate = false;
		}
    }
    
    return isValidDate;
}

function updateStoppageReasonTable(){
    // get Stoppage Reason data, ordered by selected option
    // generate table
    // drop old table and append new one
    
    //var sortingOption = $('input[name="tableOrdering"]').filter(':checked').val()
    //console.log("Sorting option: " + sortingOption);

	var sortingOption = "byAlphabetic";
    
    $.ajax({
        url:"../scripts/server/stoppages.php",
        type:"GET",
        dataType:"text",
        data:{
            "request":"getStoppageReasonTableData",
            "tableOrdering":sortingOption
        },
        success:function(result){
            console.log(result);
            resultJson = $.parseJSON(result);
            
            if(resultJson["status"] != "success"){
                console.log("Failed to update table: " + resultJson["result"]);
                $("#tablePlaceholder").html(resultJson["result"]);
            }
            else{
                var tableData = resultJson["result"];
                var tableStructure = {
                    "rows":{
                        "linksToPage":false
                    },
                    "columns":[
                        {
                            "headingName":"Reason ID",
                            "dataName":"stoppageReasonId"
                        },
						{
                            "headingName":"Name",
                            "dataName": "stoppageReasonName"
                        },
                        {
                            "headingName":"QR Code",
                            "functionToRun":getDownloadStoppageQrCode,
                            "functionParamDataName":"stoppageReasonId",
                            "functionParamDataLabel":"stoppageReasonId",
                            "functionButtonText":"Download QR Code"
                        },
                        {
                            "headingName":"Delete Problem",
                            "functionToRun":deleteStoppageReason,
                            "functionParamDataName":"stoppageReasonId",
                            "functionParamDataLabel":"stoppageReasonId",
                            "functionButtonText":"Delete Reason"
                        }
                    ]
                };
                
                var table = generateTable("stoppageReasonTable", tableData, tableStructure);
                $("#existingStoppagesReasonContainer").empty().append(table);
            }
        }
    });
}

function updateStoppageLogsTable(){
    var SearchPhrase = $("#searchPhrase").val();
    inputStartDate = $("#dateStartInput").val();
    inputEndDate = $("#dateEndInput").val();

    $("#stoppagesLogTableContainer").empty().html("Working. Please wait....");

    $.ajax({
        url:"../scripts/server/stoppages.php",
        type:"GET",
        dataType:"text",
        data:{
            "request" : "getStoppagesLog",
            "useStartDate" : $("#startDateCheckbox").is(':checked'),
            "useEndDate" : $("#endDateCheckbox").is(':checked'),
            "startDate" : inputStartDate,
            "endDate" : inputEndDate,
            "searchPhrase" : SearchPhrase
        },
        success:function(result){
            console.log(result);
            resultJson = $.parseJSON(result);
            
            if(resultJson["status"] != "success"){
                console.log("Failed to load problems log table: " + resultJson["result"]);
                $("#stoppagesLogTableContainer").html("");
                $("#stoppagesLogTableContainer").empty().html(resultJson["result"]);
            }
            else{
                var tableData = resultJson["result"];
                            
                var tableStructure = {
                    "rows":{
                            "linksToPage":true,
                            "link":"job_details_client.php",
                            "linkParamLabel":"jobId",
                            "linkParamDataName":"jobId",
                    },
                    "columns":[
                        {
                            "headingName":"Job Name",
                            "dataName":"jobName"
                        },
                        {
                            "headingName":"Customer Name",
                            "dataName":"customerId"
                        },
                        {
                            "headingName":"Problem Name",
                            "dataName":"stoppageReasonName"
                        },
                        {
                            "headingName":"Description",
                            "dataName":"description"
                        },
                        {
                            "headingName":"Location",
                            "dataName":"stationId"
                        },
                        {
                            "headingName":"Start Time",
                            "dataName":"startTime"
                        },
                        {
                            "headingName":"Start Date",
                            "dataName":"startDate"
                        },
                        {
                            "headingName":"End Time",
                            "dataName":"endTime"
                        },
                        {
                            "headingName":"End Date",
                            "dataName":"endDate"
                        },
                        {
                            "headingName":"Duration",
                            "dataName":"duration"
                        },
                        {
                            "headingName":"status",
                            "dataName":"status"
                        }
                    ]
                };
                
                var table = generateTable("stoppagesLogTable", tableData, tableStructure);
                $("#stoppagesLogTableContainer").empty().append(table);

                urlParams = {
                    "request":"getStoppagesLogCSV",
                    "useStartDate" : $('#startDateCheckbox').is(':checked'),
                    "useEndDate" : $('#endDateCheckbox').is(':checked'),
                    "startDate" : inputStartDate,
                    "endDate" : inputEndDate,
                    "searchPhrase" : SearchPhrase
                };
                var csvUrl = "../scripts/server/stoppages.php?" + $.param(urlParams);
                $("#csvDownloadLink").attr("href",csvUrl).show();
            }
        }
    });
}

function addNewStoppageReason(){
    var stoppageReason = $("#newStoppageReason").val();
    stoppageReason = stoppageReason.trim();
    
    if(stoppageReason.length == 0){
        $("#addStoppageReasonResponseField").html("Stoppage Reason must not be blank");
        return;
    }
    
    if(stoppageReason.length > 20){
        $("#addStoppageReasonResponseField").html("Stoppage Reason must not be longer than 20 characters");
        return;
    }

	regexp = /^[a-z0-9_ ]+$/i;
	if(!regexp.test(stoppageReason)){
		$("#addStoppageReasonResponseField").html("Stoppage Reason must only contain letters (a-z, A-Z), numbers (0-9), spaces and underscores (_)");
		return;
	}
	
	if(stoppageReason.charAt(0) == ' '){
		$("#addStoppageReasonResponseField").html("Stoppage Reason cannot start with a space.");
		return;
	}
    
    $.ajax({
        url:"../scripts/server/stoppages.php",
        type:"GET",
        dataType:"text",
        data:{
            "request":"addStoppageReason",
            "stoppageReason":stoppageReason
        },
        success:function(result){
	    console.log(result);
            resultJson = $.parseJSON(result);
            if(resultJson["status"] != "success")
                $("#addStoppageReasonResponseField").html(resultJson["result"]);
            else{
                $("#addStoppageReasonResponseField").html("Generating QR code. Please wait...");
                $.ajax({
                    url:"../scripts/server/stoppages.php",
                    type:"GET",
                    dataType:"text",
                    data:{
                        "request":"getStoppageReasonId",
                        "stoppageReason":stoppageReason
                    },
                    success:function(result){
                    console.log(result);
                    resultJson = $.parseJSON(result);
                    $stoppageReasonId = resultJson["result"]
                        var url = new URL(window.location.origin + "/timelogger/scripts/server/getQrCode.php?request=getDownloadstoppageIdQrCode&stoppagereasonId=" + $stoppageReasonId);
                        var a = $('<a/>')
                            .attr('href', url)
                            .html('Click here to download - ' + stoppageReason + ' - ID - QR Code');
                        $("#addStoppageReasonResponseField").empty().append(a);
                    }
                });
                // at this point, a new user is present in the system, so update the display
                updateStoppageReasonTable();
				
				//Empty new user input box
				$("#newStoppageReason").val("");
                $("#newStoppageReasonCounter").html("20/20");
            }
        }
    });
    updateStoppageReasonTable();
}

function onGetDownloadStoppageQrCodeClick(event){
    getDownloadStoppageQrCode(event.data.stoppageReasonId);
}

function getDownloadStoppageQrCode(stoppageReasonId){
    // send a request to download the stoppage qr code. 
    
    var url = new URL(window.location.origin + "/timelogger/scripts/server/getQrCode.php?request=getDownloadstoppageIdQrCode&stoppagereasonId=" + stoppageReasonId);
    window.location.href = url;
}

function deleteStoppageReason(stoppageReasonId){
    // find nearest element with a Stoppage Reason attached to it
    // send a request to delete that user
    // refresh the table
    if(confirm("Are you sure you want to permantly delete stoppage '" + stoppageReasonId + "' and all associated logs?")){
	    console.log("Deleting Stoppage Reason with ID " + stoppageReasonId);
	    
	    $.ajax({
		url:"../scripts/server/stoppages.php",
		type:"GET",
		dataType:"text",
		data:{
		    "request":"deleteStoppageReason",
		    "stoppageReasonId":stoppageReasonId
		},
		success:function(result){
		    console.log(result);
		    updateStoppageReasonTable();
		}
	    });
	}
}
