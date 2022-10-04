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
                            "linksToPage":true,
                            "link":"job_details_client.php",
                            "linkParamLabel":"jobId",
                            "linkParamDataName":"jobId",
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
    $(this).prop("disabled", true);
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
