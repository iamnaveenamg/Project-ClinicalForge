import sys
import os
import random
import urllib.parse
from datetime import datetime, timedelta
from sqlalchemy import create_engine, text

from dotenv import load_dotenv

# Load environmental profile configs
load_dotenv() 

# =========================================================================
# Project ClinicalForge: Dynamic Random Record Generation Engine
# =========================================================================

# 1. Database Connection Configurations
#  Connection Architecture Attributes
server = os.getenv("server")                    
port = os.getenv("port")
database = os.getenv("database")
user_name = os.getenv("user_name")
password = os.getenv("password")

# Check Connection Details
print(f"Connection: {server},{database},{user_name}, {password}")

# 2. Healthcare Mock Data Repositories for Randomization
FACILITIES = [
    ("ForgeCare Community Hospital", "Urgent Care", "Boston"),
    ("ClinicalForge Neurological Center", "Specialty Hospital", "Cambridge"),
    ("ForgeCare Wellness Clinic East", "Clinic", "Newton"),
    ("ClinicalForge Traumatic Injury Center", "ER", "Waltham")
]

DOCTORS = [
    ("Stephen", "Strange", "Neurosurgery", "207X00000X"),
    ("Harleen", "Quinzel", "Psychiatry", "207P00000X"),
    ("Gregory", "House", "Diagnostic Medicine", "207R00000X"),
    ("Leonard", "McCoy", "General Surgery", "208600000X"),
    ("Meredith", "Grey", "General Surgery", "208600000X")
]

PATIENTS = [
    ("Tony", "Stark", "M", "1970-05-29"),
    ("Bruce", "Banner", "M", "1969-12-18"),
    ("Natasha", "Romanoff", "F", "1984-11-22"),
    ("Wanda", "Maximoff", "F", "1989-02-10"),
    ("Steve", "Rogers", "M", "1918-07-04"),
    ("Carol", "Danvers", "F", "1968-04-24")
]

DIAGNOSES = [
    ("I10", "Essential (primary) hypertension"),
    ("E11.9", "Type 2 diabetes mellitus without complications"),
    ("J06.9", "Acute upper respiratory infection, unspecified"),
    ("R07.9", "Chest pain, unspecified"),
    ("A41.9", "Sepsis, unspecified organism"),
    ("M23.203", "Derangement of unspecified meniscus due to old tear")
]

MEDICATIONS = [
    ("864703", "Metformin hydrochloride 500 MG", "Take 1 tablet orally twice daily with meals"),
    ("308137", "Amoxicillin 250 MG Oral Capsule", "Take 1 capsule orally three times daily for 7 days"),
    ("308422", "Aspirin 81 MG Oral Tablet", "Take 1 tablet orally daily"),
    ("261242", "Ibuprofen 600 MG Oral Tablet", "Take 1 tablet orally every 6 hours as needed for pain")
]

LABS = [
    ("4548-4", "Hemoglobin A1c"),
    ("13457-7", "Troponin I.cardiac"),
    ("2345-7", "Glucose Blood"),
    ("26464-8", "Leukocytes Blood")
]

PROCEDURES = [
    ("29881", "Knee arthroscopy/menisectomy"),
    ("93452", "Left heart catheterization"),
    ("93000", "Electrocardiogram tracing"),
    ("29540", "Strapping of ankle/foot")
]

def main():
    print("🚀 Initializing Project ClinicalForge Forced-Commit Data Ingestion Pipeline...")
    
    # 1. Encode connection parameters using urllib
    odbc_params = f"DRIVER=ODBC Driver 17 for SQL Server;SERVER={server},{port};DATABASE={database};UID={user_name};PWD={password};Encrypt=yes;TrustServerCertificate=yes;"
    encoded_params = urllib.parse.quote_plus(odbc_params)
    connection_url = f"mssql+pyodbc:///?odbc_connect={encoded_params}"
    
    # Create the core engine
    engine = create_engine(connection_url, fast_executemany=True)
    
    try:
        # Open an explicit direct connection context
        with engine.connect() as connection:
            
            # Start an explicit, managed manual transaction block
            trans = connection.begin()
            
            try:
                # Bypass operational constraints temporarily
                #connection.execute(text("EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL'"))
                
                # Fetch High Watermarks from Database state
                max_fac = connection.execute(text("SELECT ISNULL(MAX(FacilityID), 0) FROM Core.Facilities")).scalar()
                max_bed = connection.execute(text("SELECT ISNULL(MAX(BedID), 0) FROM Core.Beds")).scalar()
                max_doc = connection.execute(text("SELECT ISNULL(MAX(PractitionerID), 0) FROM Core.Practitioners")).scalar()
                max_pat = connection.execute(text("SELECT ISNULL(MAX(PatientID), 0) FROM Clinical.Patients")).scalar()
                max_app = connection.execute(text("SELECT ISNULL(MAX(AppointmentID), 0) FROM Clinical.Appointments")).scalar()
                max_enc = connection.execute(text("SELECT ISNULL(MAX(EncounterID), 0) FROM Clinical.Encounters")).scalar()
                
                # Pick random configurations from pools
                fac = random.choice(FACILITIES)
                doc = random.choice(DOCTORS)
                pat = random.choice(PATIENTS)
                diag = random.choice(DIAGNOSES)
                med = random.choice(MEDICATIONS)
                lab = random.choice(LABS)
                proc = random.choice(PROCEDURES)
                
                current_time = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S.%f')[:-3]
                future_time = (datetime.utcnow() + timedelta(days=1)).strftime('%Y-%m-%d %H:%M:%S.%f')[:-3]
                
                # Execute Injections sequentially
                # Core Schema
                connection.execute(text("""
                    INSERT INTO Core.Facilities (OrganizationTaxID, FacilityName, FacilityType, NPI, City, StateCode, IsActive, LastModifiedDateTime)
                    VALUES ('99-8887776', :name, :type, :npi, :city, 'MA', 1, :tm)
                """), {"name": fac[0], "type": fac[1], "npi": str(random.randint(1000000000, 1999999999)), "city": fac[2], "tm": current_time})

                connection.execute(text("""
                    INSERT INTO Core.Beds (FacilityID, WardName, RoomNumber, BedNumber, BedStatus, LastModifiedDateTime)
                    VALUES (:fac_id, 'Emergency Telemetry Wing', :room, :bed, 'Available', :tm)
                """), {"fac_id": max_fac + 1, "room": f"Room-{random.randint(100, 500)}", "bed": f"Bed-{random.randint(1, 4)}", "tm": current_time})

                connection.execute(text("""
                    INSERT INTO Core.Practitioners (NPI, FirstName, LastName, SpecialtyDescription, PrimaryFacilityID, IsActive, LastModifiedDateTime)
                    VALUES (:npi, :fn, :ln, :spec, :fac_id, 1, :tm)
                """), {"npi": doc[3], "fn": doc[0], "ln": doc[1], "spec": doc[2], "fac_id": max_fac + 1, "tm": current_time})

                # Clinical Schema
                connection.execute(text("""
                    INSERT INTO Clinical.Patients (MRN, FirstName, LastName, DateOfBirth, AdministrativeGender, PhoneNumber, LastModifiedDateTime)
                    VALUES (:mrn, :fn, :ln, :dob, :gender, :phone, :tm)
                """), {"mrn": f"MRN-RND-{random.randint(100000, 999999)}", "fn": pat[0], "ln": pat[1], "dob": pat[3], "gender": pat[2], "phone": f"617-555-{random.randint(1000, 9999)}", "tm": current_time})

                connection.execute(text("""
                    INSERT INTO Clinical.Appointments (PatientID, PractitionerID, FacilityID, AppointmentDateTime, AppointmentStatus, LastModifiedDateTime)
                    VALUES (:pat_id, :prac_id, :fac_id, :app_tm, 'Scheduled', :tm)
                """), {"pat_id": max_pat + 1, "prac_id": max_doc + 1, "fac_id": max_fac + 1, "app_tm": future_time, "tm": current_time})

                connection.execute(text("""
                    INSERT INTO Clinical.Encounters (AppointmentID, PatientID, PractitionerID, FacilityID, EncounterClass, AdmitDateTime, DischargeDateTime, PrimaryDiagnosisCode, LastModifiedDateTime)
                    VALUES (:app_id, :pat_id, :prac_id, :fac_id, 'Emergency', :tm, NULL, :diag, :tm)
                """), {"app_id": max_app + 1, "pat_id": max_pat + 1, "prac_id": max_doc + 1, "fac_id": max_fac + 1, "diag": diag[0], "tm": current_time})

                connection.execute(text("""
                    INSERT INTO Clinical.BedAssignments (EncounterID, BedID, AssignStartDateTime, AssignEndDateTime, LastModifiedDateTime)
                    VALUES (:enc_id, :bed_id, :tm, NULL, :tm)
                """), {"enc_id": max_enc + 1, "bed_id": max_bed + 1, "tm": current_time})

                connection.execute(text("""
                    INSERT INTO Clinical.MedicationOrders (EncounterID, PatientID, PrescribingPractitionerID, MedicationCode, MedicationName, DosageInstruction, OrderStatus, LastModifiedDateTime)
                    VALUES (:enc_id, :pat_id, :prac_id, :med_code, :med_name, :inst, 'Active', :tm)
                """), {"enc_id": max_enc + 1, "pat_id": max_pat + 1, "prac_id": max_doc + 1, "med_code": med[0], "med_name": med[1], "inst": med[2], "orderStatus": "Active", "tm": current_time})

                connection.execute(text("""
                    INSERT INTO Clinical.LabOrders (EncounterID, PatientID, OrderingPractitionerID, LOINCCode, TestName, LabStatus, ResultValue, LastModifiedDateTime)
                    VALUES (:enc_id, :pat_id, :prac_id, :loin, :name, 'Ordered', NULL, :tm)
                """), {"enc_id": max_enc + 1, "pat_id": max_pat + 1, "prac_id": max_doc + 1, "loin": lab[0], "name": lab[1], "tm": current_time})

                connection.execute(text("""
                    INSERT INTO Clinical.Procedures (EncounterID, PatientID, PrimarySurgeonID, CPTCode, ProcedureDescription, ProcedureStatus, LastModifiedDateTime)
                    VALUES (:enc_id, :pat_id, :prac_id, :cpt, :desc, 'Completed', :tm)
                """), {"enc_id": max_enc + 1, "pat_id": max_pat + 1, "prac_id": max_doc + 1, "cpt": proc[0], "desc": proc[1], "tm": current_time})

                # Financial Schema
                connection.execute(text("""
                    INSERT INTO Financial.BillingInvoices (EncounterID, PatientID, InvoiceNumber, GrossAmount, NetOutstandingBalance, InvoiceStatus, LastModifiedDateTime)
                    VALUES (:enc_id, :pat_id, :inv_num, :amt, :amt, 'Active', :tm)
                """), {"enc_id": max_enc + 1, "pat_id": max_pat + 1, "inv_num": f"INV-RND-{random.randint(100000, 999999)}", "amt": float(random.randint(200, 5000)), "tm": current_time})

                # Re-enable system check constraints
                #connection.execute(text("EXEC sp_MSforeachtable 'ALTER TABLE ? CHECK CONSTRAINT ALL'"))

                # FORCED COMMIT OPERATION: Pushes changes out of memory cache straight to disk logs
                trans.commit()
                print(f"✅ Success! Transaction committed. New Encounter ID generated: {max_enc + 1}")

            except Exception as inner_error:
                trans.rollback()  
            # Safely clear the channel if a failure occurs
                print("⚠️ Transaction rolled back due to query parsing mismatch.")

                raise inner_error 
    except Exception as e:
        print(f"💥 Connection Engine Failure: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()