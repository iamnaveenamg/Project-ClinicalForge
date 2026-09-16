from pyspark.sql import functions as F, SparkSession
from typing import Dict, List, Optional

# Get SparkSession for utility file
spark = SparkSession.getActiveSession()

# ============================================================================
# Metadata-Driven Table Utilities
# ============================================================================
# These utilities help create dimension and fact tables dynamically based on
# metadata configuration with runtime customer code parameter support.
# ============================================================================

def get_customer_code():
    """
    Gets the runtime CustomerCode parameter.
    Defaults to 'BOSHOSP' if not provided.
    
    To pass at runtime:
    - Use pipeline parameters: {"customer_code": "BOSHOSP"}
    - Or set spark config: spark.conf.set("customer_code", "BOSHOSP")
    """
    try:
        return spark.conf.get("customer_code", "BOSHOSP")
    except:
        return "BOSHOSP"


def get_table_metadata_by_customer(customer_code: Optional[str] = None, table_prefix: Optional[str] = None):
    """
    Retrieves table metadata from clinicalforge.metadata for a specific customer.
    
    Args:
        customer_code: Customer code to filter (default: from runtime parameter)
        table_prefix: Filter by table name prefix ('Dim', 'Fact', etc.)
    
    Returns:
        DataFrame with metadata columns:
        - WarehouseTableID, SourceTableID, CustomerCode, CustomerName
        - TargetSchema, WarehouseTableName, SourceTableName
        - LoadMethod (IncrementalWatermark or FullRefresh)
        - isActive, WatermarkColumn
    """
    if customer_code is None:
        customer_code = get_customer_code()
    
    query = f"""
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
    WHERE C.CustomerCode = '{customer_code}'
        AND CWHT.isActive = 'true'
        AND CWHT.WatermarkColumn = 'LastModifiedDateTime'
    """
    
    if table_prefix:
        query += f" AND CWHT.WarehouseTableName LIKE '{table_prefix}%'"
    
    query += " ORDER BY CWHT.WarehouseTableID"
    
    return spark.sql(query)


def build_source_dataframe(warehouse_table_name: str, is_streaming: bool = True, customer_code: Optional[str] = None):
    """
    Builds a source DataFrame for a specific warehouse table based on metadata.
    
    Args:
        warehouse_table_name: The target warehouse table name from metadata
        is_streaming: True for streaming read, False for batch read
        customer_code: Customer code (default: from runtime parameter)
    
    Returns:
        DataFrame from clinicalforge.silver.{CustomerCode}_{SourceTableName}
    """
    if customer_code is None:
        customer_code = get_customer_code()
    
    # Get metadata for this specific warehouse table
    metadata_df = get_table_metadata_by_customer(customer_code)
    table_metadata = metadata_df.filter(F.col("WarehouseTableName") == warehouse_table_name)
    
    # Collect metadata rows
    rows = table_metadata.collect()
    
    if not rows:
        raise ValueError(
            f"No metadata found for WarehouseTableName='{warehouse_table_name}' "
            f"and CustomerCode='{customer_code}'"
        )
    
    # Get the first row (should be unique per customer + warehouse table)
    row = rows[0]
    source_table = row.SourceTableName
    watermark_col = row.WatermarkColumn
    load_method = row.LoadMethod
    
    # Build source path
    source_path = f"clinicalforge.silver.{customer_code}_{source_table}"
    
    # Create DataFrame based on load method
    if is_streaming:
        df = spark.readStream.option("skipChangeCommits", "true").table(source_path)
        if watermark_col:
            df = df.withWatermark(watermark_col, "1 hour")
    else:
        df = spark.read.table(source_path)
    
    # Add customer tracking column
    return df.withColumn("_customer_code", F.lit(customer_code))


def get_all_dim_tables():
    """
    Returns list of all dimension table names from metadata for the current customer.
    
    Returns:
        List of WarehouseTableName values for dimension tables
    """
    metadata = get_table_metadata_by_customer(table_prefix="Dim")
    return [row.WarehouseTableName for row in metadata.select("WarehouseTableName").distinct().collect()]


def get_all_fact_tables():
    """
    Returns list of all fact table names from metadata for the current customer.
    
    Returns:
        List of WarehouseTableName values for fact tables
    """
    metadata = get_table_metadata_by_customer(table_prefix="Fact")
    return [row.WarehouseTableName for row in metadata.select("WarehouseTableName").distinct().collect()]