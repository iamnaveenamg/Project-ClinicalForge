# Metadata-Driven Dimension and Fact Tables

## Overview

This pipeline implements a **metadata-driven architecture** where Dimension and Fact tables are automatically configured based on metadata stored in `clinicalforge.metadata` schema. The CustomerCode is passed at runtime, allowing the same pipeline to process data for multiple customers.

## Architecture

```
Metadata Tables (clinicalforge.metadata)
    ↓
Metadata Query (dimension_metadata / fact_metadata)
    ↓
Utility Functions (metadata_driven_tables.py)
    ↓
Dimension/Fact Tables (auto-configured by WarehouseTableName)
    ↓
Silver Layer Sources (clinicalforge.silver.{CustomerCode}_{SourceTableName})
```

## Key Components

### 1. Metadata Schema

The pipeline reads configuration from:
```sql
clinicalforge.metadata.customerwarehousetables
clinicalforge.metadata.TablesList
clinicalforge.metadata.CustomerProduct
clinicalforge.metadata.Customers
```

**Metadata Query:**
```sql
SELECT 
    CWHT.WarehouseTableID,
    CWHT.SourceTableID,
    C.CustomerCode,
    C.CustomerName,
    CWHT.TargetSchema,
    CWHT.WarehouseTableName,
    TL.SourceTableName,
    CWHT.LoadMethod,
    CWHT.isActive,
    CWHT.WatermarkColumn
FROM clinicalforge.metadata.customerwarehousetables AS CWHT
LEFT JOIN clinicalforge.metadata.TablesList AS TL 
    ON CWHT.CustomerProductID = TL.CustomerProductID 
    AND CWHT.WarehouseTableName = TL.WarehouseTableName 
    AND CWHT.SourceTableID = TL.TableID
LEFT JOIN clinicalforge.metadata.CustomerProduct AS CP 
    ON CP.CustomerProductID = CWHT.CustomerProductID
LEFT JOIN clinicalforge.metadata.Customers AS C 
    ON CP.CustomerID = C.CustomerID
WHERE C.CustomerCode = '{CustomerCode}'
    AND CWHT.isActive = 'true'
    AND CWHT.WatermarkColumn = 'LastModifiedDateTime'
ORDER BY CWHT.WarehouseTableID
```

### 2. Utility Functions (`transformations/utils/metadata_driven_tables.py`)

- `get_customer_code()` - Retrieves runtime customer code parameter
- `get_table_metadata_by_customer()` - Queries metadata for specific customer
- `build_source_dataframe()` - Creates DataFrame from silver layer based on metadata
- `get_all_dim_tables()` - Lists all dimension tables for current customer
- `get_all_fact_tables()` - Lists all fact tables for current customer

### 3. Dimension Tables (`transformations/Dimension-Clinical.py`)

- `dimension_metadata` - Metadata view for all dimension tables
- Template functions for streaming and batch dimensions
- Example dimensions: `DimPatient`, `DimLocation`, `DimProvider`

### 4. Fact Tables (`transformations/Fact-Clinical.py`)

- `fact_metadata` - Metadata view for all fact tables
- Template functions for streaming and batch facts
- Example facts: `FactPatientVitals`, `FactEncountersSummary`, `FactPatientVitalsEnriched`

## Usage

### Step 1: Configure Metadata

Ensure your metadata tables contain entries with:
- **CustomerCode**: Customer identifier (e.g., 'BOSHOSP')
- **WarehouseTableName**: Target table name (e.g., 'DimPatient', 'FactPatientVitals')
- **SourceTableName**: Source table name in silver layer
- **LoadMethod**: Either 'IncrementalWatermark' or 'FullRefresh'
- **WatermarkColumn**: Column for streaming watermark (e.g., 'LastModifiedDateTime')
- **isActive**: 'true' to include in processing

### Step 2: Verify Silver Layer Sources

Ensure tables exist with naming pattern:
```
clinicalforge.silver.{CustomerCode}_{SourceTableName}
```

Examples:
- `clinicalforge.silver.BOSHOSP_Patient`
- `clinicalforge.silver.BOSHOSP_PatientVitals`
- `clinicalforge.silver.BOSHOSP_Location`

### Step 3: Create Dimension/Fact Tables

For each `WarehouseTableName` in your metadata:

**For Streaming Tables (LoadMethod = 'IncrementalWatermark'):**
```python
@dp.table(
    comment="Auto-configured streaming dimension/fact",
    cluster_by_auto=True
)
def DimYourTableName():
    return _create_streaming_dimension("DimYourTableName")
```

**For Batch Tables (LoadMethod = 'FullRefresh'):**
```python
@dp.materialized_view(
    comment="Auto-configured batch dimension/fact",
    cluster_by_auto=True
)
def DimYourTableName():
    return _create_batch_dimension("DimYourTableName")
```

### Step 4: Run Pipeline with CustomerCode

**Method 1: Pipeline Parameters (Recommended)**
```json
{
  "customer_code": "BOSHOSP"
}
```

**Method 2: Spark Configuration**
```bash
spark-submit --conf spark.customer_code=BOSHOSP ...
```

**Method 3: Environment Variable**
```python
import os
os.environ['customer_code'] = 'BOSHOSP'
```

**Default**: If no parameter is provided, defaults to 'BOSHOSP'

### Step 5: Query Results

All tables include `_customer_code` column for tracking:
```sql
SELECT * FROM DimPatient WHERE _customer_code = 'BOSHOSP'
SELECT * FROM FactPatientVitals WHERE _customer_code = 'BOSHOSP'
```

## LoadMethod Options

### IncrementalWatermark (Streaming Table)
- Uses `spark.readStream` for streaming reads
- Applies watermark on `LastModifiedDateTime` (1 hour)
- Processes only new/changed data
- Best for: Large datasets, continuous updates, CDC patterns
- Decorator: `@dp.table()`

### FullRefresh (Materialized View)
- Uses `spark.read` for batch reads
- Fully recomputes on each refresh
- Best for: Small dimensions, reference data, aggregations
- Decorator: `@dp.materialized_view()`

## Adding Business Logic

### Deduplication
```python
@dp.table(comment="Dimension with deduplication")
def DimPatient():
    base_df = _create_streaming_dimension("DimPatient")
    return base_df.dropDuplicatesWithinWatermark(["patient_id", "_customer_code"])
```

### Transformations
```python
@dp.materialized_view(comment="Dimension with transformations")
def DimProvider():
    base_df = _create_batch_dimension("DimProvider")
    return (
        base_df
        .withColumn("full_name", F.concat_ws(" ", F.col("first_name"), F.col("last_name")))
        .filter(F.col("provider_id").isNotNull())
    )
```

### Aggregations
```python
@dp.materialized_view(comment="Aggregated fact")
def FactDailySummary():
    base_df = _create_batch_dimension("FactDailySummary")
    return (
        base_df
        .groupBy("_customer_code", "encounter_date", "location_id")
        .agg(
            F.count("encounter_id").alias("encounter_count"),
            F.countDistinct("patient_id").alias("unique_patients")
        )
    )
```

### Dimension Joins (Enriched Facts)
```python
@dp.table(comment="Enriched fact with dimension joins")
def FactPatientVitalsEnriched():
    vitals = spark.readStream.table("FactPatientVitals")
    patients = spark.read.table("DimPatient")
    
    return (
        vitals
        .join(
            patients,
            (vitals.patient_id == patients.patient_id) &
            (vitals._customer_code == patients._customer_code),
            "left"
        )
        .select(vitals["*"], patients.patient_name, patients.date_of_birth)
    )
```

## Multi-Customer Processing

To process multiple customers:

1. **Run separate pipeline updates** with different customer_code values
2. **Schedule separate jobs** for each customer
3. **Use append flows** to combine results if needed

## Troubleshooting

### Error: "No metadata found for WarehouseTableName"
- Check that metadata exists for the specified CustomerCode and WarehouseTableName
- Verify `isActive = 'true'` in metadata
- Verify `WatermarkColumn = 'LastModifiedDateTime'` in metadata

### Error: "Table or view not found: clinicalforge.silver.{CustomerCode}_{SourceTableName}"
- Verify silver layer table exists with correct naming pattern
- Check table permissions
- Ensure silver layer pipeline has run successfully

### Error: "customer_code parameter not found"
- Pass customer_code via pipeline parameters: `{"customer_code": "BOSHOSP"}`
- Or rely on default value: 'BOSHOSP'

## Best Practices

1. **Table Naming**: Use exact WarehouseTableName from metadata as function name
2. **Clustering**: Enable `cluster_by_auto=True` for all tables
3. **Customer Tracking**: Always include `_customer_code` column
4. **Data Quality**: Add expectations for critical business rules
5. **Documentation**: Add clear docstrings explaining source and transformations
6. **Testing**: Test with one customer before scaling to multiple

## Example Metadata Setup

```sql
INSERT INTO clinicalforge.metadata.customerwarehousetables
VALUES (
    1, -- WarehouseTableID
    101, -- SourceTableID
    'gold', -- TargetSchema
    'DimPatient', -- WarehouseTableName
    'IncrementalWatermark', -- LoadMethod
    'true', -- isActive
    'LastModifiedDateTime', -- WatermarkColumn
    1 -- CustomerProductID
);

INSERT INTO clinicalforge.metadata.TablesList
VALUES (
    101, -- TableID
    'Patient', -- SourceTableName (used as: BOSHOSP_Patient)
    1, -- CustomerProductID
    'DimPatient' -- WarehouseTableName
);
```

## Support

For questions or issues:
1. Check metadata configuration
2. Verify silver layer sources exist
3. Review pipeline event logs
4. Check customer_code parameter is passed correctly
