<?php 
 
 require "db_params.php";
 require "common.php";

 function showQuantityComplete($DbConn = null){

    global $dbParamsServerName;
    global $dbParamsUserName;
    global $dbParamsPassword;
    global $dbParamsDbName;

    if ($DbConn == null)
        $DbConn = initDbConn($dbParamsServerName, $dbParamsUserName, $dbParamsPassword, $dbParamsDbName);

    // check show quantity totals is true ot false
    $query = "SELECT `paramValue` FROM `config` WHERE `paramName`='showQuantityComplete' LIMIT 1";
    
    $dbresult = $DbConn->prepare($query);

    $dbresult->execute();
    
    $res = $dbresult->get_result();

    $dbRow = $res->fetch_assoc();

    $getQuantityRow = $dbRow['paramValue'];
    
    if ($getQuantityRow=='true')
         return true;
    else
        return false;

}
 

?>