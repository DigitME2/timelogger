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

// searches the database for a keyword, usen constructs a table of the associated job records
function searchJobs($DbConn, $SearchPhrase)
{
    global $debug;
    // Get job IDs, descriptions, and expected hours for jobs where the
    // description contains the search phrase (case insensitive).
    
    // for each job ID, call the table generation functions in
    // job_details_computation_script to get the status and total worked time.
    // Note: This is probably very inefficient, but it will work.
    
    printDebug("Searching job records for search key " . $SearchPhrase);
    
    $SearchPhrase = "%" . $SearchPhrase . "%";
    
    printDebug("Set search key to " . $SearchPhrase);
    
    $query = "SELECT jobId, description, expectedHours FROM jobs WHERE description LIKE ? ORDER BY jobAdded DESC";
    if(!($getJobsQuery = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($getJobsQuery->bind_param('s', $SearchPhrase)))
        errorHandler("Error binding parameters: ($getJobsQuery->errno) $getJobsQuery->error, line " . __LINE__);
    
    if(!$getJobsQuery->execute())
        errorHandler("Error executing statement: ($getJobsQuery->errno) $getJobsQuery->error, line " . __LINE__);
    
    $fullSearchResults = array();
    
    $res = $getJobsQuery->get_result();
    
    for($i = 0; $i < $res->num_rows; $i++)
    {
        $row = $res->fetch_assoc();
        
        $searchResult = array(
            "jobId" => $row["jobId"],
            "description" => $row["description"],
            "expectedHours" => $row["expectedHours"]
        );
        
        $jobRecord = getJobRecords($DbConn, $row["jobId"]);
        
        $searchResult["workedTime"] = $jobRecord["totalWorkedTime"];
        $searchResult["status"] = $jobRecord["currentStatus"];
        
        array_push($fullSearchResults, $searchResult);
    }
    
    return $fullSearchResults;
}
?>

