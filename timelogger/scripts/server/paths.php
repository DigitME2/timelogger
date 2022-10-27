<?

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

    $sysOS = "linux";

    if (($sysOS) == "windows") {    

        $JobQrCodeDirAbs = "C:/xampp/htdocs/timelogger/generatedJobQrCodes/";
        $JobQrCodeDirRelativeToPage = "../generatedJobQrCodes/";

        $ProductQrCodeDirAbs = "C:/xampp/htdocs/timelogger/generatedProductQrCodes/";
        $ProductQrCodeDirRelativeToPage = "../generatedProductQrCodes/";

        $StoppageReasonQrCodeDirAbs = "C:/xampp/htdocs/timelogger/generatedStoppageReasonQrCodes/";
        $StoppageReasonQrCodeDirRelativeToPage = "../generatedStoppageReasonQrCodes/";

    } elseif (($sysos) == "linux") {

        $JobQrCodeDirAbs = "/var/www/html/timelogger/generatedJobQrCodes/";
        $JobQrCodeDirRelativeToPage = "../generatedJobQrCodes/";

        $ProductQrCodeDirAbs = "/var/www/html/timelogger/generatedProductQrCodes/";
        $ProductQrCodeDirRelativeToPage = "../generatedProductQrCodes/";

        $StoppageReasonQrCodeDirAbs = "/var/www/html/timelogger/generatedStoppageReasonQrCodes/";
        $StoppageReasonQrCodeDirRelativeToPage = "../generatedStoppageReasonQrCodes/";

    } elseif (($sysos) == "lampp") {

        $JobQrCodeDirAbs = "/opt/lampp/htdocs/timelogger/generatedJobQrCodes/";
        $JobQrCodeDirRelativeToPage = "../generatedJobQrCodes/";

        $ProductQrCodeDirAbs = "/opt/lampp/htdocs/timelogger/generatedProductQrCodes/";
        $ProductQrCodeDirRelativeToPage = "../generatedProductQrCodes/";

        $StoppageReasonQrCodeDirAbs = "/opt/lampp/htdocs/timelogger/generatedStoppageReasonQrCodes/";
        $StoppageReasonQrCodeDirRelativeToPage = "../generatedStoppageReasonQrCodes/";

    }

    
?>