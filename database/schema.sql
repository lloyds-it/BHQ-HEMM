-- Database Schema for Equipment Log Mobile Application
CREATE DATABASE IF NOT EXISTS `equipment_log_db` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `equipment_log_db`;

-- Drop tables if they exist to allow clean re-runs
DROP TABLE IF EXISTS `SummaryLogs`;
DROP TABLE IF EXISTS `LiveEntries`;
DROP TABLE IF EXISTS `Operators`;
DROP TABLE IF EXISTS `Equipment`;
DROP TABLE IF EXISTS `Projects`;
DROP TABLE IF EXISTS `Users`;

-- 1. Users Table
CREATE TABLE `Users` (
    `UserId` INT AUTO_INCREMENT PRIMARY KEY,
    `Username` VARCHAR(100) NOT NULL UNIQUE,
    `PasswordHash` VARCHAR(255) NOT NULL,
    `Role` VARCHAR(50) NOT NULL, -- Admin, Supervisor, Operator
    `IsActive` TINYINT(1) NOT NULL DEFAULT 1,
    `CreatedDate` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 2. Projects Table
CREATE TABLE `Projects` (
    `ProjectId` INT AUTO_INCREMENT PRIMARY KEY,
    `ProjectName` VARCHAR(150) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- 3. Equipment Table
CREATE TABLE `Equipment` (
    `EquipmentId` INT AUTO_INCREMENT PRIMARY KEY,
    `EquipmentNumber` VARCHAR(100) NOT NULL UNIQUE,
    `ProjectId` INT NOT NULL,
    `IsActive` TINYINT(1) NOT NULL DEFAULT 1,
    FOREIGN KEY (`ProjectId`) REFERENCES `Projects` (`ProjectId`) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 4. Operators Table
CREATE TABLE `Operators` (
    `OperatorId` INT AUTO_INCREMENT PRIMARY KEY,
    `OperatorName` VARCHAR(150) NOT NULL,
    `Mobile` VARCHAR(20) NULL,
    `IsActive` TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

-- 5. LiveEntries Table
CREATE TABLE `LiveEntries` (
    `EntryId` INT AUTO_INCREMENT PRIMARY KEY,
    `ProjectId` INT NOT NULL,
    `EquipmentId` INT NOT NULL,
    `OperatorId` INT NULL, -- Nullable because Operator May be edited or skipped
    `EntryTimestamp` DATETIME NOT NULL,
    `HMRValue` DECIMAL(18,2) NOT NULL,
    `ActivityType` VARCHAR(50) NOT NULL, -- Running, Idle, Breakdown, Stoppage
    `CreatedBy` VARCHAR(100) NOT NULL,
    `CreatedDate` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`ProjectId`) REFERENCES `Projects` (`ProjectId`),
    FOREIGN KEY (`EquipmentId`) REFERENCES `Equipment` (`EquipmentId`),
    FOREIGN KEY (`OperatorId`) REFERENCES `Operators` (`OperatorId`) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 6. SummaryLogs Table
CREATE TABLE `SummaryLogs` (
    `SummaryId` INT AUTO_INCREMENT PRIMARY KEY,
    `ProjectId` INT NOT NULL,
    `Date` DATE NOT NULL,
    `Shift` VARCHAR(50) NOT NULL,
    `EquipmentId` INT NOT NULL,
    `OperatorId` INT NOT NULL,
    `StartTimestamp` DATETIME NOT NULL,
    `EndTimestamp` DATETIME NOT NULL,
    `StartHMR` DECIMAL(18,2) NOT NULL,
    `EndHMR` DECIMAL(18,2) NOT NULL,
    `TotalHMR` DECIMAL(18,2) NOT NULL, -- End HMR - Start HMR
    `ClockHours` DECIMAL(18,2) NOT NULL, -- End Time - Start Time in hours
    `ActivityType` VARCHAR(50) NOT NULL,
    `WorkDone` VARCHAR(255) NULL,
    `Location` VARCHAR(255) NULL,
    `Diesel` DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `HydraulicOil` DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `EngineOil` DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `TransmissionOil` DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `GearOil` DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    `Remarks` TEXT NULL,
    `CreatedBy` VARCHAR(100) NOT NULL,
    `CreatedDate` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`ProjectId`) REFERENCES `Projects` (`ProjectId`),
    FOREIGN KEY (`EquipmentId`) REFERENCES `Equipment` (`EquipmentId`),
    FOREIGN KEY (`OperatorId`) REFERENCES `Operators` (`OperatorId`)
) ENGINE=InnoDB;
