import os
import sys
from sqlalchemy import create_engine, text
import urllib.parse
from dotenv import load_dotenv

# Load environmental profile configs
load_dotenv() 

# =========================================================================
# Project ClinicalForge: Python Relational Infrastructure Engine
# =========================================================================

# 1. Connection Architecture Attributes
server = os.getenv("server")                    
port = os.getenv("port")
database = os.getenv("database")
user_name = os.getenv("user_name")
password = os.getenv("password")


print(f"Connection: {server},{database},{user_name}, {password}")
# 2. Sequence of Target SQL Execution Units
# DYNAMIC DIRECTORY MAPPING:
# Finds the path of /Clinical/Pipeline/
PIPELINE_DIR = os.path.dirname(os.path.abspath(__file__))

# Steps up one folder level to find the /Clinical/ root directory
PROJECT_ROOT = os.path.abspath(os.path.join(PIPELINE_DIR, ".."))

# 2. Sequence of Target SQL Execution Units mapped across target directory folders
SQL_FILES = [
    os.path.join(PROJECT_ROOT, "SourceDB", "01_clinicalforge_schema_ddl.sql"),       
    os.path.join(PROJECT_ROOT, "SourceMetadata", "02_clinicalforge_static_data_seed.sql")  
]


def build_connection_engine():
    """Uses urllib to format parameters securely into an SQLAlchemy connection engine."""
    driver = "ODBC Driver 17 for SQL Server"
    
    # Cleanly resolve server + port string configuration channel
    server_address = f"{server},{port}" if port else server
    
    # ESCAPE PASSWORD: Wrap the password in literal ODBC curly braces.
    # This stops the driver from misinterpreting raw semicolons (;) or equals (=).
    if password and not (password.startswith('{') and password.endswith('}')):
        escaped_password = f"{{{password}}}"
    else:
        escaped_password = password
    
    # Establish complete raw connection string template mapping
    params = (
        f"DRIVER={driver};"
        f"SERVER={server_address};"
        f"DATABASE={database};"
        f"UID={user_name};"
        f"PWD={escaped_password};"
        "Encrypt=yes;"
        "TrustServerCertificate=yes;"
    )
    
    # Translate structural text symbols into strict URL-safe hex formats
    encoded_params = urllib.parse.quote_plus(params)
    
    # Synthesize the formal SQLAlchemy connection URL
    connection_url = f"mssql+pyodbc:///?odbc_connect={encoded_params}"
    
    # Create engine and enforce optimized row streaming configurations
    return create_engine(connection_url, fast_executemany=True)

def execute_sql_file(connection, file_path):
    """Parses a SQL script, splits it by 'GO' keywords, and runs queries via SQLAlchemy text execution."""
    if not os.path.exists(file_path):
        print(f"⚠️ Target migration file missing: {file_path}. Skipping batch loop.")
        return

    print(f"⏳ Processing schema blueprint payload: {file_path}...")
    with open(file_path, "r", encoding="utf-8") as f:
        sql_content = f.read()

    # Split script body by SQL Server standard transaction boundary keyword
    sql_batches = sql_content.split("GO")

    for batch in sql_batches:
        clean_query = batch.strip()
        if clean_query:  # Avoid executing blank blocks or trailing whitespaces
            try:
                connection.execute(text(clean_query))
            except Exception as e:
                print(f"❌ Error executing query batch near: {clean_query[:60]}...")
                print(f"Details: {str(e)}")
                raise e

def main():
    print("🚀 Initializing Project ClinicalForge Database Deployment via SQLAlchemy Engine...")
    
    # === TARGET SQL FILE DIAGNOSTIC PRINTS ===
    print("\n🔍 Target SQL File Diagnostic Checks:")
    print(f"  Main Directory: '{BASE_DIR}'")
    for index, sql_file in enumerate(SQL_FILES, 1):
        file_exists = os.path.exists(sql_file)
        status_icon = "🟢 Found" if file_exists else "🔴 MISSING"
        print(f"  [{index}] Absolute Target Path: {sql_file}")
        print(f"      Status:               {status_icon}")
    print("=" * 80 + "\n")
    # ==========================================

    # Verification guard for environmental parameters
    if not all([server, database, user_name, password]):
        print("💥 Configuration Error: Missing core credential parameters inside environment profile (.env)")
        sys.exit(1)
        
    try:
        engine = build_connection_engine()
        
        # Open an atomic database transaction context block
        with engine.begin() as connection:
            print("✅ Successfully established connection profile link via Urllib encoding.")
            
            # Sequentially process each data layer migration script
            for sql_file in SQL_FILES:
                execute_sql_file(connection, sql_file)
                print(f"✅ Successfully deployed: {sql_file}")
                
        print("\n🏁 Master Relational Ingestion Script complete! All static tables are fully forged.")

    except Exception as e:
        print(f"💥 Critical Pipeline Deployment Failure: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()