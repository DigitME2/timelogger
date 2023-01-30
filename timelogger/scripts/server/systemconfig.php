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

 
require "db_params.php";

function getSystemConfigParameterValue($ParamName, $DbConn = null)
{
    global $dbParamsServerName;
    global $dbParamsUserName;
    global $dbParamsPassword;
    global $dbParamsDbName;

    if ($DbConn == null)
        $DbConn = initDbConn($dbParamsServerName, $dbParamsUserName, $dbParamsPassword, $dbParamsDbName);

    // check show quantity totals is true or false
    $query = "SELECT `paramValue` FROM `config` WHERE `paramName`=? LIMIT 1";
    
    if(!($statement = $DbConn->prepare($query)))
        errorHandler("Error preparing statement: ($DbConn->errno) $DbConn->error, line " . __LINE__);
    
    if(!($statement->bind_param('s', $ParamName)))
        errorHandler("Error binding parameters: ($statement->errno) $statement->error, line " . __LINE__);
    
    if(!$statement->execute())
        errorHandler("Error executing statement: ($statement->errno) $statement->error, line " . __LINE__);
    
    $res = $statement->get_result();

    if($res->num_rows > 0)
    {
        $row = $res->fetch_row();
        return $row[0];
    }
    
    return null;
}

function showQuantityComplete($DbConn = null)
{
    return getSystemConfigParameterValue("showQuantityComplete", $DbConn) == "true";
}

function publishKafkaEvents($DbConn = null)
{
    return getSystemConfigParameterValue("publishKafkaEvents", $DbConn) == "true";
}

?>