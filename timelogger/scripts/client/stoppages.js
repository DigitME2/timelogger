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
                            "linkDataName":"pathToQrCode",
                            "linkIsDownload":true,
                            "linkText":"Download QR code"
                        },
                        {
                            "headingName":"Delete stoppage",
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


				var a = $('<a/>')
                    .attr('href', resultJson["result"])
                    .attr('download', stoppageReason+"_qrcode.png")
                    .html('Click here to download Stoppage Reason QR code');
                $("#addStoppageReasonResponseField").empty().append(a);
                
                // at this point, a new user is present in the system, so update the display
                updateStoppageReasonTable();
				
				//Empty new user input box
				$("#newStoppageReason").val("");
                $("#newStoppageReasonCounter").html("20/20");
            }
        }
    });
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
