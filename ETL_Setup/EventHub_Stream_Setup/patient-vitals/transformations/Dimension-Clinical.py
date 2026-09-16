from pyspark import pipelines as dp
from pyspark.sql import functions as F
import sys
sys.path.append("/Workspace/Users/naveenreddymg408@gmail.com/Project-ClinicalForge/ETL_Setup/EventHub_Stream_Setup/patient-vitals/transformations/utils")
from metadata_driven_tables import (
    get_customer_code,
    get_table_metadata_by_customer,
    build_source_dataframe,
    get_all_dim_tables
)

# ============================================================================
# RUNTIME CONFIGURATION
# ============================================================================
# CustomerCode is passed at runtime via pipeline parameters:
# Example: {"customer_code": "BOSHOSP"}
# Default: BOSHOSP
# ============================================================================

# ============================================================================
# METADATA VIEW - Configuration for dimension tables (current customer)
# ============================================================================

@dp.materialized_view(
    comment="Metadata configuration for dimension tables (filtered by runtime CustomerCode)"
)
def dimension_metadata():
    """
    Retrieves dimension table metadata for the runtime customer.
    
    Runtime Parameter:
    - customer_code: Customer to process (default: 'BOSHOSP')
    
    Query Filters:
    - CustomerCode = runtime parameter value
    - isActive = 'true'
    - WatermarkColumn = 'LastModifiedDateTime'
    - WarehouseTableName LIKE 'Dim%'
    
    Returns:
    - WarehouseTableID, SourceTableID, CustomerCode, CustomerName
    - TargetSchema, WarehouseTableName, SourceTableName
    - LoadMethod (IncrementalWatermark or FullRefresh)
    - isActive, WatermarkColumn
    
    Source Pattern:
    - clinicalforge.silver.{CustomerCode}_{SourceTableName}
    """
    return get_table_metadata_by_customer(table_prefix="Dim")


# ============================================================================
# METADATA-DRIVEN DIMENSION TABLE IMPLEMENTATION
# ============================================================================
# All dimension tables are automatically configured from metadata.
# The CustomerCode is passed at runtime via pipeline parameters.
#
# To create tables for your metadata:
# 1. Query dimension_metadata to see available WarehouseTableNames
# 2. For each WarehouseTableName, create a function below
# 3. Use build_source_dataframe() to automatically load the correct source
# ============================================================================

# ----------------------------------------------------------------------------
# TEMPLATE: Streaming Dimension (LoadMethod = 'IncrementalWatermark')
# ----------------------------------------------------------------------------

def _create_streaming_dimension(warehouse_table_name: str):
    """
    Generic streaming dimension table builder.
    Reads metadata and creates streaming table from correct silver source.
    """
    return build_source_dataframe(
        warehouse_table_name=warehouse_table_name,
        is_streaming=True
    )

# ----------------------------------------------------------------------------
# TEMPLATE: Batch Dimension (LoadMethod = 'FullRefresh')
# ----------------------------------------------------------------------------

def _create_batch_dimension(warehouse_table_name: str):
    """
    Generic batch dimension table builder.
    Reads metadata and creates materialized view from correct silver source.
    """
    return build_source_dataframe(
        warehouse_table_name=warehouse_table_name,
        is_streaming=False
    )


# ============================================================================
# ACTUAL DIMENSION TABLES - Auto-configured from metadata
# ============================================================================
# All 4 dimension tables from metadata (CustomerCode: BOSHOSP)
# All use FullRefresh (materialized views) to handle updates/deletes in silver
# Source pattern: clinicalforge.silver.{CustomerCode}_{SourceTableName}
# ============================================================================

@dp.materialized_view(
    comment="Beds dimension - Source: clinicalforge.silver.BOSHOSP_Beds",
    cluster_by_auto=True
)
def DimBeds():
    """
    Dimension: Beds
    LoadMethod: FullRefresh (Materialized View)
    Source: clinicalforge.silver.BOSHOSP_Beds
    """
    return _create_batch_dimension("DimBeds")


@dp.materialized_view(
    comment="Facilities dimension - Source: clinicalforge.silver.BOSHOSP_Facilities",
    cluster_by_auto=True
)
def DimFacilities():
    """
    Dimension: Facilities
    LoadMethod: FullRefresh (Materialized View)
    Source: clinicalforge.silver.BOSHOSP_Facilities
    """
    return _create_batch_dimension("DimFacilities")


@dp.materialized_view(
    comment="Patients dimension - Source: clinicalforge.silver.BOSHOSP_Patients",
    cluster_by_auto=True
)
def DimPatients():
    """
    Dimension: Patients
    LoadMethod: FullRefresh (Materialized View)
    Source: clinicalforge.silver.BOSHOSP_Patients
    """
    return _create_batch_dimension("DimPatients")


@dp.materialized_view(
    comment="Practitioners dimension - Source: clinicalforge.silver.BOSHOSP_Practitioners",
    cluster_by_auto=True
)
def DimPractitioners():
    """
    Dimension: Practitioners
    LoadMethod: FullRefresh (Materialized View)
    Source: clinicalforge.silver.BOSHOSP_Practitioners
    """
    return _create_batch_dimension("DimPractitioners")


# ============================================================================
# PRODUCTION IMPLEMENTATION STEPS:
# ============================================================================
# 1. Query dimension_metadata to see available WarehouseTableNames for your customer
# 2. For each unique WarehouseTableName:
#    a. Create a function with a unique name (e.g., DimDoctor_mv)
#    b. Use @dp.materialized_view() for batch (handles updates/deletes in silver)
#    c. Call _create_batch_dimension() for batch reads
# 3. Pass CustomerCode at runtime: spark-submit --conf customer_code=CLIENTA
# 4. Add business logic:
#    - SCD Type 2 for historical tracking
#    - Deduplication by business keys
#    - Data quality expectations
#    - Derived/calculated columns
#    - Lookups and enrichment
#
# Example:
# @dp.table(comment="Auto-configured streaming dimension", cluster_by_auto=True)
# def DimDoctor():
#     return _create_streaming_dimension("DimDoctor")
# ============================================================================
