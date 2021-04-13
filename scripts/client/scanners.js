$(document).ready(function(){
	setUpKeyPress();// setup enter press submit

	updateScannersTable();
	$("#scannerNewName").on('keyup', function(){
		var nameCharsRemaining = 14 - $("#scannerNewName").val().length;
		$("#scannerNewNameCounter").html(nameCharsRemaining + "/14"); 
	});
	setInterval(function(){updateScannersTable();}, 60000)
	
	$("#newStation").prop("checked", false);
	
	$("#newStation").change(function(){
	    if($(this).is(':checked')) {
			$("#scannerCurrentName").prop("disabled", true);
	    } else {
			$("#scannerCurrentName").prop("disabled", false);
	    }
	});
});

// set function to call renameScanner when enter key pressed to submit
function setUpKeyPress(){
	$("#scannerNewName").keypress(function(e) {
		var keycode = (e.keycode ? e.keycode : e.which);
		if (keycode == 13){
			renameScanner();
		}
	});
}

function updateScannersTable(){
	$.ajax({
        url:"../scripts/server/scanners.php",
        type:"GET",
        dataType:"text",
        data:{
            "request":"getConnectedClients"
        },
        success:function(result){
	    console.log(result);
            resultJson = $.parseJSON(result);
            if(resultJson["status"] != "success")
                console.log(resultJson["result"]);
            else{
                var tableData = resultJson.result;
				var tableStructure = {
                        "rows":{},
                        "columns":[
                            {
                                "headingName":"Scanner Station Name",
                                "dataName":"stationId"
                            },
                            {
                                "headingName":"Last Seen",
                                "dataName":"lastSeen"
                            },
		                    {
		                        "headingName":"Delete",
		                        "functionToRun":deleteStation,
		                        "functionParamDataName":"stationId",
		                        "functionParamDataLabel":"stationId",
		                        "functionButtonText":"Delete"
		                    }
                        ]
                    };
				var table = generateTable("activeScannersTable", tableData, tableStructure);
				$("#scannerNameTableContainer").empty().append(table);
				
				// update the select box to show only currently active scanners
				$("#scannerCurrentName").empty().append('<option value="noSelection">Select a scanner...</option>');
				for(var i = 0; i < tableData.length; i++){
					var newOption = $("<option>")
						.text(tableData[i].stationId)
						.attr("value", tableData[i].stationId);
					$("#scannerCurrentName").append(newOption);
				}
            }
        }
    });
}

function renameScanner(){
	if ($('#newStation').is(":checked")){
		scannerCurrentName = null;
	}
	else{
		scannerCurrentName = $("#scannerCurrentName").val();
		if(scannerCurrentName == "noSelection"){
			console.log("No current scanner selected, Stopping.");
			$("#renameFeedback").html("No current scanner selected, unable to rename!!");
			setTimeout(function(){$("#renameFeedback").empty()},10000);
			return;
		}
	}
	
	scannerNewName = $("#scannerNewName").val();
	if(scannerNewName == ""){
		console.log("No new name entered, Stopping.");
		$("#renameFeedback").html("No new name entered, unable to rename!!");
		setTimeout(function(){$("#renameFeedback").empty()},10000);
		return;
	}
	
	regexp = /^[a-z0-9_ ]+$/i;
	if(! regexp.test(scannerNewName)){
		console.log("Scanner Name entered contains invalid chars. Stopping");
		$("#renameFeedback").empty().html("Scanner Name must only contain letters (a-z, A-Z), numbers (0-9), spaces ( ) and underscores (_)!!");
		setTimeout(function(){$("#renameFeedback").empty();},10000);
		return;
	}
	
	$.ajax({
        url:"../scripts/server/scanners.php",
        type:"GET",
        dataType:"text",
        data:{
            "request":"startRenameClient",
			"currentName":scannerCurrentName,
			"newName":scannerNewName
        },
        success:function(result){
	    console.log(result);
            resultJson = $.parseJSON(result);
            if(resultJson["status"] != "success"){
                console.log(resultJson["result"]);
				$("#renameFeedback").html("Error");
			}
			else{
				clearInput();
				$("#renameFeedback").html("Station renamed. Please reopen app for change to take effect.");
				setTimeout(function(){$("#renameFeedback").empty()},10000);
				updateScannersTable();
			}
        }
    });
}



function deleteStation(stationId){
	if(stationId == "" || stationId == null){
		console.log("No current scanner selected, Stopping.");
		$("#renameFeedback").html("No current scanner selected!");
		setTimeout(function(){$("#renameFeedback").empty()},10000);
		return;
	}
	
	$.ajax({
        url:"../scripts/server/scanners.php",
        type:"GET",
        dataType:"text",
        data:{
            "request":"deleteStation",
			"currentName":stationId
        },
        success:function(result){
	    console.log(result);
            resultJson = $.parseJSON(result);
            if(resultJson["status"] != "success"){
                console.log(resultJson["result"]);
				$("#renameFeedback").html("Error");
			}
			else{
				clearInput();
				$("#renameFeedback").html("Station deleted. Please reopen app for change to take effect.");
				setTimeout(function(){$("#renameFeedback").empty()},10000);
				updateScannersTable();
			}
        }
    });
}

function clearInput(){
	$("#newStation").prop("checked", false);
	$("#scannerCurrentName").prop("disabled", false);
	$("#scannerNewName").val("");
	$("#scannerCurrentName").val("noSelection");
}
