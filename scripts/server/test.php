<?php

print("POST:");
print_r($_POST);
print("REQUEST:");
print_r($_REQUEST);
print("FILES:");
var_dump($_FILES);

$fileName = $_FILES["files1"]["tmp_name"];
$csv = array_map('str_getcsv', file($fileName));
array_walk($csv, function(&$a) use ($csv) {
  $a = array_combine($csv[0], $a);
});
array_shift($csv); # remove column header
print_r($csv);
?>

