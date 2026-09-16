-- Ensure schemas exist before mapping data execution
-- USE DATABASE clinicalforge;
-- GO

-- =========================================================================
-- LEVEL 1: SEEDING TENANCY & ENVIRONMENT CORE
-- =========================================================================

-- 1. Insert Customer / Tenant
INSERT INTO clinicalforge.metadata.Customers (CustomerID, CustomerCode, CustomerName, SubscriptionTier, IsActive, CreatedDateTime)
VALUES (1, 'BOSHOSP', 'BostonHealthSystem', 'Enterprise', TRUE, '2026-01-15 08:00:00');

-- 2. Insert Core Analytics Product
INSERT INTO clinicalforge.metadata.Products (ProductID, ProductCode, ProductName, ProductDescription, IsActive)
VALUES (1, 'CLIN_FORGE', 'ClinicalIntelligenceForge', 'Real-time telemetry and clinical EMR pipeline analytics mapping engine.', TRUE);

-- 3. Link Customer to Product (CustomerProduct Junction Table)
INSERT INTO clinicalforge.metadata.CustomerProduct (CustomerProductID, CustomerID, ProductID)
VALUES (1, 1, 1);

-- 4. Insert Multi-Tenant Connection Profile
INSERT INTO clinicalforge.metadata.ConnectionDetails (ConnectionID, CustomerProductID, ConnectionName, TargetPlatform, HostServer, DatabaseName, KeyVaultSecretName, IsActive)
VALUES (1, 1, 'conn_sql_boshosp_prod', 'AzureSQL', 'boshosp-prod-srvr.database.windows.net', 'ClinicalForgeSourceDB', 'boshosp-sql-connectionstring', TRUE);

-- =========================================================================
-- LEVEL 2: SEEDING STREAMING TELEMENTRY CONFIGURATION
-- =========================================================================

-- 5. Insert Event Hub Real-Time Routing Parameters (The single streaming table link)
INSERT INTO clinicalforge.metadata.EventHubDetails (EventHubID, CustomerProductID, NamespaceName, TopicName, ConsumerGroup, PartitionCount, KeyVaultConnSecretStr, TargetDeltaTablePath)
VALUES (1, 1, 'evh-ns-clinicalforge-prod', 'clinicalforge.telemetry.patient-vitals', 'databricks-telemetry-cg', 4, 'eventhub-vitals-connstr', '/mnt/lakehouse/silver/unified_patient_telemetry');

-- =========================================================================
-- LEVEL 3: SEEDING OBJECT MAPPING LAYER (Tables List Registry)
-- =========================================================================

-- 6. Mapping Source OLTP tables to target Data Warehouse tables
INSERT INTO clinicalforge.metadata.TablesList (TableID, CustomerProductID, SourceConnectionID, SourceSchema, SourceTableName, WarehouseSchema, WarehouseTableName, ExtractionType, WatermarkColumn, LastExtractWatermark, DatabricksNotebookPath, IsActive)
VALUES 
(1,  1, 1, 'Core',      'Facilities',       'Gold', 'DimFacilities',        'FullRefresh', 'LastModifiedDateTime', '1900-01-01 00:00:00', '/Production/DimFacilities',        TRUE),
(2,  1, 1, 'Core',      'Beds',             'Gold', 'DimBeds',              'FullRefresh', 'LastModifiedDateTime', '1900-01-01 00:00:00', '/Production/DimBeds',              TRUE),
(3,  1, 1, 'Core',      'Practitioners',    'Gold', 'DimPractitioners',     'Incremental', 'LastModifiedDateTime', '1900-01-01 00:00:00', '/Production/DimPractitioners',     TRUE),
(4,  1, 1, 'Clinical',  'Patients',         'Gold', 'DimPatients',          'Incremental', 'LastModifiedDateTime', '1900-01-01 00:00:00', '/Production/DimPatients',          TRUE),
(5,  1, 1, 'Clinical',  'Appointments',     'Gold', 'FactAppointments',     'Incremental', 'LastModifiedDateTime', '1900-01-01 00:00:00', '/Production/FactAppointments',     TRUE),
(6,  1, 1, 'Clinical',  'Encounters',       'Gold', 'FactEncounters',       'Incremental', 'LastModifiedDateTime', '1900-01-01 00:00:00', '/Production/FactEncounters',       TRUE),
(7,  1, 1, 'Clinical',  'BedAssignments',   'Gold', 'FactBedAssignments',   'Incremental', 'LastModifiedDateTime', '1900-01-01 00:00:00', '/Production/FactBedAssignments',   TRUE),
(8,  1, 1, 'Clinical',  'MedicationOrders', 'Gold', 'FactMedicationOrders', 'Incremental', 'LastModifiedDateTime', '1900-01-01 00:00:00', '/Production/FactMedicationOrders', TRUE),
(9,  1, 1, 'Clinical',  'LabOrders',        'Gold', 'FactLabOrders',        'Incremental', 'LastModifiedDateTime', '1900-01-01 00:00:00', '/Production/FactLabOrders',        TRUE),
(10, 1, 1, 'Clinical',  'Procedures',       'Gold', 'FactProcedures',       'Incremental', 'LastModifiedDateTime', '1900-01-01 00:00:00', '/Production/FactProcedures',       TRUE),
(11, 1, 1, 'Financial', 'BillingInvoices',   'Gold', 'FactBillingInvoices',  'Incremental', 'LastModifiedDateTime', '1900-01-01 00:00:00', '/Production/FactBillingInvoices',  TRUE);


-- =========================================================================
-- LEVEL 4: SEEDING SCHEMAS & FIELD DICTIONARIES (Source Data Definitions)
-- =========================================================================

-- 7. Registering Key Sample Fields mapping to core source profiles (Example: Clinical.Patients = TableID 4)
/*
INSERT INTO clinicalforge.metadata.SourceTableFields 
(FieldID, TableID, CustomerProductID, FieldName, DataType, IsPrimaryKey, IsSensitivePHI)
VALUES 
(401, 4, 1001, 'PatientID',            'INT',       TRUE,  FALSE),
(402, 4, 1001, 'MRN',                  'VARCHAR',   FALSE, FALSE),
(403, 4, 1001, 'NationalID_SSN',       'VARCHAR',   FALSE, TRUE),  -- Flagged for PII hashing
(404, 4, 1001, 'FirstName',            'VARCHAR',   FALSE, TRUE),  -- Flagged for PII obfuscation
(405, 4, 1001, 'LastName',             'VARCHAR',   FALSE, TRUE),  -- Flagged for PII obfuscation
(406, 4, 1001, 'DateOfBirth',          'DATE',      FALSE, FALSE),
(407, 4, 1001, 'LastModifiedDateTime', 'TIMESTAMP', FALSE, FALSE);
*/

-- =========================================================================
-- LEVEL 5: SEEDING CUSTOMER WAREHOUSE TABLES ORCHESTRATION MATRIX
-- =========================================================================

-- 8. Explicit mapping of Warehouse Destination Execution Methods
INSERT INTO clinicalforge.metadata.CustomerWarehouseTables 
(WarehouseTableID, CustomerProductID, TargetSchema, WarehouseTableName, LoadMethod, WatermarkColumn, IsActive, CreatedDateTime)
VALUES 
(1, 1, 'Gold', 'DimFacilities',        'FullRefresh',          'LastModifiedDateTime', TRUE, '2026-09-14 23:50:00'),
(2, 1, 'Gold', 'DimBeds',              'FullRefresh',          'LastModifiedDateTime', TRUE, '2026-09-14 23:50:00'),
(3, 1, 'Gold', 'DimPractitioners',     'IncrementalWatermark', 'LastModifiedDateTime', TRUE, '2026-09-14 23:50:00'),
(4, 1, 'Gold', 'DimPatients',          'IncrementalWatermark', 'LastModifiedDateTime', TRUE, '2026-09-14 23:50:00'),
(5, 1, 'Gold', 'FactAppointments',     'IncrementalWatermark', 'LastModifiedDateTime', TRUE, '2026-09-14 23:50:00'),
(6, 1, 'Gold', 'FactEncounters',       'IncrementalWatermark', 'LastModifiedDateTime', TRUE, '2026-09-14 23:50:00'),
(7, 1, 'Gold', 'FactBedAssignments',   'IncrementalWatermark', 'LastModifiedDateTime', TRUE, '2026-09-14 23:50:00'),
(8, 1, 'Gold', 'FactMedicationOrders', 'IncrementalWatermark', 'LastModifiedDateTime', TRUE, '2026-09-14 23:50:00'),
(9, 1, 'Gold', 'FactLabOrders',        'IncrementalWatermark', 'LastModifiedDateTime', TRUE, '2026-09-14 23:50:00'),
(10, 1, 'Gold', 'FactProcedures',       'IncrementalWatermark', 'LastModifiedDateTime', TRUE, '2026-09-14 23:50:00'),
(11, 1, 'Gold', 'FactBillingInvoices',  'IncrementalWatermark', 'LastModifiedDateTime', TRUE, '2026-09-14 23:50:00');



-- Registering the Unified Telemetry target within your data warehouse configuration matrix
INSERT INTO clinicalforge.metadata.CustomerWarehouseTables 
(WarehouseTableID, CustomerProductID, TargetSchema, WarehouseTableName, LoadMethod, WatermarkColumn, IsActive, CreatedDateTime)
VALUES 
(12, 1, 'Gold', 'FactUnifiedPatientTelemetry', 'AppendStream', 'EnqueuedDateTime', TRUE, '2026-09-14 23:55:00');
