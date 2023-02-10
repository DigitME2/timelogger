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

// note, parts of this page adapted from https://arnaud.le-blanc.net/php-rdkafka-doc/phpdoc/rdkafka.examples-producer.html
// note, problems are also referred to as stoppages within older parts of the code base. This was changed and the newer name is used here.

require_once "systemconfig.php";

// topic list. Kept in one place for easy editing.
$CreateJobTopic             = "ptt_events";
$UpdateJobTopic             = "ptt_events";
$ChangeJobIdTopic           = "ptt_events";
$DeleteJobTopic             = "ptt_events";
$SetJobProgressStateTopic   = "ptt_events";
$ClockUserTopic             = "ptt_events";
$RecordWorkQtyCompleteTopic = "ptt_events";
$CreateProblemReasonTopic   = "ptt_events";
$DeleteProblemReasonTopic   = "ptt_events";
$RecordProblemStateTopic    = "ptt_events";
$AddProductTypeTopic        = "ptt_events";
$DeleteProductTypeTopic     = "ptt_events";
$SetRouteTopic              = "ptt_events";
$DeleteRouteTopic           = "ptt_events";
$CreateScannerLocationTopic = "ptt_events";
$DeleteScannerLocationTopic = "ptt_events";
$CreateUserTopic            = "ptt_events";
$DeleteUserTopic            = "ptt_events";
$SetWorkHoursTopic          = "ptt_events";
$DeleteWorkHoursTopic       = "ptt_events";
$AddEmptyWorkLogTopic       = "ptt_events";
$InsertWorkLogBreakTopic    = "ptt_events";
$ChangeWorkLogTopic         = "ptt_events";
$DeleteWorkLogTopic         = "ptt_events";

function getKafkaProducer()
{
    $KafkaBrokerUrl = getSystemConfigParameterValue("kafkaBrokerAddress");

    $conf = new RdKafka\Conf();
    $conf->set('metadata.broker.list', $KafkaBrokerUrl);

    $conf->set('enable.idempotence', 'true'); // send exactly once, retaining ordering

    $producer = new RdKafka\Producer($conf);

    return $producer;
}


// function to publish PTT status information as kafka messages. Expects a topic name
// and a string-encoded chunk of JSON to send as the message body
function publishKafkaMessage($TopicName, $MsgBody)
{
    $producer = getKafkaProducer();
    $topic = $producer->newTopic($TopicName);
    $topic->produce(RD_KAFKA_PARTITION_UA, 0, $MsgBody);
    $producer->poll(0);

    for ($flushRetries = 0; $flushRetries < 10; $flushRetries++) {
        $result = $producer->flush(10000);
        if (RD_KAFKA_RESP_ERR_NO_ERROR === $result) {
            break;
        }
    }
    
    if (RD_KAFKA_RESP_ERR_NO_ERROR !== $result) {
        throw new \RuntimeException('Was unable to flush, messages might be lost!');
    }
}

function kafkaOutputCreateJob($JobId, $CustomerName, $ExpectedDurationSec, $DueDate, $Description, $ChargeForJob, $NumberOfUnits, $TotalParts, $ProductId, $RouteId, $Priority)
{
    global $CreateJobTopic;

    // make an early exit if we aren't using kafka
    if(!publishKafkaEvents())
        return;

    $messageBodyParts = array(
        "action" => "create-job",
        "job_id" => $JobId,
        "customer_name" => $CustomerName,
        "expected_time_s" => $ExpectedDurationSec,
        "due_date" => $DueDate,
        "description" => $Description,
        "charge_for_job" => $ChargeForJob,
        "number_of_units" => $NumberOfUnits,
        "total_parts" => $TotalParts,
        "product_id" => $ProductId,
        "route_id" => $RouteId,
        "priority" => $Priority
    );

    publishKafkaMessage($CreateJobTopic, json_encode($messageBodyParts));
}

function kafkaOutputUpdateJobDetails($JobId, $CustomerName, $ExpectedDurationSec, $DueDate, $Description, $ChargeForJob, $NumberOfUnits, $TotalParts, $RouteId, $RouteStageIndex, $Priority, $Notes)
{
    global $UpdateJobTopic;

    // make an early exit if we aren't using kafka
    if(!publishKafkaEvents())
        return;

    $messageBodyParts = array(
        "action" => "update-job",
        "job_id" => $JobId,
        "customer_name" => $CustomerName,
        "expected_time_s" => $ExpectedDurationSec,
        "due_date" => $DueDate,
        "description" => $Description,
        "charge_for_job" => $ChargeForJob,
        "number_of_units" => $NumberOfUnits,
        "total_parts" => $TotalParts,
        "route_id" => $RouteId,
        "route_stage_index" => $RouteStageIndex,
        "priority" => $Priority,
        "notes" => $Notes
    );

    publishKafkaMessage($UpdateJobTopic, json_encode($messageBodyParts));
}

function kafkaOutputChangeJobId($OldJobId, $NewJobId)
{
    global $ChangeJobIdTopic;

    // make an early exit if we aren't using kafka
    if(!publishKafkaEvents())
        return;

    $messageBodyParts = array(
        "action" => "update-job-id",
        "old_id" => $OldjobId,
        "new_id" => $NewJobId
    );

    publishKafkaMessage($ChangeJobIdTopic, json_encode($messageBodyParts));
}

function kafkaOutputDeleteJob($JobId)
{
    global $DeleteJobTopic;

    // make an early exit if we aren't using kafka
    if(!publishKafkaEvents())
        return;

    $messageBodyParts = array(
        "action" => "delete-job",
        "job_id" => $JobId
    );

    publishKafkaMessage($DeleteJobTopic, json_encode($messageBodyParts));
}

function kafkaOutputSetJobProgressState($JobId, $JobState, $RouteId, $RouteStageIndex)
{
    global $SetJobProgressStateTopic;

    // make an early exit if we aren't using kafka
    if(!publishKafkaEvents())
        return;

    $messageBodyParts = array(
        "action" => "set-job-state",
        "job_id" => $JobId,
        "job_state" => $JobState,
        "route_id" => $RouteId,
        "route_stage_index" => $RouteStageIndex
    );

    publishKafkaMessage($SetJobProgressStateTopic, json_encode($messageBodyParts));
}

function kafkaOutputClockUser($UserId, $UserState, $JobId, $StationId, $WorkStatus, $WorkLogRecordId)
{
    global $ClockUserTopic;

    // make an early exit if we aren't using kafka
    if(!publishKafkaEvents())
        return;

    $messageBodyParts = array(
        "action" => "clock-user",
        "user_id" => $UserId,
        "user_state" => $UserState,
        "job_id" => $JobId,
        "station_id" => $StationId,
        "work_status" => $WorkStatus,
        "work_log_record_id" => $WorkLogRecordId
        
    );

    publishKafkaMessage($ClockUserTopic, json_encode($messageBodyParts));
}

function kafkaOutputRecordWorkQuantityComplete($Quantity, $WorkLogRecordId)
{
    global $RecordWorkQtyCompleteTopic;

    // make an early exit if we aren't using kafka
    if(!publishKafkaEvents())
        return;

    $messageBodyParts = array(
        "action" => "record-quantity-complete",
        "quantity" => $Quantity,
        "work_log_record_id" => $WorkLogRecordId
    );

    publishKafkaMessage($RecordWorkQtyCompleteTopic, json_encode($messageBodyParts));
}

function kafkaOutputCreateProblemReason($ProblemTypeId, $ProblemTypeName)
{
    global $CreateProblemReasonTopic;

    // make an early exit if we aren't using kafka
    if(!publishKafkaEvents())
        return;

    $messageBodyParts = array(
        "action" => "create-problem-reason",
        "problem_type_id" => $ProblemTypeId,
        "problem_type_name" => $ProblemTypeName
    );

    publishKafkaMessage($CreateProblemReasonTopic, json_encode($messageBodyParts));
}

function kafkaOutputDeleteProblemReason($ProblemTypeId)
{
    global $DeleteProblemReasonTopic;

    // make an early exit if we aren't using kafka
    if(!publishKafkaEvents())
        return;

    $messageBodyParts = array(
        "action" => "delete-problem-reason",
        "problem_type_id" => $ProblemTypeId
    );

    publishKafkaMessage($DeleteProblemReasonTopic, json_encode($messageBodyParts));
}

function kafkaOutputRecordProblemState($JobId, $ProblemTypeId, $ProblemIsCurrentlyActive)
{
    global $RecordProblemStateTopic;

    // make an early exit if we aren't using kafka
    if(!publishKafkaEvents())
        return;

    $messageBodyParts = array(
        "action" => "record-problem-state",
        "job_id" => $JobId,
        "problem_type_id" => $ProblemTypeId,
        "problem_currently_active" => $ProblemIsCurrentlyActive
    
    );

    publishKafkaMessage($RecordProblemStateTopic, json_encode($messageBodyParts));
}

function kafkaOutputAddProductType($ProductTypeId)
{
    global $AddProductTypeTopic;

    // make an early exit if we aren't using kafka
    if(!publishKafkaEvents())
        return;

    $messageBodyParts = array(
        "action" => "add-product-type",
        "product_type_id" => $ProductTypeId
    );

    publishKafkaMessage($AddProductTypeTopic, json_encode($messageBodyParts));
}

function kafkaOutputDeleteProductType($ProductTypeId)
{
    global $DeleteProductTypeTopic;

    // make an early exit if we aren't using kafka
    if(!publishKafkaEvents())
        return;

    $messageBodyParts = array(
        "action" => "delete-product-type",
        "product_type_id" => $ProductTypeId
    );

    publishKafkaMessage($DeleteProductTypeTopic, json_encode($messageBodyParts));
}

function kafkaOutputSetRoute($RouteId, $RouteDescription)
{
    global $SetRouteTopic;

    // make an early exit if we aren't using kafka
    if(!publishKafkaEvents())
        return;

    $messageBodyParts = array(
        "action" => "set-route",
        "route_id" => $RouteId,
        "route_description" => $RouteDescription
    );

    publishKafkaMessage($SetRouteTopic, json_encode($messageBodyParts));
}

function kafkaOutputDeleteRoute($RouteId)
{
    global $DeleteRouteTopic;

    // make an early exit if we aren't using kafka
    if(!publishKafkaEvents())
        return;

    $messageBodyParts = array(
        "action" => "delete-route",
        "route_id" => $RouteId
    );

    publishKafkaMessage($DeleteRouteTopic, json_encode($messageBodyParts));
}

function kafkaOutputCreateScannerLocation($LocationName)
{
    global $CreateScannerLocationTopic;

    // make an early exit if we aren't using kafka
    if(!publishKafkaEvents())
        return;

    $messageBodyParts = array(
        "action" => "create-scanner-location",
        "location_name" => $LocationName
    );

    publishKafkaMessage($CreateScannerLocationTopic, json_encode($messageBodyParts));
}

function kafkaOutputDeleteScannerLocation($LocationName)
{
    global $DeleteScannerLocationTopic;

    // make an early exit if we aren't using kafka
    if(!publishKafkaEvents())
        return;

    $messageBodyParts = array(
        "action" => "delete-scanner-location",
        "location_name" => $LocationName
    );

    publishKafkaMessage($DeleteScannerLocationTopic, json_encode($messageBodyParts));
}

function kafkaOutputCreateUser($UserId, $UserName)
{
    global $CreateUserTopic;

    // make an early exit if we aren't using kafka
    if(!publishKafkaEvents())
        return;

    $messageBodyParts = array(
        "action" => "create-user",
        "user_id" => $UserId,
        "user_name" => $UserName
        
    );

    publishKafkaMessage($CreateUserTopic, json_encode($messageBodyParts));
}

function kafkaOutputDeleteUser($UserId)
{
    global $DeleteUserTopic;

    // make an early exit if we aren't using kafka
    if(!publishKafkaEvents())
        return;

    $messageBodyParts = array(
        "action" => "delete-user",
        "user_id" => $UserId
    );

    publishKafkaMessage($DeleteUserTopic, json_encode($messageBodyParts));
}

function kafkaOutputSetWorkHours($DayStartTimes, $DayEndTimes, $LunchStartTimes, $LunchEndTimes)
{
    global $SetWorkHoursTopic;

    // make an early exit if we aren't using kafka
    if(!publishKafkaEvents())
        return;

    $messageBodyParts = array(
        "action" => "set-work-hours",
        "day_start_times" => $DayStartTimes,
        "lunch_start_times" => $LunchStartTimes,
        "lunch_end_times" => $LunchEndTimes,
        "day_end_times" => $DayEndTimes
    );

    publishKafkaMessage($SetWorkHoursTopic, json_encode($messageBodyParts));
}

function kafkaOutputAddEmptyWorkLog($WorkLogId)
{
    global $AddEmptyWorkLogTopic;

    // make an early exit if we aren't using kafka
    if(!publishKafkaEvents())
        return;

    $messageBodyParts = array(
        "action" => "add-empty-work-log",
        "work_log_id" => $WorkLogId
    );

    publishKafkaMessage($AddEmptyWorkLogTopic, json_encode($messageBodyParts));
}

function kafkaOutputChangeWorkLogTopic($WorkLogId, $StationId, $UserId, $RecordDate, $ClockOnTime, $ClockOffTime, $WorkStatus, $QuantityComplete)
{
    global $ChangeWorkLogTopic;

    // make an early exit if we aren't using kafka
    if(!publishKafkaEvents())
        return;

    $messageBodyParts = array(
        "action" => "change-work-log",
        "work_log_id" => $WorkLogId,
        "station_id" => $StationId,
        "user_id" => $UserId,
        "record_date" => $RecordDate,
        "clock_on_time" => $ClockOnTime,
        "clock_off_time" => $ClockOffTime,
        "work_status" => $WorkStatus,
        "quantityComplete" => $QuantityComplete
    );

    publishKafkaMessage($ChangeWorkLogTopic, json_encode($messageBodyParts));
}

function kafkaOutputDeleteWorkLog($WorkLogId)
{
    global $DeleteWorkLogTopic;

    // make an early exit if we aren't using kafka
    if(!publishKafkaEvents())
        return;

    $messageBodyParts = array(
        "action" => "delete-work-log",
        "work_log_id" => $WorkLogId
    );

    publishKafkaMessage($DeleteWorkLogTopic, json_encode($messageBodyParts));
}

function kafkaOutputInsertWorkLogBreak($OriginalWorkLogId, $StartTime, $EndTime)
{
    global $InsertWorkLogBreakTopic;

    // make an early exit if we aren't using kafka
    if(!publishKafkaEvents())
        return;

    $messageBodyParts = array(
        "action" => "insert-work-log-break",
        "original_record_id" => $OriginalWorkLogId,
        "break_start_time" => $StartTime,
        "break_end_time" => $EndTime
    );

    publishKafkaMessage($InsertWorkLogBreakTopic, json_encode($messageBodyParts));
}


?>

