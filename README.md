# Project-ClinicalForge 🏥

**Healthcare Data Integration & Analytics Platform**

A comprehensive end-to-end data pipeline solution for ingesting, processing, and analyzing healthcare data from multiple sources into a unified Databricks Lakehouse architecture.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Features](#features)
- [Setup & Configuration](#setup--configuration)
- [Pipeline Components](#pipeline-components)
- [Monitoring & Notifications](#monitoring--notifications)
- [Usage](#usage)
- [Contributing](#contributing)

---

## 🎯 Overview

ClinicalForge is a multi-tenant healthcare data platform that:
- **Automates** customer onboarding and data provisioning
- **Ingests** healthcare data from various source systems (SQL Server, PostgreSQL, etc.)
- **Processes** data through Bronze → Silver → Gold layers
- **Delivers** analytics-ready datasets for consumption
- **Monitors** pipeline execution with automated email notifications

### Key Capabilities
- ✅ Multi-customer support with isolated data namespaces
- ✅ Metadata-driven pipeline configuration
- ✅ Real-time streaming via Event Hubs/Kafka
- ✅ Batch processing with Azure Data Factory
- ✅ Unity Catalog governance and lineage
- ✅ Automated pipeline run tracking and alerting

---

## 🏗️ Architecture

```
[ Step 1: Source DB ] ──► [ Step 2: Metadata Config ] ──► [ Step 3: Event Hubs / Kafka ]
                                                                     │
 ┌───────────────────────────────────────────────────────────────────┘
 ▼
[ Step 4: ADF Batch ] ──► [ Step 5: Databricks Lakehouse ] ──► [ Step 6: Gold DWH ] ──► [ Step 7: Consumption ]
```

### Pipeline Stages

| Stage | Component | Description |
|-------|-----------|-------------|
| **1** | Source DB | Healthcare source systems (FHIR, HL7, EHR databases) |
| **2** | Metadata Config | Unity Catalog metadata tables for configuration |
| **3** | Event Hubs/Kafka | Real-time streaming ingestion layer |
| **4** | ADF Batch | Azure Data Factory orchestration for batch loads |
| **5** | Databricks Lakehouse | Delta Lake processing (Bronze/Silver/Gold) |
| **6** | Gold DWH | Analytics-ready data warehouse |
| **7** | Consumption | BI dashboards, ML models, reporting |

---

## 📁 Project Structure

```
Project-ClinicalForge/
├── ETL_Setup/
│   ├── OnBoarding_Setup/
│   │   ├── MasterOnboard_Pipeline          # Customer provisioning pipeline
│   │   ├── 00_Setup_Secret_Scope          # Secret management setup
│   │   └── onboard_customer.json          # Customer configuration template
│   └── Pipeline_Execution/
│       └── EmailForCustomer               # Email notification system
├── Volumes/
│   └── clinicalforge/metadata/onboardingfile/
│       └── Customer_Onboarding/           # Customer config files
├── Metadata/
│   ├── clinicalforge.metadata.pipelinerun # Pipeline execution tracking
│   ├── clinicalforge.metadata.customer    # Customer master data
│   └── Stored Procedures/
│       └── sp_ProvisionNewCustomer        # Customer provisioning SP
└── README.md                              # This file
```

---

## ✨ Features

### 1. **Automated Customer Onboarding**
- JSON-driven configuration for new customers
- Stored procedure provisioning workflow
- Automatic schema and table creation
- Connection string and credential management

### 2. **Metadata-Driven Processing**
- Unity Catalog metadata tables:
  - `clinicalforge.metadata.customer` - Customer details
  - `clinicalforge.metadata.pipelinerun` - Run tracking
  - `clinicalforge.metadata.connectiondetails` - Connection configs

### 3. **Healthcare Data Tables**
Supports ingestion of common healthcare entities:
- 🏥 Facilities
- 🛏️ Beds & BedAssignments
- 👨‍⚕️ Practitioners
- 👤 Patients
- 📅 Appointments
- 🏥 Encounters
- 💊 MedicationOrders
- 🔬 LabOrders
- ⚕️ Procedures
- 💰 BillingInvoices

### 4. **Pipeline Monitoring**
- Real-time execution tracking
- Email notifications with detailed run results
- Success/failure status per table
- Records ingested count
- Duration and error logging

---

## 🚀 Setup & Configuration

### Prerequisites
- Databricks workspace (AWS/Azure/GCP)
- Unity Catalog enabled
- Email SMTP access (Gmail App Password recommended)
- Source database credentials

### 1. Initial Setup

```bash
# Clone or import the project into your Databricks workspace
# Default path: /Users/<your-email>/Project-ClinicalForge/
```

### 2. Configure Secrets (for Email Notifications)

Run the `00_Setup_Secret_Scope` notebook or use CLI:

```bash
# Create secret scope
databricks secrets create-scope gmail_api_key

# Add Gmail App Password
databricks secrets put-secret gmail_api_key secret_value
```

### 3. Prepare Customer Onboarding Config

Edit `/Volumes/clinicalforge/metadata/onboardingfile/Customer_Onboarding/onboard_customer.json`:

```json
{
  "Customer": {
    "CustomerCode": "BOSHOSP",
    "CustomerName": "Boston Hospital",
    "SubscriptionTier": "Premium"
  },
  "ConnectionDetails": {
    "TargetPlatform": "SQLServer",
    "HostServer": "sqlserver.database.windows.net",
    "DatabaseName": "healthdb",
    "UserName": "admin",
    "Password": "<secure-password>"
  },
  "EventHub": {
    "NamespaceName": "clinicalforge-eh",
    "TopicName": "healthcare-events",
    "ConnSecretStringEH": "Endpoint=sb://..."
  },
  "Product": {
    "ProductCode": "FHIR",
    "ProductName": "FHIR Data Integration"
  }
}
```

### 4. Run Customer Onboarding

Execute the `MasterOnboard_Pipeline` notebook with parameter:
```python
CustomerOnboard = "Onboard"  # Or specify existing CustomerCode
```

---

## 🔧 Pipeline Components

### MasterOnboard_Pipeline
**Purpose:** Provisions new customers and initializes metadata

**Key Steps:**
1. Reads JSON configuration from UC Volume
2. Flattens nested customer data
3. Calls `sp_ProvisionNewCustomer` stored procedure
4. Sets task values for downstream jobs

**Parameters:**
- `CustomerOnboard`: "Onboard" (new customer) or CustomerCode (existing)

### EmailForCustomer
**Purpose:** Sends pipeline execution summary emails

**Features:**
- Queries `clinicalforge.metadata.pipelinerun` table
- Generates HTML email with all tables processed
- Shows status, record counts, duration, errors
- Color-coded success/failure indicators

**Configuration:**
```python
SENDER_EMAIL = "your-email@gmail.com"
CUSTOMER_EMAIL = "customer@example.com"
SENDER_PASSWORD = dbutils.secrets.get("gmail_api_key", "secret_value")
```

### Stored Procedure: sp_ProvisionNewCustomer
**Purpose:** Provisions customer metadata and connections

**Parameters:**
- Customer details (code, name, tier)
- Connection details (platform, host, credentials)
- Event Hub configuration
- Product information

---

## 📊 Monitoring & Notifications

### Pipeline Run Tracking

All pipeline executions are logged in:
```sql
SELECT * FROM clinicalforge.metadata.pipelinerun 
WHERE RunID = '<run_id>'
```

**Tracked Metrics:**
- RunID, CustomerProductID, TableID
- HealthClientID, TargetTableName
- StartDateTime, EndDateTime
- RecordsIngested, RunStatus
- ErrorMessage (if failed)

### Email Notifications

**Subject Format:**
```
Pipeline SUCCESS - boshosp - 11 Tables - Run #1234
```

**Email Content:**
- Overall execution summary
- Total tables processed
- Total records ingested
- Detailed table-by-table results
- Timestamps and durations
- Error messages (if any)

---

## 💻 Usage

### Query Pipeline Results

```sql
-- Get latest run for a customer
SELECT * 
FROM clinicalforge.metadata.pipelinerun 
WHERE HealthClientID = 'boshosp'
ORDER BY StartDateTime DESC
LIMIT 1
```

```sql
-- Calculate success rate by table
SELECT 
  TargetTableName,
  COUNT(*) AS total_runs,
  SUM(CASE WHEN RunStatus = 'SUCCESS' THEN 1 ELSE 0 END) AS successful_runs,
  ROUND(100.0 * SUM(CASE WHEN RunStatus = 'SUCCESS' THEN 1 ELSE 0 END) / COUNT(*), 2) AS success_rate
FROM clinicalforge.metadata.pipelinerun
GROUP BY TargetTableName
ORDER BY success_rate DESC
```

### Trigger Email Notification

```python
# Run the EmailForCustomer notebook
run_id = "1234"  # Your pipeline run ID
dbutils.notebook.run("/Path/To/EmailForCustomer", 0, {"run_id": run_id})
```

---

## 🤝 Contributing

### Development Workflow
1. Create feature branch for changes
2. Test with sample customer data
3. Update documentation
4. Submit for review

### Code Standards
- Follow PEP 8 for Python code
- Use descriptive variable names
- Add comments for complex logic
- Include error handling
- Log all pipeline activities

---

## 📝 License

Proprietary - ClinicalForge Healthcare Data Platform

---

## 📞 Support

For questions or issues:Concat on Linkedin

---

**Built with ❤️ using Databricks on Azure**