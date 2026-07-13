-- Seeding Data for Equipment Log Mobile Application
USE `equipment_log_db`;

-- 1. Default Projects
INSERT INTO `Projects` (`ProjectName`) VALUES 
('BHQ Hedri'),
('BHQ East Pit'),
('BHQ West Pit');

-- 2. Default Operators
INSERT INTO `Operators` (`OperatorName`, `Mobile`, `IsActive`) VALUES
('Rajesh Kumar', '9876543210', 1),
('Amit Sharma', '8765432109', 1),
('Vijay Yadav', '7654321098', 1),
('Sunil Singh', '6543210987', 1);

-- 3. Default Equipment / Trucks
-- We want searchable dropdown by last 4 digits, so let's make numbers like:
-- EQ-TR-2034, EQ-TR-4567, EQ-TR-8812, etc.
INSERT INTO `Equipment` (`EquipmentNumber`, `ProjectId`, `IsActive`) VALUES
('EQ-TR-2034', 1, 1),
('EQ-TR-4567', 1, 1),
('EQ-TR-8812', 1, 1),
('EQ-TR-9051', 2, 1),
('EQ-TR-1122', 2, 1),
('EQ-TR-3344', 3, 1);

-- 4. Default Users (Passwords hashed using BCrypt. Net-Next for 'Password@123')
-- BCrypt Hash: $2a$11$e09ZtA8/OUNj.9LhS.Xk/O7N0l/RuxoU/7G2y5x0l217Wb25Gg86K
INSERT INTO `Users` (`Username`, `PasswordHash`, `Role`, `IsActive`) VALUES
('admin', '$2a$11$e09ZtA8/OUNj.9LhS.Xk/O7N0l/RuxoU/7G2y5x0l217Wb25Gg86K', 'Admin', 1),
('supervisor', '$2a$11$e09ZtA8/OUNj.9LhS.Xk/O7N0l/RuxoU/7G2y5x0l217Wb25Gg86K', 'Supervisor', 1),
('operator', '$2a$11$e09ZtA8/OUNj.9LhS.Xk/O7N0l/RuxoU/7G2y5x0l217Wb25Gg86K', 'Operator', 1);

-- 5. Seed initial Live Entry to test operator auto-fill
-- EquipmentId=1 (EQ-TR-2034), OperatorId=1 (Rajesh Kumar), ProjectId=1 (BHQ Hedri)
INSERT INTO `LiveEntries` (`ProjectId`, `EquipmentId`, `OperatorId`, `EntryTimestamp`, `HMRValue`, `ActivityType`, `CreatedBy`) VALUES
(1, 1, 1, DATE_SUB(NOW(), INTERVAL 1 HOUR), 1250.50, 'Running', 'supervisor');

-- 6. Seed initial Summary Logs
INSERT INTO `SummaryLogs` (`ProjectId`, `Date`, `Shift`, `EquipmentId`, `OperatorId`, `StartTimestamp`, `EndTimestamp`, `StartHMR`, `EndHMR`, `TotalHMR`, `ClockHours`, `ActivityType`, `WorkDone`, `Location`, `Diesel`, `HydraulicOil`, `EngineOil`, `TransmissionOil`, `GearOil`, `Remarks`, `CreatedBy`) VALUES
(1, CURRENT_DATE(), 'Day', 1, 1, DATE_SUB(NOW(), INTERVAL 8 HOUR), DATE_SUB(NOW(), INTERVAL 4 HOUR), 1242.50, 1246.50, 4.00, 4.00, 'Running', 'Excavation Work', 'North Face', 150.00, 10.00, 5.00, 0.00, 0.00, 'Shift completed smoothly', 'supervisor');
