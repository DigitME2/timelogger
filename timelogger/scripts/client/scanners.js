$(document).ready(function(){
	setUpKeyPress();// setup enter press submit

	updateScannersTable();
	loadExtraScannerNames();
	
	$("#scannerNewName").on('keyup', function(){
		var nameCharsRemaining = 14 - $("#scannerNewName").val().length;
		$("#scannerNewNameCounter").html(nameCharsRemaining + "/14"); 
	});
	
	$("#newExtraScannerName").on('keyup', function(){
		var nameCharsRemaining = 14 - $("#newExtraScannerName").val().length;
		$("#extraScannerNewNameCounter").html(nameCharsRemaining + "/14"); 
	});
	
	setInterval(function(){updateScannersTable();}, 10000)
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

function loadExtraScannerNames(){
	$.ajax({
        url:"../scripts/server/scanners.php",
        type:"GET",
        dataType:"text",
        data:{
            "request":"getExtraScannerNames"
        },
        success:function(result){
	    console.log(result);
            resultJson = $.parseJSON(result);
            if(resultJson["status"] != "success")
                console.log(resultJson["result"]);
            else{
                var extraNames = resultJson.result;
				
				// update the select box to show only currently active scanners
				$("#extraScannerNames").empty().append('<option value="noSelection">Select a scanner...</option>');
				for(var i = 0; i < extraNames.length; i++){
					var newOption = $("<option>")
						.text(extraNames[i])
						.attr("value", extraNames[i]);
					$("#extraScannerNames").append(newOption);
				}
				$("#extraScannerNames").val("noSelection");
            }
        }
    });
}

function addNewExtraScannerName(){
	var newName = $("#newExtraScannerName").val();
	$.ajax({
        url:"../scripts/server/scanners.php",
        type:"GET",
        dataType:"text",
        data:{
            "request":"addExtraScannerName",
            "newName":newName
        },
        success:function(result){
	    console.log(result);
            resultJson = $.parseJSON(result);
            if(resultJson["status"] != "success"){
                console.log(resultJson["result"]);
                $("#extraScannerNameFeedback").empty().html("Error");
				setTimeout(function(){$("#extraScannerNameFeedback").empty();},10000);
			}
            else{
				loadExtraScannerNames();
				$("#newExtraScannerName").val("");
				$("#extraScannerNameFeedback").empty().html(newName + " added");
				setTimeout(function(){$("#extraScannerNameFeedback").empty();},10000);
            }
        }
    });
}

function deleteExtraScannerName(){
	var name = $("#extraScannerNames").val();
	if(name != "noSelection"){
		$.ajax({
		    url:"../scripts/server/scanners.php",
		    type:"GET",
		    dataType:"text",
		    data:{
		        "request":"deleteExtraScannerName",
		        "name":name
		    },
		    success:function(result){
			console.log(result);
		        resultJson = $.parseJSON(result);
		        if(resultJson["status"] != "success"){
		            console.log(resultJson["result"]);
		            $("#extraScannerNameFeedback").empty().html("Error");
					setTimeout(function(){$("#extraScannerNameFeedback").empty();},10000);
		        }
		        else{
					loadExtraScannerNames();
					$("#extraScannerNameFeedback").empty().html(name + " removed");
					setTimeout(function(){$("#extraScannerNameFeedback").empty();},10000);
		        }
		    }
		});
	}
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
                
                var listContainsBoxes = false;
                var listContainsApps = false;
                
                for(let i = 0; i < tableData.length; i++){
                	if(tableData[i]['isApp'] == "true")
                		listContainsApps = true;
                	else
                		listContainsBoxes = true;
                }
                
                if(listContainsApps && listContainsBoxes)
                {
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
		                            "headingName":"Version",
		                            "dataName":"version"
		                        },
		                        {
		                        	"headingName":"Is App?",
		                        	"dataName":"isApp"
		                        }
		                    ]
		                };
				}
				else
				{
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
		                            "headingName":"Version",
		                            "dataName":"version"
		                        }
		                    ]
		                };
				}
				var table = generateTable("activeScannersTable", tableData, tableStructure);
				$("#scannerNameTableContainer").empty().append(table);
				
				if(listContainsBoxes){
					$("#scannerRenameContainer").prop("hidden",false);
					// update the select box to show only currently active scanners
					$("#scannerCurrentName").empty().append('<option value="noSelection">Select a scanner...</option>');
					for(var i = 0; i < tableData.length; i++){
						if(tableData[i].isApp == "false"){
							var newOption = $("<option>")
								.text(tableData[i].stationId)
								.attr("value", tableData[i].stationId);
							$("#scannerCurrentName").append(newOption);
						}
					}
				}
            }
        }
    });
}

function renameScanner(){
	scannerCurrentName = $("#scannerCurrentName").val();
	if(scannerCurrentName == "noSelection"){
		console.log("No current scanner selected, Stopping.");
		$("#renameFeedback").html("No current scanner selected, unable to rename!!");
		setTimeout(function(){$("#renameFeedback").empty()},10000);
		return;
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
				$("#scannerNewName").val("");
				$("#scannerCurrentName").val("noSelection");
				$("#renameFeedback").html("Station renamed. This may require a moment to take effect.");
				setTimeout(function(){$("#renameFeedback").empty()},10000);
			}
        }
    });
}
