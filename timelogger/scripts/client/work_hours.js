$(document).ready(function(){
    getCurrentSettings();
});

// get the ccurrent settings from the server and puts them on the screen
function getCurrentSettings(){
    $.ajax({
        url:"../scripts/server/work_hours.php",
        type:"GET",
        dataType:"text",
        data:{
            "request":"getSettings"
        },
        success:function(result){

	    console.log(result);
            var res = $.parseJSON(result);
            if(res["status"] == "success"){
				var workTimes = res["result"]["times"]["workTimes"];
				var lunchTimes = res["result"]["times"]["lunchTimes"];
				
                console.log("Fetched times\n:");
                console.log(workTimes);
                
                for(var i = 0; i < workTimes.length; i++){
                    switch (workTimes[i].day){
                        case "Monday":
                            $("#mondayStart").val(workTimes[i].startTime);
                            $("#mondayFinish").val(workTimes[i].endTime);
                            break;
                        case "Tuesday":
                            $("#tuesdayStart").val(workTimes[i].startTime);
                            $("#tuesdayFinish").val(workTimes[i].endTime);
                            break;
                        case "Wednesday":
                            $("#wednesdayStart").val(workTimes[i].startTime);
                            $("#wednesdayFinish").val(workTimes[i].endTime);
                            break;
                        case "Thursday":
                            $("#thursdayStart").val(workTimes[i].startTime);
                            $("#thursdayFinish").val(workTimes[i].endTime);
                            break;
                        case "Friday":
                            $("#fridayStart").val(workTimes[i].startTime);
                            $("#fridayFinish").val(workTimes[i].endTime);
                            break;
                        case "Saturday":
                            $("#saturdayStart").val(workTimes[i].startTime);
                            $("#saturdayFinish").val(workTimes[i].endTime);
                            break;
                        case "Sunday":
                            $("#sundayStart").val(workTimes[i].startTime);
                            $("#sundayFinish").val(workTimes[i].endTime);
                            break;
                    }
                }
				
				
				
                console.log(lunchTimes);
                
                for(var i = 0; i < lunchTimes.length; i++){
                    switch (lunchTimes[i].day){
                        case "Monday":
                            $("#mondayLunchtimeStart").val(lunchTimes[i].startTime);
                            $("#mondayLunchtimeFinish").val(lunchTimes[i].endTime);
                            break;
                        case "Tuesday":
                            $("#tuesdayLunchtimeStart").val(lunchTimes[i].startTime);
                            $("#tuesdayLunchtimeFinish").val(lunchTimes[i].endTime);
                            break;
                        case "Wednesday":
                            $("#wednesdayLunchtimeStart").val(lunchTimes[i].startTime);
                            $("#wednesdayLunchtimeFinish").val(lunchTimes[i].endTime);
                            break;
                        case "Thursday":
                            $("#thursdayLunchtimeStart").val(lunchTimes[i].startTime);
                            $("#thursdayLunchtimeFinish").val(lunchTimes[i].endTime);
                            break;
                        case "Friday":
                            $("#fridayLunchtimeStart").val(lunchTimes[i].startTime);
                            $("#fridayLunchtimeFinish").val(lunchTimes[i].endTime);
                            break;
                        case "Saturday":
                            $("#saturdayLunchtimeStart").val(lunchTimes[i].startTime);
                            $("#saturdayLunchtimeFinish").val(lunchTimes[i].endTime);
                            break;
                        case "Sunday":
                            $("#sundayLunchtimeStart").val(lunchTimes[i].startTime);
                            $("#sundayLunchtimeFinish").val(lunchTimes[i].endTime);
                            break;
                    }
                }
				
				if(res["result"]["allowMultipleClockOn"] == true)
					$("#allowMultipleClockOn").prop('checked',true);
				else
					$("#allowMultipleClockOn").prop('checked',false);
            }
            else
                console.log(res["result"]);
        }
    });
}

function timesValid(StartTime, EndTime){
    if(StartTime.length != 5 || EndTime.length != 5)
        return false;
    
    var startTimeParts = StartTime.split(":");
    var endTimeParts = EndTime.split(":");
    
    if(startTimeParts.length != 2 || endTimeParts.length != 2)
        return false;
    
    var startHour = parseInt(startTimeParts[0]);
    var startMinute = parseInt(startTimeParts[1]);
    var endHour = parseInt(endTimeParts[0]);
    var endMinute = parseInt(endTimeParts[1]);
    
    if(isNaN(startHour) || isNaN(startMinute) || isNaN(endHour) || isNaN(endMinute))
        return false;
    
    if(startHour < 0 || startHour >= 24 || endHour < 0 || endHour >= 24)
        return false;
    
    if(startMinute < 0 || startMinute >= 60 || endMinute < 0 || endMinute >= 60)
        return false;
        
    if(startHour > endHour)
        return false;
    
    if(startHour == endHour && startMinute > endMinute)
        return false;
    
    return true;
}

function setWorkHours(){
    var times = [];
	var lunchTimes = [];
    var allTimesvalid = true;
    var day = "", startTime = "", endTime = "";
    
    day = "Monday";
    startTime = $("#mondayStart").val();   
    endTime = $("#mondayFinish").val();
    if(!timesValid(startTime, endTime))
        allTimesvalid = false;
    times.push({"day":day, "startTime":startTime, "endTime":endTime});
	
	startTime = $("#mondayLunchtimeStart").val();   
    endTime = $("#mondayLunchtimeFinish").val();
    if(!timesValid(startTime, endTime))
        allTimesvalid = false;
    lunchTimes.push({"day":day, "startTime":startTime, "endTime":endTime});
	
    
    day = "Tuesday";
    startTime = $("#tuesdayStart").val();   
    endTime = $("#tuesdayFinish").val();
    if(!timesValid(startTime, endTime))
        allTimesvalid = false;
    times.push({"day":day, "startTime":startTime, "endTime":endTime});
	
	startTime = $("#tuesdayLunchtimeStart").val();   
    endTime = $("#tuesdayLunchtimeFinish").val();
    if(!timesValid(startTime, endTime))
        allTimesvalid = false;
    lunchTimes.push({"day":day, "startTime":startTime, "endTime":endTime});
	
    
    day = "Wednesday";
    startTime = $("#wednesdayStart").val();   
    endTime = $("#wednesdayFinish").val();
    if(!timesValid(startTime, endTime))
        allTimesvalid = false;
    times.push({"day":day, "startTime":startTime, "endTime":endTime});
	
	startTime = $("#wednesdayLunchtimeStart").val();   
    endTime = $("#wednesdayLunchtimeFinish").val();
    if(!timesValid(startTime, endTime))
        allTimesvalid = false;
    lunchTimes.push({"day":day, "startTime":startTime, "endTime":endTime});
	
    
    day = "Thursday";
    startTime = $("#thursdayStart").val();   
    endTime = $("#thursdayFinish").val();
    if(!timesValid(startTime, endTime))
        allTimesvalid = false;
    times.push({"day":day, "startTime":startTime, "endTime":endTime});
	
	startTime = $("#thursdayLunchtimeStart").val();   
    endTime = $("#thursdayLunchtimeFinish").val();
    if(!timesValid(startTime, endTime))
        allTimesvalid = false;
    lunchTimes.push({"day":day, "startTime":startTime, "endTime":endTime});
	
    
    day = "Friday";
    startTime = $("#fridayStart").val();   
    endTime = $("#fridayFinish").val();
    if(!timesValid(startTime, endTime))
        allTimesvalid = false;
    times.push({"day":day, "startTime":startTime, "endTime":endTime});
	
	startTime = $("#fridayLunchtimeStart").val();   
    endTime = $("#fridayLunchtimeFinish").val();
    if(!timesValid(startTime, endTime))
        allTimesvalid = false;
    lunchTimes.push({"day":day, "startTime":startTime, "endTime":endTime});
	
    
    day = "Saturday";
    startTime = $("#saturdayStart").val();   
    endTime = $("#saturdayFinish").val();
    if(!timesValid(startTime, endTime))
        allTimesvalid = false;
    times.push({"day":day, "startTime":startTime, "endTime":endTime});
	
	startTime = $("#saturdayLunchtimeStart").val();   
    endTime = $("#saturdayLunchtimeFinish").val();
    if(!timesValid(startTime, endTime))
        allTimesvalid = false;
    lunchTimes.push({"day":day, "startTime":startTime, "endTime":endTime});
	
    
    day = "Sunday";
    startTime = $("#sundayStart").val();   
    endTime = $("#sundayFinish").val();
    if(!timesValid(startTime, endTime))
        allTimesvalid = false;
    times.push({"day":day, "startTime":startTime, "endTime":endTime});
	
	startTime = $("#sundayLunchtimeStart").val();   
    endTime = $("#sundayLunchtimeFinish").val();
    if(!timesValid(startTime, endTime))
        allTimesvalid = false;
    lunchTimes.push({"day":day, "startTime":startTime, "endTime":endTime});
	
    
    console.log(times);
	console.log(lunchTimes);
    
    if(!allTimesvalid){
        $("#saveResponseField").html("All times must be valid in the 24 hr format HH:MM and a start time can not be after the finish time");
    }
    else{
        console.log(JSON.stringify(times));
        $("#saveResponseField").html("Please wait...");
		
		if($("#allowMultipleClockOn").is(':checked'))
			var multiClockOn = "true";
		else
			var multiClockOn = "false";
		
        $.ajax({
            url:"../scripts/server/work_hours.php",
            type:"GET",
            dataType:"text",
            data:{
                "request":"saveSettings",
                "workTimes":JSON.stringify(times),
				"lunchTimes":JSON.stringify(lunchTimes),
				"allowMultipleClockOn":multiClockOn
            },
            success:function(result){
	        console.log(result);
                res = $.parseJSON(result);
                if(res["status"] == "success")
                    $("#saveResponseField").html("Settings saved");
                else
                    $("#saveResponseField").html(res["result"]);
            },
            complete:function(){
                console.log(this.url);
            }
            
        });
    }
}
