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
  `jobName` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`jobId`),
  KEY `jobIdIndex` (`jobIdIndex`),
  KEY `IDX_jobId_desc` (`jobId`,`description`)
) ENGINE=InnoDB AUTO_INCREMENT=72 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jobs`
--

LOCK TABLES `jobs` WRITE;
/*!40000 ALTER TABLE `jobs` DISABLE KEYS */;
INSERT INTO `jobs` VALUES ('job_70',0,0,0,'','pending',NULL,NULL,'2023-05-22 12:46:40',NULL,'',NULL,-1,'9999-12-31',NULL,0,0,70,'',0,NULL,NULL,0,'','70'),('job_awegd',199800,135820,0,'Custom moulds','workInProgress',NULL,NULL,'2023-05-19 11:11:01','','Main Production Route','Cutting',1,'2023-05-31',NULL,5,24000,64,'',4,NULL,NULL,5,'Wandas Wonders','awegd'),('job_gcghf',0,0,0,'','pending',NULL,NULL,'2023-05-22 11:12:03','','','',-1,'9999-12-31',NULL,0,0,69,'',0,NULL,NULL,0,'','gcghf'),('job_wehkasdfjx',0,0,0,'','pending',NULL,NULL,'2023-05-22 13:13:12','','','',-1,'9999-12-31',NULL,0,0,71,'',0,NULL,NULL,0,'','wehkasdfjx'),('job_WO33652',207900,1042165,2665,'Modular frame assemblies','complete',NULL,NULL,'2023-05-06 11:10:58',NULL,'No Paint','Shipping',5,'2023-05-14',NULL,10,90000,51,'',2,NULL,NULL,80,'ABC Construction','WO33652'),('job_WO33653',71100,357935,35,'Packing noodles','complete',NULL,NULL,'2023-05-06 11:10:58',NULL,'Main Production Route','Shipping',6,'2023-05-15',NULL,1,3000,52,'',1,NULL,NULL,100,'Willson Logistics','WO33653'),('job_WO33654',28800,146265,620,'Racking','complete',NULL,NULL,'2023-05-08 11:10:59',NULL,'No Paint','Shipping',5,'2023-05-24',NULL,3,65000,53,'',3,NULL,NULL,15,'Bakewell Cakes','WO33654'),('job_WO33655',58500,294375,1385,'Tables x 10','complete',NULL,NULL,'2023-05-09 11:10:59',NULL,'Main Production Route','Shipping',6,'2023-05-17',NULL,10,45000,54,'',2,NULL,NULL,80,'Greendale','WO33655'),('job_WO33656',49500,249015,0,'Warehouse shelving','complete',NULL,NULL,'2023-05-09 11:10:59',NULL,'No Paint','Shipping',5,'2023-05-25',NULL,50,23000,55,'',2,NULL,NULL,500,'Purple Boxes','WO33656'),('job_WO33657',63000,317595,850,'Bespoke metalwork parts','complete',NULL,NULL,'2023-05-10 11:10:59',NULL,'Short Route','Shipping',4,'2023-05-29',NULL,2,72000,56,'',3,NULL,NULL,6,'Smith and Johnson','WO33657'),('job_WO33658',100800,505370,1800,'Detector system','workInProgress',NULL,NULL,'2023-05-11 11:10:59',NULL,'Main Production Route','Shipping',6,'2023-05-13',NULL,1,83000,57,'',1,NULL,NULL,1,'P4 Computer Supplies','WO33658'),('job_WO33659',45000,162715,930,'Case assemblies','workInProgress',NULL,NULL,'2023-05-15 11:10:59',NULL,'Main Production Route','Assembly',4,'2023-05-23',NULL,10,79000,58,'',3,NULL,NULL,100,'Proton Fire Systems','WO33659'),('job_WO33660',83700,95935,0,'Jetpack harness parts','workInProgress',NULL,NULL,'2023-05-16 11:11:00',NULL,'Main Production Route','Painting',3,'2023-05-23',NULL,1,10000,59,'',2,NULL,NULL,53,'Paris & Co.','WO33660'),('job_WO33661',88200,199345,625,'Bottling machine','workInProgress',NULL,NULL,'2023-05-16 11:11:00',NULL,'Main Production Route','Painting',3,'2023-05-27',NULL,1,50000,60,'',4,NULL,NULL,150,'Empire Supplies','WO33661'),('job_WO33662',93600,190380,785,'Desk chairs','workInProgress',NULL,NULL,'2023-05-16 11:11:00',NULL,'Main Production Route','Painting',3,'2023-05-25',NULL,5,70000,61,'',3,NULL,NULL,50,'Ransom, Willis and Co','WO33662'),('job_WO33663',62100,49995,0,'Custom wheel mountings','workInProgress',NULL,NULL,'2023-05-17 11:11:00',NULL,'Main Production Route','Welding',2,'2023-05-29',NULL,4,20000,62,'',2,NULL,NULL,4,'Burns Farm','WO33663'),('job_WO33666',121500,0,0,'Doors - steel','pending',NULL,NULL,'2023-05-20 11:11:01',NULL,'Main Production Route',NULL,-1,'2023-05-21',NULL,16,22000,65,'',2,NULL,NULL,32,'Hearthstone Windows','WO33666'),('job_WO33667',121500,0,0,'Projectors','pending',NULL,NULL,'2023-05-20 11:11:01',NULL,'Main Production Route',NULL,-1,'2023-05-29',NULL,3,53000,66,'',3,NULL,NULL,81,'Joes pharmacy','WO33667'),('job_WO33668',54000,0,0,'Bespoke metalwork parts','pending',NULL,NULL,'2023-05-21 11:11:01',NULL,'Short Route',NULL,-1,'2023-06-05',NULL,17,12000,67,'',1,NULL,NULL,17,'BTB Construction','WO33668'),('job_WO33669',23400,0,0,'Mount','pending',NULL,NULL,'2023-05-22 11:11:01',NULL,'Main Production Route',NULL,-1,'2023-06-12',NULL,1,6000,68,'',1,NULL,NULL,27,'Freeman Shipping','WO33669'),('job_wrgr4',32400,52775,290,'Sensor casings','workInProgress',NULL,NULL,'2023-05-18 11:11:00','','Main Production Route','Welding',2,'2023-05-20',NULL,10,70000,63,'',4,NULL,NULL,60,'Hall Detectors','wrgr4');
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
) ENGINE=InnoDB AUTO_INCREMENT=832 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `timeLog`
--

LOCK TABLES `timeLog` WRITE;
/*!40000 ALTER TABLE `timeLog` DISABLE KEYS */;
INSERT INTO `timeLog` VALUES (322,'WO33652','Cutting','user_Delt','08:00:34','12:02:25','2023-05-08','2023-05-08 07:00:34',14511,0,'workInProgress',NULL,1),(323,'WO33652','Cutting','user_Delt','13:00:16','17:01:05','2023-05-08','2023-05-08 12:00:16',14449,65,'workInProgress',NULL,1),(324,'WO33652','Cutting','user_Delt','08:00:30','12:02:06','2023-05-09','2023-05-09 07:00:30',14496,0,'workInProgress',NULL,1),(325,'WO33652','Cutting','user_Delt','13:01:55','17:02:00','2023-05-09','2023-05-09 12:01:55',14405,120,'workInProgress',NULL,1),(326,'WO33652','Cutting','user_Delt','08:02:46','10:00:02','2023-05-10','2023-05-10 07:02:46',7036,0,'stageComplete',NULL,1),(327,'WO33653','Cutting','user_Delt','10:00:55','12:00:24','2023-05-10','2023-05-10 09:00:55',7169,0,'workInProgress',NULL,1),(328,'WO33653','Cutting','user_Delt','13:02:04','17:00:07','2023-05-10','2023-05-10 12:02:04',14283,7,'workInProgress',NULL,1),(329,'WO33653','Cutting','user_Delt','08:01:39','12:01:50','2023-05-11','2023-05-11 07:01:39',14411,0,'workInProgress',NULL,1),(330,'WO33653','Cutting','user_Delt','13:02:35','15:04:52','2023-05-11','2023-05-11 12:02:35',7337,0,'stageComplete',NULL,1),(331,'WO33654','Cutting','user_Delt','15:07:50','16:39:44','2023-05-11','2023-05-11 14:07:50',5514,0,'stageComplete',NULL,1),(332,'WO33655','Cutting','user_Delt','16:40:52','17:00:58','2023-05-11','2023-05-11 15:40:52',1206,58,'workInProgress',NULL,1),(333,'WO33655','Cutting','user_Delt','08:02:31','08:42:51','2023-05-12','2023-05-12 07:02:31',2420,0,'stageComplete',NULL,1),(334,'WO33656','Cutting','user_Delt','08:44:12','10:44:19','2023-05-12','2023-05-12 07:44:12',7207,0,'stageComplete',NULL,1),(335,'WO33657','Cutting','user_Delt','10:44:24','12:00:06','2023-05-12','2023-05-12 09:44:24',4542,0,'workInProgress',NULL,1),(336,'WO33657','Cutting','user_Delt','13:02:46','14:49:22','2023-05-12','2023-05-12 12:02:46',6396,0,'stageComplete',NULL,1),(337,'WO33658','Cutting','user_Delt','14:49:24','17:01:37','2023-05-12','2023-05-12 13:49:24',7933,97,'workInProgress',NULL,1),(338,'WO33658','Cutting','user_Delt','08:02:55','09:51:37','2023-05-15','2023-05-15 07:02:55',6522,0,'stageComplete',NULL,1),(339,'WO33659','Cutting','user_Delt','09:53:25','11:53:32','2023-05-15','2023-05-15 08:53:25',7207,0,'stageComplete',NULL,1),(340,'WO33660','Cutting','user_Delt','08:02:15','09:33:11','2023-05-16','2023-05-16 07:02:15',5456,0,'stageComplete',NULL,1),(341,'WO33661','Cutting','user_Delt','09:35:03','12:02:06','2023-05-16','2023-05-16 08:35:03',8823,0,'workInProgress',NULL,1),(342,'WO33661','Cutting','user_Delt','13:02:21','13:36:17','2023-05-16','2023-05-16 12:02:21',2036,0,'stageComplete',NULL,1),(343,'WO33662','Cutting','user_Delt','13:37:45','16:08:44','2023-05-16','2023-05-16 12:37:45',9059,0,'stageComplete',NULL,1),(344,'WO33663','Cutting','user_Delt','08:02:53','08:48:49','2023-05-17','2023-05-17 07:02:53',2756,0,'stageComplete',NULL,1),(345,'job_wrgr4','Cutting','user_Delt','08:01:57','10:03:11','2023-05-18','2023-05-18 07:01:57',7274,0,'stageComplete',NULL,1),(346,'awegd','Cutting','user_Delt','08:00:05','12:01:46','2023-05-19','2023-05-19 07:00:05',14501,0,'workInProgress',NULL,1),(347,'awegd','Cutting','user_Delt','13:02:22','16:33:25','2023-05-19','2023-05-19 12:02:22',12663,0,'stageComplete',NULL,1),(348,'WO33652','Welding','user_Delt','10:00:27','12:00:47','2023-05-10','2023-05-10 09:00:27',7220,0,'workInProgress',NULL,2),(349,'WO33652','Welding','user_Delt','13:02:41','17:01:15','2023-05-10','2023-05-10 12:02:41',14314,75,'workInProgress',NULL,2),(350,'WO33652','Welding','user_Delt','08:00:30','12:01:25','2023-05-11','2023-05-11 07:00:30',14455,0,'workInProgress',NULL,2),(351,'WO33652','Welding','user_Delt','13:02:08','15:04:07','2023-05-11','2023-05-11 12:02:08',7319,0,'stageComplete',NULL,2),(352,'WO33653','Welding','user_Delt','08:02:09','09:35:00','2023-05-12','2023-05-12 07:02:09',5571,0,'stageComplete',NULL,2),(353,'WO33654','Welding','user_Delt','09:35:48','12:01:17','2023-05-12','2023-05-12 08:35:48',8729,0,'workInProgress',NULL,2),(354,'WO33654','Welding','user_Delt','13:01:12','13:08:13','2023-05-12','2023-05-12 12:01:12',421,0,'stageComplete',NULL,2),(355,'WO33655','Welding','user_Delt','13:10:20','17:02:09','2023-05-12','2023-05-12 12:10:20',13909,129,'workInProgress',NULL,2),(356,'WO33655','Welding','user_Delt','08:01:40','10:12:21','2023-05-15','2023-05-15 07:01:40',7841,0,'stageComplete',NULL,2),(357,'WO33656','Welding','user_Delt','10:12:29','12:02:02','2023-05-15','2023-05-15 09:12:29',6573,0,'workInProgress',NULL,2),(358,'WO33656','Welding','user_Delt','13:01:02','16:13:12','2023-05-15','2023-05-15 12:01:02',11530,0,'stageComplete',NULL,2),(359,'WO33657','Welding','user_Delt','16:14:58','17:02:50','2023-05-15','2023-05-15 15:14:58',2872,170,'workInProgress',NULL,2),(360,'WO33657','Welding','user_Delt','08:00:44','12:01:33','2023-05-16','2023-05-16 07:00:44',14449,0,'workInProgress',NULL,2),(361,'WO33657','Welding','user_Delt','13:02:20','16:46:38','2023-05-16','2023-05-16 12:02:20',13458,0,'stageComplete',NULL,2),(362,'WO33658','Welding','user_Delt','16:49:30','17:01:35','2023-05-16','2023-05-16 15:49:30',725,95,'workInProgress',NULL,2),(363,'WO33658','Welding','user_Delt','08:00:22','09:50:09','2023-05-17','2023-05-17 07:00:22',6587,0,'stageComplete',NULL,2),(364,'WO33659','Welding','user_Delt','09:52:58','11:25:08','2023-05-17','2023-05-17 08:52:58',5530,0,'stageComplete',NULL,2),(365,'WO33660','Welding','user_Delt','11:25:35','12:00:41','2023-05-17','2023-05-17 10:25:35',2106,0,'workInProgress',NULL,2),(366,'WO33660','Welding','user_Delt','13:02:13','14:58:47','2023-05-17','2023-05-17 12:02:13',6994,0,'stageComplete',NULL,2),(367,'WO33661','Welding','user_Delt','15:00:21','17:02:05','2023-05-17','2023-05-17 14:00:21',7304,125,'workInProgress',NULL,2),(368,'WO33661','Welding','user_Delt','08:00:07','12:02:00','2023-05-18','2023-05-18 07:00:07',14513,0,'workInProgress',NULL,2),(369,'WO33661','Welding','user_Delt','13:00:11','13:57:52','2023-05-18','2023-05-18 12:00:11',3461,0,'stageComplete',NULL,2),(370,'WO33662','Welding','user_Delt','14:00:52','17:02:37','2023-05-18','2023-05-18 13:00:52',10905,157,'workInProgress',NULL,2),(371,'WO33662','Welding','user_Delt','08:02:31','12:02:28','2023-05-19','2023-05-19 07:02:31',14397,0,'workInProgress',NULL,2),(372,'WO33662','Welding','user_Delt','13:01:40','14:02:43','2023-05-19','2023-05-19 12:01:40',3663,0,'stageComplete',NULL,2),(373,'WO33663','Welding','user_Delt','14:03:26','16:04:09','2023-05-19','2023-05-19 13:03:26',7243,0,'stageComplete',NULL,2),(374,'job_wrgr4','Welding','user_Delt','16:06:17','17:00:58','2023-05-19','2023-05-19 15:06:17',3281,58,'workInProgress',NULL,2),(375,'WO33653','Painting','user_Delt','09:35:03','12:00:51','2023-05-12','2023-05-12 08:35:03',8748,0,'workInProgress',NULL,3),(376,'WO33653','Painting','user_Delt','13:02:18','13:08:50','2023-05-12','2023-05-12 12:02:18',392,0,'stageComplete',NULL,3),(377,'WO33655','Painting','user_Delt','10:13:20','12:01:43','2023-05-15','2023-05-15 09:13:20',6503,0,'workInProgress',NULL,3),(378,'WO33655','Painting','user_Delt','13:02:11','14:45:16','2023-05-15','2023-05-15 12:02:11',6185,0,'stageComplete',NULL,3),(379,'WO33658','Painting','user_Delt','09:52:36','12:01:30','2023-05-17','2023-05-17 08:52:36',7734,0,'workInProgress',NULL,3),(380,'WO33658','Painting','user_Delt','13:01:57','16:54:11','2023-05-17','2023-05-17 12:01:57',13934,0,'stageComplete',NULL,3),(381,'WO33659','Painting','user_Delt','16:56:59','17:02:20','2023-05-17','2023-05-17 15:56:59',321,140,'workInProgress',NULL,3),(382,'WO33659','Painting','user_Delt','08:02:35','08:27:15','2023-05-18','2023-05-18 07:02:35',1480,0,'stageComplete',NULL,3),(383,'WO33660','Painting','user_Delt','08:28:53','09:46:04','2023-05-18','2023-05-18 07:28:53',4631,0,'stageComplete',NULL,3),(384,'WO33661','Painting','user_Delt','13:58:25','15:00:37','2023-05-18','2023-05-18 12:58:25',3732,0,'stageComplete',NULL,3),(385,'WO33662','Painting','user_Delt','14:05:06','14:05:58','2023-05-19','2023-05-19 13:05:06',52,0,'stageComplete',NULL,3),(386,'WO33652','Assembly','user_Delt','15:05:56','17:00:14','2023-05-11','2023-05-11 14:05:56',6858,14,'workInProgress',NULL,3),(387,'WO33652','Assembly','user_Delt','08:02:03','12:01:33','2023-05-12','2023-05-12 07:02:03',14370,0,'workInProgress',NULL,3),(388,'WO33652','Assembly','user_Delt','13:02:25','15:40:58','2023-05-12','2023-05-12 12:02:25',9513,0,'stageComplete',NULL,3),(389,'WO33653','Assembly','user_Delt','15:41:49','16:43:58','2023-05-12','2023-05-12 14:41:49',3729,0,'stageComplete',NULL,4),(390,'WO33654','Assembly','user_Delt','16:45:43','17:02:04','2023-05-12','2023-05-12 15:45:43',981,124,'workInProgress',NULL,3),(391,'WO33654','Assembly','user_Delt','08:01:31','09:01:56','2023-05-15','2023-05-15 07:01:31',3625,0,'stageComplete',NULL,3),(392,'WO33655','Assembly','user_Delt','14:46:44','16:46:44','2023-05-15','2023-05-15 13:46:44',7200,0,'stageComplete',NULL,4),(393,'WO33656','Assembly','user_Delt','08:02:17','11:34:35','2023-05-16','2023-05-16 07:02:17',12738,0,'stageComplete',NULL,3),(394,'WO33658','Assembly','user_Delt','16:56:50','17:02:36','2023-05-17','2023-05-17 15:56:50',346,156,'workInProgress',NULL,4),(395,'WO33658','Assembly','user_Delt','08:01:24','12:01:57','2023-05-18','2023-05-18 07:01:24',14433,0,'workInProgress',NULL,4),(396,'WO33658','Assembly','user_Delt','13:02:33','17:00:07','2023-05-18','2023-05-18 12:02:33',14254,7,'workInProgress',NULL,4),(397,'WO33658','Assembly','user_Delt','08:00:58','10:59:47','2023-05-19','2023-05-19 07:00:58',10729,0,'stageComplete',NULL,4),(398,'WO33659','Assembly','user_Delt','11:00:32','12:02:20','2023-05-19','2023-05-19 10:00:32',3708,0,'workInProgress',NULL,4),(399,'WO33659','Assembly','user_Delt','13:02:29','17:00:46','2023-05-19','2023-05-19 12:02:29',14297,46,'workInProgress',NULL,4),(400,'WO33652','QC','user_Delt','15:41:21','17:02:21','2023-05-12','2023-05-12 14:41:21',4860,141,'workInProgress',NULL,4),(401,'WO33652','QC','user_Delt','08:01:05','10:55:13','2023-05-15','2023-05-15 07:01:05',10448,0,'stageComplete',NULL,4),(402,'WO33653','QC','user_Delt','10:58:05','11:28:23','2023-05-15','2023-05-15 09:58:05',1818,0,'stageComplete',NULL,5),(403,'WO33654','QC','user_Delt','11:28:44','11:43:48','2023-05-15','2023-05-15 10:28:44',904,0,'stageComplete',NULL,4),(404,'WO33655','QC','user_Delt','16:48:39','17:00:03','2023-05-15','2023-05-15 15:48:39',684,3,'workInProgress',NULL,5),(405,'WO33655','QC','user_Delt','08:01:11','08:50:50','2023-05-16','2023-05-16 07:01:11',2979,0,'stageComplete',NULL,5),(406,'WO33656','QC','user_Delt','13:01:08','15:16:36','2023-05-16','2023-05-16 12:01:08',8128,0,'stageComplete',NULL,4),(407,'WO33657','QC','user_Delt','08:02:39','11:03:26','2023-05-17','2023-05-17 07:02:39',10847,0,'stageComplete',NULL,3),(408,'WO33658','QC','user_Delt','11:01:15','12:01:14','2023-05-19','2023-05-19 10:01:15',3599,0,'workInProgress',NULL,5),(409,'WO33658','QC','user_Delt','13:00:17','14:01:00','2023-05-19','2023-05-19 12:00:17',3643,0,'stageComplete',NULL,5),(410,'WO33652','Shipping','user_Delt','10:55:53','12:01:05','2023-05-15','2023-05-15 09:55:53',3912,0,'workInProgress',NULL,5),(411,'WO33652','Shipping','user_Delt','13:02:15','17:00:43','2023-05-15','2023-05-15 12:02:15',14308,43,'workInProgress',NULL,5),(412,'WO33652','Shipping','user_Delt','08:02:48','12:01:09','2023-05-16','2023-05-16 07:02:48',14301,0,'workInProgress',NULL,5),(413,'WO33652','Shipping','user_Delt','13:02:45','17:01:15','2023-05-16','2023-05-16 12:02:45',14310,75,'workInProgress',NULL,5),(414,'WO33652','Shipping','user_Delt','08:01:56','10:04:24','2023-05-17','2023-05-17 07:01:56',7348,0,'stageComplete',NULL,5),(415,'WO33653','Shipping','user_Delt','10:05:46','12:02:07','2023-05-17','2023-05-17 09:05:46',6981,0,'workInProgress',NULL,6),(416,'WO33653','Shipping','user_Delt','13:02:01','13:21:09','2023-05-17','2023-05-17 12:02:01',1148,0,'stageComplete',NULL,6),(417,'WO33654','Shipping','user_Delt','13:21:15','15:52:34','2023-05-17','2023-05-17 12:21:15',9079,0,'stageComplete',NULL,5),(418,'WO33655','Shipping','user_Delt','15:54:12','17:01:27','2023-05-17','2023-05-17 14:54:12',4035,87,'workInProgress',NULL,6),(419,'WO33655','Shipping','user_Delt','08:01:47','09:40:20','2023-05-18','2023-05-18 07:01:47',5913,0,'stageComplete',NULL,6),(420,'WO33656','Shipping','user_Delt','09:41:26','10:41:53','2023-05-18','2023-05-18 08:41:26',3627,0,'stageComplete',NULL,5),(421,'WO33657','Shipping','user_Delt','10:42:57','12:02:10','2023-05-18','2023-05-18 09:42:57',4753,0,'workInProgress',NULL,4),(422,'WO33657','Shipping','user_Delt','13:00:53','14:44:15','2023-05-18','2023-05-18 12:00:53',6202,0,'stageComplete',NULL,4),(423,'WO33658','Shipping','user_Delt','14:02:50','17:00:05','2023-05-19','2023-05-19 13:02:50',10635,5,'workInProgress',NULL,6),(424,'WO33652','Cutting','user_Delt','08:00:34','12:02:25','2023-05-08','2023-05-08 07:00:34',14511,0,'workInProgress',NULL,1),(425,'WO33652','Cutting','user_Delt','13:00:16','17:01:05','2023-05-08','2023-05-08 12:00:16',14449,65,'workInProgress',NULL,1),(426,'WO33652','Cutting','user_Delt','08:00:30','12:02:06','2023-05-09','2023-05-09 07:00:30',14496,0,'workInProgress',NULL,1),(427,'WO33652','Cutting','user_Delt','13:01:55','17:02:00','2023-05-09','2023-05-09 12:01:55',14405,120,'workInProgress',NULL,1),(428,'WO33652','Cutting','user_Delt','08:02:46','10:00:02','2023-05-10','2023-05-10 07:02:46',7036,0,'stageComplete',NULL,1),(429,'WO33653','Cutting','user_Delt','10:00:55','12:00:24','2023-05-10','2023-05-10 09:00:55',7169,0,'workInProgress',NULL,1),(430,'WO33653','Cutting','user_Delt','13:02:04','17:00:07','2023-05-10','2023-05-10 12:02:04',14283,7,'workInProgress',NULL,1),(431,'WO33653','Cutting','user_Delt','08:01:39','12:01:50','2023-05-11','2023-05-11 07:01:39',14411,0,'workInProgress',NULL,1),(432,'WO33653','Cutting','user_Delt','13:02:35','15:04:52','2023-05-11','2023-05-11 12:02:35',7337,0,'stageComplete',NULL,1),(433,'WO33654','Cutting','user_Delt','15:07:50','16:39:44','2023-05-11','2023-05-11 14:07:50',5514,0,'stageComplete',NULL,1),(434,'WO33655','Cutting','user_Delt','16:40:52','17:00:58','2023-05-11','2023-05-11 15:40:52',1206,58,'workInProgress',NULL,1),(435,'WO33655','Cutting','user_Delt','08:02:31','08:42:51','2023-05-12','2023-05-12 07:02:31',2420,0,'stageComplete',NULL,1),(436,'WO33656','Cutting','user_Delt','08:44:12','10:44:19','2023-05-12','2023-05-12 07:44:12',7207,0,'stageComplete',NULL,1),(437,'WO33657','Cutting','user_Delt','10:44:24','12:00:06','2023-05-12','2023-05-12 09:44:24',4542,0,'workInProgress',NULL,1),(438,'WO33657','Cutting','user_Delt','13:02:46','14:49:22','2023-05-12','2023-05-12 12:02:46',6396,0,'stageComplete',NULL,1),(439,'WO33658','Cutting','user_Delt','14:49:24','17:01:37','2023-05-12','2023-05-12 13:49:24',7933,97,'workInProgress',NULL,1),(440,'WO33658','Cutting','user_Delt','08:02:55','09:51:37','2023-05-15','2023-05-15 07:02:55',6522,0,'stageComplete',NULL,1),(441,'WO33659','Cutting','user_Delt','09:53:25','11:53:32','2023-05-15','2023-05-15 08:53:25',7207,0,'stageComplete',NULL,1),(442,'WO33660','Cutting','user_Delt','08:02:15','09:33:11','2023-05-16','2023-05-16 07:02:15',5456,0,'stageComplete',NULL,1),(443,'WO33661','Cutting','user_Delt','09:35:03','12:02:06','2023-05-16','2023-05-16 08:35:03',8823,0,'workInProgress',NULL,1),(444,'WO33661','Cutting','user_Delt','13:02:21','13:36:17','2023-05-16','2023-05-16 12:02:21',2036,0,'stageComplete',NULL,1),(445,'WO33662','Cutting','user_Delt','13:37:45','16:08:44','2023-05-16','2023-05-16 12:37:45',9059,0,'stageComplete',NULL,1),(446,'WO33663','Cutting','user_Delt','08:02:53','08:48:49','2023-05-17','2023-05-17 07:02:53',2756,0,'stageComplete',NULL,1),(447,'job_wrgr4','Cutting','user_Delt','08:01:57','10:03:11','2023-05-18','2023-05-18 07:01:57',7274,0,'stageComplete',NULL,1),(448,'awegd','Cutting','user_Delt','08:00:05','12:01:46','2023-05-19','2023-05-19 07:00:05',14501,0,'workInProgress',NULL,1),(449,'awegd','Cutting','user_Delt','13:02:22','16:33:25','2023-05-19','2023-05-19 12:02:22',12663,0,'stageComplete',NULL,1),(450,'WO33652','Welding','user_Delt','10:00:27','12:00:47','2023-05-10','2023-05-10 09:00:27',7220,0,'workInProgress',NULL,2),(451,'WO33652','Welding','user_Delt','13:02:41','17:01:15','2023-05-10','2023-05-10 12:02:41',14314,75,'workInProgress',NULL,2),(452,'WO33652','Welding','user_Delt','08:00:30','12:01:25','2023-05-11','2023-05-11 07:00:30',14455,0,'workInProgress',NULL,2),(453,'WO33652','Welding','user_Delt','13:02:08','15:04:07','2023-05-11','2023-05-11 12:02:08',7319,0,'stageComplete',NULL,2),(454,'WO33653','Welding','user_Delt','08:02:09','09:35:00','2023-05-12','2023-05-12 07:02:09',5571,0,'stageComplete',NULL,2),(455,'WO33654','Welding','user_Delt','09:35:48','12:01:17','2023-05-12','2023-05-12 08:35:48',8729,0,'workInProgress',NULL,2),(456,'WO33654','Welding','user_Delt','13:01:12','13:08:13','2023-05-12','2023-05-12 12:01:12',421,0,'stageComplete',NULL,2),(457,'WO33655','Welding','user_Delt','13:10:20','17:02:09','2023-05-12','2023-05-12 12:10:20',13909,129,'workInProgress',NULL,2),(458,'WO33655','Welding','user_Delt','08:01:40','10:12:21','2023-05-15','2023-05-15 07:01:40',7841,0,'stageComplete',NULL,2),(459,'WO33656','Welding','user_Delt','10:12:29','12:02:02','2023-05-15','2023-05-15 09:12:29',6573,0,'workInProgress',NULL,2),(460,'WO33656','Welding','user_Delt','13:01:02','16:13:12','2023-05-15','2023-05-15 12:01:02',11530,0,'stageComplete',NULL,2),(461,'WO33657','Welding','user_Delt','16:14:58','17:02:50','2023-05-15','2023-05-15 15:14:58',2872,170,'workInProgress',NULL,2),(462,'WO33657','Welding','user_Delt','08:00:44','12:01:33','2023-05-16','2023-05-16 07:00:44',14449,0,'workInProgress',NULL,2),(463,'WO33657','Welding','user_Delt','13:02:20','16:46:38','2023-05-16','2023-05-16 12:02:20',13458,0,'stageComplete',NULL,2),(464,'WO33658','Welding','user_Delt','16:49:30','17:01:35','2023-05-16','2023-05-16 15:49:30',725,95,'workInProgress',NULL,2),(465,'WO33658','Welding','user_Delt','08:00:22','09:50:09','2023-05-17','2023-05-17 07:00:22',6587,0,'stageComplete',NULL,2),(466,'WO33659','Welding','user_Delt','09:52:58','11:25:08','2023-05-17','2023-05-17 08:52:58',5530,0,'stageComplete',NULL,2),(467,'WO33660','Welding','user_Delt','11:25:35','12:00:41','2023-05-17','2023-05-17 10:25:35',2106,0,'workInProgress',NULL,2),(468,'WO33660','Welding','user_Delt','13:02:13','14:58:47','2023-05-17','2023-05-17 12:02:13',6994,0,'stageComplete',NULL,2),(469,'WO33661','Welding','user_Delt','15:00:21','17:02:05','2023-05-17','2023-05-17 14:00:21',7304,125,'workInProgress',NULL,2),(470,'WO33661','Welding','user_Delt','08:00:07','12:02:00','2023-05-18','2023-05-18 07:00:07',14513,0,'workInProgress',NULL,2),(471,'WO33661','Welding','user_Delt','13:00:11','13:57:52','2023-05-18','2023-05-18 12:00:11',3461,0,'stageComplete',NULL,2),(472,'WO33662','Welding','user_Delt','14:00:52','17:02:37','2023-05-18','2023-05-18 13:00:52',10905,157,'workInProgress',NULL,2),(473,'WO33662','Welding','user_Delt','08:02:31','12:02:28','2023-05-19','2023-05-19 07:02:31',14397,0,'workInProgress',NULL,2),(474,'WO33662','Welding','user_Delt','13:01:40','14:02:43','2023-05-19','2023-05-19 12:01:40',3663,0,'stageComplete',NULL,2),(475,'WO33663','Welding','user_Delt','14:03:26','16:04:09','2023-05-19','2023-05-19 13:03:26',7243,0,'stageComplete',NULL,2),(476,'job_wrgr4','Welding','user_Delt','16:06:17','17:00:58','2023-05-19','2023-05-19 15:06:17',3281,58,'workInProgress',NULL,2),(477,'WO33653','Painting','user_Delt','09:35:03','12:00:51','2023-05-12','2023-05-12 08:35:03',8748,0,'workInProgress',NULL,3),(478,'WO33653','Painting','user_Delt','13:02:18','13:08:50','2023-05-12','2023-05-12 12:02:18',392,0,'stageComplete',NULL,3),(479,'WO33655','Painting','user_Delt','10:13:20','12:01:43','2023-05-15','2023-05-15 09:13:20',6503,0,'workInProgress',NULL,3),(480,'WO33655','Painting','user_Delt','13:02:11','14:45:16','2023-05-15','2023-05-15 12:02:11',6185,0,'stageComplete',NULL,3),(481,'WO33658','Painting','user_Delt','09:52:36','12:01:30','2023-05-17','2023-05-17 08:52:36',7734,0,'workInProgress',NULL,3),(482,'WO33658','Painting','user_Delt','13:01:57','16:54:11','2023-05-17','2023-05-17 12:01:57',13934,0,'stageComplete',NULL,3),(483,'WO33659','Painting','user_Delt','16:56:59','17:02:20','2023-05-17','2023-05-17 15:56:59',321,140,'workInProgress',NULL,3),(484,'WO33659','Painting','user_Delt','08:02:35','08:27:15','2023-05-18','2023-05-18 07:02:35',1480,0,'stageComplete',NULL,3),(485,'WO33660','Painting','user_Delt','08:28:53','09:46:04','2023-05-18','2023-05-18 07:28:53',4631,0,'stageComplete',NULL,3),(486,'WO33661','Painting','user_Delt','13:58:25','15:00:37','2023-05-18','2023-05-18 12:58:25',3732,0,'stageComplete',NULL,3),(487,'WO33662','Painting','user_Delt','14:05:06','14:05:58','2023-05-19','2023-05-19 13:05:06',52,0,'stageComplete',NULL,3),(488,'WO33652','Assembly','user_Delt','15:05:56','17:00:14','2023-05-11','2023-05-11 14:05:56',6858,14,'workInProgress',NULL,3),(489,'WO33652','Assembly','user_Delt','08:02:03','12:01:33','2023-05-12','2023-05-12 07:02:03',14370,0,'workInProgress',NULL,3),(490,'WO33652','Assembly','user_Delt','13:02:25','15:40:58','2023-05-12','2023-05-12 12:02:25',9513,0,'stageComplete',NULL,3),(491,'WO33653','Assembly','user_Delt','15:41:49','16:43:58','2023-05-12','2023-05-12 14:41:49',3729,0,'stageComplete',NULL,4),(492,'WO33654','Assembly','user_Delt','16:45:43','17:02:04','2023-05-12','2023-05-12 15:45:43',981,124,'workInProgress',NULL,3),(493,'WO33654','Assembly','user_Delt','08:01:31','09:01:56','2023-05-15','2023-05-15 07:01:31',3625,0,'stageComplete',NULL,3),(494,'WO33655','Assembly','user_Delt','14:46:44','16:46:44','2023-05-15','2023-05-15 13:46:44',7200,0,'stageComplete',NULL,4),(495,'WO33656','Assembly','user_Delt','08:02:17','11:34:35','2023-05-16','2023-05-16 07:02:17',12738,0,'stageComplete',NULL,3),(496,'WO33658','Assembly','user_Delt','16:56:50','17:02:36','2023-05-17','2023-05-17 15:56:50',346,156,'workInProgress',NULL,4),(497,'WO33658','Assembly','user_Delt','08:01:24','12:01:57','2023-05-18','2023-05-18 07:01:24',14433,0,'workInProgress',NULL,4),(498,'WO33658','Assembly','user_Delt','13:02:33','17:00:07','2023-05-18','2023-05-18 12:02:33',14254,7,'workInProgress',NULL,4),(499,'WO33658','Assembly','user_Delt','08:00:58','10:59:47','2023-05-19','2023-05-19 07:00:58',10729,0,'stageComplete',NULL,4),(500,'WO33659','Assembly','user_Delt','11:00:32','12:02:20','2023-05-19','2023-05-19 10:00:32',3708,0,'workInProgress',NULL,4),(501,'WO33659','Assembly','user_Delt','13:02:29','17:00:46','2023-05-19','2023-05-19 12:02:29',14297,46,'workInProgress',NULL,4),(502,'WO33652','QC','user_Delt','15:41:21','17:02:21','2023-05-12','2023-05-12 14:41:21',4860,141,'workInProgress',NULL,4),(503,'WO33652','QC','user_Delt','08:01:05','10:55:13','2023-05-15','2023-05-15 07:01:05',10448,0,'stageComplete',NULL,4),(504,'WO33653','QC','user_Delt','10:58:05','11:28:23','2023-05-15','2023-05-15 09:58:05',1818,0,'stageComplete',NULL,5),(505,'WO33654','QC','user_Delt','11:28:44','11:43:48','2023-05-15','2023-05-15 10:28:44',904,0,'stageComplete',NULL,4),(506,'WO33655','QC','user_Delt','16:48:39','17:00:03','2023-05-15','2023-05-15 15:48:39',684,3,'workInProgress',NULL,5),(507,'WO33655','QC','user_Delt','08:01:11','08:50:50','2023-05-16','2023-05-16 07:01:11',2979,0,'stageComplete',NULL,5),(508,'WO33656','QC','user_Delt','13:01:08','15:16:36','2023-05-16','2023-05-16 12:01:08',8128,0,'stageComplete',NULL,4),(509,'WO33657','QC','user_Delt','08:02:39','11:03:26','2023-05-17','2023-05-17 07:02:39',10847,0,'stageComplete',NULL,3),(510,'WO33658','QC','user_Delt','11:01:15','12:01:14','2023-05-19','2023-05-19 10:01:15',3599,0,'workInProgress',NULL,5),(511,'WO33658','QC','user_Delt','13:00:17','14:01:00','2023-05-19','2023-05-19 12:00:17',3643,0,'stageComplete',NULL,5),(512,'WO33652','Shipping','user_Delt','10:55:53','12:01:05','2023-05-15','2023-05-15 09:55:53',3912,0,'workInProgress',NULL,5),(513,'WO33652','Shipping','user_Delt','13:02:15','17:00:43','2023-05-15','2023-05-15 12:02:15',14308,43,'workInProgress',NULL,5),(514,'WO33652','Shipping','user_Delt','08:02:48','12:01:09','2023-05-16','2023-05-16 07:02:48',14301,0,'workInProgress',NULL,5),(515,'WO33652','Shipping','user_Delt','13:02:45','17:01:15','2023-05-16','2023-05-16 12:02:45',14310,75,'workInProgress',NULL,5),(516,'WO33652','Shipping','user_Delt','08:01:56','10:04:24','2023-05-17','2023-05-17 07:01:56',7348,0,'stageComplete',NULL,5),(517,'WO33653','Shipping','user_Delt','10:05:46','12:02:07','2023-05-17','2023-05-17 09:05:46',6981,0,'workInProgress',NULL,6),(518,'WO33653','Shipping','user_Delt','13:02:01','13:21:09','2023-05-17','2023-05-17 12:02:01',1148,0,'stageComplete',NULL,6),(519,'WO33654','Shipping','user_Delt','13:21:15','15:52:34','2023-05-17','2023-05-17 12:21:15',9079,0,'stageComplete',NULL,5),(520,'WO33655','Shipping','user_Delt','15:54:12','17:01:27','2023-05-17','2023-05-17 14:54:12',4035,87,'workInProgress',NULL,6),(521,'WO33655','Shipping','user_Delt','08:01:47','09:40:20','2023-05-18','2023-05-18 07:01:47',5913,0,'stageComplete',NULL,6),(522,'WO33656','Shipping','user_Delt','09:41:26','10:41:53','2023-05-18','2023-05-18 08:41:26',3627,0,'stageComplete',NULL,5),(523,'WO33657','Shipping','user_Delt','10:42:57','12:02:10','2023-05-18','2023-05-18 09:42:57',4753,0,'workInProgress',NULL,4),(524,'WO33657','Shipping','user_Delt','13:00:53','14:44:15','2023-05-18','2023-05-18 12:00:53',6202,0,'stageComplete',NULL,4),(525,'WO33658','Shipping','user_Delt','14:02:50','17:00:05','2023-05-19','2023-05-19 13:02:50',10635,5,'workInProgress',NULL,6),(526,'WO33652','Cutting','user_Delt','08:00:34','12:02:25','2023-05-08','2023-05-08 07:00:34',14511,0,'workInProgress',NULL,1),(527,'WO33652','Cutting','user_Delt','13:00:16','17:01:05','2023-05-08','2023-05-08 12:00:16',14449,65,'workInProgress',NULL,1),(528,'WO33652','Cutting','user_Delt','08:00:30','12:02:06','2023-05-09','2023-05-09 07:00:30',14496,0,'workInProgress',NULL,1),(529,'WO33652','Cutting','user_Delt','13:01:55','17:02:00','2023-05-09','2023-05-09 12:01:55',14405,120,'workInProgress',NULL,1),(530,'WO33652','Cutting','user_Delt','08:02:46','10:00:02','2023-05-10','2023-05-10 07:02:46',7036,0,'stageComplete',NULL,1),(531,'WO33653','Cutting','user_Delt','10:00:55','12:00:24','2023-05-10','2023-05-10 09:00:55',7169,0,'workInProgress',NULL,1),(532,'WO33653','Cutting','user_Delt','13:02:04','17:00:07','2023-05-10','2023-05-10 12:02:04',14283,7,'workInProgress',NULL,1),(533,'WO33653','Cutting','user_Delt','08:01:39','12:01:50','2023-05-11','2023-05-11 07:01:39',14411,0,'workInProgress',NULL,1),(534,'WO33653','Cutting','user_Delt','13:02:35','15:04:52','2023-05-11','2023-05-11 12:02:35',7337,0,'stageComplete',NULL,1),(535,'WO33654','Cutting','user_Delt','15:07:50','16:39:44','2023-05-11','2023-05-11 14:07:50',5514,0,'stageComplete',NULL,1),(536,'WO33655','Cutting','user_Delt','16:40:52','17:00:58','2023-05-11','2023-05-11 15:40:52',1206,58,'workInProgress',NULL,1),(537,'WO33655','Cutting','user_Delt','08:02:31','08:42:51','2023-05-12','2023-05-12 07:02:31',2420,0,'stageComplete',NULL,1),(538,'WO33656','Cutting','user_Delt','08:44:12','10:44:19','2023-05-12','2023-05-12 07:44:12',7207,0,'stageComplete',NULL,1),(539,'WO33657','Cutting','user_Delt','10:44:24','12:00:06','2023-05-12','2023-05-12 09:44:24',4542,0,'workInProgress',NULL,1),(540,'WO33657','Cutting','user_Delt','13:02:46','14:49:22','2023-05-12','2023-05-12 12:02:46',6396,0,'stageComplete',NULL,1),(541,'WO33658','Cutting','user_Delt','14:49:24','17:01:37','2023-05-12','2023-05-12 13:49:24',7933,97,'workInProgress',NULL,1),(542,'WO33658','Cutting','user_Delt','08:02:55','09:51:37','2023-05-15','2023-05-15 07:02:55',6522,0,'stageComplete',NULL,1),(543,'WO33659','Cutting','user_Delt','09:53:25','11:53:32','2023-05-15','2023-05-15 08:53:25',7207,0,'stageComplete',NULL,1),(544,'WO33660','Cutting','user_Delt','08:02:15','09:33:11','2023-05-16','2023-05-16 07:02:15',5456,0,'stageComplete',NULL,1),(545,'WO33661','Cutting','user_Delt','09:35:03','12:02:06','2023-05-16','2023-05-16 08:35:03',8823,0,'workInProgress',NULL,1),(546,'WO33661','Cutting','user_Delt','13:02:21','13:36:17','2023-05-16','2023-05-16 12:02:21',2036,0,'stageComplete',NULL,1),(547,'WO33662','Cutting','user_Delt','13:37:45','16:08:44','2023-05-16','2023-05-16 12:37:45',9059,0,'stageComplete',NULL,1),(548,'WO33663','Cutting','user_Delt','08:02:53','08:48:49','2023-05-17','2023-05-17 07:02:53',2756,0,'stageComplete',NULL,1),(549,'job_wrgr4','Cutting','user_Delt','08:01:57','10:03:11','2023-05-18','2023-05-18 07:01:57',7274,0,'stageComplete',NULL,1),(550,'awegd','Cutting','user_Delt','08:00:05','12:01:46','2023-05-19','2023-05-19 07:00:05',14501,0,'workInProgress',NULL,1),(551,'awegd','Cutting','user_Delt','13:02:22','16:33:25','2023-05-19','2023-05-19 12:02:22',12663,0,'stageComplete',NULL,1),(552,'WO33652','Welding','user_Delt','10:00:27','12:00:47','2023-05-10','2023-05-10 09:00:27',7220,0,'workInProgress',NULL,2),(553,'WO33652','Welding','user_Delt','13:02:41','17:01:15','2023-05-10','2023-05-10 12:02:41',14314,75,'workInProgress',NULL,2),(554,'WO33652','Welding','user_Delt','08:00:30','12:01:25','2023-05-11','2023-05-11 07:00:30',14455,0,'workInProgress',NULL,2),(555,'WO33652','Welding','user_Delt','13:02:08','15:04:07','2023-05-11','2023-05-11 12:02:08',7319,0,'stageComplete',NULL,2),(556,'WO33653','Welding','user_Delt','08:02:09','09:35:00','2023-05-12','2023-05-12 07:02:09',5571,0,'stageComplete',NULL,2),(557,'WO33654','Welding','user_Delt','09:35:48','12:01:17','2023-05-12','2023-05-12 08:35:48',8729,0,'workInProgress',NULL,2),(558,'WO33654','Welding','user_Delt','13:01:12','13:08:13','2023-05-12','2023-05-12 12:01:12',421,0,'stageComplete',NULL,2),(559,'WO33655','Welding','user_Delt','13:10:20','17:02:09','2023-05-12','2023-05-12 12:10:20',13909,129,'workInProgress',NULL,2),(560,'WO33655','Welding','user_Delt','08:01:40','10:12:21','2023-05-15','2023-05-15 07:01:40',7841,0,'stageComplete',NULL,2),(561,'WO33656','Welding','user_Delt','10:12:29','12:02:02','2023-05-15','2023-05-15 09:12:29',6573,0,'workInProgress',NULL,2),(562,'WO33656','Welding','user_Delt','13:01:02','16:13:12','2023-05-15','2023-05-15 12:01:02',11530,0,'stageComplete',NULL,2),(563,'WO33657','Welding','user_Delt','16:14:58','17:02:50','2023-05-15','2023-05-15 15:14:58',2872,170,'workInProgress',NULL,2),(564,'WO33657','Welding','user_Delt','08:00:44','12:01:33','2023-05-16','2023-05-16 07:00:44',14449,0,'workInProgress',NULL,2),(565,'WO33657','Welding','user_Delt','13:02:20','16:46:38','2023-05-16','2023-05-16 12:02:20',13458,0,'stageComplete',NULL,2),(566,'WO33658','Welding','user_Delt','16:49:30','17:01:35','2023-05-16','2023-05-16 15:49:30',725,95,'workInProgress',NULL,2),(567,'WO33658','Welding','user_Delt','08:00:22','09:50:09','2023-05-17','2023-05-17 07:00:22',6587,0,'stageComplete',NULL,2),(568,'WO33659','Welding','user_Delt','09:52:58','11:25:08','2023-05-17','2023-05-17 08:52:58',5530,0,'stageComplete',NULL,2),(569,'WO33660','Welding','user_Delt','11:25:35','12:00:41','2023-05-17','2023-05-17 10:25:35',2106,0,'workInProgress',NULL,2),(570,'WO33660','Welding','user_Delt','13:02:13','14:58:47','2023-05-17','2023-05-17 12:02:13',6994,0,'stageComplete',NULL,2),(571,'WO33661','Welding','user_Delt','15:00:21','17:02:05','2023-05-17','2023-05-17 14:00:21',7304,125,'workInProgress',NULL,2),(572,'WO33661','Welding','user_Delt','08:00:07','12:02:00','2023-05-18','2023-05-18 07:00:07',14513,0,'workInProgress',NULL,2),(573,'WO33661','Welding','user_Delt','13:00:11','13:57:52','2023-05-18','2023-05-18 12:00:11',3461,0,'stageComplete',NULL,2),(574,'WO33662','Welding','user_Delt','14:00:52','17:02:37','2023-05-18','2023-05-18 13:00:52',10905,157,'workInProgress',NULL,2),(575,'WO33662','Welding','user_Delt','08:02:31','12:02:28','2023-05-19','2023-05-19 07:02:31',14397,0,'workInProgress',NULL,2),(576,'WO33662','Welding','user_Delt','13:01:40','14:02:43','2023-05-19','2023-05-19 12:01:40',3663,0,'stageComplete',NULL,2),(577,'WO33663','Welding','user_Delt','14:03:26','16:04:09','2023-05-19','2023-05-19 13:03:26',7243,0,'stageComplete',NULL,2),(578,'job_wrgr4','Welding','user_Delt','16:06:17','17:00:58','2023-05-19','2023-05-19 15:06:17',3281,58,'workInProgress',NULL,2),(579,'WO33653','Painting','user_Delt','09:35:03','12:00:51','2023-05-12','2023-05-12 08:35:03',8748,0,'workInProgress',NULL,3),(580,'WO33653','Painting','user_Delt','13:02:18','13:08:50','2023-05-12','2023-05-12 12:02:18',392,0,'stageComplete',NULL,3),(581,'WO33655','Painting','user_Delt','10:13:20','12:01:43','2023-05-15','2023-05-15 09:13:20',6503,0,'workInProgress',NULL,3),(582,'WO33655','Painting','user_Delt','13:02:11','14:45:16','2023-05-15','2023-05-15 12:02:11',6185,0,'stageComplete',NULL,3),(583,'WO33658','Painting','user_Delt','09:52:36','12:01:30','2023-05-17','2023-05-17 08:52:36',7734,0,'workInProgress',NULL,3),(584,'WO33658','Painting','user_Delt','13:01:57','16:54:11','2023-05-17','2023-05-17 12:01:57',13934,0,'stageComplete',NULL,3),(585,'WO33659','Painting','user_Delt','16:56:59','17:02:20','2023-05-17','2023-05-17 15:56:59',321,140,'workInProgress',NULL,3),(586,'WO33659','Painting','user_Delt','08:02:35','08:27:15','2023-05-18','2023-05-18 07:02:35',1480,0,'stageComplete',NULL,3),(587,'WO33660','Painting','user_Delt','08:28:53','09:46:04','2023-05-18','2023-05-18 07:28:53',4631,0,'stageComplete',NULL,3),(588,'WO33661','Painting','user_Delt','13:58:25','15:00:37','2023-05-18','2023-05-18 12:58:25',3732,0,'stageComplete',NULL,3),(589,'WO33662','Painting','user_Delt','14:05:06','14:05:58','2023-05-19','2023-05-19 13:05:06',52,0,'stageComplete',NULL,3),(590,'WO33652','Assembly','user_Delt','15:05:56','17:00:14','2023-05-11','2023-05-11 14:05:56',6858,14,'workInProgress',NULL,3),(591,'WO33652','Assembly','user_Delt','08:02:03','12:01:33','2023-05-12','2023-05-12 07:02:03',14370,0,'workInProgress',NULL,3),(592,'WO33652','Assembly','user_Delt','13:02:25','15:40:58','2023-05-12','2023-05-12 12:02:25',9513,0,'stageComplete',NULL,3),(593,'WO33653','Assembly','user_Delt','15:41:49','16:43:58','2023-05-12','2023-05-12 14:41:49',3729,0,'stageComplete',NULL,4),(594,'WO33654','Assembly','user_Delt','16:45:43','17:02:04','2023-05-12','2023-05-12 15:45:43',981,124,'workInProgress',NULL,3),(595,'WO33654','Assembly','user_Delt','08:01:31','09:01:56','2023-05-15','2023-05-15 07:01:31',3625,0,'stageComplete',NULL,3),(596,'WO33655','Assembly','user_Delt','14:46:44','16:46:44','2023-05-15','2023-05-15 13:46:44',7200,0,'stageComplete',NULL,4),(597,'WO33656','Assembly','user_Delt','08:02:17','11:34:35','2023-05-16','2023-05-16 07:02:17',12738,0,'stageComplete',NULL,3),(598,'WO33658','Assembly','user_Delt','16:56:50','17:02:36','2023-05-17','2023-05-17 15:56:50',346,156,'workInProgress',NULL,4),(599,'WO33658','Assembly','user_Delt','08:01:24','12:01:57','2023-05-18','2023-05-18 07:01:24',14433,0,'workInProgress',NULL,4),(600,'WO33658','Assembly','user_Delt','13:02:33','17:00:07','2023-05-18','2023-05-18 12:02:33',14254,7,'workInProgress',NULL,4),(601,'WO33658','Assembly','user_Delt','08:00:58','10:59:47','2023-05-19','2023-05-19 07:00:58',10729,0,'stageComplete',NULL,4),(602,'WO33659','Assembly','user_Delt','11:00:32','12:02:20','2023-05-19','2023-05-19 10:00:32',3708,0,'workInProgress',NULL,4),(603,'WO33659','Assembly','user_Delt','13:02:29','17:00:46','2023-05-19','2023-05-19 12:02:29',14297,46,'workInProgress',NULL,4),(604,'WO33652','QC','user_Delt','15:41:21','17:02:21','2023-05-12','2023-05-12 14:41:21',4860,141,'workInProgress',NULL,4),(605,'WO33652','QC','user_Delt','08:01:05','10:55:13','2023-05-15','2023-05-15 07:01:05',10448,0,'stageComplete',NULL,4),(606,'WO33653','QC','user_Delt','10:58:05','11:28:23','2023-05-15','2023-05-15 09:58:05',1818,0,'stageComplete',NULL,5),(607,'WO33654','QC','user_Delt','11:28:44','11:43:48','2023-05-15','2023-05-15 10:28:44',904,0,'stageComplete',NULL,4),(608,'WO33655','QC','user_Delt','16:48:39','17:00:03','2023-05-15','2023-05-15 15:48:39',684,3,'workInProgress',NULL,5),(609,'WO33655','QC','user_Delt','08:01:11','08:50:50','2023-05-16','2023-05-16 07:01:11',2979,0,'stageComplete',NULL,5),(610,'WO33656','QC','user_Delt','13:01:08','15:16:36','2023-05-16','2023-05-16 12:01:08',8128,0,'stageComplete',NULL,4),(611,'WO33657','QC','user_Delt','08:02:39','11:03:26','2023-05-17','2023-05-17 07:02:39',10847,0,'stageComplete',NULL,3),(612,'WO33658','QC','user_Delt','11:01:15','12:01:14','2023-05-19','2023-05-19 10:01:15',3599,0,'workInProgress',NULL,5),(613,'WO33658','QC','user_Delt','13:00:17','14:01:00','2023-05-19','2023-05-19 12:00:17',3643,0,'stageComplete',NULL,5),(614,'WO33652','Shipping','user_Delt','10:55:53','12:01:05','2023-05-15','2023-05-15 09:55:53',3912,0,'workInProgress',NULL,5),(615,'WO33652','Shipping','user_Delt','13:02:15','17:00:43','2023-05-15','2023-05-15 12:02:15',14308,43,'workInProgress',NULL,5),(616,'WO33652','Shipping','user_Delt','08:02:48','12:01:09','2023-05-16','2023-05-16 07:02:48',14301,0,'workInProgress',NULL,5),(617,'WO33652','Shipping','user_Delt','13:02:45','17:01:15','2023-05-16','2023-05-16 12:02:45',14310,75,'workInProgress',NULL,5),(618,'WO33652','Shipping','user_Delt','08:01:56','10:04:24','2023-05-17','2023-05-17 07:01:56',7348,0,'stageComplete',NULL,5),(619,'WO33653','Shipping','user_Delt','10:05:46','12:02:07','2023-05-17','2023-05-17 09:05:46',6981,0,'workInProgress',NULL,6),(620,'WO33653','Shipping','user_Delt','13:02:01','13:21:09','2023-05-17','2023-05-17 12:02:01',1148,0,'stageComplete',NULL,6),(621,'WO33654','Shipping','user_Delt','13:21:15','15:52:34','2023-05-17','2023-05-17 12:21:15',9079,0,'stageComplete',NULL,5),(622,'WO33655','Shipping','user_Delt','15:54:12','17:01:27','2023-05-17','2023-05-17 14:54:12',4035,87,'workInProgress',NULL,6),(623,'WO33655','Shipping','user_Delt','08:01:47','09:40:20','2023-05-18','2023-05-18 07:01:47',5913,0,'stageComplete',NULL,6),(624,'WO33656','Shipping','user_Delt','09:41:26','10:41:53','2023-05-18','2023-05-18 08:41:26',3627,0,'stageComplete',NULL,5),(625,'WO33657','Shipping','user_Delt','10:42:57','12:02:10','2023-05-18','2023-05-18 09:42:57',4753,0,'workInProgress',NULL,4),(626,'WO33657','Shipping','user_Delt','13:00:53','14:44:15','2023-05-18','2023-05-18 12:00:53',6202,0,'stageComplete',NULL,4),(627,'WO33658','Shipping','user_Delt','14:02:50','17:00:05','2023-05-19','2023-05-19 13:02:50',10635,5,'workInProgress',NULL,6),(628,'WO33652','Cutting','user_Delt','08:00:34','12:02:25','2023-05-08','2023-05-08 07:00:34',14511,0,'workInProgress',NULL,1),(629,'WO33652','Cutting','user_Delt','13:00:16','17:01:05','2023-05-08','2023-05-08 12:00:16',14449,65,'workInProgress',NULL,1),(630,'WO33652','Cutting','user_Delt','08:00:30','12:02:06','2023-05-09','2023-05-09 07:00:30',14496,0,'workInProgress',NULL,1),(631,'WO33652','Cutting','user_Delt','13:01:55','17:02:00','2023-05-09','2023-05-09 12:01:55',14405,120,'workInProgress',NULL,1),(632,'WO33652','Cutting','user_Delt','08:02:46','10:00:02','2023-05-10','2023-05-10 07:02:46',7036,0,'stageComplete',NULL,1),(633,'WO33653','Cutting','user_Delt','10:00:55','12:00:24','2023-05-10','2023-05-10 09:00:55',7169,0,'workInProgress',NULL,1),(634,'WO33653','Cutting','user_Delt','13:02:04','17:00:07','2023-05-10','2023-05-10 12:02:04',14283,7,'workInProgress',NULL,1),(635,'WO33653','Cutting','user_Delt','08:01:39','12:01:50','2023-05-11','2023-05-11 07:01:39',14411,0,'workInProgress',NULL,1),(636,'WO33653','Cutting','user_Delt','13:02:35','15:04:52','2023-05-11','2023-05-11 12:02:35',7337,0,'stageComplete',NULL,1),(637,'WO33654','Cutting','user_Delt','15:07:50','16:39:44','2023-05-11','2023-05-11 14:07:50',5514,0,'stageComplete',NULL,1),(638,'WO33655','Cutting','user_Delt','16:40:52','17:00:58','2023-05-11','2023-05-11 15:40:52',1206,58,'workInProgress',NULL,1),(639,'WO33655','Cutting','user_Delt','08:02:31','08:42:51','2023-05-12','2023-05-12 07:02:31',2420,0,'stageComplete',NULL,1),(640,'WO33656','Cutting','user_Delt','08:44:12','10:44:19','2023-05-12','2023-05-12 07:44:12',7207,0,'stageComplete',NULL,1),(641,'WO33657','Cutting','user_Delt','10:44:24','12:00:06','2023-05-12','2023-05-12 09:44:24',4542,0,'workInProgress',NULL,1),(642,'WO33657','Cutting','user_Delt','13:02:46','14:49:22','2023-05-12','2023-05-12 12:02:46',6396,0,'stageComplete',NULL,1),(643,'WO33658','Cutting','user_Delt','14:49:24','17:01:37','2023-05-12','2023-05-12 13:49:24',7933,97,'workInProgress',NULL,1),(644,'WO33658','Cutting','user_Delt','08:02:55','09:51:37','2023-05-15','2023-05-15 07:02:55',6522,0,'stageComplete',NULL,1),(645,'WO33659','Cutting','user_Delt','09:53:25','11:53:32','2023-05-15','2023-05-15 08:53:25',7207,0,'stageComplete',NULL,1),(646,'WO33660','Cutting','user_Delt','08:02:15','09:33:11','2023-05-16','2023-05-16 07:02:15',5456,0,'stageComplete',NULL,1),(647,'WO33661','Cutting','user_Delt','09:35:03','12:02:06','2023-05-16','2023-05-16 08:35:03',8823,0,'workInProgress',NULL,1),(648,'WO33661','Cutting','user_Delt','13:02:21','13:36:17','2023-05-16','2023-05-16 12:02:21',2036,0,'stageComplete',NULL,1),(649,'WO33662','Cutting','user_Delt','13:37:45','16:08:44','2023-05-16','2023-05-16 12:37:45',9059,0,'stageComplete',NULL,1),(650,'WO33663','Cutting','user_Delt','08:02:53','08:48:49','2023-05-17','2023-05-17 07:02:53',2756,0,'stageComplete',NULL,1),(651,'job_wrgr4','Cutting','user_Delt','08:01:57','10:03:11','2023-05-18','2023-05-18 07:01:57',7274,0,'stageComplete',NULL,1),(652,'awegd','Cutting','user_Delt','08:00:05','12:01:46','2023-05-19','2023-05-19 07:00:05',14501,0,'workInProgress',NULL,1),(653,'awegd','Cutting','user_Delt','13:02:22','16:33:25','2023-05-19','2023-05-19 12:02:22',12663,0,'stageComplete',NULL,1),(654,'WO33652','Welding','user_Delt','10:00:27','12:00:47','2023-05-10','2023-05-10 09:00:27',7220,0,'workInProgress',NULL,2),(655,'WO33652','Welding','user_Delt','13:02:41','17:01:15','2023-05-10','2023-05-10 12:02:41',14314,75,'workInProgress',NULL,2),(656,'WO33652','Welding','user_Delt','08:00:30','12:01:25','2023-05-11','2023-05-11 07:00:30',14455,0,'workInProgress',NULL,2),(657,'WO33652','Welding','user_Delt','13:02:08','15:04:07','2023-05-11','2023-05-11 12:02:08',7319,0,'stageComplete',NULL,2),(658,'WO33653','Welding','user_Delt','08:02:09','09:35:00','2023-05-12','2023-05-12 07:02:09',5571,0,'stageComplete',NULL,2),(659,'WO33654','Welding','user_Delt','09:35:48','12:01:17','2023-05-12','2023-05-12 08:35:48',8729,0,'workInProgress',NULL,2),(660,'WO33654','Welding','user_Delt','13:01:12','13:08:13','2023-05-12','2023-05-12 12:01:12',421,0,'stageComplete',NULL,2),(661,'WO33655','Welding','user_Delt','13:10:20','17:02:09','2023-05-12','2023-05-12 12:10:20',13909,129,'workInProgress',NULL,2),(662,'WO33655','Welding','user_Delt','08:01:40','10:12:21','2023-05-15','2023-05-15 07:01:40',7841,0,'stageComplete',NULL,2),(663,'WO33656','Welding','user_Delt','10:12:29','12:02:02','2023-05-15','2023-05-15 09:12:29',6573,0,'workInProgress',NULL,2),(664,'WO33656','Welding','user_Delt','13:01:02','16:13:12','2023-05-15','2023-05-15 12:01:02',11530,0,'stageComplete',NULL,2),(665,'WO33657','Welding','user_Delt','16:14:58','17:02:50','2023-05-15','2023-05-15 15:14:58',2872,170,'workInProgress',NULL,2),(666,'WO33657','Welding','user_Delt','08:00:44','12:01:33','2023-05-16','2023-05-16 07:00:44',14449,0,'workInProgress',NULL,2),(667,'WO33657','Welding','user_Delt','13:02:20','16:46:38','2023-05-16','2023-05-16 12:02:20',13458,0,'stageComplete',NULL,2),(668,'WO33658','Welding','user_Delt','16:49:30','17:01:35','2023-05-16','2023-05-16 15:49:30',725,95,'workInProgress',NULL,2),(669,'WO33658','Welding','user_Delt','08:00:22','09:50:09','2023-05-17','2023-05-17 07:00:22',6587,0,'stageComplete',NULL,2),(670,'WO33659','Welding','user_Delt','09:52:58','11:25:08','2023-05-17','2023-05-17 08:52:58',5530,0,'stageComplete',NULL,2),(671,'WO33660','Welding','user_Delt','11:25:35','12:00:41','2023-05-17','2023-05-17 10:25:35',2106,0,'workInProgress',NULL,2),(672,'WO33660','Welding','user_Delt','13:02:13','14:58:47','2023-05-17','2023-05-17 12:02:13',6994,0,'stageComplete',NULL,2),(673,'WO33661','Welding','user_Delt','15:00:21','17:02:05','2023-05-17','2023-05-17 14:00:21',7304,125,'workInProgress',NULL,2),(674,'WO33661','Welding','user_Delt','08:00:07','12:02:00','2023-05-18','2023-05-18 07:00:07',14513,0,'workInProgress',NULL,2),(675,'WO33661','Welding','user_Delt','13:00:11','13:57:52','2023-05-18','2023-05-18 12:00:11',3461,0,'stageComplete',NULL,2),(676,'WO33662','Welding','user_Delt','14:00:52','17:02:37','2023-05-18','2023-05-18 13:00:52',10905,157,'workInProgress',NULL,2),(677,'WO33662','Welding','user_Delt','08:02:31','12:02:28','2023-05-19','2023-05-19 07:02:31',14397,0,'workInProgress',NULL,2),(678,'WO33662','Welding','user_Delt','13:01:40','14:02:43','2023-05-19','2023-05-19 12:01:40',3663,0,'stageComplete',NULL,2),(679,'WO33663','Welding','user_Delt','14:03:26','16:04:09','2023-05-19','2023-05-19 13:03:26',7243,0,'stageComplete',NULL,2),(680,'job_wrgr4','Welding','user_Delt','16:06:17','17:00:58','2023-05-19','2023-05-19 15:06:17',3281,58,'workInProgress',NULL,2),(681,'WO33653','Painting','user_Delt','09:35:03','12:00:51','2023-05-12','2023-05-12 08:35:03',8748,0,'workInProgress',NULL,3),(682,'WO33653','Painting','user_Delt','13:02:18','13:08:50','2023-05-12','2023-05-12 12:02:18',392,0,'stageComplete',NULL,3),(683,'WO33655','Painting','user_Delt','10:13:20','12:01:43','2023-05-15','2023-05-15 09:13:20',6503,0,'workInProgress',NULL,3),(684,'WO33655','Painting','user_Delt','13:02:11','14:45:16','2023-05-15','2023-05-15 12:02:11',6185,0,'stageComplete',NULL,3),(685,'WO33658','Painting','user_Delt','09:52:36','12:01:30','2023-05-17','2023-05-17 08:52:36',7734,0,'workInProgress',NULL,3),(686,'WO33658','Painting','user_Delt','13:01:57','16:54:11','2023-05-17','2023-05-17 12:01:57',13934,0,'stageComplete',NULL,3),(687,'WO33659','Painting','user_Delt','16:56:59','17:02:20','2023-05-17','2023-05-17 15:56:59',321,140,'workInProgress',NULL,3),(688,'WO33659','Painting','user_Delt','08:02:35','08:27:15','2023-05-18','2023-05-18 07:02:35',1480,0,'stageComplete',NULL,3),(689,'WO33660','Painting','user_Delt','08:28:53','09:46:04','2023-05-18','2023-05-18 07:28:53',4631,0,'stageComplete',NULL,3),(690,'WO33661','Painting','user_Delt','13:58:25','15:00:37','2023-05-18','2023-05-18 12:58:25',3732,0,'stageComplete',NULL,3),(691,'WO33662','Painting','user_Delt','14:05:06','14:05:58','2023-05-19','2023-05-19 13:05:06',52,0,'stageComplete',NULL,3),(692,'WO33652','Assembly','user_Delt','15:05:56','17:00:14','2023-05-11','2023-05-11 14:05:56',6858,14,'workInProgress',NULL,3),(693,'WO33652','Assembly','user_Delt','08:02:03','12:01:33','2023-05-12','2023-05-12 07:02:03',14370,0,'workInProgress',NULL,3),(694,'WO33652','Assembly','user_Delt','13:02:25','15:40:58','2023-05-12','2023-05-12 12:02:25',9513,0,'stageComplete',NULL,3),(695,'WO33653','Assembly','user_Delt','15:41:49','16:43:58','2023-05-12','2023-05-12 14:41:49',3729,0,'stageComplete',NULL,4),(696,'WO33654','Assembly','user_Delt','16:45:43','17:02:04','2023-05-12','2023-05-12 15:45:43',981,124,'workInProgress',NULL,3),(697,'WO33654','Assembly','user_Delt','08:01:31','09:01:56','2023-05-15','2023-05-15 07:01:31',3625,0,'stageComplete',NULL,3),(698,'WO33655','Assembly','user_Delt','14:46:44','16:46:44','2023-05-15','2023-05-15 13:46:44',7200,0,'stageComplete',NULL,4),(699,'WO33656','Assembly','user_Delt','08:02:17','11:34:35','2023-05-16','2023-05-16 07:02:17',12738,0,'stageComplete',NULL,3),(700,'WO33658','Assembly','user_Delt','16:56:50','17:02:36','2023-05-17','2023-05-17 15:56:50',346,156,'workInProgress',NULL,4),(701,'WO33658','Assembly','user_Delt','08:01:24','12:01:57','2023-05-18','2023-05-18 07:01:24',14433,0,'workInProgress',NULL,4),(702,'WO33658','Assembly','user_Delt','13:02:33','17:00:07','2023-05-18','2023-05-18 12:02:33',14254,7,'workInProgress',NULL,4),(703,'WO33658','Assembly','user_Delt','08:00:58','10:59:47','2023-05-19','2023-05-19 07:00:58',10729,0,'stageComplete',NULL,4),(704,'WO33659','Assembly','user_Delt','11:00:32','12:02:20','2023-05-19','2023-05-19 10:00:32',3708,0,'workInProgress',NULL,4),(705,'WO33659','Assembly','user_Delt','13:02:29','17:00:46','2023-05-19','2023-05-19 12:02:29',14297,46,'workInProgress',NULL,4),(706,'WO33652','QC','user_Delt','15:41:21','17:02:21','2023-05-12','2023-05-12 14:41:21',4860,141,'workInProgress',NULL,4),(707,'WO33652','QC','user_Delt','08:01:05','10:55:13','2023-05-15','2023-05-15 07:01:05',10448,0,'stageComplete',NULL,4),(708,'WO33653','QC','user_Delt','10:58:05','11:28:23','2023-05-15','2023-05-15 09:58:05',1818,0,'stageComplete',NULL,5),(709,'WO33654','QC','user_Delt','11:28:44','11:43:48','2023-05-15','2023-05-15 10:28:44',904,0,'stageComplete',NULL,4),(710,'WO33655','QC','user_Delt','16:48:39','17:00:03','2023-05-15','2023-05-15 15:48:39',684,3,'workInProgress',NULL,5),(711,'WO33655','QC','user_Delt','08:01:11','08:50:50','2023-05-16','2023-05-16 07:01:11',2979,0,'stageComplete',NULL,5),(712,'WO33656','QC','user_Delt','13:01:08','15:16:36','2023-05-16','2023-05-16 12:01:08',8128,0,'stageComplete',NULL,4),(713,'WO33657','QC','user_Delt','08:02:39','11:03:26','2023-05-17','2023-05-17 07:02:39',10847,0,'stageComplete',NULL,3),(714,'WO33658','QC','user_Delt','11:01:15','12:01:14','2023-05-19','2023-05-19 10:01:15',3599,0,'workInProgress',NULL,5),(715,'WO33658','QC','user_Delt','13:00:17','14:01:00','2023-05-19','2023-05-19 12:00:17',3643,0,'stageComplete',NULL,5),(716,'WO33652','Shipping','user_Delt','10:55:53','12:01:05','2023-05-15','2023-05-15 09:55:53',3912,0,'workInProgress',NULL,5),(717,'WO33652','Shipping','user_Delt','13:02:15','17:00:43','2023-05-15','2023-05-15 12:02:15',14308,43,'workInProgress',NULL,5),(718,'WO33652','Shipping','user_Delt','08:02:48','12:01:09','2023-05-16','2023-05-16 07:02:48',14301,0,'workInProgress',NULL,5),(719,'WO33652','Shipping','user_Delt','13:02:45','17:01:15','2023-05-16','2023-05-16 12:02:45',14310,75,'workInProgress',NULL,5),(720,'WO33652','Shipping','user_Delt','08:01:56','10:04:24','2023-05-17','2023-05-17 07:01:56',7348,0,'stageComplete',NULL,5),(721,'WO33653','Shipping','user_Delt','10:05:46','12:02:07','2023-05-17','2023-05-17 09:05:46',6981,0,'workInProgress',NULL,6),(722,'WO33653','Shipping','user_Delt','13:02:01','13:21:09','2023-05-17','2023-05-17 12:02:01',1148,0,'stageComplete',NULL,6),(723,'WO33654','Shipping','user_Delt','13:21:15','15:52:34','2023-05-17','2023-05-17 12:21:15',9079,0,'stageComplete',NULL,5),(724,'WO33655','Shipping','user_Delt','15:54:12','17:01:27','2023-05-17','2023-05-17 14:54:12',4035,87,'workInProgress',NULL,6),(725,'WO33655','Shipping','user_Delt','08:01:47','09:40:20','2023-05-18','2023-05-18 07:01:47',5913,0,'stageComplete',NULL,6),(726,'WO33656','Shipping','user_Delt','09:41:26','10:41:53','2023-05-18','2023-05-18 08:41:26',3627,0,'stageComplete',NULL,5),(727,'WO33657','Shipping','user_Delt','10:42:57','12:02:10','2023-05-18','2023-05-18 09:42:57',4753,0,'workInProgress',NULL,4),(728,'WO33657','Shipping','user_Delt','13:00:53','14:44:15','2023-05-18','2023-05-18 12:00:53',6202,0,'stageComplete',NULL,4),(729,'WO33658','Shipping','user_Delt','14:02:50','17:00:05','2023-05-19','2023-05-19 13:02:50',10635,5,'workInProgress',NULL,6),(730,'WO33652','Cutting','user_0001','08:00:34','12:02:25','2023-05-08','2023-05-08 07:00:34',14511,0,'workInProgress',NULL,1),(731,'WO33652','Cutting','user_0001','13:00:16','17:01:05','2023-05-08','2023-05-08 12:00:16',14449,65,'workInProgress',NULL,1),(732,'WO33652','Cutting','user_0001','08:00:30','12:02:06','2023-05-09','2023-05-09 07:00:30',14496,0,'workInProgress',NULL,1),(733,'WO33652','Cutting','user_0001','13:01:55','17:02:00','2023-05-09','2023-05-09 12:01:55',14405,120,'workInProgress',NULL,1),(734,'WO33652','Cutting','user_0001','08:02:46','10:00:02','2023-05-10','2023-05-10 07:02:46',7036,0,'stageComplete',NULL,1),(735,'WO33653','Cutting','user_0001','10:00:55','12:00:24','2023-05-10','2023-05-10 09:00:55',7169,0,'workInProgress',NULL,1),(736,'WO33653','Cutting','user_0001','13:02:04','17:00:07','2023-05-10','2023-05-10 12:02:04',14283,7,'workInProgress',NULL,1),(737,'WO33653','Cutting','user_0001','08:01:39','12:01:50','2023-05-11','2023-05-11 07:01:39',14411,0,'workInProgress',NULL,1),(738,'WO33653','Cutting','user_0001','13:02:35','15:04:52','2023-05-11','2023-05-11 12:02:35',7337,0,'stageComplete',NULL,1),(739,'WO33654','Cutting','user_0001','15:07:50','16:39:44','2023-05-11','2023-05-11 14:07:50',5514,0,'stageComplete',NULL,1),(740,'WO33655','Cutting','user_0001','16:40:52','17:00:58','2023-05-11','2023-05-11 15:40:52',1206,58,'workInProgress',NULL,1),(741,'WO33655','Cutting','user_0001','08:02:31','08:42:51','2023-05-12','2023-05-12 07:02:31',2420,0,'stageComplete',NULL,1),(742,'WO33656','Cutting','user_0001','08:44:12','10:44:19','2023-05-12','2023-05-12 07:44:12',7207,0,'stageComplete',NULL,1),(743,'WO33657','Cutting','user_0001','10:44:24','12:00:06','2023-05-12','2023-05-12 09:44:24',4542,0,'workInProgress',NULL,1),(744,'WO33657','Cutting','user_0001','13:02:46','14:49:22','2023-05-12','2023-05-12 12:02:46',6396,0,'stageComplete',NULL,1),(745,'WO33658','Cutting','user_0001','14:49:24','17:01:37','2023-05-12','2023-05-12 13:49:24',7933,97,'workInProgress',NULL,1),(746,'WO33658','Cutting','user_0001','08:02:55','09:51:37','2023-05-15','2023-05-15 07:02:55',6522,0,'stageComplete',NULL,1),(747,'WO33659','Cutting','user_0001','09:53:25','11:53:32','2023-05-15','2023-05-15 08:53:25',7207,0,'stageComplete',NULL,1),(748,'WO33660','Cutting','user_0001','08:02:15','09:33:11','2023-05-16','2023-05-16 07:02:15',5456,0,'stageComplete',NULL,1),(749,'WO33661','Cutting','user_0001','09:35:03','12:02:06','2023-05-16','2023-05-16 08:35:03',8823,0,'workInProgress',NULL,1),(750,'WO33661','Cutting','user_0001','13:02:21','13:36:17','2023-05-16','2023-05-16 12:02:21',2036,0,'stageComplete',NULL,1),(751,'WO33662','Cutting','user_0001','13:37:45','16:08:44','2023-05-16','2023-05-16 12:37:45',9059,0,'stageComplete',NULL,1),(752,'WO33663','Cutting','user_0001','08:02:53','08:48:49','2023-05-17','2023-05-17 07:02:53',2756,0,'stageComplete',NULL,1),(753,'job_wrgr4','Cutting','user_0001','08:01:57','10:03:11','2023-05-18','2023-05-18 07:01:57',7274,0,'stageComplete',NULL,1),(754,'awegd','Cutting','user_0001','08:00:05','12:01:46','2023-05-19','2023-05-19 07:00:05',14501,0,'workInProgress',NULL,1),(755,'awegd','Cutting','user_0001','13:02:22','16:33:25','2023-05-19','2023-05-19 12:02:22',12663,0,'stageComplete',NULL,1),(756,'WO33652','Welding','user_0002','10:00:27','12:00:47','2023-05-10','2023-05-10 09:00:27',7220,0,'workInProgress',NULL,2),(757,'WO33652','Welding','user_0002','13:02:41','17:01:15','2023-05-10','2023-05-10 12:02:41',14314,75,'workInProgress',NULL,2),(758,'WO33652','Welding','user_0002','08:00:30','12:01:25','2023-05-11','2023-05-11 07:00:30',14455,0,'workInProgress',NULL,2),(759,'WO33652','Welding','user_0002','13:02:08','15:04:07','2023-05-11','2023-05-11 12:02:08',7319,0,'stageComplete',NULL,2),(760,'WO33653','Welding','user_0002','08:02:09','09:35:00','2023-05-12','2023-05-12 07:02:09',5571,0,'stageComplete',NULL,2),(761,'WO33654','Welding','user_0002','09:35:48','12:01:17','2023-05-12','2023-05-12 08:35:48',8729,0,'workInProgress',NULL,2),(762,'WO33654','Welding','user_0002','13:01:12','13:08:13','2023-05-12','2023-05-12 12:01:12',421,0,'stageComplete',NULL,2),(763,'WO33655','Welding','user_0002','13:10:20','17:02:09','2023-05-12','2023-05-12 12:10:20',13909,129,'workInProgress',NULL,2),(764,'WO33655','Welding','user_0002','08:01:40','10:12:21','2023-05-15','2023-05-15 07:01:40',7841,0,'stageComplete',NULL,2),(765,'WO33656','Welding','user_0002','10:12:29','12:02:02','2023-05-15','2023-05-15 09:12:29',6573,0,'workInProgress',NULL,2),(766,'WO33656','Welding','user_0002','13:01:02','16:13:12','2023-05-15','2023-05-15 12:01:02',11530,0,'stageComplete',NULL,2),(767,'WO33657','Welding','user_0002','16:14:58','17:02:50','2023-05-15','2023-05-15 15:14:58',2872,170,'workInProgress',NULL,2),(768,'WO33657','Welding','user_0002','08:00:44','12:01:33','2023-05-16','2023-05-16 07:00:44',14449,0,'workInProgress',NULL,2),(769,'WO33657','Welding','user_0002','13:02:20','16:46:38','2023-05-16','2023-05-16 12:02:20',13458,0,'stageComplete',NULL,2),(770,'WO33658','Welding','user_0002','16:49:30','17:01:35','2023-05-16','2023-05-16 15:49:30',725,95,'workInProgress',NULL,2),(771,'WO33658','Welding','user_0002','08:00:22','09:50:09','2023-05-17','2023-05-17 07:00:22',6587,0,'stageComplete',NULL,2),(772,'WO33659','Welding','user_0002','09:52:58','11:25:08','2023-05-17','2023-05-17 08:52:58',5530,0,'stageComplete',NULL,2),(773,'WO33660','Welding','user_0002','11:25:35','12:00:41','2023-05-17','2023-05-17 10:25:35',2106,0,'workInProgress',NULL,2),(774,'WO33660','Welding','user_0002','13:02:13','14:58:47','2023-05-17','2023-05-17 12:02:13',6994,0,'stageComplete',NULL,2),(775,'WO33661','Welding','user_0002','15:00:21','17:02:05','2023-05-17','2023-05-17 14:00:21',7304,125,'workInProgress',NULL,2),(776,'WO33661','Welding','user_0002','08:00:07','12:02:00','2023-05-18','2023-05-18 07:00:07',14513,0,'workInProgress',NULL,2),(777,'WO33661','Welding','user_0002','13:00:11','13:57:52','2023-05-18','2023-05-18 12:00:11',3461,0,'stageComplete',NULL,2),(778,'WO33662','Welding','user_0002','14:00:52','17:02:37','2023-05-18','2023-05-18 13:00:52',10905,157,'workInProgress',NULL,2),(779,'WO33662','Welding','user_0002','08:02:31','12:02:28','2023-05-19','2023-05-19 07:02:31',14397,0,'workInProgress',NULL,2),(780,'WO33662','Welding','user_0002','13:01:40','14:02:43','2023-05-19','2023-05-19 12:01:40',3663,0,'stageComplete',NULL,2),(781,'WO33663','Welding','user_0002','14:03:26','16:04:09','2023-05-19','2023-05-19 13:03:26',7243,0,'stageComplete',NULL,2),(782,'job_wrgr4','Welding','user_0002','16:06:17','17:00:58','2023-05-19','2023-05-19 15:06:17',3281,58,'workInProgress',NULL,2),(783,'WO33653','Painting','user_0003','09:35:03','12:00:51','2023-05-12','2023-05-12 08:35:03',8748,0,'workInProgress',NULL,3),(784,'WO33653','Painting','user_0003','13:02:18','13:08:50','2023-05-12','2023-05-12 12:02:18',392,0,'stageComplete',NULL,3),(785,'WO33655','Painting','user_0003','10:13:20','12:01:43','2023-05-15','2023-05-15 09:13:20',6503,0,'workInProgress',NULL,3),(786,'WO33655','Painting','user_0003','13:02:11','14:45:16','2023-05-15','2023-05-15 12:02:11',6185,0,'stageComplete',NULL,3),(787,'WO33658','Painting','user_0003','09:52:36','12:01:30','2023-05-17','2023-05-17 08:52:36',7734,0,'workInProgress',NULL,3),(788,'WO33658','Painting','user_0003','13:01:57','16:54:11','2023-05-17','2023-05-17 12:01:57',13934,0,'stageComplete',NULL,3),(789,'WO33659','Painting','user_0003','16:56:59','17:02:20','2023-05-17','2023-05-17 15:56:59',321,140,'workInProgress',NULL,3),(790,'WO33659','Painting','user_0003','08:02:35','08:27:15','2023-05-18','2023-05-18 07:02:35',1480,0,'stageComplete',NULL,3),(791,'WO33660','Painting','user_0003','08:28:53','09:46:04','2023-05-18','2023-05-18 07:28:53',4631,0,'stageComplete',NULL,3),(792,'WO33661','Painting','user_0003','13:58:25','15:00:37','2023-05-18','2023-05-18 12:58:25',3732,0,'stageComplete',NULL,3),(793,'WO33662','Painting','user_0003','14:05:06','14:05:58','2023-05-19','2023-05-19 13:05:06',52,0,'stageComplete',NULL,3),(794,'WO33652','Assembly','user_0004','15:05:56','17:00:14','2023-05-11','2023-05-11 14:05:56',6858,14,'workInProgress',NULL,3),(795,'WO33652','Assembly','user_0004','08:02:03','12:01:33','2023-05-12','2023-05-12 07:02:03',14370,0,'workInProgress',NULL,3),(796,'WO33652','Assembly','user_0004','13:02:25','15:40:58','2023-05-12','2023-05-12 12:02:25',9513,0,'stageComplete',NULL,3),(797,'WO33653','Assembly','user_0004','15:41:49','16:43:58','2023-05-12','2023-05-12 14:41:49',3729,0,'stageComplete',NULL,4),(798,'WO33654','Assembly','user_0004','16:45:43','17:02:04','2023-05-12','2023-05-12 15:45:43',981,124,'workInProgress',NULL,3),(799,'WO33654','Assembly','user_0004','08:01:31','09:01:56','2023-05-15','2023-05-15 07:01:31',3625,0,'stageComplete',NULL,3),(800,'WO33655','Assembly','user_0004','14:46:44','16:46:44','2023-05-15','2023-05-15 13:46:44',7200,0,'stageComplete',NULL,4),(801,'WO33656','Assembly','user_0004','08:02:17','11:34:35','2023-05-16','2023-05-16 07:02:17',12738,0,'stageComplete',NULL,3),(802,'WO33658','Assembly','user_0004','16:56:50','17:02:36','2023-05-17','2023-05-17 15:56:50',346,156,'workInProgress',NULL,4),(803,'WO33658','Assembly','user_0004','08:01:24','12:01:57','2023-05-18','2023-05-18 07:01:24',14433,0,'workInProgress',NULL,4),(804,'WO33658','Assembly','user_0004','13:02:33','17:00:07','2023-05-18','2023-05-18 12:02:33',14254,7,'workInProgress',NULL,4),(805,'WO33658','Assembly','user_0004','08:00:58','10:59:47','2023-05-19','2023-05-19 07:00:58',10729,0,'stageComplete',NULL,4),(806,'WO33659','Assembly','user_0004','11:00:32','12:02:20','2023-05-19','2023-05-19 10:00:32',3708,0,'workInProgress',NULL,4),(807,'WO33659','Assembly','user_0004','13:02:29','17:00:46','2023-05-19','2023-05-19 12:02:29',14297,46,'workInProgress',NULL,4),(808,'WO33652','QC','user_0005','15:41:21','17:02:21','2023-05-12','2023-05-12 14:41:21',4860,141,'workInProgress',NULL,4),(809,'WO33652','QC','user_0005','08:01:05','10:55:13','2023-05-15','2023-05-15 07:01:05',10448,0,'stageComplete',NULL,4),(810,'WO33653','QC','user_0005','10:58:05','11:28:23','2023-05-15','2023-05-15 09:58:05',1818,0,'stageComplete',NULL,5),(811,'WO33654','QC','user_0005','11:28:44','11:43:48','2023-05-15','2023-05-15 10:28:44',904,0,'stageComplete',NULL,4),(812,'WO33655','QC','user_0005','16:48:39','17:00:03','2023-05-15','2023-05-15 15:48:39',684,3,'workInProgress',NULL,5),(813,'WO33655','QC','user_0005','08:01:11','08:50:50','2023-05-16','2023-05-16 07:01:11',2979,0,'stageComplete',NULL,5),(814,'WO33656','QC','user_0005','13:01:08','15:16:36','2023-05-16','2023-05-16 12:01:08',8128,0,'stageComplete',NULL,4),(815,'WO33657','QC','user_0005','08:02:39','11:03:26','2023-05-17','2023-05-17 07:02:39',10847,0,'stageComplete',NULL,3),(816,'WO33658','QC','user_0005','11:01:15','12:01:14','2023-05-19','2023-05-19 10:01:15',3599,0,'workInProgress',NULL,5),(817,'WO33658','QC','user_0005','13:00:17','14:01:00','2023-05-19','2023-05-19 12:00:17',3643,0,'stageComplete',NULL,5),(818,'WO33652','Shipping','user_0006','10:55:53','12:01:05','2023-05-15','2023-05-15 09:55:53',3912,0,'workInProgress',NULL,5),(819,'WO33652','Shipping','user_0006','13:02:15','17:00:43','2023-05-15','2023-05-15 12:02:15',14308,43,'workInProgress',NULL,5),(820,'WO33652','Shipping','user_0006','08:02:48','12:01:09','2023-05-16','2023-05-16 07:02:48',14301,0,'workInProgress',NULL,5),(821,'WO33652','Shipping','user_0006','13:02:45','17:01:15','2023-05-16','2023-05-16 12:02:45',14310,75,'workInProgress',NULL,5),(822,'WO33652','Shipping','user_0006','08:01:56','10:04:24','2023-05-17','2023-05-17 07:01:56',7348,0,'stageComplete',NULL,5),(823,'WO33653','Shipping','user_0006','10:05:46','12:02:07','2023-05-17','2023-05-17 09:05:46',6981,0,'workInProgress',NULL,6),(824,'WO33653','Shipping','user_0006','13:02:01','13:21:09','2023-05-17','2023-05-17 12:02:01',1148,0,'stageComplete',NULL,6),(825,'WO33654','Shipping','user_0006','13:21:15','15:52:34','2023-05-17','2023-05-17 12:21:15',9079,0,'stageComplete',NULL,5),(826,'WO33655','Shipping','user_0006','15:54:12','17:01:27','2023-05-17','2023-05-17 14:54:12',4035,87,'workInProgress',NULL,6),(827,'WO33655','Shipping','user_0006','08:01:47','09:40:20','2023-05-18','2023-05-18 07:01:47',5913,0,'stageComplete',NULL,6),(828,'WO33656','Shipping','user_0006','09:41:26','10:41:53','2023-05-18','2023-05-18 08:41:26',3627,0,'stageComplete',NULL,5),(829,'WO33657','Shipping','user_0006','10:42:57','12:02:10','2023-05-18','2023-05-18 09:42:57',4753,0,'workInProgress',NULL,4),(830,'WO33657','Shipping','user_0006','13:00:53','14:44:15','2023-05-18','2023-05-18 12:00:53',6202,0,'stageComplete',NULL,4),(831,'WO33658','Shipping','user_0006','14:02:50','17:00:05','2023-05-19','2023-05-19 13:02:50',10635,5,'workInProgress',NULL,6);
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
INSERT INTO `users` VALUES ('user_Delt','User Deleted',NULL,NULL,'2021-04-15 16:59:34',-2),('office','Office',NULL,NULL,'2021-04-15 16:59:34',-1),('noName','N/A',NULL,NULL,'2021-04-15 16:59:34',0),('user_0001','Alice',NULL,NULL,'2023-05-22 11:10:51',1),('user_0002','Bob',NULL,NULL,'2023-05-22 11:10:52',2),('user_0003','Charlotte',NULL,NULL,'2023-05-22 11:10:53',3),('user_0004','David',NULL,NULL,'2023-05-22 11:10:54',4),('user_0005','Emily',NULL,NULL,'2023-05-22 11:10:55',5),('user_0006','Felix',NULL,NULL,'2023-05-22 11:10:57',6);
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

-- Dump completed on 2023-05-26  8:52:49
