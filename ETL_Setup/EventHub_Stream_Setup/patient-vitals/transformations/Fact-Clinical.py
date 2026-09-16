from pyspark import pipelines as dp
from pyspark.sql import functions as F
import sys
sys.path.append("/Workspace/Users/naveenreddymg408@gmail.com/Project-ClinicalForge/ETL_Setup/EventHub_Stream_Setup/patient-vitals/transformations/utils")
from metadata_driven_tables import (
    get_customer_code,
    get_table_metadata_by_customer,
    build_source_dataframe,
    get_all_fact_tables
)

# ============================================================================
# RUNTIME CONFIGURATION
# ============================================================================
# CustomerCode is passed at runtime via pipeline parameters:
# Example: {"customer_code": "BOSHOSP"}
# Default: BOSHOSP
# ============================================================================

# ============================================================================
# METADATA VIEW - Configuration for fact tables (current customer)
# ============================================================================

@dp.materialized_view(
    comment="Metadata configuration for fact tables (filtered by runtime CustomerCode)"
)
def fact_metadata():
    """
    Retrieves fact table metadata for the runtime customer.
    
    Runtime Parameter:
    - customer_code: Customer to process (default: 'BOSHOSP')
    
    Query Filters:
    - CustomerCode = runtime parameter value
    - isActive = 'true'
    - WatermarkColumn = 'LastModifiedDateTime'
    - WarehouseTableName LIKE 'Fact%'
    
    Returns:
    - WarehouseTableID, SourceTableID, CustomerCode, CustomerName
    - TargetSchema, WarehouseTableName, SourceTableName
    - LoadMethod (IncrementalWatermark or FullRefresh)
    - isActive, WatermarkColumn
    
    Source Pattern:
    - clinicalforge.silver.{CustomerCode}_{SourceTableName}
    """
    return get_table_metadata_by_customer(table_prefix="Fact")


# ============================================================================
# METADATA-DRIVEN FACT TABLE IMPLEMENTATION
# ============================================================================
# All fact tables are automatically configured from metadata.
# The CustomerCode is passed at runtime via pipeline parameters.
#
# To create tables for your metadata:
# 1. Query fact_metadata to see available WarehouseTableNames
# 2. For each WarehouseTableName, create a function below
# 3. Use build_source_dataframe() to automatically load the correct source
# ============================================================================

# ----------------------------------------------------------------------------
# TEMPLATE: Streaming Fact (LoadMethod = 'IncrementalWatermark')
# ----------------------------------------------------------------------------

def _create_streaming_fact(warehouse_table_name: str):
    """
    Generic streaming fact table builder.
    Reads metadata and creates streaming table from correct silver source.
    """
    return build_source_dataframe(
        warehouse_table_name=warehouse_table_name,
        is_streaming=True
    )

# ----------------------------------------------------------------------------
# TEMPLATE: Batch Fact (LoadMethod = 'FullRefresh')
# ----------------------------------------------------------------------------

def _create_batch_fact(warehouse_table_name: str):
    """
    Generic batch fact table builder.
    Reads metadata and creates materialized view from correct silver source.
    """
    return build_source_dataframe(
        warehouse_table_name=warehouse_table_name,
        is_streaming=False
    )


# ============================================================================
# ACTUAL FACT TABLES - Auto-configured from metadata
# ============================================================================
# All 7 fact tables from metadata (CustomerCode: BOSHOSP)
# All use FullRefresh (materialized views) to handle updates/deletes in silver
# Source pattern: clinicalforge.silver.{CustomerCode}_{SourceTableName}
# ============================================================================

@dp.materialized_view(
    comment="Appointments fact - Source: clinicalforge.silver.BOSHOSP_Appointments",
    cluster_by_auto=True
)
def FactAppointments():
    """
    Fact: Appointments
    LoadMethod: FullRefresh (Materialized View)
    Source: clinicalforge.silver.BOSHOSP_Appointments
    """
    return _create_batch_fact("FactAppointments")


@dp.materialized_view(
    comment="BedAssignments fact - Source: clinicalforge.silver.BOSHOSP_BedAssignments",
    cluster_by_auto=True
)
def FactBedAssignments():
    """
    Fact: BedAssignments
    LoadMethod: FullRefresh (Materialized View)
    Source: clinicalforge.silver.BOSHOSP_BedAssignments
    """
    return _create_batch_fact("FactBedAssignments")


@dp.materialized_view(
    comment="BillingInvoices fact - Source: clinicalforge.silver.BOSHOSP_BillingInvoices",
    cluster_by_auto=True
)
def FactBillingInvoices():
    """
    Fact: BillingInvoices
    LoadMethod: FullRefresh (Materialized View)
    Source: clinicalforge.silver.BOSHOSP_BillingInvoices
    """
    return _create_batch_fact("FactBillingInvoices")


@dp.materialized_view(
    comment="Encounters fact - Source: clinicalforge.silver.BOSHOSP_Encounters",
    cluster_by_auto=True
)
def FactEncounters():
    """
    Fact: Encounters
    LoadMethod: FullRefresh (Materialized View)
    Source: clinicalforge.silver.BOSHOSP_Encounters
    """
    return _create_batch_fact("FactEncounters")


@dp.materialized_view(
    comment="LabOrders fact - Source: clinicalforge.silver.BOSHOSP_LabOrders",
    cluster_by_auto=True
)
def FactLabOrders():
    """
    Fact: LabOrders
    LoadMethod: FullRefresh (Materialized View)
    Source: clinicalforge.silver.BOSHOSP_LabOrders
    """
    return _create_batch_fact("FactLabOrders")


@dp.materialized_view(
    comment="MedicationOrders fact - Source: clinicalforge.silver.BOSHOSP_MedicationOrders",
    cluster_by_auto=True
)
def FactMedicationOrders():
    """
    Fact: MedicationOrders
    LoadMethod: FullRefresh (Materialized View)
    Source: clinicalforge.silver.BOSHOSP_MedicationOrders
    """
    return _create_batch_fact("FactMedicationOrders")


@dp.materialized_view(
    comment="Procedures fact - Source: clinicalforge.silver.BOSHOSP_Procedures",
    cluster_by_auto=True
)
def FactProcedures():
    """
    Fact: Procedures
    LoadMethod: FullRefresh (Materialized View)
    Source: clinicalforge.silver.BOSHOSP_Procedures
    """
    return _create_batch_fact("FactProcedures")


# ============================================================================
# PRODUCTION IMPLEMENTATION STEPS:
# ============================================================================
# 1. Query fact_metadata to see available WarehouseTableNames for your customer
# 2. For each unique WarehouseTableName:
#    a. Create a function with a unique name (e.g., FactAdmissions_mv)
#    b. Use @dp.materialized_view() for batch (handles updates/deletes in silver)
#    c. Call _create_batch_fact() for batch reads
# 3. Pass CustomerCode at runtime: spark-submit --conf customer_code=CLIENTA
# 4. Add business logic:
#    - Aggregations for summary facts
#    - Joins with dimensions
#    - Data quality expectations
#    - Deduplication
#
# Example:
# @dp.table(comment="Auto-configured streaming fact", cluster_by_auto=True)
# def FactLabResults():
#     return _create_streaming_fact("FactLabResults")
# ============================================================================