--USE ClinicalForgeSourceDB;
--GO

-- Disable Check Constraints and Triggers temporarily to enable clean sequential identity inserts

-- =========================================================================
-- 1. SEED DATA: CORE.FACILITIES (10 Records)
-- =========================================================================
SET IDENTITY_INSERT Core.Facilities ON;
INSERT INTO Core.Facilities (FacilityID, OrganizationTaxID, FacilityName, FacilityType, NPI, City, StateCode, IsActive, LastModifiedDateTime) VALUES 
(1, '12-3456789', 'ClinicalForge General Hospital', 'General Hospital', '1982736450', 'Boston', 'MA', 1, '2026-01-15 08:00:00'),
(2, '12-3456789', 'ForgeCare Urgent Clinic West', 'Urgent Care', '1029384756', 'Newton', 'MA', 1, '2026-08-10 14:30:00'),
(3, '98-7654321', 'ClinicalForge Pediatrics Center', 'Clinic', '1564738291', 'Cambridge', 'MA', 1, '2026-05-01 07:00:00'),
(4, '55-4433221', 'ForgeCare Cardiology Annex', 'Clinic', '1122334455', 'Boston', 'MA', 1, '2026-02-10 08:00:00'),
(5, '12-3456789', 'ClinicalForge North Health Hub', 'Urgent Care', '1223344556', 'Lowell', 'MA', 1, '2026-06-15 08:00:00'),
(6, '12-3456789', 'ForgeCare Outpatient Surgical', 'Surgical Center', '1334455667', 'Waltham', 'MA', 1, '2026-04-12 06:30:00'),
(7, '88-7766554', 'Bay State Orthopedics Forge', 'Clinic', '1445566778', 'Quincy', 'MA', 1, '2026-01-20 09:00:00'),
(8, '12-3456789', 'ClinicalForge Labs Metro', 'Diagnostic Lab', '1556677889', 'Cambridge', 'MA', 1, '2026-07-01 07:00:00'),
(9, '22-3344556', 'ForgeCare Family Practice South', 'Clinic', '1667788990', 'Brockton', 'MA', 1, '2026-03-01 08:00:00'),
(10, '12-3456789', 'ClinicalForge Emergency Trauma', 'ER', '1778899001', 'Boston', 'MA', 1, '2026-01-15 00:00:00');
SET IDENTITY_INSERT Core.Facilities OFF;
GO

-- =========================================================================
-- 2. SEED DATA: CORE.BEDS (10 Records)
-- =========================================================================
SET IDENTITY_INSERT Core.Beds ON;
INSERT INTO Core.Beds (BedID, FacilityID, WardName, RoomNumber, BedNumber, BedStatus, LastModifiedDateTime) VALUES 
(1, 1, 'Intensive Care Unit (ICU)', 'ICU-301', 'Bed-A', 'Occupied', '2026-09-12 12:00:00'),
(2, 1, 'Intensive Care Unit (ICU)', 'ICU-301', 'Bed-B', 'Available', '2026-09-12 12:00:00'),
(3, 1, 'Emergency Department', 'ER-105', 'Bed-1', 'Occupied', '2026-09-12 12:00:00'),
(4, 1, 'Emergency Department', 'ER-106', 'Bed-1', 'Cleaning', '2026-09-12 12:00:00'),
(5, 1, 'Medical-Surgical Ward', 'MedSurg-412', 'Bed-A', 'Available', '2026-09-12 12:00:00'),
(6, 1, 'Medical-Surgical Ward', 'MedSurg-412', 'Bed-B', 'Occupied', '2026-09-12 12:00:00'),
(7, 10, 'Trauma Center Bay', 'Trauma-1', 'Bed-X', 'Occupied', '2026-09-12 12:00:00'),
(8, 10, 'Trauma Center Bay', 'Trauma-1', 'Bed-Y', 'Available', '2026-09-12 12:00:00'),
(9, 1, 'ICU Post-Op', 'ICU-305', 'Bed-1', 'Available', '2026-09-12 12:00:00'),
(10, 1, 'Pediatric Inpatient', 'Peds-202', 'Bed-A', 'Occupied', '2026-09-12 12:00:00');
SET IDENTITY_INSERT Core.Beds OFF;
GO

-- =========================================================================
-- 3. SEED DATA: CORE.PRACTITIONERS (10 Records)
-- =========================================================================
SET IDENTITY_INSERT Core.Practitioners ON;
INSERT INTO Core.Practitioners (PractitionerID, NPI, FirstName, LastName, SpecialtyDescription, PrimaryFacilityID, IsActive, LastModifiedDateTime) VALUES 
(1, '1487693021', 'Sarah', 'Abernathy', 'Internal Medicine', 1, 1, '2026-01-16 09:00:00'),
(2, '1851403928', 'James', 'Callahan', 'Emergency Medicine', 10, 1, '2026-09-01 14:00:00'),
(3, '1295847361', 'Elena', 'Rostova', 'Pediatrics', 3, 1, '2026-05-02 08:00:00'),
(4, '1033495827', 'Marcus', 'Vance', 'Cardiovascular Disease', 4, 1, '2026-02-11 11:00:00'),
(5, '1334422115', 'Robert', 'Murdock', 'Orthopedic Surgery', 7, 1, '2026-01-22 09:00:00'),
(6, '1554433221', 'Linda', 'Zhang', 'Family Medicine', 9, 1, '2026-03-02 08:00:00'),
(7, '1667744332', 'David', 'Kim', 'Surgery', 6, 1, '2026-04-15 08:00:00'),
(8, '1778855443', 'Susan', 'Patel', 'Internal Medicine', 2, 1, '2026-03-25 09:00:00'),
(9, '1889966554', 'Thomas', 'Wayne', 'Emergency Medicine', 10, 1, '2026-01-16 00:00:00'),
(10, '1990077665', 'Alice', 'Smith', 'Pediatrics', 3, 1, '2026-05-02 08:00:00');
SET IDENTITY_INSERT Core.Practitioners OFF;
GO
