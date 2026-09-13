
-- =========================================================================
-- 4. SEED DATA: CLINICAL.PATIENTS (10 Records)
-- =========================================================================
SET IDENTITY_INSERT Clinical.Patients ON;
INSERT INTO Clinical.Patients (PatientID, MRN, FirstName, LastName, DateOfBirth, AdministrativeGender, PhoneNumber, LastModifiedDateTime) VALUES 
(1, 'MRN-908123', 'John', 'Doe', '1975-04-12', 'M', '617-555-9001', '2026-01-20 08:00:00'),
(2, 'MRN-451029', 'Mary', 'Watson', '1988-09-23', 'F', '617-555-9101', '2026-02-15 10:00:00'),
(3, 'MRN-773821', 'Bruce', 'Wayne', '1980-02-19', 'M', '617-555-1939', '2026-01-15 00:00:00'),
(4, 'MRN-102938', 'Diana', 'Prince', '1990-11-05', 'F', '617-555-7001', '2026-03-10 14:00:00'),
(5, 'MRN-554637', 'Peter', 'Parker', '2001-08-10', 'M', '718-555-3214', '2026-04-05 09:30:00'),
(6, 'MRN-229481', 'Clark', 'Kent', '1985-06-18', 'M', '212-555-8844', '2026-05-12 11:15:00'),
(7, 'MRN-638291', 'Tony', 'Stark', '1970-05-29', 'M', '310-555-1000', '2026-01-30 08:45:00'),
(8, 'MRN-883920', 'Selina', 'Kyle', '1992-03-14', 'F', '617-555-4422', '2026-06-01 16:20:00'),
(9, 'MRN-119284', 'Barry', 'Allen', '1989-01-07', 'M', '508-555-7876', '2026-07-22 13:10:00'),
(10, 'MRN-330492', 'Arthur', 'Curry', '1986-01-28', 'M', '508-555-3474', '2026-08-05 10:00:00');
SET IDENTITY_INSERT Clinical.Patients OFF;
GO

-- =========================================================================
-- 5. SEED DATA: CLINICAL.APPOINTMENTS (10 Records)
-- =========================================================================
SET IDENTITY_INSERT Clinical.Appointments ON;
INSERT INTO Clinical.Appointments (AppointmentID, PatientID, PractitionerID, FacilityID, AppointmentDateTime, AppointmentStatus, LastModifiedDateTime) VALUES 
(1, 1, 1, 1, '2026-09-12 09:00:00', 'Completed', '2026-09-12 09:30:00'),
(2, 2, 3, 3, '2026-09-12 10:00:00', 'Completed', '2026-09-12 10:15:00'),
(3, 4, 4, 4, '2026-09-12 11:00:00', 'Completed', '2026-09-12 11:45:00'),
(4, 5, 3, 3, '2026-09-12 13:00:00', 'Scheduled', '2026-09-12 13:00:00'),
(5, 6, 6, 9, '2026-09-12 14:00:00', 'Scheduled', '2026-09-01 08:00:00'),
(6, 7, 7, 6, '2026-09-12 07:30:00', 'Completed', '2026-09-12 10:00:00'),
(7, 8, 8, 2, '2026-09-12 15:30:00', 'Scheduled', '2026-09-08 15:30:00'),
(8, 9, 1, 1, '2026-09-12 16:00:00', 'Scheduled', '2026-09-10 16:00:00'),
(9, 10, 5, 7, '2026-09-12 10:30:00', 'No-Show', '2026-09-12 11:00:00'),
(10, 2, 8, 2, '2026-09-12 08:15:00', 'Cancelled', '2026-09-11 09:00:00');
SET IDENTITY_INSERT Clinical.Appointments OFF;
GO

-- =========================================================================
-- 6. SEED DATA: CLINICAL.ENCOUNTERS (10 Records)
-- =========================================================================
SET IDENTITY_INSERT Clinical.Encounters ON;
INSERT INTO Clinical.Encounters (EncounterID, AppointmentID, PatientID, PractitionerID, FacilityID, EncounterClass, AdmitDateTime, DischargeDateTime, PrimaryDiagnosisCode, LastModifiedDateTime) VALUES 
(1, 1, 1, 1, 1, 'Outpatient', '2026-09-12 09:00:00', '2026-09-12 09:30:00', 'I10', '2026-09-12 09:30:00'),
(2, 2, 2, 3, 3, 'Outpatient', '2026-09-12 10:00:00', '2026-09-12 10:15:00', 'H66.90', '2026-09-12 10:15:00'),
(3, 3, 4, 4, 4, 'Outpatient', '2026-09-12 11:00:00', '2026-09-12 11:45:00', 'R00.2', '2026-09-12 11:45:00'),
(4, NULL, 3, 2, 10, 'Emergency', '2026-09-12 01:00:00', NULL, 'R07.9', '2026-09-12 01:00:00'),
(5, NULL, 5, 9, 10, 'Emergency', '2026-09-12 02:30:00', '2026-09-12 05:00:00', 'S93.401A', '2026-09-12 05:00:00'),
(6, 6, 7, 7, 6, 'Ambulatory', '2026-09-12 07:30:00', '2026-09-12 11:00:00', 'M23.203', '2026-09-12 11:00:00'),
(7, NULL, 1, 2, 10, 'Inpatient', '2026-09-11 22:00:00', NULL, 'A41.9', '2026-09-11 22:00:00'),
(8, NULL, 8, 9, 10, 'Emergency', '2026-09-12 17:00:00', NULL, 'R51.9', '2026-09-12 17:00:00'),
(9, NULL, 9, 1, 1, 'Inpatient', '2026-09-10 14:00:00', NULL, 'E11.9', '2026-09-10 14:00:00'),
(10, NULL, 10, 2, 10, 'Emergency', '2026-09-12 08:00:00', '2026-09-12 12:30:00', 'J06.9', '2026-09-12 12:30:00');
SET IDENTITY_INSERT Clinical.Encounters OFF;

-- =========================================================================
-- 7. SEED DATA: CLINICAL.BEDASSIGNMENTS (10 Records)
-- =========================================================================
SET IDENTITY_INSERT Clinical.BedAssignments ON;
INSERT INTO Clinical.BedAssignments (AssignmentID, EncounterID, BedID, AssignStartDateTime, AssignEndDateTime, LastModifiedDateTime) VALUES 
(1, 4, 3, '2026-09-12 01:05:00', NULL, '2026-09-12 01:05:00'),
(2, 5, 4, '2026-09-12 02:40:00', '2026-09-12 04:50:00', '2026-09-12 04:50:00'),
(3, 7, 7, '2026-09-11 22:15:00', '2026-09-12 00:05:00', '2026-09-12 00:05:00'),
(4, 7, 1, '2026-09-12 00:05:00', NULL, '2026-09-12 00:05:00'),
(5, 8, 8, '2026-09-12 17:10:00', '2026-09-12 18:00:00', '2026-09-12 18:00:00'),
(6, 9, 6, '2026-09-10 14:30:00', NULL, '2026-09-10 14:30:00'),
(7, 10, 4, '2026-09-12 08:15:00', '2026-09-12 12:15:00', '2026-09-12 12:15:00'),
(8, 6, 5, '2026-09-12 07:45:00', '2026-09-12 10:45:00', '2026-09-12 10:45:00'),
(9, 1, 5, '2026-09-12 09:05:00', '2026-09-12 09:25:00', '2026-09-12 09:25:00'),
(10, 8, 4, '2026-09-12 18:00:00', NULL, '2026-09-12 18:00:00');
SET IDENTITY_INSERT Clinical.BedAssignments OFF;
GO

-- =========================================================================
-- 8. SEED DATA: CLINICAL.MEDICATIONORDERS (10 Records)
-- =========================================================================
SET IDENTITY_INSERT Clinical.MedicationOrders ON;
INSERT INTO Clinical.MedicationOrders (MedicationOrderID, EncounterID, PatientID, PrescribingPractitionerID, MedicationCode, MedicationName, DosageInstruction, OrderStatus, LastModifiedDateTime) 
VALUES
(1, 1, 1, 1, '864703', 'Metformin hydrochloride 500 MG', '500mg Oral tablet Twice daily', 'Active', '2026-09-12 09:25:00'),
(2, 2, 2, 3, '308137', 'Amoxicillin 250 MG Oral Capsule', '250mg Oral capsule Three times daily', 'Active', '2026-09-12 10:10:00'),
(3, 4, 3, 2, '308422', 'Aspirin 81 MG Oral Tablet', '81mg Oral tablet Once daily', 'Active', '2026-09-12 01:15:00'),
(4, 4, 3, 2, '1156683', 'Nitroglycerin 0.4 MG Sublingual Tablet', '0.4mg Sublingual as needed for pain', 'Active', '2026-09-12 01:20:00'),
(5, 7, 1, 2, '313175', 'Vancomycin 1000 MG Injection', '1000mg Intravenous every 12 hours', 'Active', '2026-09-11 22:30:00'),
(6, 6, 7, 7, '261242', 'Ibuprofen 600 MG Oral Tablet', '600mg Oral tablet every 6 hours', 'Active', '2026-09-12 10:30:00'),
(7, 9, 9, 1, '855332', 'Lisinopril 10 MG Oral Tablet', '10mg Oral tablet Once daily', 'Active', '2026-09-10 14:15:00'),
(8, 10, 10, 2, '212170', 'Fluticasone propionate 0.05 MG Nasal Spray', '1 spray in each nostril daily', 'Active', '2026-09-12 12:00:00'),
(9, 3, 4, 4, '311680', 'Metoprolol succinate 50 MG ER', '50mg Extended Release Once daily', 'Active', '2026-09-12 11:30:00'),
(10, 5, 5, 9, '261239', 'Ibuprofen 400 MG Oral Tablet', '400mg Oral tablet as needed', 'Completed', '2026-09-12 05:00:00');
SET IDENTITY_INSERT Clinical.MedicationOrders OFF;
GO

-- =========================================================================
-- 9. SEED DATA: CLINICAL.LABORDERS (10 Records)
-- =========================================================================
SET IDENTITY_INSERT Clinical.LabOrders ON;
INSERT INTO Clinical.LabOrders (LabOrderID, EncounterID, PatientID, OrderingPractitionerID, LOINCCode, TestName, LabStatus, ResultValue, LastModifiedDateTime) VALUES
(1, 1, 1, 1, '4548-4', 'Hemoglobin A1c', 'Completed', '6.8 %', '2026-09-12 14:00:00'),
(2, 4, 3, 2, '13457-7', 'Troponin I.cardiac', 'Completed', '0.15 ng/mL', '2026-09-12 01:45:00'),
(3, 4, 3, 2, '2345-7', 'Glucose Blood', 'Completed', '105 mg/dL', '2026-09-12 01:30:00'),
(4, 7, 1, 2, '5778-6', 'Lactate Blood', 'Completed', '4.2 mmol/L', '2026-09-11 22:40:00'),
(5, 7, 1, 2, '26464-8', 'Leukocytes Blood', 'Completed', '16.5 103/uL', '2026-09-11 22:50:00'),
(6, 6, 7, 7, '26453-1', 'Erythrocytes Blood', 'Completed', '4.8 106/uL', '2026-09-12 07:00:00'),
(7, 9, 9, 1, '1558-1', 'Fasting Glucose', 'Completed', '142 mg/dL', '2026-09-11 09:00:00'),
(8, 10, 10, 2, '6301-4', 'Influenza A Ag', 'Completed', 'Negative', '2026-09-12 09:15:00'),
(9, 10, 10, 2, '6305-5', 'Influenza B Ag', 'Completed', 'Negative', '2026-09-12 09:15:00'),
(10, 4, 3, 2, '3094-0', 'BUN Serum', 'Ordered', NULL, '2026-09-12 18:15:00');
SET IDENTITY_INSERT Clinical.LabOrders OFF;
GO
-- =========================================================================
-- 10. SEED DATA: CLINICAL.PROCEDURES (10 Records)
-- =========================================================================
SET IDENTITY_INSERT Clinical.Procedures ON;
INSERT INTO Clinical.Procedures (ProcedureID, EncounterID, PatientID, PrimarySurgeonID, CPTCode, ProcedureDescription, ProcedureStatus, LastModifiedDateTime) VALUES
(1, 6, 7, 7, '29881', 'Knee arthroscopy/menisectomy', 'Completed', '2026-09-12 09:45:00'),
(2, 4, 3, 2, '93452', 'Left heart catheterization', 'Completed', '2026-09-12 03:30:00'),
(3, 5, 5, 9, '29540', 'Strapping of ankle/foot', 'Completed', '2026-09-12 04:00:00'),
(4, 7, 1, 2, '36556', 'Insertion of central line', 'Completed', '2026-09-11 23:45:00'),
(5, 1, 1, 1, '99213', 'Outpatient procedure visit', 'Completed', '2026-09-12 09:30:00'),
(6, 2, 2, 3, '69210', 'Removal of impacted cerumen', 'Completed', '2026-09-12 10:12:00'),
(7, 3, 4, 4, '93000', 'Electrocardiogram tracing', 'Completed', '2026-09-12 11:25:00'),
(8, 10, 10, 2, '94640', 'Inhalation treatment', 'Completed', '2026-09-12 09:50:00'),
(9, 7, 1, 7, '43239', 'Upper GI endoscopy', 'Scheduled', '2026-09-12 16:00:00'),
(10, 4, 3, 2, '94010', 'Spirometry respiratory test', 'Scheduled', '2026-09-12 18:30:00');
SET IDENTITY_INSERT Clinical.Procedures OFF;
GO

