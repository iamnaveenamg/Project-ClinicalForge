# Databricks notebook source
# DBTITLE 1,Orchestrate Source → Bronze → Silver Pipeline
# Databricks notebook source
# =====================================================
# Orchestrator: Loop Through Tables and Execute Pipelines
# =====================================================

import json
from concurrent.futures import ThreadPoolExecutor, as_completed

# =====================================================
# 1️⃣ Get Widgets
# =====================================================

dbutils.widgets.text("CustomerCode_Source", "BOSHOSP")
CustomerCode_Source = dbutils.widgets.get("CustomerCode_Source")

dbutils.widgets.text("run_id", "")
run_id = dbutils.widgets.get("run_id")

if not run_id:
    # If no run_id provided, generate one from the job context
    try:
        run_id = dbutils.notebook.entry_point.getDbutils().notebook().getContext().tags().get("jobId").get() + "_" + dbutils.notebook.entry_point.getDbutils().notebook().getContext().tags().get("idInJob").get()
    except:
        run_id = str(spark.sql("SELECT current_timestamp()").collect()[0][0])

print(f"CustomerCode_Source: {CustomerCode_Source}")
print(f"Run ID: {run_id}")

# =====================================================
# 2️⃣ Read Metadata from Previous Task
# =====================================================

# Get the tables metadata from the previous task
try:
    # Try to get from task values (when running in a job)
    tables_metadata_str = dbutils.jobs.taskValues.get(
        taskKey="ReadTablesList-ClinicalForge",
        key="tables_metadata",
        debugValue="[]"
    )
    tables_metadata = json.loads(tables_metadata_str) if isinstance(tables_metadata_str, str) else tables_metadata_str
except:
    # Fallback: query the metadata directly
    print("⚠️  Could not get task values, querying metadata directly...")
    tables_df = spark.sql(f"""
        SELECT TL.CustomerProductID, TL.TableID, C.CustomerName, C.CustomerCode, 
               TL.SourceSchema, TL.SourceTablename, TL.ExtractionType, 
               TL.WatermarkColumn, TL.LastExtractWatermark, 'Bronze' as TargetSchema,
               TL.IsActive
        FROM clinicalforge.metadata.TablesList as TL
        LEFT JOIN clinicalforge.metadata.ConnectionDetails as CD 
            ON TL.SourceConnectionID=CD.ConnectionID AND TL.CustomerProductID=CD.CustomerProductID
        LEFT JOIN clinicalforge.metadata.CustomerProduct as CP 
            ON CP.CustomerProductID=TL.CustomerProductID
        LEFT JOIN clinicalforge.metadata.customers as C 
            ON CP.CustomerID=C.CustomerID
        WHERE LOWER(C.CustomerCode) = LOWER('{CustomerCode_Source}') AND TL.IsActive = true
        ORDER BY TL.TableID
    """)
    
    rows = tables_df.collect()
    tables_metadata = [
        {
            "CustomerProductID": str(row.CustomerProductID) if row.CustomerProductID is not None else "",
            "TableID": str(row.TableID) if row.TableID is not None else "",
            "SourceTablename": str(row.SourceTablename) if row.SourceTablename is not None else "",
            "SourceSchema": str(row.SourceSchema) if row.SourceSchema is not None else "",
            "CustomerName": str(row.CustomerName) if row.CustomerName is not None else "",
            "CustomerCode": str(row.CustomerCode) if row.CustomerCode is not None else "",
            "ExtractionType": str(row.ExtractionType) if row.ExtractionType is not None else "",
            "WatermarkColumn": str(row.WatermarkColumn) if row.WatermarkColumn is not None else "",
            "LastExtractWatermark": str(row.LastExtractWatermark) if row.LastExtractWatermark is not None else "",
            "TargetSchema": str(row.TargetSchema) if row.TargetSchema is not None else "",
            "IsActive": str(row.IsActive) if row.IsActive is not None else ""
        }
        for row in rows
    ]

print(f"\n📊 Found {len(tables_metadata)} tables to process")
for table in tables_metadata:
    print(f"  - {table['SourceTablename']}")

# COMMAND ----------

# DBTITLE 1,Execute Source → Bronze for Each Table
# =====================================================
# 3️⃣ Execute Source → Bronze for Each Table
# =====================================================

print("\n" + "="*60)
print("PHASE 1: Source → Bronze")
print("="*60)

failed_tables_source_bronze = []
successful_tables_source_bronze = []

for table_meta in tables_metadata:
    table_name = table_meta['SourceTablename']
    print(f"\n🔄 Processing {table_name}: Source → Bronze...")
    
    try:
        # Convert dict to JSON string for passing to notebook
        table_metadata_json = json.dumps(table_meta)
        
        # Run 01_Source_Bronze notebook
        result = dbutils.notebook.run(
            "/Users/naveenreddymg408@gmail.com/Project-ClinicalForge/ETL_Setup/Source_BronzeLayer_Setup/01_Source_Bronze",
            timeout_seconds=3600,  # 60 minutes timeout
            arguments={
                "table_metadata": table_metadata_json,
                "CustomerCode_Source": CustomerCode_Source,
                "run_id": run_id
            }
        )
        
        print(f"✅ {table_name}: Source → Bronze completed successfully")
        successful_tables_source_bronze.append(table_name)
        
    except Exception as e:
        error_msg = str(e)
        print(f"❌ {table_name}: Source → Bronze failed: {error_msg}")
        failed_tables_source_bronze.append({"table": table_name, "error": error_msg})
        # Continue with next table even if this one fails

print(f"\n✅ Source → Bronze: {len(successful_tables_source_bronze)} successful")
if failed_tables_source_bronze:
    print(f"❌ Source → Bronze: {len(failed_tables_source_bronze)} failed")
    for failure in failed_tables_source_bronze:
        print(f"  - {failure['table']}: {failure['error'][:100]}")

# COMMAND ----------

# DBTITLE 1,Execute Bronze → Silver for Each Table
# =====================================================
# 4️⃣ Execute Bronze → Silver for Each Table
# =====================================================

print("\n" + "="*60)
print("PHASE 2: Bronze → Silver")
print("="*60)

failed_tables_bronze_silver = []
successful_tables_bronze_silver = []

for table_meta in tables_metadata:
    table_name = table_meta['SourceTablename']
    
    # Skip if Source → Bronze failed
    if any(f['table'] == table_name for f in failed_tables_source_bronze):
        print(f"\n⏭️  Skipping {table_name}: Bronze → Silver (Source → Bronze failed)")
        continue
    
    print(f"\n🔄 Processing {table_name}: Bronze → Silver...")
    
    try:
        # Convert dict to JSON string for passing to notebook
        table_metadata_json = json.dumps(table_meta)
        
        # Run Bronze_SilverLayer notebook
        result = dbutils.notebook.run(
            "/Users/naveenreddymg408@gmail.com/Project-ClinicalForge/ETL_Setup/Bronze_SilverLayer_Setup/Bronze_SilverLayer",
            timeout_seconds=3600,  # 60 minutes timeout
            arguments={
                "table_metadata": table_metadata_json,
                "CustomerCode_Source": CustomerCode_Source,
                "run_id": run_id
            }
        )
        
        print(f"✅ {table_name}: Bronze → Silver completed successfully")
        successful_tables_bronze_silver.append(table_name)
        
    except Exception as e:
        error_msg = str(e)
        print(f"❌ {table_name}: Bronze → Silver failed: {error_msg}")
        failed_tables_bronze_silver.append({"table": table_name, "error": error_msg})
        # Continue with next table even if this one fails

print(f"\n✅ Bronze → Silver: {len(successful_tables_bronze_silver)} successful")
if failed_tables_bronze_silver:
    print(f"❌ Bronze → Silver: {len(failed_tables_bronze_silver)} failed")
    for failure in failed_tables_bronze_silver:
        print(f"  - {failure['table']}: {failure['error'][:100]}")

# COMMAND ----------

# DBTITLE 1,Summary Report
# =====================================================
# 5️⃣ Final Summary
# =====================================================

print("\n" + "="*60)
print("FINAL SUMMARY")
print("="*60)

total_tables = len(tables_metadata)
print(f"\n📊 Total tables processed: {total_tables}")
print(f"\n✅ Source → Bronze: {len(successful_tables_source_bronze)}/{total_tables} successful")
print(f"✅ Bronze → Silver: {len(successful_tables_bronze_silver)}/{total_tables} successful")

if failed_tables_source_bronze:
    print(f"\n❌ Source → Bronze failures ({len(failed_tables_source_bronze)}):")
    for failure in failed_tables_source_bronze:
        print(f"  - {failure['table']}")

if failed_tables_bronze_silver:
    print(f"\n❌ Bronze → Silver failures ({len(failed_tables_bronze_silver)}):")
    for failure in failed_tables_bronze_silver:
        print(f"  - {failure['table']}")

# Raise error if any failures
if failed_tables_source_bronze or failed_tables_bronze_silver:
    raise Exception(f"Pipeline completed with failures: {len(failed_tables_source_bronze)} Source→Bronze, {len(failed_tables_bronze_silver)} Bronze→Silver")
else:
    print("\n🎉 All tables processed successfully!")

# COMMAND ----------

