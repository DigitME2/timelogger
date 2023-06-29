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
    loadLastState();
    getLocations();
    getUserNames();
    getJobNames();
    resetUserStatus();
});

function onLocationSelectChanged(){
    localStorage.setItem("selectedLocation", $("#location_select").val());
}

function onUserNameSearchInput(){
    localStorage.setItem("lastUserSearchTerm", $("#user_name_search").val());
    getUserNames();
    updateClockOnOffButtonEnabled();
}

function onUserNameSelectChanged(){
    localStorage.setItem("selectedUserName", $("#user_name_select").val());
    updateUserStatus();
}

function onJobNameSearchInput(){
    localStorage.setItem("lastJobSearchTerm", $("#job_name_search").val());
    getJobNames();
    updateClockOnOffButtonEnabled();
}

function onJobNameSelectChanged(){
    localStorage.setItem("selectedJobName", $("#job_name_select").val());
}

function onWorkStatusSelectChanged(){
    localStorage.setItem("selectedWorkStatus", $("#work_status_select").val());
}

function loadLastState(){
    let lastUserSearchTerm = localStorage.getItem("lastUserSearchTerm");
    let lastJobSearchTerm = localStorage.getItem("lastJobSearchTerm");
    let lastWorkStatus = localStorage.getItem("selectedWorkStatus");

    if(lastUserSearchTerm != undefined)
        $("#user_name_search").val(lastUserSearchTerm);

    if(lastJobSearchTerm != undefined)
        $("#job_name_search").val(lastJobSearchTerm);


    if(lastWorkStatus != undefined && lastWorkStatus != null && lastWorkStatus != "")
        $("#work_status_select").val(lastWorkStatus);
}

function getLocations(){
    $.ajax({
        url:"../scripts/server/user_clocking.php",
        type:"GET",
        dataType:"text",
        data:{
            "request": "getLocationNames"
        },
        success:function(result){
            console.log(result);
            let res = $.parseJSON(result);
            let locations = res['result'];

            $("#location_select").empty();

            let i = 0;
            for(i = 0; i < locations.length; i++){
                let option = $("<option>");
                option.html(locations[i]);

                if(locations[i] == localStorage.getItem("selectedLocation"))
                    option.attr("selected", true);

                $("#location_select").append(option);
            }
        }
    });
}

function getUserNames(){
    $.ajax({
        url:"../scripts/server/user_clocking.php",
        type:"GET",
        dataType:"text",
        data:{
            "request": "getUserNames",
            "searchTerm": $("#user_name_search").val()
        },
        success:function(result){
            console.log(result);
            let res = $.parseJSON(result);
            let userNames = res['result'];

            $("#user_name_select").empty();

            let i = 0;
            for(i = 0; i < userNames.length; i++){
                let option = $("<option>");
                option.html(userNames[i]["userName"]);
                option.val(userNames[i]["userId"]);

                if(userNames[i]["userId"] == localStorage.getItem("selectedUserName"))
                    option.prop("selected", true);

                $("#user_name_select").append(option);
            }
            
            if(userNames.length > 0)
                updateUserStatus();
            else
                resetUserStatus();
        }
    });
}

function getJobNames(){
    $.ajax({
        url:"../scripts/server/user_clocking.php",
        type:"GET",
        dataType:"text",
        data:{
            "request": "getJobNames",
            "searchTerm": $("#job_name_search").val()
        },
        success:function(result){
            console.log(result);
            let res = $.parseJSON(result);
            let jobNames = res['result'];

            $("#job_name_select").empty();

            let i = 0;
            for(i = 0; i < jobNames.length; i++){
                let option = $("<option>");
                option.html(jobNames[i]["jobName"]);
                option.val(jobNames[i]["jobId"])

                if(jobNames[i]["jobId"] == localStorage.getItem("selectedJobName"))
                    option.prop("selected", true);
                
                $("#job_name_select").append(option);
            }
        }
    });
}

function resetUserStatus(){
    $("#user_status_current_state").val("Select a username...");
    $("#user_status_job_name").val("No Data");
    $("#user_status_product_name").val("No Data");
    $("#user_status_location_name").val("No Data");
    $("#user_status_display").removeClass("clockedOn clockedOff");
    $("#user_status_display").addClass("noStatus");
}

function updateUserStatus(){
    var userId = $("#user_name_select").val();
    $.ajax({
        url:"../scripts/server/current_users.php",
        type:"GET",
        dataType:"text",
        data:{
            "request": "GetUserStatus",
            "userId": userId
        },
        success:function(result){
            console.log(result);
            let res = $.parseJSON(result);
            let userStatus = res['result'];
            if(userStatus['status'] == 'clockedOn'){
                let selectedUserName = $("#user_name_select>option:selected").text();
                $("#user_status_current_username").text(selectedUserName);
                // $("#user_status_job_name").text(userStatus["jobId"]);
                $("#user_status_job_name").text(userStatus["jobName"]);
                $("#user_status_product_name").text(userStatus["productId"]);
                $("#user_status_location_name").text(userStatus["stationId"]);
                
                $("#user_status_current_state").text("Clocked On");
                $("#user_status_display").removeClass("clockedOff noStatus");
                $("#user_status_display").addClass("clockedOn");
                }
            else if(userStatus['status'] == 'clockedOff'){
                let selectedUserName = $("#user_name_select>option:selected").text();
                $("#user_status_current_username").text(selectedUserName);  
                $("#user_status_job_name").text("");
                $("#user_status_product_name").text("");
                $("#user_status_location_name").text("");

                $("#user_status_current_state").text("Clocked Off");
                $("#user_status_display").removeClass("clockedOn noStatus");
                $("#user_status_display").addClass("clockedOff");
                
            }
            else
                resetUserStatus();
        }
    });
}

function updateClockOnOffButtonEnabled(){

}

function clockUser(){
    let location = $("#location_select").val();
    let userId = $("#user_name_select").val();
    let jobId = $("#job_name_select").val();
    let workStatus = $("#work_status_select").val();

    if(userId == "" || jobId == ""){
        console.log("no username or no job ID. Skipping clocking");
    }

    resetUserStatus();

    $.ajax({
        url:"../scripts/server/client_input.php",
        type:"GET",
        dataType:"text",
        data:{
            "request": "clockUser",
            "userId": userId,
            "jobId": jobId,
            "stationId": location,
            "jobStatus": workStatus
        },
        success:function(result){
            console.log(result);
            let res = $.parseJSON(result);
            if(res['status'] != "success"){
                $("#clock_user_button").val("Error");
                $("#clock_user_button").addClass("error");
                setTimeout(function(){
                    $("#clock_user_button").removeClass("error clockedOn clockedOff");
                    $("#clock_user_button").val("Clock On/Off");
                }, 3000);
            }
            else{
                $("#clock_user_button").prop("disabled",true);
                setTimeout(function(){
                    $("#clock_user_button").prop("disabled", false);
                    updateUserStatus();
                }, 500);
            }
        }
    }); 
}
