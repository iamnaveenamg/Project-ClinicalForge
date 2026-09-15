-- CREATE SCHEMA IF NOT EXISTS clinicalforge.gold;
-- USE clinicalforge.gold;

-- =========================================================================
-- 1. DIMENSION TABLES (Conformed Dimensions)
-- =========================================================================

-- Target Name: DimFacilities [LoadMethod: FullRefresh]
CREATE TABLE clinicalforge.gold.DimFacilities (
    FacilitySK BIGINT GENERATED ALWAYS AS IDENTITY, -- Warehouse Surrogate Key
    HealthClientID VARCHAR(20) NOT NULL,            -- Tenant tracking index (e.g., 'BOSHOSP')
    FacilityID INT NOT NULL,                        -- Source Natural Key
    FacilityName VARCHAR(150) NOT NULL,
    FacilityType VARCHAR(50) NOT NULL,
    City VARCHAR(100) NOT NULL,
    StateCode CHAR(2) NOT NULL,
    IsActive BOOLEAN NOT NULL,
    NPI varchar(100)
    IngestionTimestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT PK_DimFacilities PRIMARY KEY (FacilitySK)
) USING DELTA;

-- Target Name: DimBeds [LoadMethod: FullRefresh]
CREATE TABLE clinicalforge.gold.DimBeds (
    BedSK BIGINT GENERATED ALWAYS AS IDENTITY,
    HealthClientID VARCHAR(20) NOT NULL,
    BedID INT NOT NULL,
    FacilityID INT NOT NULL,
    WardName VARCHAR(100) NOT NULL,                  -- ICU, Emergency, Medical-Surgical
    RoomNumber VARCHAR(20) NOT NULL,
    BedNumber VARCHAR(20) NOT NULL,
    BedStatus VARCHAR(30) NOT NULL,
    IngestionTimestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT PK_DimBeds PRIMARY KEY (BedSK)
) USING DELTA;

-- Target Name: DimPractitioners [LoadMethod: IncrementalWatermark]
CREATE TABLE clinicalforge.gold.DimPractitioners (
    PractitionerSK BIGINT GENERATED ALWAYS AS IDENTITY,
    HealthClientID VARCHAR(20) NOT NULL,
    PractitionerID INT NOT NULL,
    NPI VARCHAR(10) NOT NULL,                       -- National Provider Identifier
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    SpecialtyDescription VARCHAR(150) NOT NULL,
    IsActive BOOLEAN NOT NULL,
    IngestionTimestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT PK_DimPractitioners PRIMARY KEY (PractitionerSK)
) USING DELTA;

-- Target Name: DimPatients [LoadMethod: IncrementalWatermark - Type 2 History Tracker]
CREATE TABLE clinicalforge.gold.DimPatients (
    PatientSK BIGINT GENERATED ALWAYS AS IDENTITY,
    HealthClientID VARCHAR(20) NOT NULL,
    PatientID INT NOT NULL,
    MRN VARCHAR(50) NOT NULL,                       -- Medical Record Number
    MaskedFirstName VARCHAR(100) NOT NULL,          -- De-identified via Silver layer
    MaskedLastName VARCHAR(100) NOT NULL,
    DateOfBirth DATE NOT NULL,
    AdministrativeGender CHAR(1) NOT NULL,
    PhoneNumber VARCHAR(20) NOT NULL,
    -- Slowly Changing Dimension (SCD) Type 2 tracking parameters
    RowValidFrom TIMESTAMP NOT NULL,
    RowValidTo TIMESTAMP,
    IsCurrentRow BOOLEAN DEFAULT TRUE NOT NULL,
    CONSTRAINT PK_DimPatients PRIMARY KEY (PatientSK)
) USING DELTA;


-- =========================================================================
-- 2. FACT TABLES (Accumulating & Transactional Core Metrics)
-- =========================================================================

-- Target Name: FactAppointments [LoadMethod: IncrementalWatermark]
CREATE TABLE clinicalforge.gold.FactAppointments (
    AppointmentID INT NOT NULL,
    HealthClientID VARCHAR(20) NOT NULL,
    PatientSK BIGINT NOT NULL,          -- Linked to DimPatients
    PractitionerSK BIGINT NOT NULL,      -- Linked to DimPractitioners
    FacilitySK BIGINT NOT NULL,          -- Linked to DimFacilities
    AppointmentDateTime TIMESTAMP NOT NULL,
    AppointmentStatus VARCHAR(30) NOT NULL, -- Scheduled, Completed, Cancelled
    IngestionTimestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT PK_FactAppointments PRIMARY KEY (AppointmentID)
) USING DELTA 
PARTITIONED BY (HealthClientID);

-- Target Name: FactEncounters [LoadMethod: IncrementalWatermark]
CREATE TABLE clinicalforge.gold.FactEncounters (
    EncounterID INT NOT NULL,
    AppointmentID INT,                  -- Nullable for direct emergency walk-ins
    HealthClientID VARCHAR(20) NOT NULL,
    PatientSK BIGINT NOT NULL,
    PractitionerSK BIGINT NOT NULL,
    FacilitySK BIGINT NOT NULL,
    EncounterClass VARCHAR(30) NOT NULL,  -- Inpatient, Outpatient, Emergency
    AdmitDateTime TIMESTAMP NOT NULL,
    DischargeDateTime TIMESTAMP,
    PrimaryDiagnosisCode VARCHAR(20),    -- ICD-10 Code System
    IngestionTimestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT PK_FactEncounters PRIMARY KEY (EncounterID)
) USING DELTA 
PARTITIONED BY (HealthClientID);

-- Target Name: FactMedicationOrders [LoadMethod: IncrementalWatermark]
CREATE TABLE clinicalforge.gold.FactMedicationOrders (
    MedicationOrderID INT NOT NULL,
    EncounterID INT NOT NULL,           -- Links back to FactEncounters
    HealthClientID VARCHAR(20) NOT NULL,
    PatientSK BIGINT NOT NULL,
    PrescribingPractitionerSK BIGINT NOT NULL,
    MedicationCode VARCHAR(20) NOT NULL, -- RxNorm Code System
    MedicationName VARCHAR(255) NOT NULL,
    DosageInstruction VARCHAR(255) NOT NULL,
    OrderStatus VARCHAR(30) NOT NULL,    -- Active, Completed, Cancelled
    IngestionTimestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT PK_FactMedicationOrders PRIMARY KEY (MedicationOrderID)
) USING DELTA 
PARTITIONED BY (HealthClientID);

-- Target Name: FactLabOrders [LoadMethod: IncrementalWatermark]
CREATE TABLE clinicalforge.gold.FactLabOrders (
    LabOrderID INT NOT NULL,
    EncounterID INT NOT NULL,
    HealthClientID VARCHAR(20) NOT NULL,
    PatientSK BIGINT NOT NULL,
    OrderingPractitionerSK BIGINT NOT NULL,
    LOINCCode VARCHAR(20) NOT NULL,       -- LOINC Standard Diagnostic Code
    TestName VARCHAR(150) NOT NULL,
    LabStatus VARCHAR(30) NOT NULL,
    ResultValue VARCHAR(50),
    IngestionTimestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT PK_FactLabOrders PRIMARY KEY (LabOrderID)
) USING DELTA 
PARTITIONED BY (HealthClientID);

-- Target Name: FactBillingInvoices [LoadMethod: IncrementalWatermark]
CREATE TABLE clinicalforge.gold.FactBillingInvoices (
    InvoiceID INT NOT NULL,
    EncounterID INT NOT NULL,
    HealthClientID VARCHAR(20) NOT NULL,
    PatientSK BIGINT NOT NULL,
    InvoiceNumber VARCHAR(50) NOT NULL,
    GrossAmount DECIMAL(18,4) NOT NULL,
    NetOutstandingBalance DECIMAL(18,4) NOT NULL,
    InvoiceStatus VARCHAR(30) NOT NULL,
    IngestionTimestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT PK_FactBillingInvoices PRIMARY KEY (InvoiceID)
) USING DELTA 
PARTITIONED BY (HealthClientID);




-- USE SYSTEM CATALOG: clinicalforge.gold;

-- =========================================================================
-- ADDITIONAL FACT TABLES (Star Schema Mapping)
-- =========================================================================

-- Target Name: FactProcedures [LoadMethod: IncrementalWatermark]
CREATE TABLE clinicalforge.gold.FactProcedures (
    ProcedureID INT NOT NULL,
    EncounterID INT NOT NULL,              -- Natural Key hook back to Gold.FactEncounters
    HealthClientID VARCHAR(20) NOT NULL,    -- Multi-tenant separation token (e.g., 'BOSHOSP')
    PatientSK BIGINT NOT NULL,             -- Resolves prefix to target DimPatients SK
    PrimarySurgeonSK BIGINT NOT NULL,       -- Resolves prefix to target DimPractitioners SK
    CPTCode VARCHAR(10) NOT NULL,          -- Current Procedural Terminology billing standard
    ProcedureDescription VARCHAR(255) NOT NULL,
    ProcedureStatus VARCHAR(30) NOT NULL,  -- Scheduled, Completed, Aborted
    IngestionTimestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT PK_FactProcedures PRIMARY KEY (ProcedureID)
) USING DELTA 
PARTITIONED BY (HealthClientID);

-- Target Name: FactBedAssignments [LoadMethod: IncrementalWatermark]
-- Used for real-time and historical operational capacity tracking (e.g., ICU occupancy)
CREATE TABLE clinicalforge.gold.FactBedAssignments (
    AssignmentID INT NOT NULL,
    EncounterID INT NOT NULL,              -- Hook back to Gold.FactEncounters
    HealthClientID VARCHAR(20) NOT NULL,
    BedSK BIGINT NOT NULL,                 -- Resolves prefix to target DimBeds SK
    AssignStartDateTime TIMESTAMP NOT NULL,
    AssignEndDateTime TIMESTAMP,           -- Remains NULL if the patient is currently in this bed
    -- Derived metric column calculating total minutes stayed in that specific bed asset
    BedStayDurationMinutes AS (DATEDIFF(MINUTE, AssignStartDateTime, ISNULL(AssignEndDateTime, CURRENT_TIMESTAMP()))),
    IngestionTimestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT PK_FactBedAssignments PRIMARY KEY (AssignmentID)
) USING DELTA 
PARTITIONED BY (HealthClientID);


-- =========================================================================
-- 3. THE UNIFIED REAL-TIME STREAMING FACT TABLE
-- =========================================================================

-- Target Name: FactUnifiedPatientTelemetry [LoadMethod: AppendStream]
CREATE TABLE clinicalforge.gold.FactUnifiedPatientTelemetry (
    TelemetryID STRING NOT NULL,           -- Unique Event UUID
    
    HealthClientID VARCHAR(20) NOT NULL,
    
    PatientSK BIGINT NOT NULL,
    
    EncounterID INT NOT NULL,              -- Direct analytical hook to FactEncounters
    
    DeviceID STRING NOT NULL,
    
    EnqueuedDateTime TIMESTAMP NOT NULL,   -- Kafka / Event Hub ingestion cluster log time
    HeartRate INT,
    OxygenSaturation INT,
    SystolicBloodPressure INT,
    DiastolicBloodPressure INT,
    RespiratoryRate INT,
    BodyTemperature DOUBLE,
    IngestionTimestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
) USING DELTA 
PARTITIONED BY (HealthClientID, PatientSK); -- Optimized for ultra-fast individual health dashboards
