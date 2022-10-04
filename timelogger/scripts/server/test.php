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

