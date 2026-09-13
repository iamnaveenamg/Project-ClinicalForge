import sys
import os
import time
import json
import uuid
import random
import urllib.parse
from datetime import datetime
from sqlalchemy import create_engine, text
from azure.eventhub import EventHubProducerClient, EventData

# =========================================================================
# Project ClinicalForge: Real-Time Unified Telemetry Streaming Simulator
# =========================================================================


from dotenv import load_dotenv

# Load environmental profile configs
load_dotenv() 


# 1. Database Connection Configuration (Static Source Lookup)
DB_SERVER = os.getenv("server") 
DB_PORT = os.getenv("port")
DB_DATABASE = os.getenv("database")
DB_USERNAME = os.getenv("user_name")
DB_PASSWORD = os.getenv("password")

# 2. Azure Event Hubs Configuration
# Replace with your actual primary connection string from Azure Shared Access Policies
EVENT_HUB_CONNECTION_STRING = os.getenv("EVENTHUB_CONNECTION_STRING")
EVENT_HUB_NAME = os.getenv("EVENTHUB_NAME")

def fetch_active_patients(engine):
    """
    Queries the static relational source database to find active encounters
    (where DischargeDateTime IS NULL) so we simulate data for real patients.
    """
    query = text("""
        SELECT PatientID, EncounterID 
        FROM Clinical.Encounters 
        WHERE DischargeDateTime IS NULL
    """)
    
    with engine.connect() as connection:
        result = connection.execute(query).fetchall()
        # Convert to a list of dictionaries
        active_list = [{"patientId": row[0], "encounterId": row[1]} for row in result]
        return active_list

def generate_random_vitals():
    """Generates realistic medical vital signs that fluctuate within expected clinical ranges."""
    # Simulating standard resting ranges with slight random variance
    heart_rate = random.randint(65, 110)
    oxygen_sat = random.randint(92, 100)  # SpO2 %
    systolic_bp = random.randint(110, 140)
    diastolic_bp = random.randint(70, 90)
    resp_rate = random.randint(12, 22)
    
    # 5% chance of simulating a critical medical anomaly alert (e.g., Sepsis/SIRS indicator)
    if random.random() < 0.05:
        heart_rate = random.randint(125, 150)  # Tachycardia
        oxygen_sat = random.randint(82, 89)    # Hypoxia
        
    return {
        "heartRate": heart_rate,
        "oxygenSaturation": oxygen_sat,
        "systolicBP": systolic_bp,
        "diastolicBP": diastolic_bp,
        "respiratoryRate": resp_rate,
        "bodyTemperature": round(random.uniform(36.5, 39.1), 1)  # Celcius
    }

def main():
    print("🚀 Starting Project ClinicalForge Real-Time Telemetry Streaming Engine...")

    # 1. Connect to static database using SQLAlchemy and urllib
    odbc_params = f"DRIVER=ODBC Driver 17 for SQL Server;SERVER={DB_SERVER},{DB_PORT};DATABASE={DB_DATABASE};UID={DB_USERNAME};PWD={DB_PASSWORD};Encrypt=yes;TrustServerCertificate=yes;"
    encoded_params = urllib.parse.quote_plus(odbc_params)
    db_url = f"mssql+pyodbc:///?odbc_connect={encoded_params}"
    db_engine = create_engine(db_url)

    try:
        active_patients = fetch_active_patients(db_engine)
        if not active_patients:
            print("⚠️ Warning: No active encounters (DischargeDateTime IS NULL) found in the database.")
            print("Please run your data seed script first to establish running patient encounters.")
            sys.exit(1)
        print(f"📊 Found {len(active_patients)} active hospital encounters to stream biometrics for.")
    except Exception as db_err:
        print(f"❌ Failed to fetch reference data from static source database: {str(db_err)}")
        sys.exit(1)

    # 2. Initialize the Azure Event Hub Client
    try:
        producer = EventHubProducerClient.from_connection_string(
            conn_str=EVENT_HUB_CONNECTION_STRING, 
            eventhub_name=EVENT_HUB_NAME
        )
        print(f"📡 Connected to Event Hub Namespace topic: '{EVENT_HUB_NAME}'")
    except Exception as eh_err:
        print(f"❌ Failed to initialize Event Hub Client: {str(eh_err)}")
        sys.exit(1)

    print("⚡ Telemetry stream is now active. Press Ctrl+C to terminate transmission...\n")
    
    try:
        with producer:
            while True:
                # Group messages into a high-performance event batch
                event_batch = producer.create_batch()
                
                # Generate a streaming record for each active patient found in the static DB
                for patient in active_patients:
                    vitals = generate_random_vitals()
                    
                    # Construct the unified JSON telemetry event payload
                    payload = {
                        "telemetryId": str(uuid.uuid4()),
                        "deviceId": f"ICU-MONITOR-BED-{patient['encounterId']}",
                        "patientId": patient['patientId'],
                        "encounterId": patient['encounterId'],
                        "telemetryTimestamp": datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S.%fZ'),
                        "heartRate": vitals['heartRate'],
                        "oxygenSaturation": vitals['oxygenSaturation'],
                        "systolicBP": vitals['systolicBP'],
                        "diastolicBP": vitals['diastolicBP'],
                        "respiratoryRate": vitals['respiratoryRate'],
                        "bodyTemperature": vitals['bodyTemperature']
                    }
                    
                    # Convert to string and wrap into EventData object
                    json_data = json.dumps(payload)
                    event_data = EventData(json_data)
                    
                    # Assign PartitionKey by PatientID so data for a patient stays ordered sequentially
                    event_data.properties = {"PartitionKey": str(patient['patientId'])}
                    
                    event_batch.add(event_data)
                    print(f"📥 Buffered Payload for Patient ID [{patient['patientId']}]: HR: {vitals['heartRate']} bpm, SpO2: {vitals['oxygenSaturation']}%")
                    print(payload)
                # Push the batch to the Azure cloud endpoint
                producer.send_batch(event_batch)
                print(f"📡 [SUCCESS] Flushed data batch to Azure Event Hub at {datetime.utcnow().strftime('%H:%M:%S')}")
                
                # Frequency control interval: Wait 3 seconds before sending the next vitals cycle
                time.sleep(3)
                
    except KeyboardInterrupt:
        print("\n🔒 Telemetry pipeline execution gracefully paused by user. Stopping stream.")
    except Exception as run_err:
        print(f"💥 Critical Stream Failure: {str(run_err)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
