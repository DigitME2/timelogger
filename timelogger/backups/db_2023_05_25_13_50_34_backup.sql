-- MySQL dump 10.13  Distrib 8.0.33, for Linux (x86_64)
--
-- Host: localhost    Database: work_tracking
-- ------------------------------------------------------
-- Server version	8.0.33-0ubuntu0.22.04.2

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `accounts`
--

DROP TABLE IF EXISTS `accounts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `accounts` (
  `id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `accounts`
--

LOCK TABLES `accounts` WRITE;
/*!40000 ALTER TABLE `accounts` DISABLE KEYS */;
INSERT INTO `accounts` VALUES (1,'test','$2y$10$SfhYIDtn.iOuCW7zfoFLuuZHX6lja4lF4XA4JqNmpiH/.P3zB8JCa');
/*!40000 ALTER TABLE `accounts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `clientNames`
--

DROP TABLE IF EXISTS `clientNames`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `clientNames` (
  `currentName` varchar(50) DEFAULT NULL,
  `newName` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `clientNames`
--

LOCK TABLES `clientNames` WRITE;
/*!40000 ALTER TABLE `clientNames` DISABLE KEYS */;
/*!40000 ALTER TABLE `clientNames` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `config`
--

DROP TABLE IF EXISTS `config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `config` (
  `paramName` varchar(100) NOT NULL,
  `paramValue` varchar(100) NOT NULL,
  PRIMARY KEY (`paramName`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `config`
--

LOCK TABLES `config` WRITE;
/*!40000 ALTER TABLE `config` DISABLE KEYS */;
INSERT INTO `config` VALUES ('addLunchBreak','false'),('allowMultipleClockOn','false'),('configVersion','1'),('kafkaBrokerAddress','localhost'),('publishKafkaEvents','false'),('quantityComplete','true'),('requireStageComplete','true'),('showQuantityComplete','true'),('showWorkedTimeInSeconds','false'),('trimLunch','false');
/*!40000 ALTER TABLE `config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `connectedClients`
--

DROP TABLE IF EXISTS `connectedClients`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `connectedClients` (
  `stationId` varchar(50) NOT NULL,
  `lastSeen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `version` varchar(50) DEFAULT NULL,
  `isApp` tinyint(1) DEFAULT '0',
  `nameType` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`stationId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `connectedClients`
--

LOCK TABLES `connectedClients` WRITE;
/*!40000 ALTER TABLE `connectedClients` DISABLE KEYS */;
/*!40000 ALTER TABLE `connectedClients` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `extraScannerNames`
--

DROP TABLE IF EXISTS `extraScannerNames`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `extraScannerNames` (
  `name` varchar(50) DEFAULT NULL,
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `extraScannerNames`
--

LOCK TABLES `extraScannerNames` WRITE;
/*!40000 ALTER TABLE `extraScannerNames` DISABLE KEYS */;
INSERT INTO `extraScannerNames` VALUES ('Assembly'),('Cutting'),('Painting'),('QC'),('Shipping'),('Welding');
/*!40000 ALTER TABLE `extraScannerNames` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jobs`
--

DROP TABLE IF EXISTS `jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jobs` (
  `jobId` varchar(20) NOT NULL,
  `expectedDuration` int DEFAULT NULL,
  `closedWorkedDuration` int NOT NULL DEFAULT '0',
  `closedOvertimeDuration` int NOT NULL DEFAULT '0',
  `description` varchar(200) DEFAULT NULL,
  `currentStatus` varchar(50) DEFAULT NULL,
  `absolutePathToQrCode` varchar(200) DEFAULT NULL,
  `relativePathToQrCode` varchar(200) DEFAULT NULL,
  `recordAdded` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `notes` text,
  `routeName` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `routeCurrentStageName` varchar(50) DEFAULT NULL,
  `routeCurrentStageIndex` int NOT NULL DEFAULT '-1',
  `dueDate` date DEFAULT '9999-12-31',
  `stoppages` text,
  `numberOfUnits` int DEFAULT NULL,
  `totalChargeToCustomer` int DEFAULT NULL,
  `jobIdIndex` int NOT NULL AUTO_INCREMENT,
  `productId` varchar(20) DEFAULT '',
  `priority` int DEFAULT '0',
  `stageQuantityComplete` int DEFAULT NULL,
  `stageOutstandingUnits` int DEFAULT NULL,
  `totalParts` int DEFAULT NULL,
  `customerName` varchar(120) DEFAULT NULL,
  PRIMARY KEY (`jobId`),
  KEY `jobIdIndex` (`jobIdIndex`),
  KEY `IDX_jobId_desc` (`jobId`,`description`)
) ENGINE=InnoDB AUTO_INCREMENT=90 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jobs`
--

LOCK TABLES `jobs` WRITE;
/*!40000 ALTER TABLE `jobs` DISABLE KEYS */;
INSERT INTO `jobs` VALUES ('WO33652',207900,208361,620,'Modular frame assemblies','complete',NULL,NULL,'2023-05-09 12:48:50',NULL,'No Paint','Shipping',5,'2023-05-17',NULL,10,90000,72,'',2,NULL,NULL,80,'ABC Construction'),('WO33653',71100,71695,7,'Packing noodles','complete',NULL,NULL,'2023-05-09 12:48:50',NULL,'Main Production Route','Shipping',6,'2023-05-18',NULL,1,3000,73,'',1,NULL,NULL,100,'Willson Logistics'),('WO33654',28800,29320,117,'Racking','complete',NULL,NULL,'2023-05-11 12:48:50',NULL,'No Paint','Shipping',5,'2023-05-27',NULL,3,65000,74,'',3,NULL,NULL,15,'Bakewell Cakes'),('WO33655',58500,59067,198,'Tables x 10','complete',NULL,NULL,'2023-05-12 12:48:50',NULL,'Main Production Route','Shipping',6,'2023-05-20',NULL,10,45000,75,'',2,NULL,NULL,80,'Greendale'),('WO33656',49500,49839,0,'Warehouse shelving','complete',NULL,NULL,'2023-05-12 12:48:50',NULL,'No Paint','Shipping',5,'2023-05-28',NULL,50,23000,76,'',2,NULL,NULL,500,'Purple Boxes'),('WO33657',63000,63487,130,'Bespoke metalwork parts','complete',NULL,NULL,'2023-05-13 12:48:51',NULL,'Short Route','Shipping',4,'2023-06-01',NULL,2,72000,77,'',3,NULL,NULL,6,'Smith and Johnson'),('WO33658',100800,101155,449,'Detector system','workInProgress',NULL,NULL,'2023-05-14 12:48:51',NULL,'Main Production Route','Shipping',6,'2023-05-16',NULL,1,83000,78,'',1,NULL,NULL,1,'P4 Computer Supplies'),('WO33659',45000,32721,17,'Case assemblies','workInProgress',NULL,NULL,'2023-05-18 12:48:51',NULL,'Main Production Route','Assembly',4,'2023-05-26',NULL,10,79000,79,'',3,NULL,NULL,100,'Proton Fire Systems'),('WO33660',83700,19245,0,'Jetpack harness parts','workInProgress',NULL,NULL,'2023-05-19 12:48:51',NULL,'Main Production Route','Painting',3,'2023-05-26',NULL,1,10000,80,'',2,NULL,NULL,53,'Paris & Co.'),('WO33661',88200,39846,165,'Bottling machine','workInProgress',NULL,NULL,'2023-05-19 12:48:51',NULL,'Main Production Route','Painting',3,'2023-05-30',NULL,1,50000,81,'',4,NULL,NULL,150,'Empire Supplies'),('WO33662',93600,38086,51,'Desk chairs','workInProgress',NULL,NULL,'2023-05-19 12:48:51',NULL,'Main Production Route','Painting',3,'2023-05-28',NULL,5,70000,82,'',3,NULL,NULL,50,'Ransom, Willis and Co'),('WO33663',62100,10044,0,'Custom wheel mountings','workInProgress',NULL,NULL,'2023-05-20 12:48:52',NULL,'Main Production Route','Welding',2,'2023-06-01',NULL,4,20000,83,'',2,NULL,NULL,4,'Burns Farm'),('WO33664',32400,10554,90,'Sensor casings','workInProgress',NULL,NULL,'2023-05-21 12:48:52',NULL,'Main Production Route','Welding',2,'2023-05-23',NULL,10,70000,84,'',4,NULL,NULL,60,'Hall Detectors'),('WO33665',199800,27047,164,'Custom moulds','workInProgress',NULL,NULL,'2023-05-22 12:48:52',NULL,'Main Production Route','Cutting',1,'2023-06-03',NULL,5,24000,85,'',4,NULL,NULL,5,'Wandas Wonders'),('WO33666',121500,9085,0,'Doors - steel','workInProgress',NULL,NULL,'2023-05-23 12:48:52',NULL,'Main Production Route','Cutting',1,'2023-05-24',NULL,16,22000,86,'',2,NULL,NULL,32,'Hearthstone Windows'),('WO33667',121500,9108,0,'Projectors','workInProgress',NULL,NULL,'2023-05-23 12:48:52',NULL,'Main Production Route','Cutting',1,'2023-06-01',NULL,3,53000,87,'',3,NULL,NULL,81,'Joes pharmacy'),('WO33668',54000,10971,0,'Bespoke metalwork parts','workInProgress',NULL,NULL,'2023-05-24 12:48:52',NULL,'Short Route','Cutting',1,'2023-06-08',NULL,17,12000,88,'',1,NULL,NULL,17,'BTB Construction'),('WO33669',23400,0,0,'Mount','pending',NULL,NULL,'2023-05-25 12:48:52',NULL,'Main Production Route',NULL,-1,'2023-06-15',NULL,1,6000,89,'',1,NULL,NULL,27,'Freeman Shipping');
/*!40000 ALTER TABLE `jobs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `lunchTimes`
--

DROP TABLE IF EXISTS `lunchTimes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `lunchTimes` (
  `ref` int NOT NULL AUTO_INCREMENT,
  `dayDate` date DEFAULT NULL,
  `startTime` time DEFAULT NULL,
  `endTime` time DEFAULT NULL,
  PRIMARY KEY (`ref`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lunchTimes`
--

LOCK TABLES `lunchTimes` WRITE;
/*!40000 ALTER TABLE `lunchTimes` DISABLE KEYS */;
INSERT INTO `lunchTimes` VALUES (1,'2021-03-17','12:00:00','13:00:00'),(2,'2021-03-18','12:00:00','13:00:00'),(3,'2021-03-19','12:00:00','13:00:00'),(4,'2021-03-20','00:00:00','00:00:00'),(5,'2021-03-21','00:00:00','00:00:00'),(6,'2021-03-22','12:00:00','13:00:00'),(7,'2021-03-23','12:00:00','13:00:00');
/*!40000 ALTER TABLE `lunchTimes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `products`
--

DROP TABLE IF EXISTS `products`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `products` (
  `productId` varchar(20) NOT NULL,
  `description` varchar(200) DEFAULT NULL,
  `absolutePathToQrCode` varchar(200) DEFAULT NULL,
  `relativePathToQrCode` varchar(200) DEFAULT NULL,
  `currentJobId` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`productId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `products`
--

LOCK TABLES `products` WRITE;
/*!40000 ALTER TABLE `products` DISABLE KEYS */;
INSERT INTO `products` VALUES ('Case_Assembly',NULL,NULL,NULL,NULL),('Frame_Assembly',NULL,NULL,NULL,NULL);
/*!40000 ALTER TABLE `products` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `routes`
--

DROP TABLE IF EXISTS `routes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `routes` (
  `routeName` varchar(50) NOT NULL,
  `routeDescription` varchar(1000) NOT NULL,
  PRIMARY KEY (`routeName`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `routes`
--

LOCK TABLES `routes` WRITE;
/*!40000 ALTER TABLE `routes` DISABLE KEYS */;
INSERT INTO `routes` VALUES ('Main Production Route','Cutting,Welding,Painting,Assembly,QC,Shipping'),('No Paint','Cutting,Welding,Assembly,QC,Shipping'),('Short Route','Cutting,Welding,QC,Shipping');
/*!40000 ALTER TABLE `routes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `stoppageReasons`
--

DROP TABLE IF EXISTS `stoppageReasons`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `stoppageReasons` (
  `stoppageReasonId` varchar(20) NOT NULL,
  `stoppageReasonName` varchar(200) DEFAULT NULL,
  `absolutePathToQrCode` varchar(200) DEFAULT NULL,
  `relativePathToQrCode` varchar(200) DEFAULT NULL,
  `stoppageReasonIdIndex` int NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`stoppageReasonId`),
  KEY `stoppageReasonIdIndex` (`stoppageReasonIdIndex`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `stoppageReasons`
--

LOCK TABLES `stoppageReasons` WRITE;
/*!40000 ALTER TABLE `stoppageReasons` DISABLE KEYS */;
INSERT INTO `stoppageReasons` VALUES ('stpg_0001','Breakdown',NULL,NULL,1),('stpg_0002','Material unavailable',NULL,NULL,2),('stpg_0003','Lack of fuel',NULL,NULL,3);
/*!40000 ALTER TABLE `stoppageReasons` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `stoppagesLog`
--

DROP TABLE IF EXISTS `stoppagesLog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `stoppagesLog` (
  `ref` bigint NOT NULL AUTO_INCREMENT,
  `jobId` varchar(20) DEFAULT NULL,
  `stationId` varchar(50) DEFAULT NULL,
  `stoppageReasonId` varchar(20) DEFAULT NULL,
  `description` text,
  `startTime` time DEFAULT NULL,
  `endTime` time DEFAULT NULL,
  `startDate` date DEFAULT NULL,
  `endDate` date DEFAULT NULL,
  `recordTimestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `duration` int DEFAULT NULL,
  `status` varchar(20) NOT NULL,
  PRIMARY KEY (`ref`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `stoppagesLog`
--

LOCK TABLES `stoppagesLog` WRITE;
/*!40000 ALTER TABLE `stoppagesLog` DISABLE KEYS */;
/*!40000 ALTER TABLE `stoppagesLog` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `timeLog`
--

DROP TABLE IF EXISTS `timeLog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `timeLog` (
  `ref` bigint NOT NULL AUTO_INCREMENT,
  `jobId` varchar(20) DEFAULT NULL,
  `stationId` varchar(50) DEFAULT NULL,
  `userId` varchar(20) DEFAULT NULL,
  `clockOnTime` time DEFAULT NULL,
  `clockOffTime` time DEFAULT NULL,
  `recordDate` date DEFAULT NULL,
  `recordTimestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `workedDuration` int DEFAULT NULL,
  `overtimeDuration` int DEFAULT NULL,
  `workStatus` varchar(20) NOT NULL,
  `quantityComplete` int DEFAULT NULL,
  `routeStageIndex` int DEFAULT NULL,
  PRIMARY KEY (`ref`),
  KEY `IDX_ClockOffTime_JobID` (`clockOffTime`,`jobId`) USING BTREE,
  KEY `IDX_ClockOffTime_UserId` (`clockOffTime`,`userId`),
  KEY `IDX_ClockOffTime_UserId_date` (`clockOffTime`,`userId`,`recordDate`)
) ENGINE=InnoDB AUTO_INCREMENT=939 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `timeLog`
--

LOCK TABLES `timeLog` WRITE;
/*!40000 ALTER TABLE `timeLog` DISABLE KEYS */;
INSERT INTO `timeLog` VALUES (345,'job_wrgr4','Cutting','user_Delt','08:01:57','10:03:11','2023-05-18','2023-05-18 07:01:57',7274,0,'stageComplete',NULL,1),(374,'job_wrgr4','Welding','user_Delt','16:06:17','17:00:58','2023-05-19','2023-05-19 15:06:17',3281,58,'workInProgress',NULL,2),(447,'job_wrgr4','Cutting','user_Delt','08:01:57','10:03:11','2023-05-18','2023-05-18 07:01:57',7274,0,'stageComplete',NULL,1),(476,'job_wrgr4','Welding','user_Delt','16:06:17','17:00:58','2023-05-19','2023-05-19 15:06:17',3281,58,'workInProgress',NULL,2),(549,'job_wrgr4','Cutting','user_Delt','08:01:57','10:03:11','2023-05-18','2023-05-18 07:01:57',7274,0,'stageComplete',NULL,1),(578,'job_wrgr4','Welding','user_Delt','16:06:17','17:00:58','2023-05-19','2023-05-19 15:06:17',3281,58,'workInProgress',NULL,2),(651,'job_wrgr4','Cutting','user_Delt','08:01:57','10:03:11','2023-05-18','2023-05-18 07:01:57',7274,0,'stageComplete',NULL,1),(680,'job_wrgr4','Welding','user_Delt','16:06:17','17:00:58','2023-05-19','2023-05-19 15:06:17',3281,58,'workInProgress',NULL,2),(753,'job_wrgr4','Cutting','user_Delt','08:01:57','10:03:11','2023-05-18','2023-05-18 07:01:57',7274,0,'stageComplete',NULL,1),(782,'job_wrgr4','Welding','user_Delt','16:06:17','17:00:58','2023-05-19','2023-05-19 15:06:17',3281,58,'workInProgress',NULL,2),(832,'WO33652','Cutting','user_0001','08:00:34','12:02:25','2023-05-11','2023-05-11 07:00:34',14511,0,'workInProgress',NULL,1),(833,'WO33652','Cutting','user_0001','13:00:16','17:01:05','2023-05-11','2023-05-11 12:00:16',14449,65,'workInProgress',NULL,1),(834,'WO33652','Cutting','user_0001','08:00:30','12:02:06','2023-05-12','2023-05-12 07:00:30',14496,0,'workInProgress',NULL,1),(835,'WO33652','Cutting','user_0001','13:01:55','17:02:00','2023-05-12','2023-05-12 12:01:55',14405,120,'workInProgress',NULL,1),(836,'WO33652','Cutting','user_0001','08:02:46','10:00:02','2023-05-15','2023-05-15 07:02:46',7036,0,'stageComplete',NULL,1),(837,'WO33653','Cutting','user_0001','10:00:55','12:00:24','2023-05-15','2023-05-15 09:00:55',7169,0,'workInProgress',NULL,1),(838,'WO33653','Cutting','user_0001','13:02:04','17:00:07','2023-05-15','2023-05-15 12:02:04',14283,7,'workInProgress',NULL,1),(839,'WO33653','Cutting','user_0001','08:01:39','12:01:50','2023-05-16','2023-05-16 07:01:39',14411,0,'workInProgress',NULL,1),(840,'WO33653','Cutting','user_0001','13:02:35','15:04:52','2023-05-16','2023-05-16 12:02:35',7337,0,'stageComplete',NULL,1),(841,'WO33654','Cutting','user_0001','15:07:50','16:39:44','2023-05-16','2023-05-16 14:07:50',5514,0,'stageComplete',NULL,1),(842,'WO33655','Cutting','user_0001','16:40:52','17:00:58','2023-05-16','2023-05-16 15:40:52',1206,58,'workInProgress',NULL,1),(843,'WO33655','Cutting','user_0001','08:02:31','08:42:51','2023-05-17','2023-05-17 07:02:31',2420,0,'stageComplete',NULL,1),(844,'WO33656','Cutting','user_0001','08:44:12','10:44:19','2023-05-17','2023-05-17 07:44:12',7207,0,'stageComplete',NULL,1),(845,'WO33657','Cutting','user_0001','10:44:24','12:00:06','2023-05-17','2023-05-17 09:44:24',4542,0,'workInProgress',NULL,1),(846,'WO33657','Cutting','user_0001','13:02:46','14:49:22','2023-05-17','2023-05-17 12:02:46',6396,0,'stageComplete',NULL,1),(847,'WO33658','Cutting','user_0001','14:49:24','17:01:37','2023-05-17','2023-05-17 13:49:24',7933,97,'workInProgress',NULL,1),(848,'WO33658','Cutting','user_0001','08:02:55','09:51:37','2023-05-18','2023-05-18 07:02:55',6522,0,'stageComplete',NULL,1),(849,'WO33659','Cutting','user_0001','09:53:25','11:53:32','2023-05-18','2023-05-18 08:53:25',7207,0,'stageComplete',NULL,1),(850,'WO33660','Cutting','user_0001','08:02:15','09:33:11','2023-05-19','2023-05-19 07:02:15',5456,0,'stageComplete',NULL,1),(851,'WO33661','Cutting','user_0001','09:35:03','12:02:06','2023-05-19','2023-05-19 08:35:03',8823,0,'workInProgress',NULL,1),(852,'WO33661','Cutting','user_0001','13:02:21','13:36:17','2023-05-19','2023-05-19 12:02:21',2036,0,'stageComplete',NULL,1),(853,'WO33662','Cutting','user_0001','13:37:45','16:08:44','2023-05-19','2023-05-19 12:37:45',9059,0,'stageComplete',NULL,1),(854,'WO33663','Cutting','user_0001','08:02:53','08:48:49','2023-05-22','2023-05-22 07:02:53',2756,0,'stageComplete',NULL,1),(855,'WO33664','Cutting','user_0001','08:50:46','10:52:00','2023-05-22','2023-05-22 07:50:46',7274,0,'stageComplete',NULL,1),(856,'WO33665','Cutting','user_0001','10:52:05','12:01:46','2023-05-22','2023-05-22 09:52:05',4181,0,'workInProgress',NULL,1),(857,'WO33665','Cutting','user_0001','13:02:22','17:02:44','2023-05-22','2023-05-22 12:02:22',14422,164,'workInProgress',NULL,1),(858,'WO33665','Cutting','user_0001','08:00:25','10:21:09','2023-05-23','2023-05-23 07:00:25',8444,0,'stageComplete',NULL,1),(859,'WO33666','Cutting','user_0001','10:23:50','12:01:15','2023-05-23','2023-05-23 09:23:50',5845,0,'workInProgress',NULL,1),(860,'WO33666','Cutting','user_0001','13:00:30','13:54:30','2023-05-23','2023-05-23 12:00:30',3240,0,'stageComplete',NULL,1),(861,'WO33667','Cutting','user_0001','13:56:38','16:28:26','2023-05-23','2023-05-23 12:56:38',9108,0,'stageComplete',NULL,1),(862,'WO33668','Cutting','user_0001','08:02:09','11:05:00','2023-05-24','2023-05-24 07:02:09',10971,0,'stageComplete',NULL,1),(863,'WO33652','Welding','user_0002','10:00:50','12:01:17','2023-05-15','2023-05-15 09:00:50',7227,0,'workInProgress',NULL,2),(864,'WO33652','Welding','user_0002','13:01:12','17:02:30','2023-05-15','2023-05-15 12:01:12',14478,150,'workInProgress',NULL,2),(865,'WO33652','Welding','user_0002','08:02:07','12:02:09','2023-05-16','2023-05-16 07:02:07',14402,0,'workInProgress',NULL,2),(866,'WO33652','Welding','user_0002','13:01:40','15:02:23','2023-05-16','2023-05-16 12:01:40',7243,0,'stageComplete',NULL,2),(867,'WO33653','Welding','user_0002','08:00:08','09:32:10','2023-05-17','2023-05-17 07:00:08',5522,0,'stageComplete',NULL,2),(868,'WO33654','Welding','user_0002','09:33:12','12:01:43','2023-05-17','2023-05-17 08:33:12',8911,0,'workInProgress',NULL,2),(869,'WO33654','Welding','user_0002','13:01:46','13:06:05','2023-05-17','2023-05-17 12:01:46',259,0,'stageComplete',NULL,2),(870,'WO33655','Welding','user_0002','13:06:49','17:01:33','2023-05-17','2023-05-17 12:06:49',14084,93,'workInProgress',NULL,2),(871,'WO33655','Welding','user_0002','08:02:20','10:10:35','2023-05-18','2023-05-18 07:02:20',7695,0,'stageComplete',NULL,2),(872,'WO33656','Welding','user_0002','10:13:27','12:01:35','2023-05-18','2023-05-18 09:13:27',6488,0,'workInProgress',NULL,2),(873,'WO33656','Welding','user_0002','13:00:22','16:14:06','2023-05-18','2023-05-18 12:00:22',11624,0,'stageComplete',NULL,2),(874,'WO33657','Welding','user_0002','16:16:55','17:02:10','2023-05-18','2023-05-18 15:16:55',2715,130,'workInProgress',NULL,2),(875,'WO33657','Welding','user_0002','08:00:27','12:00:41','2023-05-19','2023-05-19 07:00:27',14414,0,'workInProgress',NULL,2),(876,'WO33657','Welding','user_0002','13:02:13','16:48:24','2023-05-19','2023-05-19 12:02:13',13571,0,'stageComplete',NULL,2),(877,'WO33658','Welding','user_0002','16:49:58','17:02:05','2023-05-19','2023-05-19 15:49:58',727,125,'workInProgress',NULL,2),(878,'WO33658','Welding','user_0002','08:00:07','09:50:00','2023-05-22','2023-05-22 07:00:07',6593,0,'stageComplete',NULL,2),(879,'WO33659','Welding','user_0002','09:50:11','11:21:29','2023-05-22','2023-05-22 08:50:11',5478,0,'stageComplete',NULL,2),(880,'WO33660','Welding','user_0002','11:24:29','12:02:37','2023-05-22','2023-05-22 10:24:29',2288,0,'workInProgress',NULL,2),(881,'WO33660','Welding','user_0002','13:02:31','14:56:51','2023-05-22','2023-05-22 12:02:31',6860,0,'stageComplete',NULL,2),(882,'WO33661','Welding','user_0002','14:58:31','17:02:45','2023-05-22','2023-05-22 13:58:31',7454,165,'workInProgress',NULL,2),(883,'WO33661','Welding','user_0002','08:00:43','12:00:43','2023-05-23','2023-05-23 07:00:43',14400,0,'workInProgress',NULL,2),(884,'WO33661','Welding','user_0002','13:02:08','13:58:52','2023-05-23','2023-05-23 12:02:08',3404,0,'stageComplete',NULL,2),(885,'WO33662','Welding','user_0002','13:58:55','17:00:51','2023-05-23','2023-05-23 12:58:55',10916,51,'workInProgress',NULL,2),(886,'WO33662','Welding','user_0002','08:02:18','12:02:20','2023-05-24','2023-05-24 07:02:18',14402,0,'workInProgress',NULL,2),(887,'WO33662','Welding','user_0002','13:00:59','14:00:44','2023-05-24','2023-05-24 12:00:59',3585,0,'stageComplete',NULL,2),(888,'WO33663','Welding','user_0002','14:02:55','16:04:23','2023-05-24','2023-05-24 13:02:55',7288,0,'stageComplete',NULL,2),(889,'WO33664','Welding','user_0002','16:06:50','17:01:30','2023-05-24','2023-05-24 15:06:50',3280,90,'workInProgress',NULL,2),(890,'WO33653','Painting','user_0003','09:34:07','12:01:08','2023-05-17','2023-05-17 08:34:07',8821,0,'workInProgress',NULL,3),(891,'WO33653','Painting','user_0003','13:02:48','13:08:07','2023-05-17','2023-05-17 12:02:48',319,0,'stageComplete',NULL,3),(892,'WO33655','Painting','user_0003','10:13:10','12:00:01','2023-05-18','2023-05-18 09:13:10',6411,0,'workInProgress',NULL,3),(893,'WO33655','Painting','user_0003','13:01:38','14:46:58','2023-05-18','2023-05-18 12:01:38',6320,0,'stageComplete',NULL,3),(894,'WO33658','Painting','user_0003','09:50:33','12:02:12','2023-05-22','2023-05-22 08:50:33',7899,0,'workInProgress',NULL,3),(895,'WO33658','Painting','user_0003','13:02:23','16:51:36','2023-05-22','2023-05-22 12:02:23',13753,0,'stageComplete',NULL,3),(896,'WO33659','Painting','user_0003','16:53:25','17:00:14','2023-05-22','2023-05-22 15:53:25',409,14,'workInProgress',NULL,3),(897,'WO33659','Painting','user_0003','08:02:03','08:26:47','2023-05-23','2023-05-23 07:02:03',1484,0,'stageComplete',NULL,3),(898,'WO33660','Painting','user_0003','08:29:12','09:46:33','2023-05-23','2023-05-23 07:29:12',4641,0,'stageComplete',NULL,3),(899,'WO33661','Painting','user_0003','13:59:43','15:01:52','2023-05-23','2023-05-23 12:59:43',3729,0,'stageComplete',NULL,3),(900,'WO33662','Painting','user_0003','14:02:29','14:04:33','2023-05-24','2023-05-24 13:02:29',124,0,'stageComplete',NULL,3),(901,'WO33652','Assembly','user_0004','15:03:54','17:01:46','2023-05-16','2023-05-16 14:03:54',7072,106,'workInProgress',NULL,3),(902,'WO33652','Assembly','user_0004','08:01:28','12:00:00','2023-05-17','2023-05-17 07:01:28',14312,0,'workInProgress',NULL,3),(903,'WO33652','Assembly','user_0004','13:02:17','15:38:11','2023-05-17','2023-05-17 12:02:17',9354,0,'stageComplete',NULL,3),(904,'WO33653','Assembly','user_0004','15:40:50','16:43:26','2023-05-17','2023-05-17 14:40:50',3756,0,'stageComplete',NULL,4),(905,'WO33654','Assembly','user_0004','16:44:50','17:01:57','2023-05-17','2023-05-17 15:44:50',1027,117,'workInProgress',NULL,3),(906,'WO33654','Assembly','user_0004','08:02:33','09:00:33','2023-05-18','2023-05-18 07:02:33',3480,0,'stageComplete',NULL,3),(907,'WO33655','Assembly','user_0004','14:47:56','16:50:38','2023-05-18','2023-05-18 13:47:56',7362,0,'stageComplete',NULL,4),(908,'WO33656','Assembly','user_0004','08:00:45','11:33:05','2023-05-19','2023-05-19 07:00:45',12740,0,'stageComplete',NULL,3),(909,'WO33658','Assembly','user_0004','16:54:05','17:00:46','2023-05-22','2023-05-22 15:54:05',401,46,'workInProgress',NULL,4),(910,'WO33658','Assembly','user_0004','08:00:23','12:02:21','2023-05-23','2023-05-23 07:00:23',14518,0,'workInProgress',NULL,4),(911,'WO33658','Assembly','user_0004','13:01:05','17:00:08','2023-05-23','2023-05-23 12:01:05',14343,8,'workInProgress',NULL,4),(912,'WO33658','Assembly','user_0004','08:02:52','10:55:28','2023-05-24','2023-05-24 07:02:52',10356,0,'stageComplete',NULL,4),(913,'WO33659','Assembly','user_0004','10:55:49','12:00:04','2023-05-24','2023-05-24 09:55:49',3855,0,'workInProgress',NULL,4),(914,'WO33659','Assembly','user_0004','13:01:55','17:00:03','2023-05-24','2023-05-24 12:01:55',14288,3,'workInProgress',NULL,4),(915,'WO33652','QC','user_0005','15:39:22','17:01:03','2023-05-17','2023-05-17 14:39:22',4901,63,'workInProgress',NULL,4),(916,'WO33652','QC','user_0005','08:01:08','10:54:55','2023-05-18','2023-05-18 07:01:08',10427,0,'stageComplete',NULL,4),(917,'WO33653','QC','user_0005','10:57:34','11:28:21','2023-05-18','2023-05-18 09:57:34',1847,0,'stageComplete',NULL,5),(918,'WO33654','QC','user_0005','11:29:49','11:46:03','2023-05-18','2023-05-18 10:29:49',974,0,'stageComplete',NULL,4),(919,'WO33655','QC','user_0005','16:50:55','17:00:42','2023-05-18','2023-05-18 15:50:55',587,42,'workInProgress',NULL,5),(920,'WO33655','QC','user_0005','08:00:40','08:51:58','2023-05-19','2023-05-19 07:00:40',3078,0,'stageComplete',NULL,5),(921,'WO33656','QC','user_0005','13:02:15','15:17:58','2023-05-19','2023-05-19 12:02:15',8143,0,'stageComplete',NULL,4),(922,'WO33657','QC','user_0005','08:02:48','11:03:57','2023-05-22','2023-05-22 07:02:48',10869,0,'stageComplete',NULL,3),(923,'WO33658','QC','user_0005','10:58:13','12:01:15','2023-05-24','2023-05-24 09:58:13',3782,0,'workInProgress',NULL,5),(924,'WO33658','QC','user_0005','13:01:56','14:01:53','2023-05-24','2023-05-24 12:01:56',3597,0,'stageComplete',NULL,5),(925,'WO33652','Shipping','user_0006','10:56:17','12:02:07','2023-05-18','2023-05-18 09:56:17',3950,0,'workInProgress',NULL,5),(926,'WO33652','Shipping','user_0006','13:02:01','17:00:29','2023-05-18','2023-05-18 12:02:01',14308,29,'workInProgress',NULL,5),(927,'WO33652','Shipping','user_0006','08:00:06','12:01:19','2023-05-19','2023-05-19 07:00:06',14473,0,'workInProgress',NULL,5),(928,'WO33652','Shipping','user_0006','13:01:38','17:01:27','2023-05-19','2023-05-19 12:01:38',14389,87,'workInProgress',NULL,5),(929,'WO33652','Shipping','user_0006','08:01:47','09:57:15','2023-05-22','2023-05-22 07:01:47',6928,0,'stageComplete',NULL,5),(930,'WO33653','Shipping','user_0006','09:58:21','12:00:27','2023-05-22','2023-05-22 08:58:21',7326,0,'workInProgress',NULL,6),(931,'WO33653','Shipping','user_0006','13:01:04','13:16:08','2023-05-22','2023-05-22 12:01:04',904,0,'stageComplete',NULL,6),(932,'WO33654','Shipping','user_0006','13:17:01','15:49:36','2023-05-22','2023-05-22 12:17:01',9155,0,'stageComplete',NULL,5),(933,'WO33655','Shipping','user_0006','15:51:26','17:00:05','2023-05-22','2023-05-22 14:51:26',4119,5,'workInProgress',NULL,6),(934,'WO33655','Shipping','user_0006','08:00:57','09:37:22','2023-05-23','2023-05-23 07:00:57',5785,0,'stageComplete',NULL,6),(935,'WO33656','Shipping','user_0006','09:39:03','10:39:40','2023-05-23','2023-05-23 08:39:03',3637,0,'stageComplete',NULL,5),(936,'WO33657','Shipping','user_0006','10:39:49','12:00:41','2023-05-23','2023-05-23 09:39:49',4852,0,'workInProgress',NULL,4),(937,'WO33657','Shipping','user_0006','13:01:54','14:44:02','2023-05-23','2023-05-23 12:01:54',6128,0,'stageComplete',NULL,4),(938,'WO33658','Shipping','user_0006','14:04:02','17:02:53','2023-05-24','2023-05-24 13:04:02',10731,173,'workInProgress',NULL,6);
/*!40000 ALTER TABLE `timeLog` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `userId` varchar(20) DEFAULT NULL,
  `userName` varchar(50) DEFAULT NULL,
  `relativePathToQrCode` varchar(200) DEFAULT NULL,
  `absolutePathToQrCode` varchar(200) DEFAULT NULL,
  `recordAdded` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `userIdIndex` int DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES ('user_Delt','User Deleted',NULL,NULL,'2021-04-15 16:59:34',-2),('office','Office',NULL,NULL,'2021-04-15 16:59:34',-1),('noName','N/A',NULL,NULL,'2021-04-15 16:59:34',0),('user_0001','Alice',NULL,NULL,'2023-05-25 12:48:43',1),('user_0002','Bob',NULL,NULL,'2023-05-25 12:48:44',2),('user_0003','Charlotte',NULL,NULL,'2023-05-25 12:48:45',3),('user_0004','David',NULL,NULL,'2023-05-25 12:48:46',4),('user_0005','Emily',NULL,NULL,'2023-05-25 12:48:47',5),('user_0006','Felix',NULL,NULL,'2023-05-25 12:48:48',6);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `workHours`
--

DROP TABLE IF EXISTS `workHours`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `workHours` (
  `ref` int NOT NULL AUTO_INCREMENT,
  `dayDate` date DEFAULT NULL,
  `startTime` time DEFAULT NULL,
  `endTime` time DEFAULT NULL,
  PRIMARY KEY (`ref`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `workHours`
--

LOCK TABLES `workHours` WRITE;
/*!40000 ALTER TABLE `workHours` DISABLE KEYS */;
INSERT INTO `workHours` VALUES (1,'2021-03-17','08:00:00','17:00:00'),(2,'2021-03-18','08:00:00','17:00:00'),(3,'2021-03-19','08:00:00','17:00:00'),(4,'2021-03-20','00:00:00','00:00:00'),(5,'2021-03-21','00:00:00','00:00:00'),(6,'2021-03-22','08:00:00','17:00:00'),(7,'2021-03-23','08:00:00','17:00:00');
/*!40000 ALTER TABLE `workHours` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2023-05-25 13:50:34
