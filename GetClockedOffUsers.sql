DELIMITER $$

DROP PROCEDURE IF EXISTS `getClockedOffUsers`$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getClockedOffUsers`() MODIFIES SQL DATA
BEGIN
    DECLARE _countUserIds INT DEFAULT 0;
    DECLARE _userId VARCHAR(20) DEFAULT NULL;
    DECLARE _userName VARCHAR(20) DEFAULT NULL;
    DECLARE _jobId VARCHAR(20) DEFAULT NULL;
    DECLARE _stationId VARCHAR(50) DEFAULT NULL;
    DECLARE _clockOffTime TIME DEFAULT NULL;
    DECLARE _recordDate DATE DEFAULT NULL;

    CREATE TEMPORARY TABLE clockedOffUsersInfo (userName VARCHAR(20), jobId VARCHAR(20), stationId VARCHAR(50), clockOffTime TIME, recordDate DATE);
    CREATE TEMPORARY TABLE clockedOnUserIds (userId VARCHAR(20)); 
    CREATE TEMPORARY TABLE clockedOffUserIds (userId VARCHAR(20));


    INSERT INTO clockedOnUserIds (userId) SELECT DISTINCT userId FROM timeLog 
    WHERE timeLog.clockOnTime IS NOT NULL AND timeLog.clockOffTime IS NULL ORDER BY timeLog.userId ASC;

    -- SELECT userId FROM clockedOnUserIds;
    
    INSERT INTO clockedOffUserIds (userId) SELECT DISTINCT users.userId FROM users 
    WHERE userId != 'office' AND userId != 'noName' AND userId != 'user_Delt' 
    AND userId NOT IN (SELECT clockedOnUserIds.userId FROM clockedOnUserIds);
    
    -- SELECT userId FROM clockedOnUserIds;

    get_user_data_loop: LOOP

        SET _jobId = NULL;
        SET _stationId = NULL;
        SET _clockOffTime = NULL;
        SET _recordDate = NULL;

        SELECT userId INTO _userId FROM clockedOffUserIds LIMIT 1;

        SELECT userName INTO _userName FROM users WHERE users.userId = _userId;
        INSERT INTO clockedOffUsersInfo (userName) VALUE (_userName);

        SELECT JobId, stationId, clockOffTime, recordDate INTO _jobId, _stationId, _clockOffTime, _recordDate FROM timeLog WHERE timeLog.userId = _userId AND clockOffTime IS NOT NULL 
        ORDER BY recordDate DESC, clockOffTime DESC LIMIT 1;

        UPDATE clockedOffUsersInfo SET jobId=_jobId, stationId=_stationId, clockOffTime=_clockOffTime, recordDate=_recordDate 
        WHERE userName = _userName;

        DELETE FROM clockedOffUserIds WHERE userId = _userId;

        SELECT COUNT(userId) INTO _countUserIds FROM clockedOffUserIds;

        IF _countUserIds = 0 THEN
            leave get_user_data_loop;
        END IF;

    END LOOP get_user_data_loop;

    SELECT userName, jobId, stationId, clockOffTime, recordDate FROM clockedOffUsersInfo WHERE clockedOffUsersInfo.userName IS NOT NULL ORDER BY userName ASC;
    
	END$$

DELIMITER ;;