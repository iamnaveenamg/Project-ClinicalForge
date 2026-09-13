-- =========================================================================
-- CORE SCHEMA: MASTER INFRASTRUCTURE TABLES
-- =========================================================================

CREATE TABLE Core.Facilities (
    FacilityID INT IDENTITY(1,1) NOT NULL,
    OrganizationTaxID VARCHAR(20) NOT NULL,
    FacilityName VARCHAR(150) NOT NULL,
    FacilityType VARCHAR(50) NOT NULL, -- General Hospital, Urgent Care, Clinic
    NPI VARCHAR(10) NULL,
    City VARCHAR(100) NOT NULL,
    StateCode CHAR(2) NOT NULL,
    IsActive BIT DEFAULT 1 NOT NULL,
    LastModifiedDateTime DATETIME2(3) DEFAULT SYSUTCDATETIME() NOT NULL,
    RowVersion ROWVERSION NOT NULL,
    CONSTRAINT PK_Facilities PRIMARY KEY CLUSTERED (FacilityID)
);

CREATE TABLE Core.Beds (
    BedID INT IDENTITY(1,1) NOT NULL,
    FacilityID INT NOT NULL,
    WardName VARCHAR(100) NOT NULL,    -- ICU, Emergency, General Ward
    RoomNumber VARCHAR(20) NOT NULL,
    BedNumber VARCHAR(20) NOT NULL,
    BedStatus VARCHAR(30) NOT NULL,    -- Available, Occupied, Cleaning
    LastModifiedDateTime DATETIME2(3) DEFAULT SYSUTCDATETIME() NOT NULL,
    RowVersion ROWVERSION NOT NULL,
    CONSTRAINT PK_Beds PRIMARY KEY CLUSTERED (BedID),
    CONSTRAINT FK_Beds_Facilities FOREIGN KEY (FacilityID) REFERENCES Core.Facilities(FacilityID)
);

CREATE TABLE Core.Practitioners (
    PractitionerID INT IDENTITY(1,1) NOT NULL,
    NPI VARCHAR(10) NOT NULL,          -- National Provider Identifier
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    SpecialtyDescription VARCHAR(150) NOT NULL,
    PrimaryFacilityID INT NOT NULL,
    IsActive BIT DEFAULT 1 NOT NULL,
    LastModifiedDateTime DATETIME2(3) DEFAULT SYSUTCDATETIME() NOT NULL,
    RowVersion ROWVERSION NOT NULL,
    CONSTRAINT PK_Practitioners PRIMARY KEY CLUSTERED (PractitionerID),
    CONSTRAINT FK_Practitioners_Facilities FOREIGN KEY (PrimaryFacilityID) REFERENCES Core.Facilities(FacilityID),
    CONSTRAINT UQ_Practitioner_NPI UNIQUE (NPI)
);

-- =========================================================================
-- HIGH-VELOCITY INCREMENTAL RETRIEVAL PIPELINE INDEXES
-- =========================================================================
CREATE NONCLUSTERED INDEX IX_Facilities_WM ON Core.Facilities (LastModifiedDateTime);
CREATE NONCLUSTERED INDEX IX_Beds_WM ON Core.Beds (LastModifiedDateTime);
CREATE NONCLUSTERED INDEX IX_Practitioners_WM ON Core.Practitioners (LastModifiedDateTime);




