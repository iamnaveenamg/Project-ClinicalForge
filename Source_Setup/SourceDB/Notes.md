Real-Time Streaming Event Tables List

1. Clinical Orders Domain (High Priority for Streaming)
These tables record direct medical actions that need immediate downstream processing (e.g., alerting the pharmacy or updating lab queues).

--Clinical.MedicationOrders
Kafka/EventHub Topic: clinicalforge.orders.medication
Event Payload Type: Prescription Creation, Order Modification, Discontinuations.

--Clinical.LabOrders
Kafka/EventHub Topic: clinicalforge.orders.labs
Event Payload Type: Lab Requests, Sample Collections, Verified Lab Results.

--Clinical.Procedures
Kafka/EventHub Topic: clinicalforge.orders.procedures
Event Payload Type: Surgical Scheduling, OR Room Check-in, Surgery Completions.

2. Patient Flow & Telemetry Domain
These streams capture patient movement and live biometric feeds across the hospital.

--Clinical.Encounters
Kafka/EventHub Topic: clinicalforge.clinical.encounters
Event Payload Type: ER Admissions, Check-ins, Patient Discharges.

--Clinical.BedAssignments
Kafka/EventHub Topic: clinicalforge.clinical.bed-tracking
Event Payload Type: ICU Bed Transfers, Room Assignments.

--Telemetry Feed (No static table — pure streaming)
Kafka/EventHub Topic: clinicalforge.telemetry.patient-vitals
Event Payload Type: Continuous streaming heart rate, SpO2, and respiratory metrics.

3. Financial Ingestion Domain

--Financial.BillingInvoices
Kafka/EventHub Topic: clinicalforge.financial.invoices
Event Payload Type: Real-time invoice generation, payments, and adjudication status.




------------------------
### 📡 2. The Single, Unified Real-Time Streaming Table
Instead of flooding the transactional database with millions of rows per minute from biometric devices, all telemetry targets **Azure Event Hubs / Kafka** under the topic `clinicalforge.telemetry.patient-vitals`. 

Databricks processes this stream continuously and appends it to a **single, unified Delta Lake table** with implicit foreign key relationships back to the master database.

#### Schema Layout of the Unified Telemetry Table (Target Destination)
```sql
CREATE TABLE Clinical.UnifiedPatientTelemetry (
    TelemetryID VARCHAR(50) NOT NULL,         -- Generated Unique Event UUID
    EventHubOffset BIGINT NOT NULL,           -- Event broker sequence offset
    EnqueuedDateTime DATETIME2(3) NOT NULL,   -- Kafka/Event Hub ingestion time
    
    -- Strict Relational Logical Links
    PatientID INT NOT NULL,                   -- Maps directly back to Clinical.Patients
    EncounterID INT NOT NULL,                 -- Maps directly back to Clinical.Encounters
    DeviceID VARCHAR(50) NOT NULL,            -- Unique biometric hardware ID
    
    -- Flattened Real-Time Biometric Metrics
    HeartRate INT NULL,                       -- Unit: bpm
    OxygenSaturation INT NULL,                -- Unit: % (SpO2)
    SystolicBloodPressure INT NULL,           -- Unit: mmHg
    DiastolicBloodPressure INT NULL,          -- Unit: mmHg
    RespiratoryRate INT NULL,                 -- Unit: rpm
    BodyTemperature DECIMAL(4,1) NULL,        -- Unit: °C
    
    -- Processing Constraints
    IngestionTimestamp DATETIME2(3) DEFAULT SYSUTCDATETIME() NOT NULL
) 
USING DELTA -- Configured as a Delta table inside Databricks Lakehouse
PARTITIONED BY (PatientID); -- Optimized for deep patient analytical lookup performance