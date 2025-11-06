# Run Databricks DDL Script
# This script executes databricks_ddl.sql to create tables and apply row-level security
# Usage: source("run_databricks_ddl.R")

library(DBI)
library(odbc)

cat("="*70, "\n")
cat("Databricks DDL Execution - MoorCare Peatland Conservation\n")
cat("="*70, "\n\n")

# Step 1: Connect to Databricks
cat("[1/3] Connecting to Databricks...\n")

tryCatch({
  con <- dbConnect(
    odbc::databricks()
    # Credentials are automatically detected from Positron/Workbench
  )

  # Test connection
  current_user <- dbGetQuery(con, "SELECT current_user() as user")
  cat("  ✓ Connected as:", current_user$user, "\n")
  cat("  ✓ Using catalog: demos\n")
  cat("  ✓ Using schema: moorcare\n\n")

}, error = function(e) {
  cat("  ✗ Connection failed:", e$message, "\n")
  cat("\nTroubleshooting:\n")
  cat("  1. Ensure you're in Posit Workbench with Databricks integration\n")
  cat("  2. Check your Databricks credentials are configured\n")
  cat("  3. Verify the odbc package is installed: install.packages('odbc')\n")
  stop("Unable to connect to Databricks")
})

# Step 2: Read and parse SQL file
cat("[2/3] Reading databricks_ddl.sql...\n")

if (!file.exists("databricks_ddl.sql")) {
  stop("databricks_ddl.sql not found. Make sure you're in the project root directory.")
}

sql_content <- readLines("databricks_ddl.sql", warn = FALSE)
sql_text <- paste(sql_content, collapse = "\n")

# Split into individual statements
statements <- strsplit(sql_text, ";")[[1]]

# Filter out empty statements and standalone comments
statements <- statements[sapply(statements, function(s) {
  s <- trimws(s)
  nchar(s) > 0 && !grepl("^--", s)
})]

cat("  ✓ Found", length(statements), "SQL statements to execute\n\n")

# Step 3: Execute each statement
cat("[3/3] Executing SQL statements...\n\n")

success_count <- 0
warning_count <- 0

for (i in seq_along(statements)) {
  stmt <- trimws(statements[i])

  # Extract a preview of the statement
  preview <- substr(stmt, 1, 60)
  if (nchar(stmt) > 60) preview <- paste0(preview, "...")

  cat(sprintf("Statement %d/%d: %s\n", i, length(statements), preview))

  tryCatch({
    # Execute the statement
    result <- dbExecute(con, stmt)
    cat("  ✓ Success\n\n")
    success_count <- success_count + 1

  }, error = function(e) {
    error_msg <- e$message

    # Check if it's a benign "already exists" error
    if (grepl("already exists", error_msg, ignore.case = TRUE)) {
      cat("  ℹ Already exists (skipping)\n\n")
      success_count <<- success_count + 1
    } else {
      cat("  ⚠ Warning:", error_msg, "\n\n")
      warning_count <<- warning_count + 1
    }
  })
}

# Summary
cat("="*70, "\n")
cat("Execution Complete!\n")
cat("="*70, "\n\n")

cat("Results:\n")
cat("  ✓ Successful:", success_count, "/", length(statements), "\n")
if (warning_count > 0) {
  cat("  ⚠ Warnings:", warning_count, "\n")
}

cat("\nTables created:\n")
cat("  • demos.moorcare.synthetic_peatland_sites\n")
cat("  • demos.moorcare.synthetic_monitoring_data\n")
cat("  • demos.moorcare.synthetic_restoration_projects\n")

cat("\nRow-level security:\n")
cat("  • Applied to synthetic_peatland_sites table\n")
cat("  • demo_databricks_user@posit.co restricted to Scotland region\n")

cat("\nNext steps:\n")
cat("  1. Query the tables: dbGetQuery(con, 'SELECT * FROM demos.moorcare.synthetic_peatland_sites LIMIT 10')\n")
cat("  2. Update eda.qmd to use Databricks: uncomment the Databricks connection code\n")
cat("  3. Update app.R to use Databricks: uncomment the Databricks connection code\n\n")

# Keep connection open for user to use
cat("Connection 'con' is still open for you to use.\n")
cat("Close it when done with: dbDisconnect(con)\n\n")
