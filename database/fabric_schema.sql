-- DDL Schema Script for Microsoft Fabric Data Warehouse
-- Run this script in SQL Server Management Studio (SSMS) against your database

-- 0. Schema already exists (commented out to avoid error)
-- CREATE SCHEMA [BHQ_HEMM];
-- GO

-- Drop tables if they exist for a clean run
DROP TABLE IF EXISTS [BHQ_HEMM].[SummaryLogs];
GO
DROP TABLE IF EXISTS [BHQ_HEMM].[LiveEntries];
GO
DROP TABLE IF EXISTS [BHQ_HEMM].[Users];
GO
DROP TABLE IF EXISTS [BHQ_HEMM].[Equipment];
GO
DROP TABLE IF EXISTS [BHQ_HEMM].[Operators];
GO
DROP TABLE IF EXISTS [BHQ_HEMM].[Projects];
GO

-- 1. Create Tables
-- Note: Primary Keys are omitted from DDL to comply with Fabric DW limitations. 
-- Entity Framework handles PK logic internally.
CREATE TABLE [BHQ_HEMM].[Users] (
    UserId INT NOT NULL,
    Username VARCHAR(100) NOT NULL,
    PasswordHash VARCHAR(255) NOT NULL,
    Role VARCHAR(50) NOT NULL,
    IsActive BIT NOT NULL
);
GO

CREATE TABLE [BHQ_HEMM].[Projects] (
    ProjectId INT NOT NULL,
    ProjectName VARCHAR(100) NOT NULL
);
GO

CREATE TABLE [BHQ_HEMM].[Operators] (
    OperatorId INT NOT NULL,
    OperatorName VARCHAR(100) NOT NULL,
    Mobile VARCHAR(20) NOT NULL,
    IsActive BIT NOT NULL
);
GO

CREATE TABLE [BHQ_HEMM].[Equipment] (
    EquipmentId INT NOT NULL,
    EquipmentNumber VARCHAR(100) NOT NULL,
    ProjectId INT NOT NULL,
    IsActive BIT NOT NULL
);
GO

-- Fabric DW requires precision for DATETIME2, e.g., DATETIME2(6)
CREATE TABLE [BHQ_HEMM].[LiveEntries] (
    EntryId INT NOT NULL,
    ProjectId INT NOT NULL,
    EquipmentId INT NOT NULL,
    OperatorId INT NOT NULL,
    EntryTimestamp DATETIME2(6) NOT NULL,
    HMRValue FLOAT NOT NULL,
    ActivityType VARCHAR(50) NOT NULL,
    CreatedBy VARCHAR(100) NOT NULL,
    CreatedDate DATETIME2(6) NOT NULL
);
GO

CREATE TABLE [BHQ_HEMM].[SummaryLogs] (
    SummaryId INT NOT NULL,
    ProjectId INT NOT NULL,
    Date DATETIME2(6) NOT NULL,
    Shift VARCHAR(50) NOT NULL,
    EquipmentId INT NOT NULL,
    OperatorId INT NOT NULL,
    StartTimestamp DATETIME2(6) NOT NULL,
    EndTimestamp DATETIME2(6) NOT NULL,
    StartHmr FLOAT NOT NULL,
    EndHmr FLOAT NOT NULL,
    TotalHmr FLOAT NULL,
    ClockHours FLOAT NULL,
    ActivityType VARCHAR(50) NOT NULL,
    WorkDone VARCHAR(MAX) NULL,
    Location VARCHAR(255) NULL,
    Diesel FLOAT NOT NULL,
    HydraulicOil FLOAT NOT NULL,
    EngineOil FLOAT NOT NULL,
    TransmissionOil FLOAT NOT NULL,
    GearOil FLOAT NOT NULL,
    Remarks VARCHAR(MAX) NULL,
    CreatedBy VARCHAR(100) NOT NULL
);
GO

-- 2. Seed Default Records
INSERT INTO [BHQ_HEMM].[Projects] (ProjectId, ProjectName) VALUES 
(1, 'BHQ Hedri'),
(2, 'BHQ East Pit'),
(3, 'BHQ West Pit');
GO

INSERT INTO [BHQ_HEMM].[Operators] (OperatorId, OperatorName, Mobile, IsActive) VALUES
(1, 'Rajesh Kumar', '9876543210', 1),
(2, 'Amit Sharma', '8765432109', 1),
(3, 'Vijay Yadav', '7654321098', 1),
(4, 'Sunil Singh', '6543210987', 1);
GO

INSERT INTO [BHQ_HEMM].[Equipment] (EquipmentId, EquipmentNumber, ProjectId, IsActive) VALUES
(1, 'EQ-TR-2034', 1, 1),
(2, 'EQ-TR-4567', 1, 1),
(3, 'EQ-TR-8812', 1, 1),
(4, 'EQ-TR-9051', 2, 1),
(5, 'EQ-TR-1122', 2, 1),
(6, 'EQ-TR-3344', 3, 1);
GO

-- Default passwords: 'Password@123' (BCrypt hashed)
INSERT INTO [BHQ_HEMM].[Users] (UserId, Username, PasswordHash, Role, IsActive) VALUES
(1, 'admin', '$2a$11$e09ZtA8/OUNj.9LhS.Xk/O7N0l/RuxoU/7G2y5x0l217Wb25Gg86K', 'Admin', 1),
(2, 'supervisor', '$2a$11$e09ZtA8/OUNj.9LhS.Xk/O7N0l/RuxoU/7G2y5x0l217Wb25Gg86K', 'Supervisor', 1),
(3, 'operator', '$2a$11$e09ZtA8/OUNj.9LhS.Xk/O7N0l/RuxoU/7G2y5x0l217Wb25Gg86K', 'Operator', 1);
GO

INSERT INTO [BHQ_HEMM].[LiveEntries] (EntryId, ProjectId, EquipmentId, OperatorId, EntryTimestamp, HMRValue, ActivityType, CreatedBy, CreatedDate) VALUES
(1, 1, 1, 1, DATEADD(hour, -1, GETDATE()), 1250.50, 'Running', 'supervisor', GETDATE());
GO

INSERT INTO [BHQ_HEMM].[SummaryLogs] (SummaryId, ProjectId, Date, Shift, EquipmentId, OperatorId, StartTimestamp, EndTimestamp, StartHmr, EndHmr, TotalHmr, ClockHours, ActivityType, WorkDone, Location, Diesel, HydraulicOil, EngineOil, TransmissionOil, GearOil, Remarks, CreatedBy) VALUES
(1, 1, GETDATE(), 'Day', 1, 1, DATEADD(hour, -8, GETDATE()), DATEADD(hour, -4, GETDATE()), 1242.50, 1246.50, 4.00, 4.00, 'Running', 'Excavation Work', 'North Face', 150.00, 10.00, 5.00, 0.00, 0.00, 'Shift completed smoothly', 'supervisor');
GO
