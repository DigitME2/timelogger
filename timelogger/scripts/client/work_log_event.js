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

function loadWorkLogRecord(workLogRef){
	//load the active scanner and information about the work log event and populate page
	disableControls(true);
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

				var activeScanners = resultJson.result;

				$("#stationId").empty();
				for(var i = 0; i < activeScanners.length; i++){
					var newOption = $("<option>")
						.text(activeScanners[i].stationId)
						.attr("value", activeScanners[i].stationId);
					$("#stationId").append(newOption);
				}

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
						if(record.userName == null){
							disableControls(true);
							$("#btnSaveChanges").attr("disabled", true);
							$("#btnDeleteEvent").attr("disabled", true);
							$("#btnInsertBreak").attr("disabled", true);
							$("#quantityComplete").attr("disabled", true);
							$("#saveChangesFeedback").html("RECORD NOT FOUND");
							console.log("Record not found. stopping");
							return;
						}

						var stationIds = document.getElementById('stationId').options;			
						var idPresentFlag = false;

						for (i =0; 	i < stationIds.length; i++)
						{
							if(stationIds[i].text === record.stationId)
								idPresentFlag = true;
						}
						
						if(idPresentFlag === false)
						{
							var newStationOption = $("<option>")
									.text(record.stationId)
									.attr("value", record.stationId);
							$("#stationId").append(newStationOption);
						}

						disableControls(false);
					
						//Populate Page
						$("#jobId").html(record.jobId);
						$("#stationId").val(record.stationId);
						$("#userName").html(record.userName);
						$("#date").html(record.recordDate);
						$("#startTime").val(record.clockOnTime);
						$("#endTime").val(record.clockOffTime);
						
						if(record.clockOffTime == null)
						{
							$("#endTime").attr("disabled", true);
							$("#status").attr("disabled", true);
							$("#quantityComplete").attr("disabled", true);
						}else
						{
							$("#endTime").attr("disabled", false);
							$("#status").attr("disabled", false);
							$("#quantityComplete").attr("disabled", false);
						}

						$("#stationId").attr("disabled", true);//Disable ability to edit station Id due to stage index timelog issue

						$("#duration").html(record.workedDuration);
						$("#overtime").html(record.overtimeDuration);
						$("#status").val(record.workStatus);
						$("#quantityComplete").val(record.quantityComplete);

						updateEventTable(record);	

						
					}
				});
			}
		}
	});
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

