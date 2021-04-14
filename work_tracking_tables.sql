-- phpMyAdmin SQL
-- version 4.8.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Dec 04, 2018 at 12:20 PM
-- Server version: 10.1.34-MariaDB
-- PHP Version: 7.2.7

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `work_tracking`
--


--
-- Table structure for table `clientNames`
--

CREATE TABLE `clientNames` (
  `currentName` varchar(50) DEFAULT NULL,
  `newName` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `config`
--

CREATE TABLE `config` (
  `paramName` varchar(100) NOT NULL,
  `paramValue` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `config`
--

INSERT INTO `config` (`paramName`, `paramValue`) VALUES
('allowMultipleClockOn', 'false');

INSERT INTO config(`paramName`, `paramValue`) VALUES
("configVersion", "1");

INSERT INTO `config` (`paramName`, `paramValue`) VALUES
('addLunchBreak', 'false');

INSERT INTO `config` (`paramName`, `paramValue`) VALUES
('trimLunch', 'false');

INSERT INTO `config` (`paramName`, `paramValue`) VALUES
('requireStageComplete', 'false');

-- --------------------------------------------------------

--
-- Table structure for table `connectedClients`
--

CREATE TABLE `connectedClients` (
  `stationId` varchar(50) NOT NULL,
  `lastSeen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `version` varchar(50)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `jobs`
--

CREATE TABLE `jobs` (
  `jobId` varchar(20) NOT NULL,
  `expectedDuration` int(11) DEFAULT NULL,
  `closedWorkedDuration` int(11) NOT NULL DEFAULT '0',
  `closedOvertimeDuration` int(11) NOT NULL DEFAULT '0',
  `description` varchar(200) DEFAULT NULL,
  `currentStatus` varchar(50) DEFAULT NULL,
  `absolutePathToQrCode` varchar(200) DEFAULT NULL,
  `relativePathToQrCode` varchar(200) DEFAULT NULL,
  `recordAdded` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `notes` text,
  `routeName` varchar(100) CHARACTER SET utf8 DEFAULT NULL,
  `routeCurrentStageName` varchar(50) DEFAULT NULL,
  `routeCurrentStageIndex` int(11) NOT NULL DEFAULT '-1',
  `dueDate` date DEFAULT '9999-12-31',
  `stoppages` text,
  `numberOfUnits` int(11) DEFAULT NULL,
  `totalChargeToCustomer` int(11) DEFAULT NULL,
  `jobIdIndex` int(15) AUTO_INCREMENT,
  `productId` varchar(20) DEFAULT '',
  `priority` int(1) DEFAULT 0,
  key(`jobIdIndex`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `routes`
--

CREATE TABLE `routes` (
  `routeName` varchar(50) NOT NULL,
  `routeDescription` varchar(1000) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `timeLog`
--

CREATE TABLE `timeLog` (
  `ref` bigint(20) NOT NULL,
  `jobId` varchar(20) DEFAULT NULL,
  `stationId` varchar(50) DEFAULT NULL,
  `userId` varchar(20) DEFAULT NULL,
  `clockOnTime` time DEFAULT NULL,
  `clockOffTime` time DEFAULT NULL,
  `recordDate` date DEFAULT NULL,
  `recordTimestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `workedDuration` int(11) DEFAULT NULL,
  `overtimeDuration` int(11) DEFAULT NULL,
  `workStatus` varchar(20) NOT NULL,
  `quantityComplete` int(11) DEFAULT Null,
  `routeStageIndex` int(11) DEFAULT -1
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `userId` varchar(20) DEFAULT NULL,
  `userName` varchar(50) DEFAULT NULL,
  `relativePathToQrCode` varchar(200) DEFAULT NULL,
  `absolutePathToQrCode` varchar(200) DEFAULT NULL,
  `recordAdded` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `userIdIndex` int(11) DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `workHours`
--

CREATE TABLE `workHours` (
  `ref` int(11) NOT NULL,
  `dayDate` date DEFAULT NULL,
  `startTime` time DEFAULT NULL,
  `endTime` time DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Table structure for table `lunchTimes`
--

CREATE TABLE `lunchTimes` (
  `ref` int(11) NOT NULL,
  `dayDate` date DEFAULT NULL,
  `startTime` time DEFAULT NULL,
  `endTime` time DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Table structure for table `products`
--

CREATE TABLE `products` (
  `productId` varchar(20) NOT NULL,
  `description` varchar(200) DEFAULT NULL,
  `absolutePathToQrCode` varchar(200) DEFAULT NULL,
  `relativePathToQrCode` varchar(200) DEFAULT NULL,
  `currentJobId` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Table structure for table `stoppageReasons`
--

CREATE TABLE `stoppageReasons` (
  `stoppageReasonId` varchar(20) NOT NULL,
  `stoppageReasonName` varchar(200) DEFAULT NULL,
  `absolutePathToQrCode` varchar(200) DEFAULT NULL,
  `relativePathToQrCode` varchar(200) DEFAULT NULL,
  `stoppageReasonIdIndex` int(11) AUTO_INCREMENT,
  key(`stoppageReasonIdIndex`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Table structure for table `stoppagesLog`
--

CREATE TABLE `stoppagesLog` (
  `ref` bigint(20) NOT NULL AUTO_INCREMENT,
  `jobId` varchar(20) DEFAULT NULL,
  `stationId` varchar(50) DEFAULT NULL,
  `stoppageReasonId` varchar(20) DEFAULT NULL,
  `description` text,
  `startTime` time DEFAULT NULL,
  `endTime` time DEFAULT NULL,
  `startDate` date DEFAULT NULL,
  `endDate` date DEFAULT NULL,
  `recordTimestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `duration` int(11) DEFAULT NULL,
  `status` varchar(20) NOT NULL,
  PRIMARY KEY (`ref`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `config`
--
ALTER TABLE `config`
  ADD PRIMARY KEY (`paramName`);

--
-- Indexes for table `connectedClients`
--
ALTER TABLE `connectedClients`
  ADD PRIMARY KEY (`stationId`);

--
-- Indexes for table `jobs`
--
ALTER TABLE `jobs`
  ADD PRIMARY KEY (`jobId`),
  ADD KEY `IDX_jobId_desc` (`jobId`,`description`);

--
-- Indexes for table `routes`
--
ALTER TABLE `routes`
  ADD PRIMARY KEY (`routeName`);

--
-- Indexes for table `timeLog`
--
ALTER TABLE `timeLog`
  ADD PRIMARY KEY (`ref`),
  ADD KEY `IDX_ClockOffTime_JobID` (`clockOffTime`,`jobId`) USING BTREE,
  ADD KEY `IDX_ClockOffTime_UserId` (`clockOffTime`,`userId`),
  ADD KEY `IDX_ClockOffTime_UserId_date` (`clockOffTime`,`userId`,`recordDate`);

--
-- Indexes for table `workHours`
--
ALTER TABLE `workHours`
  ADD PRIMARY KEY (`ref`);

--
-- Indexes for table `lunchTimes`
--
ALTER TABLE `lunchTimes`
  ADD PRIMARY KEY (`ref`);
  
--
-- Indexes for table `products`
--
ALTER TABLE `products`
  ADD PRIMARY KEY (`productId`);
  
--
-- Indexes for table `stoppageReasons`
--
ALTER TABLE `stoppageReasons`
  ADD PRIMARY KEY (`stoppageReasonId`);  

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `timeLog`
--
ALTER TABLE `timeLog`
  MODIFY `ref` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `workHours`
--
ALTER TABLE `workHours`
  MODIFY `ref` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `lunchTimes`
--
ALTER TABLE `lunchTimes`
  MODIFY `ref` int(11) NOT NULL AUTO_INCREMENT;


DELIMITER ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

