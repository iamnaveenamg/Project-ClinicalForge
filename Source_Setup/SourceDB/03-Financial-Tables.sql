-- =========================================================================
-- FINANCIAL SCHEMA: BILLING & REVENUE OPERATIONAL LEDGER
-- =========================================================================

CREATE TABLE Financial.BillingInvoices (
    InvoiceID INT IDENTITY(1,1) NOT NULL,
    EncounterID INT NOT NULL,
    PatientID INT NOT NULL,
    InvoiceNumber VARCHAR(50) NOT NULL,
    GrossAmount DECIMAL(18,4) NOT NULL,
    NetOutstandingBalance DECIMAL(18,4) NOT NULL,
    InvoiceStatus VARCHAR(30) NOT NULL,  -- Active, Fully Paid, Written-Off
    LastModifiedDateTime DATETIME2(3) DEFAULT SYSUTCDATETIME() NOT NULL,
    RowVersion ROWVERSION NOT NULL,
    CONSTRAINT PK_BillingInvoices PRIMARY KEY CLUSTERED (InvoiceID),
    CONSTRAINT FK_BillingInvoices_Encounters FOREIGN KEY (EncounterID) REFERENCES Clinical.Encounters(EncounterID),
    CONSTRAINT FK_BillingInvoices_Patients FOREIGN KEY (PatientID) REFERENCES Clinical.Patients(PatientID),
    CONSTRAINT UQ_InvoiceNumber UNIQUE (InvoiceNumber)
);


CREATE NONCLUSTERED INDEX IX_BillingInvoices_WM ON Financial.BillingInvoices (LastModifiedDateTime);
