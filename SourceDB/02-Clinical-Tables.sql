-- =========================================================================
-- CLINICAL SCHEMA: PATIENT DOMAIN & ENCOUNTERS
-- =========================================================================

CREATE TABLE Clinical.Patients (
    PatientID INT IDENTITY(1,1) NOT NULL,
    MRN VARCHAR(50) NOT NULL,          -- Medical Record Number
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    DateOfBirth DATE NOT NULL,
    AdministrativeGender CHAR(1) NOT NULL, -- M, F, U, O
    PhoneNumber VARCHAR(20) NOT NULL,
    LastModifiedDateTime DATETIME2(3) DEFAULT SYSUTCDATETIME() NOT NULL,
    RowVersion ROWVERSION NOT NULL,
    CONSTRAINT PK_Patients PRIMARY KEY CLUSTERED (PatientID),
    CONSTRAINT UQ_Patients_MRN UNIQUE (MRN)
);

CREATE TABLE Clinical.Appointments (
    AppointmentID INT IDENTITY(1,1) NOT NULL,
    PatientID INT NOT NULL,
    PractitionerID INT NOT NULL,
    FacilityID INT NOT NULL,
    AppointmentDateTime DATETIME2(3) NOT NULL,
    AppointmentStatus VARCHAR(30) NOT NULL, -- Scheduled, Completed, No-Show
    LastModifiedDateTime DATETIME2(3) DEFAULT SYSUTCDATETIME() NOT NULL,
    RowVersion ROWVERSION NOT NULL,
    CONSTRAINT PK_Appointments PRIMARY KEY CLUSTERED (AppointmentID),
    CONSTRAINT FK_Appointments_Patients FOREIGN KEY (PatientID) REFERENCES Clinical.Patients(PatientID),
    CONSTRAINT FK_Appointments_Practitioners FOREIGN KEY (PractitionerID) REFERENCES Core.Practitioners(PractitionerID),
    CONSTRAINT FK_Appointments_Facilities FOREIGN KEY (FacilityID) REFERENCES Core.Facilities(FacilityID)
);

CREATE TABLE Clinical.Encounters (
    EncounterID INT IDENTITY(1,1) NOT NULL,
    AppointmentID INT NULL,            -- Nullable for direct ER walk-ins
    PatientID INT NOT NULL,
    PractitionerID INT NOT NULL,
    FacilityID INT NOT NULL,
    EncounterClass VARCHAR(30) NOT NULL, -- Inpatient, Outpatient, Emergency
    AdmitDateTime DATETIME2(3) NOT NULL,
    DischargeDateTime DATETIME2(3) NULL,
    PrimaryDiagnosisCode VARCHAR(20) NULL, -- ICD-10 Code
    LastModifiedDateTime DATETIME2(3) DEFAULT SYSUTCDATETIME() NOT NULL,
    RowVersion ROWVERSION NOT NULL,
    CONSTRAINT PK_Encounters PRIMARY KEY CLUSTERED (EncounterID),
    CONSTRAINT FK_Encounters_Appointments FOREIGN KEY (AppointmentID) REFERENCES Clinical.Appointments(AppointmentID),
    CONSTRAINT FK_Encounters_Patients FOREIGN KEY (PatientID) REFERENCES Clinical.Patients(PatientID),
    CONSTRAINT FK_Encounters_Practitioners FOREIGN KEY (PractitionerID) REFERENCES Core.Practitioners(PractitionerID),
    CONSTRAINT FK_Encounters_Facilities FOREIGN KEY (FacilityID) REFERENCES Core.Facilities(FacilityID)
);

CREATE TABLE Clinical.BedAssignments (
    AssignmentID INT IDENTITY(1,1) NOT NULL,
    EncounterID INT NOT NULL,
    BedID INT NOT NULL,
    AssignStartDateTime DATETIME2(3) NOT NULL,
    AssignEndDateTime DATETIME2(3) NULL,
    LastModifiedDateTime DATETIME2(3) DEFAULT SYSUTCDATETIME() NOT NULL,
    RowVersion ROWVERSION NOT NULL,
    CONSTRAINT PK_BedAssignments PRIMARY KEY CLUSTERED (AssignmentID),
    CONSTRAINT FK_BedAssignments_Encounters FOREIGN KEY (EncounterID) REFERENCES Clinical.Encounters(EncounterID),
    CONSTRAINT FK_BedAssignments_Beds FOREIGN KEY (BedID) REFERENCES Core.Beds(BedID)
);

-- =========================================================================
-- CLINICAL SCHEMA: ORDERS, PROCEDURES & DIAGNOSTICS
-- =========================================================================

CREATE TABLE Clinical.MedicationOrders (
    MedicationOrderID INT IDENTITY(1,1) NOT NULL,
    EncounterID INT NOT NULL,
    PatientID INT NOT NULL,
    PrescribingPractitionerID INT NOT NULL,
    MedicationCode VARCHAR(20) NOT NULL, -- RxNorm Code
    MedicationName VARCHAR(255) NOT NULL,
    DosageInstruction VARCHAR(255) NOT NULL,
    OrderStatus VARCHAR(30) NOT NULL,   -- Active, Completed, Cancelled
    LastModifiedDateTime DATETIME2(3) DEFAULT SYSUTCDATETIME() NOT NULL,
    RowVersion ROWVERSION NOT NULL,
    CONSTRAINT PK_MedicationOrders PRIMARY KEY CLUSTERED (MedicationOrderID),
    CONSTRAINT FK_MedicationOrders_Encounters FOREIGN KEY (EncounterID) REFERENCES Clinical.Encounters(EncounterID),
    CONSTRAINT FK_MedicationOrders_Patients FOREIGN KEY (PatientID) REFERENCES Clinical.Patients(PatientID),
    CONSTRAINT FK_MedicationOrders_Practitioners FOREIGN KEY (PrescribingPractitionerID) REFERENCES Core.Practitioners(PractitionerID)
);

CREATE TABLE Clinical.LabOrders (
    LabOrderID INT IDENTITY(1,1) NOT NULL,
    EncounterID INT NOT NULL,
    PatientID INT NOT NULL,
    OrderingPractitionerID INT NOT NULL,
    LOINCCode VARCHAR(20) NOT NULL,     -- LOINC Code Standard
    TestName VARCHAR(150) NOT NULL,
    LabStatus VARCHAR(30) NOT NULL,     -- Ordered, Completed
    ResultValue VARCHAR(50) NULL,
    LastModifiedDateTime DATETIME2(3) DEFAULT SYSUTCDATETIME() NOT NULL,
    RowVersion ROWVERSION NOT NULL,
    CONSTRAINT PK_LabOrders PRIMARY KEY CLUSTERED (LabOrderID),
    CONSTRAINT FK_LabOrders_Encounters FOREIGN KEY (EncounterID) REFERENCES Clinical.Encounters(EncounterID),
    CONSTRAINT FK_LabOrders_Patients FOREIGN KEY (PatientID) REFERENCES Clinical.Patients(PatientID),
    CONSTRAINT FK_LabOrders_Practitioners FOREIGN KEY (OrderingPractitionerID) REFERENCES Core.Practitioners(PractitionerID)
);

CREATE TABLE Clinical.Procedures (
    ProcedureID INT IDENTITY(1,1) NOT NULL,
    EncounterID INT NOT NULL,
    PatientID INT NOT NULL,
    PrimarySurgeonID INT NOT NULL,
    CPTCode VARCHAR(10) NOT NULL,        -- CPT Code Standard
    ProcedureDescription VARCHAR(255) NOT NULL,
    ProcedureStatus VARCHAR(30) NOT NULL,
    LastModifiedDateTime DATETIME2(3) DEFAULT SYSUTCDATETIME() NOT NULL,
    RowVersion ROWVERSION NOT NULL,
    CONSTRAINT PK_Procedures PRIMARY KEY CLUSTERED (ProcedureID),
    CONSTRAINT FK_Procedures_Encounters FOREIGN KEY (EncounterID) REFERENCES Clinical.Encounters(EncounterID),
    CONSTRAINT FK_Procedures_Patients FOREIGN KEY (PatientID) REFERENCES Clinical.Patients(PatientID),
    CONSTRAINT FK_Procedures_Surgeons FOREIGN KEY (PrimarySurgeonID) REFERENCES Core.Practitioners(PractitionerID)
);


CREATE NONCLUSTERED INDEX IX_Patients_WM ON Clinical.Patients (LastModifiedDateTime);
CREATE NONCLUSTERED INDEX IX_Appointments_WM ON Clinical.Appointments (LastModifiedDateTime);
CREATE NONCLUSTERED INDEX IX_Encounters_WM ON Clinical.Encounters (LastModifiedDateTime);
CREATE NONCLUSTERED INDEX IX_BedAssignments_WM ON Clinical.BedAssignments (LastModifiedDateTime);
CREATE NONCLUSTERED INDEX IX_MedicationOrders_WM ON Clinical.MedicationOrders (LastModifiedDateTime);
CREATE NONCLUSTERED INDEX IX_LabOrders_WM ON Clinical.LabOrders (LastModifiedDateTime);
CREATE NONCLUSTERED INDEX IX_Procedures_WM ON Clinical.Procedures (LastModifiedDateTime);
