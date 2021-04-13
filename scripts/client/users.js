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
                            "linkDataName":"pathToQrCode",
                            "linkIsDownload":true,
                            "linkText":"Download QR code"
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
                $.ajax({
                    url:"../scripts/server/users.php",
                    type:"GET",
                    dataType:"text",
                    data:{
                        "request":"getQrCode",
                        "userId":userId
                    },
                    success:function(result){
                        resultJson = $.parseJSON(result);
                        if(resultJson["status"] != "success")
                            $("#addUserResponseField").html(resultJson["result"]);
                        else{
                            var a = $('<a/>')
                                .attr('href', resultJson["result"])
                                .attr('download', userId+"_qrcode.png")
                                .html('Click here to download user ID QR code');
                            $("#addUserResponseField").empty().append(a);
                            
                            // at this point, a new user is present in the system, so update the display
                            updateUserTable();
							
							//Empty new user input box
							$("#newUserName").val("");
                            $("#newUserNameCounter").html("50/50");
                        }
                    }
                });
            }
        }
    });
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
