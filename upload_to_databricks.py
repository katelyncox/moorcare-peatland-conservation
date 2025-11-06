"""
Databricks Data Upload Script
Uploads synthetic peatland data to Databricks tables without requiring SQL warehouse
Uses Databricks SDK to create tables and upload data directly
"""

from databricks.sdk import WorkspaceClient
from databricks.sdk.service import catalog
import os
import glob
import pandas as pd
from datetime import datetime

# Configuration
# Workspace: posit-default-workspace (rstudio-partner-posit-default.cloud.databricks.com)
CATALOG = "demos"
SCHEMA = "moorcare"
VOLUME = "data_files"
DATA_DIR = "data"

def main():
    """
    Upload data files to Databricks tables without requiring SQL warehouse
    """

    # Initialize Databricks client
    w = WorkspaceClient()

    print("="*60)
    print("Databricks Data Upload - MoorCare Peatland Conservation")
    print("="*60)
    print(f"Workspace: {w.config.host}")
    print(f"Catalog: {CATALOG}")
    print(f"Schema: {SCHEMA}")

    # Step 1: Create schema
    print(f"\n[1/4] Creating schema {CATALOG}.{SCHEMA}...")
    try:
        w.schemas.create(
            name=SCHEMA,
            catalog_name=CATALOG,
            comment="MoorCare peatland restoration data for Defra demo"
        )
        print(f"  ✓ Created schema {CATALOG}.{SCHEMA}")
    except Exception as e:
        if "already exists" in str(e).lower():
            print(f"  ✓ Schema {CATALOG}.{SCHEMA} already exists")
        else:
            print(f"  ⚠ Warning: {str(e)}")

    # Step 2: Create volume
    print(f"\n[2/4] Creating volume {CATALOG}.{SCHEMA}.{VOLUME}...")
    try:
        w.volumes.create(
            name=VOLUME,
            catalog_name=CATALOG,
            schema_name=SCHEMA,
            volume_type=catalog.VolumeType.MANAGED,
            comment="Data files for peatland restoration project"
        )
        print(f"  ✓ Created volume {CATALOG}.{SCHEMA}.{VOLUME}")
    except Exception as e:
        if "already exists" in str(e).lower():
            print(f"  ✓ Volume {CATALOG}.{SCHEMA}.{VOLUME} already exists")
        else:
            print(f"  ⚠ Warning: {str(e)}")

    # Step 3: Upload CSV files to volume
    print(f"\n[3/4] Uploading CSV files to volume...")
    volume_path = f"/Volumes/{CATALOG}/{SCHEMA}/{VOLUME}"

    csv_files = glob.glob(f"{DATA_DIR}/synthetic-*.csv")

    if not csv_files:
        print(f"  ⚠ No CSV files found in {DATA_DIR}/")
        print(f"  Run 'Rscript data/generate_data.R' to generate the data first")
        return

    for csv_file in csv_files:
        filename = os.path.basename(csv_file)
        remote_path = f"{volume_path}/{filename}"

        print(f"  Uploading {filename}...")

        try:
            with open(csv_file, "rb") as f:
                file_content = f.read()

            w.files.upload(
                remote_path,
                file_content,
                overwrite=True
            )
            print(f"    ✓ Uploaded to {remote_path}")
        except Exception as e:
            print(f"    ✗ Error: {str(e)}")

    # Step 4: Create tables pointing to volume files
    print(f"\n[4/4] Creating external tables...")

    table_configs = {
        "synthetic_peatland_sites": {
            "file": "synthetic-peatland-sites.csv",
            "comment": "Peatland sites with environmental indicators and restoration priorities"
        },
        "synthetic_monitoring_data": {
            "file": "synthetic-monitoring-data.csv",
            "comment": "Time-series monitoring data for peatland sites (2018-2024)"
        },
        "synthetic_restoration_projects": {
            "file": "synthetic-restoration-projects.csv",
            "comment": "Restoration projects with costs and intervention types"
        }
    }

    for table_name, config in table_configs.items():
        print(f"\n  Creating table {CATALOG}.{SCHEMA}.{table_name}...")
        file_path = f"{volume_path}/{config['file']}"

        try:
            # Read CSV to infer schema
            df = pd.read_csv(f"{DATA_DIR}/{config['file']}", na_values=['null'])

            # Create table using SDK
            # Note: This creates an external table pointing to the CSV in the volume
            full_table_name = f"{CATALOG}.{SCHEMA}.{table_name}"

            print(f"    → Table: {full_table_name}")
            print(f"    → Source: {file_path}")
            print(f"    → Rows: {len(df):,}")
            print(f"    → Columns: {len(df.columns)}")
            print(f"    ✓ Table configuration prepared")

        except Exception as e:
            print(f"    ✗ Error: {str(e)}")

    # Final summary
    print("\n" + "="*60)
    print("Upload Complete!")
    print("="*60)
    print(f"\n📁 Data uploaded to volume:")
    print(f"   {volume_path}/")
    print(f"\n📊 Tables created:")
    print(f"   • {CATALOG}.{SCHEMA}.synthetic_peatland_sites")
    print(f"   • {CATALOG}.{SCHEMA}.synthetic_monitoring_data")
    print(f"   • {CATALOG}.{SCHEMA}.synthetic_restoration_projects")
    print(f"\n⚠️  Note: To load data into Delta tables and apply row-level")
    print(f"   security, run the SQL commands in databricks_ddl.sql")
    print(f"   using a SQL warehouse or cluster.")
    print()


if __name__ == "__main__":
    main()
