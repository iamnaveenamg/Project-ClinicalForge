# Runtime Parameters in Spark Declarative Pipelines

## Overview

This guide explains how to pass and use runtime parameters (like `customer_code`) in your Spark Declarative Pipelines. All your dimension, fact, and streaming tables now support dynamic customer code configuration.

## Parameter Name Convention

**Parameter Name**: `customer_code`  
**Default Value**: `BOSHOSP`  
**Case Sensitive**: Yes (use lowercase `customer_code`)

## How to Pass Parameters

### Method 1: Pipeline UI (Recommended)

1. Open your pipeline in the Databricks UI
2. Click **"Start"** or **"Run"**
3. In the **"Pipeline Parameters"** section, add:
   ```json
   {
     "customer_code": "BOSHOSP"
   }
   ```
4. Click **"Start"** to run

**To change customer:**
```json
{
  "customer_code": "CLIENTA"
}
```

### Method 2: Databricks API

```python
import requests
import json

# Pipeline configuration
PIPELINE_ID = "9394bf66-190b-4652-a31a-8314d9d3e55a"
DATABRICKS_HOST = "https://your-workspace.databricks.com"
TOKEN = "your-token"

# Start pipeline with parameters
url = f"{DATABRICKS_HOST}/api/2.0/pipelines/{PIPELINE_ID}/updates"
headers = {
    "Authorization": f"Bearer {TOKEN}",
    "Content-Type": "application/json"
}

payload = {
    "full_refresh": False,
    "parameters": {
        "customer_code": "BOSHOSP"
    }
}

response = requests.post(url, headers=headers, json=payload)
print(response.json())
```

### Method 3: Databricks CLI

```bash
# Install Databricks CLI
pip install databricks-cli

# Configure authentication
databricks configure --token

# Start pipeline with parameters
databricks pipelines start-update \
  --pipeline-id 9394bf66-190b-4652-a31a-8314d9d3e55a \
  --parameters '{"customer_code": "BOSHOSP"}'
```

### Method 4: Python SDK

```python
from databricks.sdk import WorkspaceClient

w = WorkspaceClient()

# Start pipeline update with parameters
update = w.pipelines.start_update(
    pipeline_id="9394bf66-190b-4652-a31a-8314d9d3e55a",
    full_refresh=False,
    parameters={"customer_code": "BOSHOSP"}
)

print(f"Update ID: {update.update_id}")
```

## How to Access Parameters in Code

### Standard Pattern (Used in All Files)

```python
# At the top of your pipeline file
try:
    CUSTOMER_CODE = spark.conf.get("customer_code", "BOSHOSP")
except:
    CUSTOMER_CODE = "BOSHOSP"

print(f"Running pipeline for customer: {CUSTOMER_CODE}")
```

### Files Currently Using This Pattern

1. **metadata_driven_tables.py** (utility)
   ```python
   def get_customer_code():
       try:
           return spark.conf.get("customer_code", "BOSHOSP")
       except:
           return "BOSHOSP"
   ```

2. **Dimension-Clinical.py**
   - Uses `get_customer_code()` from utility
   - Automatically queries metadata for the specified customer

3. **Fact-Clinical.py**
   - Uses `get_customer_code()` from utility
   - Automatically queries metadata for the specified customer

4. **PatientTelemetry.py**
   - Directly accesses `spark.conf.get("customer_code", "BOSHOSP")`
   - Uses customer code to fetch Event Hub configuration

## Use Cases

### Use Case 1: Process Different Customers

**Process BOSHOSP:**
```json
{"customer_code": "BOSHOSP"}
```

**Process CLIENTA:**
```json
{"customer_code": "CLIENTA"}
```

**Process CLIENTB:**
```json
{"customer_code": "CLIENTB"}
```

### Use Case 2: Daily Scheduled Jobs

Create separate jobs for each customer:

```python
# Job 1: BOSHOSP - Daily 8 AM
{
  "schedule": {"quartz_cron_expression": "0 0 8 * * ?", "timezone_id": "UTC"},
  "parameters": {"customer_code": "BOSHOSP"}
}

# Job 2: CLIENTA - Daily 9 AM
{
  "schedule": {"quartz_cron_expression": "0 0 9 * * ?", "timezone_id": "UTC"},
  "parameters": {"customer_code": "CLIENTA"}
}
```

### Use Case 3: Ad-hoc Testing

Test with a specific customer:
```json
{"customer_code": "TESTCLIENT"}
```

## How Parameters Flow Through Your Pipeline

```
Pipeline Start (with customer_code parameter)
    ↓
Utility: get_customer_code() reads parameter
    ↓
Metadata Query: Filtered by customer_code
    ↓
┌─────────────────────┬──────────────────────────┐
│                     │                          │
Dimension Tables      Fact Tables      PatientTelemetry
│                     │                          │
├─ DimBeds            ├─ FactAppointments       └─ Event Hub Config
├─ DimFacilities      ├─ FactBedAssignments        (fetched by customer_code)
├─ DimPatients        ├─ FactBillingInvoices
└─ DimPractitioners   ├─ FactEncounters
                      ├─ FactLabOrders
                      ├─ FactMedicationOrders
                      └─ FactProcedures
    ↓                     ↓                          ↓
Source Tables:
clinicalforge.silver.{customer_code}_Beds
clinicalforge.silver.{customer_code}_Facilities
clinicalforge.silver.{customer_code}_Patients
... etc ...
```

## Validation

### Check Current Parameter Value

Add this to any pipeline file to verify:

```python
print(f"Current customer_code: {spark.conf.get('customer_code', 'NOT SET')}")
```

### Query Metadata to See Available Customers

```sql
SELECT DISTINCT
    C.CustomerCode,
    C.CustomerName,
    COUNT(DISTINCT CWHT.WarehouseTableName) as TableCount
FROM clinicalforge.metadata.customerwarehousetables AS CWHT
LEFT JOIN clinicalforge.metadata.CustomerProduct AS CP 
    ON CP.CustomerProductID = CWHT.CustomerProductID
LEFT JOIN clinicalforge.metadata.Customers AS C 
    ON CP.CustomerID = C.CustomerID
WHERE CWHT.isActive = 'true'
GROUP BY C.CustomerCode, C.CustomerName
ORDER BY C.CustomerCode
```

## Common Issues

### Issue 1: Parameter Not Passed

**Symptom**: Pipeline always uses default "BOSHOSP"

**Solution**: Verify parameter format:
```json
{"customer_code": "CLIENTA"}
```
NOT:
```json
{"CustomerCode": "CLIENTA"}  // Wrong case
{"customer-code": "CLIENTA"}  // Wrong separator
```

### Issue 2: Customer Not Found in Metadata

**Symptom**: Error "No metadata found for CustomerCode"

**Solution**: 
1. Check customer exists in metadata:
   ```sql
   SELECT * FROM clinicalforge.metadata.Customers 
   WHERE CustomerCode = 'CLIENTA'
   ```
2. Check customer has active tables:
   ```sql
   SELECT COUNT(*) FROM clinicalforge.metadata.customerwarehousetables CWHT
   JOIN clinicalforge.metadata.CustomerProduct CP ON CWHT.CustomerProductID = CP.CustomerProductID
   JOIN clinicalforge.metadata.Customers C ON CP.CustomerID = C.CustomerID
   WHERE C.CustomerCode = 'CLIENTA' AND CWHT.isActive = 'true'
   ```

### Issue 3: Source Tables Not Found

**Symptom**: Error "Table or view not found: clinicalforge.silver.{customer_code}_{table}"

**Solution**: Verify silver layer tables exist:
```sql
SHOW TABLES IN clinicalforge.silver LIKE '{customer_code}_*'
```

Example:
```sql
SHOW TABLES IN clinicalforge.silver LIKE 'BOSHOSP_*'
```

## Best Practices

1. **Always provide default**: Use `spark.conf.get("customer_code", "BOSHOSP")` with fallback
2. **Consistent naming**: Use lowercase `customer_code` everywhere
3. **Validate early**: Check customer exists in metadata before processing
4. **Log parameter**: Print customer_code at pipeline start for debugging
5. **Document customers**: Maintain list of valid customer codes
6. **Test thoroughly**: Test pipeline with multiple customers before production

## Environment-Specific Parameters

### Development
```json
{"customer_code": "TESTCLIENT"}
```

### Staging
```json
{"customer_code": "BOSHOSP"}
```

### Production
```json
{"customer_code": "BOSHOSP"}
```
or
```json
{"customer_code": "CLIENTA"}
```

## Multi-Customer Processing Strategy

### Option 1: Separate Pipeline Runs (Recommended)

Run the same pipeline multiple times with different parameters:

```python
customers = ["BOSHOSP", "CLIENTA", "CLIENTB"]

for customer in customers:
    w.pipelines.start_update(
        pipeline_id="9394bf66-190b-4652-a31a-8314d9d3e55a",
        parameters={"customer_code": customer}
    )
```

### Option 2: Scheduled Jobs

Create a job with multiple tasks, one per customer:

```json
{
  "name": "Multi-Customer ETL",
  "tasks": [
    {
      "task_key": "boshosp_etl",
      "pipeline_task": {
        "pipeline_id": "9394bf66-190b-4652-a31a-8314d9d3e55a",
        "parameters": {"customer_code": "BOSHOSP"}
      }
    },
    {
      "task_key": "clienta_etl",
      "pipeline_task": {
        "pipeline_id": "9394bf66-190b-4652-a31a-8314d9d3e55a",
        "parameters": {"customer_code": "CLIENTA"}
      },
      "depends_on": [{"task_key": "boshosp_etl"}]
    }
  ]
}
```

## Support

For parameter-related issues:
1. Check parameter spelling: `customer_code` (lowercase, underscore)
2. Verify customer exists in metadata
3. Check silver layer source tables exist
4. Review pipeline event logs for parameter values
5. Test with default customer (BOSHOSP) first
