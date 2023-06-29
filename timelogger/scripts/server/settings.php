<?php

//  Copyright 2022 DigitME2

//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at

//      http://www.apache.org/licenses/LICENSE-2.0

//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.


// Note that the database conenction is implicitly released when this script 
// terminates

ini_set('display_errors', 1);
error_reporting(E_ALL);

require "db_params.php";
require "common.php";
require_once "kafka.php";

// function getThisVersionUpdated($DbConn) 
// {
//     // removing job prefix for jobids if exists in jobs table.
//     $query = "UPDATE jobs SET jobId = REPLACE(`jobId`, 'job_', '')";
//     if(!($statement = $DbConn->prepare($query)))
//         errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
//     if(!$statement->execute())
//         errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

//     // adding jobName column to the jobs table in jobs table.
//     $query = "ALTER TABLE jobs ADD COLUMN jobName varchar(20) NOT NULL";
//     if(!($statement = $DbConn->prepare($query)))
//         errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
//     if(!$statement->execute())
//         errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

//     // copying all the jobIds without prefix to the jobName column in jobs table.
//     $query = "UPDATE jobs SET jobName=jobId";
//     if(!($statement = $DbConn->prepare($query)))
//         errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
//     if(!$statement->execute())
//         errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);

//     // Finally adding job prefix to the jobIDs in jobs table.
//     $query = "UPDATE jobs SET jobId=CONCAT('job_', jobId)";
//     if(!($statement = $DbConn->prepare($query)))
//         errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
//     if(!$statement->execute())
//         errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
// }


function db_backup(){

        //File to save backup 
        $fileName = "db_".date("H_i_s_d_m_Y")."_backup.sql";
        $returnVar = exec("mysqldump --user=server --password=gnlPdNTW1HhDuQGc work_tracking > /var/www/html/timelogger/backups/".$fileName);
        echo $returnVar;
        return $fileName;
}

function loadSavedDbFiles(){
    $Required_dir = "/var/www/html/timelogger/backups/";
    $files = scandir($Required_dir, SCANDIR_SORT_DESCENDING);
    $checkDir = count($files);
    if ($checkDir > 0){
        $files = array_diff($files, [".", ".."]);
        return $files;
    }
    else {
        return false;
    }
}

function restoreDB($selectedDB){
        $restore_db = exec("mysql --user=server --password=gnlPdNTW1HhDuQGc work_tracking < /var/www/html/timelogger/backups/" . $selectedDB);
        return true;
}

function main()
{
    global $dbParamsServerName;
    global $dbParamsUserName;
    global $dbParamsPassword;
    global $dbParamsDbName;
    
    $dbConn = initDbConn($dbParamsServerName, $dbParamsUserName, $dbParamsPassword, $dbParamsDbName);
    $dbConn->autocommit(TRUE);

    $request = $_GET["request"];
    
    switch($request)
    {
        case "dbBackup":
            $fileName = db_backup();
            sendResponseToClient("success", "Database file saved successfully - ".$fileName);
            break;
        
        case "loadDbFiles":
            if (loadSavedDbFiles()){
                $req = loadSavedDbFiles();
                sendResponseToClient("success", $req);
            }
            else {
                sendResponseToClient("Error", "Files not found!");
            }
            break;
        
        case "restoreDB":
            $selectedDb = $_GET["selecteDb"];
            printDebug("Restoring selected DB.");
            if(restoreDB($selectedDb)) {
                restoreDB($selectedDb);
                sendResponseToClient("success", "Selected DB data restored successfully.");
            }
            else {
                sendResponseToClient("Error", "Db restore failed!"); 
            }
            break;
        
        // case "versionUpdate":
        //     getThisVersionUpdated($dbConn);
        //     sendResponseToClient("success", "Version Updated successfully.");
        //     break;
    }
}

main();


?>