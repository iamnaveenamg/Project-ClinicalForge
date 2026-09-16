# 1. import required liberaries
from pyspark import pipelines as dp
from pyspark.sql.types import *
from pyspark.sql.functions import *

# 2. Define runtime parameter for CustomerCode (default: BOSHOSP)
# Access runtime parameter passed to the pipeline
# To pass: use pipeline parameters {"customer_code": "BOSHOSP"}
try:
    CUSTOMER_CODE = spark.conf.get("customer_code", "BOSHOSP")
except:
    CUSTOMER_CODE = "BOSHOSP"

# 3. Fetch Event Hub configuration from metadata tables
config_query = f"""
SELECT 
    C.CustomerName, 
    C.CustomerCode, 
    EHD.NamespaceName as NameSpace, 
    EHD.TopicName, 
    EHD.ConnectionStringEH 
FROM clinicalforge.metadata.EventHubDetails as EHD
LEFT JOIN clinicalforge.metadata.CustomerProduct as CP 
    ON EHD.CustomerProductID = CP.CustomerProductID
LEFT JOIN clinicalforge.metadata.customers as C 
    ON CP.CustomerID = C.CustomerID
WHERE C.CustomerCode = '{CUSTOMER_CODE}' 
    AND C.isActive = 'true'
"""

config_df = spark.sql(config_query)
config_row = config_df.first()

if config_row is None:
    raise ValueError(f"No Event Hub configuration found for CustomerCode: {CUSTOMER_CODE}")

# Extract configuration values
EH_NAMESPACE = config_row.NameSpace
EH_NAME = config_row.TopicName
EH_CONN_STR = config_row.ConnectionStringEH

# 3. Add Kafka Details
KAFKA_OPTIONS = {
    "kafka.bootstrap.servers": f"{EH_NAMESPACE}.servicebus.windows.net:9093",
    "subscribe": EH_NAME,
    "kafka.sasl.mechanism": "PLAIN",
    "kafka.security.protocol": "SASL_SSL",
    "kafka.sasl.jaas.config": f'kafkashaded.org.apache.kafka.common.security.plain.PlainLoginModule required username="$ConnectionString" password="{EH_CONN_STR}";',
    "kafka.request.timeout.ms": "60000",
    "kafka.session.timeout.ms": "30000",
    "maxOffsetsPerTrigger": "50000",
    "failOnDataLoss": "true",
    "startingOffsets": "earliest",
}

patient_telemetry_schema = StructType([
    StructField("telemetryId", StringType(), True),
    StructField("deviceId", StringType(), True),
    StructField("patientId", LongType(), True),
    StructField("encounterId", LongType(), True),
    StructField("telemetryTimestamp", StringType(), True),  # Use TimestampType() if you parse it during ingestion
    StructField("heartRate", IntegerType(), True),
    StructField("oxygenSaturation", IntegerType(), True),
    StructField("systolicBP", IntegerType(), True),
    StructField("diastolicBP", IntegerType(), True),
    StructField("respiratoryRate", IntegerType(), True),
    StructField("bodyTemperature", DoubleType(), True)
])


@dp.table(name="FactUnifiedPatientTelemetry", table_properties={"quality": "Gold"})
def UnifiedPatientTelemetry():
    df_raw = (
        spark.readStream
        .format("kafka")
        .options(**KAFKA_OPTIONS)
        .load()
    )

    df_parsed = (
        df_raw
        .withColumn("key_str", col("key").cast("string"))
        .withColumn("value_str", col("value").cast("string"))
        .withColumn("data", from_json("value_str", patient_telemetry_schema))
        .select("data.*")
        .withColumn("HealthClientID", lit(CUSTOMER_CODE))
        .withColumnRenamed("timestamp", "order_timestamp")
    )
    return df_parsed
