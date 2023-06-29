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
    loadSavedDbBackups();
    // setTimeout(() => { loadSavedDbBackups(); }, 3000);
    });

function onButtonClickCreateDbBackup(){
    // creates database backup file.
    $("#dbBackupResponseField").empty().html("Database backup started..");
    $.ajax({
        url:"../scripts/server/settings.php",
        type:"GET",
        data:{
            "request":"dbBackup"
        },
        success:function(result){
            console.log(result);
            var resultJson = $.parseJSON(result);

            if(resultJson.status != "success"){
				$("#dbBackupResponseField").empty().html("Database backup failed!");
			}
			else
			{
                $("#dbBackupResponseField").empty().html(resultJson.result);
            }
        }                                 
    });
}

function loadSavedDbBackups(){
    $.ajax({
        url:"../scripts/server/settings.php",
        type:"GET",
        dataTtype:"text",
        data:{
            "request":"loadDbFiles"
        },
        success:function(result){
            console.log(result);
            var resultJson = $.parseJSON(result);

            if(resultJson.status != "success"){
                $("#restoreDbDropDown").empty();
                var placeholder = $("<option>")
                        .text("Select a DB backup file to restore")
                        .attr("value", "");
                $("#restoreDbDropDown").append(placeholder);
            }
			else
			{
                var filesFound = resultJson["result"];
                $("#restoreDbDropDown").empty();
                var placeholder = $("<option>")
                        .text("Select a DB backup file to restore")
                        .attr("value", "");
                $("#restoreDbDropDown").append(placeholder);
                for(var i=0; i < filesFound.length; i++){
                    var newOption = $("<option>")
                        .text(filesFound[i])
                        .attr("value", filesFound[i]);
                    $("#restoreDbDropDown").append(newOption);
                }
            }
        }                                 
    });
}


async function onButtonClickRestoreDbBackup(){
    var selectedDBFile = $("#restoreDbDropDown").val();
    if (selectedDBFile != ""){
        var userSelection = confirm("If you restore this DB file data, then the existing data currently in this software will be permanently lossed. Do want to continue ?.")
        if (userSelection === true){
            $("#restoreDbResponseField").empty().html("Database retore started. This could take some time. Please wait !!");
            $.ajax({
                url:"../scripts/server/settings.php",
                type:"GET",
                dataTtype:"text",
                data:{
                    "request":"restoreDB",
                    "selecteDb": selectedDBFile
                },
                success:function(result){
                    console.log(result);
                    resultJson = $.parseJSON(result);

                    if(resultJson.status != "success"){
                        $("#restoreDbResponseField").empty().html(resultJson.result);
                    }
                    else
                    {
                        $("#restoreDbResponseField").empty().html(resultJson.result);
                    } 
                }                                 
            });  
        } else {
            $("#restoreDbResponseField").empty().html("Database restoration cancelled!");
        }
    }
    else {
        $("#restoreDbResponseField").empty().html("Please select the database file to restore.");
    }
    
}

// function onButtonClickVersionUpdate() {
//     var userSelection = confirm("Warning! This could cause potential break to this software and loss of your database. Do want to continue ?.")
//         if (userSelection === true){
//             $("#versionUpdateResponseField").empty().html("Version updating. This could take some time. Please wait !!");
//             $.ajax({
//                 url:"../scripts/server/settings.php",
//                 type:"GET",
//                 dataTtype:"text",
//                 data:{
//                     "request":"versionUpdate"
//                 },
//                 success:function(result){
//                     console.log(result);
//                     resultJson = $.parseJSON(result);

//                     if(resultJson.status != "success"){
//                         $("#versionUpdateResponseField").empty().html(resultJson.result);
//                     }
//                     else
//                     {
//                         $("#versionUpdateResponseField").empty().html(resultJson.result);
//                     } 
//                 }                                 
//             });  
//         } else {
//             $("#versionUpdateResponseField").empty().html("Version update cancelled!");
//         }
// }