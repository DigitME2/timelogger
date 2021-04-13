<?php
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

