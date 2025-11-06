"""
Databricks Data Upload Script
Uploads synthetic peatland data to Databricks and executes DDL
"""

from databricks import sql
from databricks.sdk import WorkspaceClient
from databricks.sdk.service import files
import os
import glob

# Configuration
# Workspace: posit-default-workspace (rstudio-partner-posit-default.cloud.databricks.com)
CATALOG = "demos"
SCHEMA = "moorcare"
VOLUME = "data_files"
DATA_DIR = "data"

def main():
    """
    Upload data files to Databricks Volume and execute DDL
    """

    # Initialize Databricks client
    # Uses credentials from environment or .databrickscfg
    w = WorkspaceClient()

    # Get configuration from WorkspaceClient
    config = w.config

    # Try to get SQL warehouse HTTP path from environment, otherwise use a default
    http_path = os.getenv("DATABRICKS_HTTP_PATH")
    if not http_path:
        print("⚠️  DATABRICKS_HTTP_PATH not set. Please set it to your SQL warehouse HTTP path.")
        print("   Example: /sql/1.0/warehouses/abc123def456")
        return

    print("Uploading data to Databricks...")
    print(f"  Workspace: {config.host}")
    print(f"  HTTP Path: {http_path}")

    # Create schema and volume if they don't exist
    print(f"\nCreating schema {CATALOG}.{SCHEMA} if not exists...")
    connection = sql.connect(
        server_hostname=config.host,
        http_path=http_path,
        credentials_provider=lambda: config
    )

    cursor = connection.cursor()

    # Create schema
    cursor.execute(f"CREATE SCHEMA IF NOT EXISTS {CATALOG}.{SCHEMA}")
    print(f"✓ Schema {CATALOG}.{SCHEMA} ready")

    # Create volume
    cursor.execute(f"CREATE VOLUME IF NOT EXISTS {CATALOG}.{SCHEMA}.{VOLUME}")
    print(f"✓ Volume {CATALOG}.{SCHEMA}.{VOLUME} ready")

    # Upload CSV files to volume
    volume_path = f"/Volumes/{CATALOG}/{SCHEMA}/{VOLUME}/"

    csv_files = glob.glob(f"{DATA_DIR}/synthetic-*.csv")

    for csv_file in csv_files:
        filename = os.path.basename(csv_file)
        remote_path = volume_path + filename

        print(f"Uploading {filename} to {remote_path}...")

        with open(csv_file, "rb") as f:
            file_content = f.read()

        w.files.upload(
            remote_path,
            file_content,
            overwrite=True
        )

        print(f"  ✓ Uploaded {filename}")

    print("\n" + "="*60)
    print("Data upload complete!")
    print("="*60)

    # Execute DDL
    print("\nExecuting DDL...")
    with open("databricks_ddl.sql", "r") as f:
        ddl_content = f.read()

    # Split DDL into individual statements
    statements = [s.strip() for s in ddl_content.split(";") if s.strip() and not s.strip().startswith("--")]

    for i, statement in enumerate(statements, 1):
        # Skip comment lines
        if statement.strip().startswith("--"):
            continue

        print(f"\nExecuting statement {i}/{len(statements)}...")
        print(f"  {statement[:100]}...")

        try:
            cursor.execute(statement)
            print("  ✓ Success")
        except Exception as e:
            print(f"  ⚠ Warning: {str(e)}")
            # Continue with next statement even if one fails

    print("\n" + "="*60)
    print("Databricks setup complete!")
    print("="*60)
    print(f"\nData loaded to:")
    print(f"  • {CATALOG}.{SCHEMA}.synthetic_peatland_sites")
    print(f"  • {CATALOG}.{SCHEMA}.synthetic_monitoring_data")
    print(f"  • {CATALOG}.{SCHEMA}.synthetic_restoration_projects")
    print(f"\nRow access policy applied:")
    print(f"  • demo_databricks_user@posit.co can only access Scotland region")

    cursor.close()
    connection.close()


if __name__ == "__main__":
    main()
