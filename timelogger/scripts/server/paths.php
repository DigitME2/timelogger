<?php

$envVersion = "linux";
//$envVersion = "windows";
//$envVersion = "xampp_docker";

if($envVersion == "linux")
{
	$JobQrCodeDirAbs = "/var/www/html/timelogger/generatedJobQrCodes/";
	$JobQrCodeDirRelativeToPage = "../generatedJobQrCodes/";

	$ProductQrCodeDirAbs = "/var/www/html/timelogger/generatedProductQrCodes/";
	$ProductQrCodeDirRelativeToPage = "../generatedProductQrCodes/";

	$StoppageReasonQrCodeDirAbs = "/var/www/html/timelogger/generatedStoppageReasonQrCodes/";
	$StoppageReasonQrCodeDirRelativeToPage = "../generatedStoppageReasonQrCodes/";
	
	$UserQrCodeDirAbs = "/var/www/html/timelogger/generatedUserQrCodes/";
	$UserQrCodeDirRelativeToPage = "../generatedUserQrCodes/";
}
else if($envVersion == "windows")
{
	$JobQrCodeDirAbs = "";
	$JobQrCodeDirRelativeToPage = "../generatedJobQrCodes/";

	$ProductQrCodeDirAbs = "";
	$ProductQrCodeDirRelativeToPage = "../generatedProductQrCodes/";

	$StoppageReasonQrCodeDirAbs = "";
	$StoppageReasonQrCodeDirRelativeToPage = "../generatedStoppageReasonQrCodes/";
	
	$UserQrCodeDirAbs = "";
	$UserQrCodeDirRelativeToPage = "../generatedUserQrCodes/";
}
else if($envVersion == "xampp_docker")
{
	$JobQrCodeDirAbs = "/opt/lampp/htdocs/timelogger/generatedJobQrCodes/";
	$JobQrCodeDirRelativeToPage = "../generatedJobQrCodes/";

	$ProductQrCodeDirAbs = "/opt/lampp/htdocs/timelogger/generatedProductQrCodes/";
	$ProductQrCodeDirRelativeToPage = "../generatedProductQrCodes/";

	$StoppageReasonQrCodeDirAbs = "/opt/lampp/htdocs/timelogger/generatedStoppageReasonQrCodes/";
	$StoppageReasonQrCodeDirRelativeToPage = "../generatedStoppageReasonQrCodes/";
	
	$UserQrCodeDirAbs = "/opt/lampp/htdocs/timelogger/generatedUserQrCodes/";
	$UserQrCodeDirRelativeToPage = "../generatedUserQrCodes/";
}

?>
