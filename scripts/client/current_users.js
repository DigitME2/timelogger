function updateUserTable(){
    $.ajax({
        url:"../scripts/server/current_users.php",
        type:"GET",
        dataType:"text",
        data:{
            "request":"getClockedOnUsers"
        },
        success:function(result){
            console.log(result);
            resultJson = $.parseJSON(result);
            
            if(resultJson["status"] != "success"){
                console.log("Failed to update table: " + resultJson["result"]);
                $("#userTablePlaceholder").html(resultJson["result"]);
            }
            else{
                var tableData = resultJson["result"];
                            
                var tableStructure = {
                    "rows":{
                        "linksToPage":false
                    },
                    "columns":[
                        {
                            "headingName":"Job ID",
                            "dataName":"jobId"
                        },
                        {
                            "headingName":"Product ID",
                            "dataName":"productId"
                        },
                        {
                            "headingName":"User Name",
                            "dataName":"userName"
                        },
                        {
                            "headingName":"Station",
                            "dataName":"stationId"
                        },
                        {
                            "headingName":"Clocked On",
                            "dataName":"clockOnTime"
                        },
						{
							"headingName":"Clock Off",
                        	"functionToRun":clockOffUser,
                            "functionParamDataName":"ref",
                            "functionParamDataLabel":"ref",
                            "functionButtonText":"Clock Off"
						}
                    ]
                };
                
                
                var table = generateTable("currentUsersTable", tableData, tableStructure);
                $("#clockOnUserTableContainer").empty().append(table);
            }
        }
    });
}

function clockOffUser(ref)
{
	$.ajax({
        url:"../scripts/server/current_users.php",
        type:"GET",
        dataType:"text",
        data:{
            "request":"clockOffUser",
			"ref":ref
        },
        success:function(result){
            console.log(result);
            resultJson = $.parseJSON(result);
            
            if(resultJson["status"] != "success"){
                console.log("Failed to clock off: " + resultJson["result"]);
                updateUserTable();
            }
            else{
				console.log("Clock Off Success: " + resultJson["result"]);
				updateUserTable();
            }
        }
    });
}
