-- =========================================================================
-- PROJECT CLINICALFORGE: DYNAMIC MAX-ID HIGH WATERMARK AUTO-INCREMENT SEED
-- =========================================================================

-- Declare operational tracking variables to hold current Max IDs
DECLARE @MaxFacilityID INT, @MaxBedID INT, @MaxPractitionerID INT, 
        @MaxPatientID INT, @MaxAppointmentID INT, @MaxEncounterID INT;

-- 1. Query current high watermarks directly from metadata footprints
SELECT @MaxFacilityID     = ISNULL(MAX(FacilityID), 1)     FROM Core.Facilities;
SELECT @MaxBedID          = ISNULL(MAX(BedID), 1)          FROM Core.Beds;
SELECT @MaxPractitionerID = ISNULL(MAX(PractitionerID), 1) FROM Core.Practitioners;
SELECT @MaxPatientID      = ISNULL(MAX(PatientID), 1)      FROM Clinical.Patients;
SELECT @MaxAppointmentID  = ISNULL(MAX(AppointmentID), 1)  FROM Clinical.Appointments;
SELECT @MaxEncounterID    = ISNULL(MAX(EncounterID), 1)    FROM Clinical.Encounters;

-- 2. Execute incremental inserts using the variable maps to ensure 100% integrity

-- [Table 1] Core.Facilities
INSERT INTO Core.Facilities (OrganizationTaxID, FacilityName, FacilityType, NPI, City, StateCode, IsActive, LastModifiedDateTime)
VALUES ('12-3456789', CONCAT('ClinicalForge Auto-Clinic #', @MaxFacilityID + 1), 'Clinic', '1999999999', 'Boston', 'MA', 1, SYSUTCDATETIME());

-- [Table 2] Core.Beds
INSERT INTO Core.Beds (FacilityID, WardName, RoomNumber, BedNumber, BedStatus, LastModifiedDateTime)
VALUES (@MaxFacilityID, 'Emergency ICU Surge', 'ICU-99', CONCAT('Bed-', @MaxBedID + 1), 'Available', SYSUTCDATETIME());

-- [Table 3] Core.Practitioners
INSERT INTO Core.Practitioners (NPI, FirstName, LastName, SpecialtyDescription, PrimaryFacilityID, IsActive, LastModifiedDateTime)
VALUES (CAST((1000000000 + @MaxPractitionerID) AS VARCHAR(10)), 'Dynamic_FN', CONCAT('MD_Batch_', @MaxPractitionerID + 1), 'Emergency Medicine', @MaxFacilityID, 1, SYSUTCDATETIME());

-- [Table 4] Clinical.Patients
INSERT INTO Clinical.Patients (MRN, FirstName, LastName, DateOfBirth, AdministrativeGender, PhoneNumber, LastModifiedDateTime)
VALUES (CONCAT('MRN-AUTO-', @MaxPatientID + 1), 'Patient_FN', CONCAT('LN_', @MaxPatientID + 1), '1990-01-01', 'U', '555-AUTO', SYSUTCDATETIME());

-- [Table 5] Clinical.Appointments
INSERT INTO Clinical.Appointments (PatientID, PractitionerID, FacilityID, AppointmentDateTime, AppointmentStatus, LastModifiedDateTime)
VALUES (@MaxPatientID + 1, @MaxPractitionerID, @MaxFacilityID, DATEADD(day, 1, SYSUTCDATETIME()), 'Scheduled', SYSUTCDATETIME());

-- [Table 6] Clinical.Encounters
INSERT INTO Clinical.Encounters (AppointmentID, PatientID, PractitionerID, FacilityID, EncounterClass, AdmitDateTime, DischargeDateTime, PrimaryDiagnosisCode, LastModifiedDateTime)
VALUES (@MaxAppointmentID, @MaxPatientID + 1, @MaxPractitionerID, @MaxFacilityID, 'Emergency', SYSUTCDATETIME(), NULL, 'R51.9', SYSUTCDATETIME());

-- [Table 7] Clinical.BedAssignments
INSERT INTO Clinical.BedAssignments (EncounterID, BedID, AssignStartDateTime, AssignEndDateTime, LastModifiedDateTime)
VALUES (@MaxEncounterID + 1, @MaxBedID + 1, SYSUTCDATETIME(), NULL, SYSUTCDATETIME());

-- [Table 8] Clinical.MedicationOrders
INSERT INTO Clinical.MedicationOrders (EncounterID, PatientID, PrescribingPractitionerID, MedicationCode, MedicationName, DosageInstruction, OrderStatus, LastModifiedDateTime)
VALUES (@MaxEncounterID + 1, @MaxPatientID + 1, @MaxPractitionerID, '261242', 'Ibuprofen 600 MG', 'Take 1 tablet every 8h', 'Active', SYSUTCDATETIME());

-- [Table 9] Clinical.LabOrders
INSERT INTO Clinical.LabOrders (EncounterID, PatientID, OrderingPractitionerID, LOINCCode, TestName, LabStatus, ResultValue, LastModifiedDateTime)
VALUES (@MaxEncounterID + 1, @MaxPatientID + 1, @MaxPractitionerID, '2345-7', 'Glucose Blood Auto', 'Ordered', NULL, SYSUTCDATETIME());

-- [Table 10] Clinical.Procedures
INSERT INTO Clinical.Procedures (EncounterID, PatientID, PrimarySurgeonID, CPTCode, ProcedureDescription, ProcedureStatus, LastModifiedDateTime)
VALUES (@MaxEncounterID + 1, @MaxPatientID + 1, @MaxPractitionerID, '93000', 'Auto EKG Tracing Check', 'Completed', SYSUTCDATETIME());

-- [Table 11] Financial.BillingInvoices
INSERT INTO Financial.BillingInvoices (EncounterID, PatientID, InvoiceNumber, GrossAmount, NetOutstandingBalance, InvoiceStatus, LastModifiedDateTime)
VALUES (@MaxEncounterID + 1, @MaxPatientID + 1, CONCAT('INV-AUTO-', @MaxEncounterID + 1), 500.0000, 500.0000, 'Active', SYSUTCDATETIME());
GO

