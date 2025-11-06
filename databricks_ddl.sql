-- Databricks Data Loading Script for Peatland Restoration Project
-- This script creates tables and applies row-level security

-- Create schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS sol_eng_demo_nickp.moorcare;

-- Create volume for data files
CREATE VOLUME IF NOT EXISTS sol_eng_demo_nickp.moorcare.data_files;

-- ============================================================================
-- Table: synthetic_peatland_sites
-- ============================================================================
CREATE TABLE IF NOT EXISTS sol_eng_demo_nickp.moorcare.synthetic_peatland_sites (
  site_id STRING,
  latitude DOUBLE,
  longitude DOUBLE,
  region STRING,
  area_hectares DOUBLE,
  peat_depth_cm DOUBLE,
  ndvi_mean DOUBLE,
  ndvi_std DOUBLE,
  moisture_index DOUBLE,
  red_band DOUBLE,
  nir_band DOUBLE,
  swir_band DOUBLE,
  drainage_status STRING,
  land_use STRING,
  vegetation_type STRING,
  erosion_severity STRING,
  bare_peat_percent DOUBLE,
  carbon_storage_t_ha DOUBLE,
  priority_score DOUBLE,
  restoration_priority STRING,
  restoration_cost_per_ha DOUBLE,
  last_assessment_year INT
)
USING DELTA
LOCATION 'dbfs:/sol_eng_demo_nickp/moorcare/synthetic_peatland_sites';

-- Load data from volume
COPY INTO sol_eng_demo_nickp.moorcare.synthetic_peatland_sites
FROM '@sol_eng_demo_nickp.moorcare.data_files/synthetic-peatland-sites.csv'
FILEFORMAT = CSV
FORMAT_OPTIONS ('header' = 'true', 'inferSchema' = 'true')
COPY_OPTIONS ('mergeSchema' = 'true');

-- ============================================================================
-- Table: synthetic_monitoring_data
-- ============================================================================
CREATE TABLE IF NOT EXISTS sol_eng_demo_nickp.moorcare.synthetic_monitoring_data (
  site_id STRING,
  year INT,
  ndvi_value DOUBLE,
  moisture_value DOUBLE,
  carbon_sequestration DOUBLE
)
USING DELTA
LOCATION 'dbfs:/sol_eng_demo_nickp/moorcare/synthetic_monitoring_data';

-- Load data from volume
COPY INTO sol_eng_demo_nickp.moorcare.synthetic_monitoring_data
FROM '@sol_eng_demo_nickp.moorcare.data_files/synthetic-monitoring-data.csv'
FILEFORMAT = CSV
FORMAT_OPTIONS ('header' = 'true', 'inferSchema' = 'true')
COPY_OPTIONS ('mergeSchema' = 'true');

-- ============================================================================
-- Table: synthetic_restoration_projects
-- ============================================================================
CREATE TABLE IF NOT EXISTS sol_eng_demo_nickp.moorcare.synthetic_restoration_projects (
  project_id STRING,
  site_id STRING,
  project_status STRING,
  start_date DATE,
  completion_date DATE,
  total_cost DOUBLE,
  funding_source STRING,
  intervention_type STRING,
  area_hectares DOUBLE
)
USING DELTA
LOCATION 'dbfs:/sol_eng_demo_nickp/moorcare/synthetic_restoration_projects';

-- Load data from volume
COPY INTO sol_eng_demo_nickp.moorcare.synthetic_restoration_projects
FROM '@sol_eng_demo_nickp.moorcare.data_files/synthetic-restoration-projects.csv'
FILEFORMAT = CSV
FORMAT_OPTIONS ('header' = 'true', 'inferSchema' = 'true')
COPY_OPTIONS ('mergeSchema' = 'true');

-- ============================================================================
-- Row Access Policy for Regional Data Filtering
-- ============================================================================
-- Create row access policy to limit demo_databricks_user@posit.co to Scotland region
CREATE OR REPLACE FUNCTION sol_eng_demo_nickp.moorcare.peatland_filter(region STRING)
RETURN
  CASE
    WHEN current_user() = 'demo_databricks_user@posit.co'
      THEN region = 'Scotland'
    ELSE TRUE
  END;

-- Apply policy to peatland sites table
ALTER TABLE sol_eng_demo_nickp.moorcare.synthetic_peatland_sites
SET ROW FILTER sol_eng_demo_nickp.moorcare.peatland_filter ON (region);

-- Grant permissions
GRANT SELECT ON TABLE sol_eng_demo_nickp.moorcare.synthetic_peatland_sites TO `demo_databricks_user@posit.co`;
GRANT SELECT ON TABLE sol_eng_demo_nickp.moorcare.synthetic_monitoring_data TO `demo_databricks_user@posit.co`;
GRANT SELECT ON TABLE sol_eng_demo_nickp.moorcare.synthetic_restoration_projects TO `demo_databricks_user@posit.co`;
