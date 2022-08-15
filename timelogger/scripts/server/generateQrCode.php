<?php
require_once "phpqrcode/qrlib.php";
$location = "test/".uniqid().".png";
$text = "random";
QRcode::png($text, $location, 'L', 10, 10);
echo "<center><img src='".$location."'><center>";
