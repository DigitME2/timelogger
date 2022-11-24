
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

function addNewStoppageReason(){
    var stoppageReason = $("#newStoppageReason").val();
    
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
    
    var url = new URL(window.location.origin + "/timelogger/scripts/server/getQrCode.php?request=getDownloadstoppageIdQrCode&stoppageReasonId=" + stoppageReasonId);
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
