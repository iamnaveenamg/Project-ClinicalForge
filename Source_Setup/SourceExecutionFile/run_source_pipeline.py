import os
import sys
from sqlalchemy import create_engine, text
import urllib.parse
from dotenv import load_dotenv

# Load environmental profile configs
load_dotenv() 

# =========================================================================
# Project ClinicalForge: Cross-Directory Architecture Relational Engine
# =========================================================================

# 1. Connection Architecture Attributes
server = os.getenv("server")                    
port = os.getenv("port")
database = os.getenv("database")
user_name = os.getenv("user_name")
password = os.getenv("password")

print(f"Connection: {server},{database},{user_name}, {password}")

# DYNAMIC DIRECTORY MAPPING:
# Finds the path of /Clinical/Pipeline/
PIPELINE_DIR = os.path.dirname(os.path.abspath(__file__))

# Steps up one folder level to find the /Clinical/ root directory
PROJECT_ROOT = os.path.abspath(os.path.join(PIPELINE_DIR, ".."))

# 2. Sequence of Target SQL Execution Units mapped across target directory folders
SQL_FILES = [
    # Table Creation
    os.path.join(PROJECT_ROOT, "Source_Setup/SourceDB", "00-schema-creation.sql"),
    os.path.join(PROJECT_ROOT, "Source_Setup/SourceDB", "01-Core-Tables.sql"),
    os.path.join(PROJECT_ROOT, "Source_Setup/SourceDB", "02-Clinical-Tables.sql"),
    os.path.join(PROJECT_ROOT, "Source_Setup/SourceDB", "03-Financial-Tables.sql"),
    # DML Script Creation
    os.path.join(PROJECT_ROOT, "Source_Setup/SourceMetadata", "01-Core-Data.sql"),
    os.path.join(PROJECT_ROOT, "Source_Setup/SourceMetadata", "02-Clinical-Data.sql"),
    os.path.join(PROJECT_ROOT, "Source_Setup/SourceMetadata", "03-Financial-Data.sql")
]

print(SQL_FILES)

def build_connection_engine():
    """Uses urllib to format parameters securely into an SQLAlchemy connection engine."""
    driver = "ODBC Driver 17 for SQL Server"
    
    # Clean up trailing hidden spaces or tabs from .env load
    db_user = user_name.strip() if user_name else ""
    db_pass = password.strip() if password else ""
    db_server = server.strip() if server else ""
    
    server_address = f"{db_server},{port}" if port else db_server
    
    # ESCAPE PASSWORD: Wrap the password in literal ODBC curly braces.
    if db_pass and not (db_pass.startswith('{') and db_pass.endswith('}')):
        escaped_password = f"{{{db_pass}}}"
    else:
        escaped_password = db_pass
    
    # Establish complete connection string template mapping
    params = (
        f"DRIVER={driver};"
        f"SERVER={server_address};"
        f"DATABASE={database};"
        f"UID={db_user};"
        f"PWD={escaped_password};"
        "Encrypt=yes;"
        "TrustServerCertificate=yes;"
    )
    
    encoded_params = urllib.parse.quote_plus(params)
    connection_url = f"mssql+pyodbc:///?odbc_connect={encoded_params}"
    
    return create_engine(connection_url, fast_executemany=True)

def execute_sql_file(connection, file_path):
    """Parses a SQL script, splits it by 'GO' keywords, and runs queries via SQLAlchemy text execution."""
    if not os.path.exists(file_path):
        print(f"⚠️ Target migration file missing at location: {file_path}. Skipping batch loop.")
        return

    print(f"⏳ Processing blueprint payload: {os.path.basename(file_path)}...")
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
    print("🚀 Initializing Project ClinicalForge Database Deployment...")
    
    # ... (Keep your directory diagnostic print code blocks here) ...

    if not all([server, database, user_name, password]):
        print("💥 Configuration Error: Missing core credential parameters inside .env")
        sys.exit(1)
        
    try:
        engine = build_connection_engine()
        
        # FIX: Connect explicitly and initiate a raw transaction controller context
        with engine.connect() as connection:
            trans = connection.begin()
            try:
                print("✅ Successfully established connection profile link.")
                
                # Sequentially process each data layer migration script
                for sql_file in SQL_FILES:
                    execute_sql_file(connection, sql_file)
                    
                    print(f"✅ Successfully processed file statements: {os.path.basename(sql_file)}")
                
                # FORCE HARD COMMIT: Ensures the server physically commits the pages to disk
                trans.commit()
                print("💾 Hard Transaction Commit executed successfully!")
                
            except Exception as file_error:
                trans.rollback()
                print("↩️ Execution failed. Transaction has been completely rolled back.")
                raise file_error
                
        print("\n🏁 Master Ingestion complete! All tables are fully forged in the database.")

    except Exception as e:
        print(f"💥 Critical Pipeline Deployment Failure: {str(e)}")
        sys.exit(1)




if __name__ == "__main__":
    main()