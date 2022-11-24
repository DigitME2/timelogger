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
    updateUserTable();
    $("#newUserName").on('keyup', function(){
        var userName = $("#newUserName").val();
        
        var userNameCharsRemaining = 50 - userName.length;
        $("#newUserNameCounter").html(userNameCharsRemaining + "/50");
    });

	$(".userDetailsInput").trigger("keyup",null);

	$("#newUserName").keypress(function(e) {
		var keycode = (e.keycode ? e.keycode : e.which)
		if (keycode == 13){
			addNewUser();
		}
	});	
   
	$("#newUserName").focus();
});


function updateUserTable(){
    // get user data, ordered by selected option
    // generate table
    // drop old table and append new one
    
    var sortingOption = $('input[name="tableOrdering"]').filter(':checked').val()
    console.log("Sorting option: " + sortingOption);
    
    $.ajax({
        url:"../scripts/server/users.php",
        type:"GET",
        dataType:"text",
        data:{
            "request":"getUserTableData",
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
                            "headingName":"User Name",
                            "dataName":"userName"
                        },
                        {
                            "headingName":"User ID",
                            "dataName":"userId"
                        },
                        {
                            "headingName":"QR Code",
                            "functionToRun":getDownloadUserQrCode,
                            "functionParamDataName":"userId",
                            "functionParamDataLabel":"userId",
                            "functionButtonText":"Download QR Code"
                        },
                        {
                            "headingName":"Delete user",
                            "functionToRun":deleteUser,
                            "functionParamDataName":"userId",
                            "functionParamDataLabel":"userId",
                            "functionButtonText":"Delete user"
                        }
                    ]
                };
                
                var table = generateTable("userTable", tableData, tableStructure);
                $("#currentUserTableContainer").empty().append(table);
            }
        }
    });
}

function addNewUser(){
    var userName = $("#newUserName").val();
    
    if(userName.length == 0){
        $("#addUserResponseField").html("User Name must not be blank");
        return;
    }
    
    if(userName.length > 50){
        $("#addUserResponseField").html("User Name must not be longer than 50 characters");
        return;
    }
	
	regexp = /^[a-z0-9_ ]+$/i;
	if(!regexp.test(userName)){
		$("#addUserResponseField").html("User Name must only contain letters (a-z, A-Z), numbers (0-9), spaces ( ) and underscores (_)");
		return;
	}
	
	if(userName.charAt(0) == ' '){
		$("#addUserResponseField").html("User Name cannot start with a space.");
		return;
	}
    
    $.ajax({
        url:"../scripts/server/users.php",
        type:"GET",
        dataType:"text",
        data:{
            "request":"addUser",
            "userName":userName
        },
        success:function(result){
	    console.log(result);
            resultJson = $.parseJSON(result);
            if(resultJson["status"] != "success")
                $("#addUserResponseField").html(resultJson["result"]);
            else{
                $("#addUserResponseField").html("Generating QR code. Please wait...");
				var userId = resultJson.result;
                // Generating userId download link.
                var url = new URL(window.location.origin + "/timelogger/scripts/server/getQrCode.php?request=getDownloadUserIdQrCode&userId=" + userId);
                var a = $('<a/>')
                    .attr('href', url)
                    .html('Click here to download - ' + userName + ' - ID - QR Code');
                $("#addUserResponseField").empty().append(a);
                
                // // // at this point, a new user is present in the system, so update the display
                updateUserTable();
                // //Empty new user input box
                $("#newUserName").val("");
                $("#newUserNameCounter").html("50/50");
            }
        }
    });
}

function onGetDownloadUserQrCodeClick(event){
    getDownloadUserQrCode(event.data.userId);
}

function getDownloadUserQrCode(UserId){
    // send a request to download the user qr code. 

    var url = new URL(window.location.origin + "/timelogger/scripts/server/getQrCode.php?request=getDownloadUserIdQrCode&userId=" + UserId);
    window.location.href = url;
}

function onDeleteUserClick(event){
    deleteUser(event.data.userId);
}

function deleteUser(UserId){
    // find nearest element with a userId attached to it
    // send a request to delete that user
    // refresh the table

    if(confirm("Are you sure you want to permantly delete '" + UserId + "'?\nTheir logs will NOT be removed but will instead be shown as 'User Deleted'.")){
		console.log("Deleting user with ID " + UserId);
		
		$.ajax({
		    url:"../scripts/server/users.php",
		    type:"GET",
		    dataType:"text",
		    data:{
		        "request":"deleteUser",
		        "userId":UserId
		    },
		    success:function(result){
			console.log(result);
                updateUserTable();
		    }
		});
	}
}
