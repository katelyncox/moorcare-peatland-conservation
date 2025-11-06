# Synthetic Peatland Data Generation Script
# This script generates artificial data for demonstration purposes only.
# All data is AI-generated and does not represent real peatland sites.

library(dplyr)
library(tidyr)
library(readr)
library(stringr)

set.seed(42)

# Number of peatland sites to generate
n_sites <- 500

# Generate synthetic peatland assessment data
peatland_sites <- tibble(
  site_id = paste0("PEAT-", str_pad(1:n_sites, 4, pad = "0")),

  # Geographic information (UK coordinates approximation)
  latitude = runif(n_sites, 50.0, 58.5),
  longitude = runif(n_sites, -5.0, 1.5),

  # Region classification
  region = sample(c("Scotland", "Northern England", "Wales", "Southwest England",
                   "East Anglia"), n_sites, replace = TRUE,
                 prob = c(0.35, 0.25, 0.20, 0.15, 0.05)),

  # Site characteristics
  area_hectares = round(rexp(n_sites, rate = 1/50) + 5, 1),
  peat_depth_cm = round(rnorm(n_sites, mean = 120, sd = 60)),

  # Vegetation indices from satellite imagery (NDVI scale: -1 to 1)
  # Missing due to cloud cover (~8% missing)
  ndvi_mean = ifelse(runif(n_sites) < 0.08, NA_real_, round(runif(n_sites, 0.2, 0.8), 3)),
  ndvi_std = ifelse(is.na(ndvi_mean), NA_real_, round(runif(n_sites, 0.05, 0.25), 3)),

  # Moisture content indicators
  # Missing due to sensor issues (~5% missing)
  moisture_index = ifelse(runif(n_sites) < 0.05, NA_real_, round(runif(n_sites, 0.1, 0.9), 3)),

  # Spectral band reflectance values (0-1 scale)
  # Missing due to cloud cover or data quality issues (~8% missing)
  red_band = ifelse(is.na(ndvi_mean), NA_real_, round(runif(n_sites, 0.05, 0.25), 3)),
  nir_band = ifelse(is.na(ndvi_mean), NA_real_, round(runif(n_sites, 0.25, 0.65), 3)),
  swir_band = ifelse(is.na(ndvi_mean), NA_real_, round(runif(n_sites, 0.15, 0.45), 3)),

  # Land use and drainage status
  drainage_status = sample(c("Intact", "Partially Drained", "Heavily Drained",
                            "Fully Drained"), n_sites, replace = TRUE,
                          prob = c(0.15, 0.25, 0.35, 0.25)),

  land_use = sample(c("Natural", "Grazing", "Forestry", "Agriculture", "Abandoned"),
                   n_sites, replace = TRUE,
                   prob = c(0.20, 0.30, 0.15, 0.20, 0.15)),

  # Vegetation type
  vegetation_type = sample(c("Sphagnum Moss", "Cotton Grass", "Heather",
                            "Mixed", "Degraded"), n_sites, replace = TRUE,
                          prob = c(0.15, 0.25, 0.25, 0.20, 0.15)),

  # Degradation indicators
  erosion_severity = sample(c("None", "Low", "Moderate", "High", "Severe"),
                           n_sites, replace = TRUE,
                           prob = c(0.15, 0.25, 0.30, 0.20, 0.10)),

  bare_peat_percent = round(runif(n_sites, 0, 60), 1),

  # Carbon storage estimate (tonnes per hectare)
  # Missing for sites where detailed surveys not yet conducted (~12% missing)
  carbon_storage_t_ha = ifelse(runif(n_sites) < 0.12, NA_real_,
                                round(rnorm(n_sites, mean = 500, sd = 200), 1))
) |>
  mutate(
    # Ensure peat depth is positive
    peat_depth_cm = pmax(peat_depth_cm, 30),

    # Calculate restoration priority score (0-100)
    # Higher scores indicate greater need for restoration
    # Handle missing moisture_index with median imputation for scoring
    priority_score = round(
      (case_when(
        drainage_status == "Fully Drained" ~ 35,
        drainage_status == "Heavily Drained" ~ 30,
        drainage_status == "Partially Drained" ~ 20,
        TRUE ~ 10
      ) +
      case_when(
        erosion_severity == "Severe" ~ 25,
        erosion_severity == "High" ~ 20,
        erosion_severity == "Moderate" ~ 15,
        erosion_severity == "Low" ~ 8,
        TRUE ~ 0
      ) +
      case_when(
        vegetation_type == "Degraded" ~ 20,
        vegetation_type == "Heather" ~ 15,
        vegetation_type == "Cotton Grass" ~ 10,
        vegetation_type == "Mixed" ~ 8,
        TRUE ~ 5
      ) +
      (bare_peat_percent / 100 * 20) +
      (1 - coalesce(moisture_index, 0.5)) * 10
    ), 0),

    # Restoration recommendation
    restoration_priority = case_when(
      priority_score >= 70 ~ "Critical",
      priority_score >= 50 ~ "High",
      priority_score >= 30 ~ "Moderate",
      TRUE ~ "Low"
    ),

    # Estimated restoration cost (£ per hectare)
    restoration_cost_per_ha = round(
      case_when(
        restoration_priority == "Critical" ~ rnorm(1, 5000, 1000),
        restoration_priority == "High" ~ rnorm(1, 3500, 800),
        restoration_priority == "Moderate" ~ rnorm(1, 2000, 500),
        TRUE ~ rnorm(1, 1000, 300)
      ), 0
    ),

    # Year of last assessment
    last_assessment_year = sample(2018:2024, n_sites, replace = TRUE)
  )

# Generate time series data for monitoring (subset of sites)
monitoring_sites <- sample(peatland_sites$site_id, 50)

monitoring_data <- expand_grid(
  site_id = monitoring_sites,
  year = 2018:2024
) |>
  left_join(peatland_sites |> select(site_id, restoration_priority), by = "site_id") |>
  group_by(site_id) |>
  mutate(
    # Simulate trends in vegetation health over time
    ndvi_value = round(0.3 + cumsum(rnorm(n(), 0.02, 0.05)), 3),
    ndvi_value = pmin(pmax(ndvi_value, 0.1), 0.9),
    # Introduce missing values due to equipment failure or cloud cover (~10% missing)
    ndvi_value = ifelse(runif(n()) < 0.10, NA_real_, ndvi_value),

    # Moisture trends
    moisture_value = round(0.5 + cumsum(rnorm(n(), 0.01, 0.03)), 3),
    moisture_value = pmin(pmax(moisture_value, 0.1), 0.95),
    # Introduce missing values due to sensor issues (~7% missing)
    moisture_value = ifelse(runif(n()) < 0.07, NA_real_, moisture_value),

    # Carbon sequestration rate (tonnes CO2e per hectare per year)
    carbon_sequestration = round(rnorm(n(), 2.5, 1.0), 2),
    carbon_sequestration = pmax(carbon_sequestration, 0),
    # Introduce missing values where measurements not taken (~15% missing)
    carbon_sequestration = ifelse(runif(n()) < 0.15, NA_real_, carbon_sequestration)
  ) |>
  ungroup() |>
  select(-restoration_priority)

# Generate restoration projects data
restoration_projects <- peatland_sites |>
  filter(restoration_priority %in% c("Critical", "High")) |>
  slice_sample(n = 80) |>
  mutate(
    project_id = paste0("PROJ-", str_pad(1:n(), 3, pad = "0")),
    project_status = sample(c("Planned", "In Progress", "Completed"),
                           n(), replace = TRUE,
                           prob = c(0.3, 0.4, 0.3)),
    start_date = as.Date("2020-01-01") + sample(0:1460, n()),
    completion_date = if_else(
      project_status == "Completed",
      start_date + sample(180:730, n()),
      as.Date(NA)
    ),
    total_cost = round(area_hectares * restoration_cost_per_ha, 0),
    funding_source = sample(c("Government Grant", "Private Investment",
                             "NGO Partnership", "Mixed Funding"),
                           n(), replace = TRUE,
                           prob = c(0.4, 0.2, 0.25, 0.15)),
    intervention_type = sample(c("Drain Blocking", "Revegetation", "Grazing Management",
                                "Combined Approach"), n(), replace = TRUE,
                              prob = c(0.3, 0.25, 0.2, 0.25))
  ) |>
  select(project_id, site_id, project_status, start_date, completion_date,
         total_cost, funding_source, intervention_type, area_hectares)

# Save datasets (write missing values as "null" instead of empty strings)
write_csv(peatland_sites, "data/synthetic-peatland-sites.csv", na = "null")
write_csv(monitoring_data, "data/synthetic-monitoring-data.csv", na = "null")
write_csv(restoration_projects, "data/synthetic-restoration-projects.csv", na = "null")

cat("✓ Generated synthetic peatland data:\n")
cat("  - synthetic-peatland-sites.csv:", nrow(peatland_sites), "sites\n")
cat("  - synthetic-monitoring-data.csv:", nrow(monitoring_data), "observations\n")
cat("  - synthetic-restoration-projects.csv:", nrow(restoration_projects), "projects\n")

# Report missing data statistics
cat("\n📊 Missing Data Summary (realistic patterns):\n")
cat("  Peatland Sites:\n")
cat("    - NDVI data:", sum(is.na(peatland_sites$ndvi_mean)), "missing (",
    round(mean(is.na(peatland_sites$ndvi_mean)) * 100, 1), "%)\n")
cat("    - Moisture index:", sum(is.na(peatland_sites$moisture_index)), "missing (",
    round(mean(is.na(peatland_sites$moisture_index)) * 100, 1), "%)\n")
cat("    - Carbon storage:", sum(is.na(peatland_sites$carbon_storage_t_ha)), "missing (",
    round(mean(is.na(peatland_sites$carbon_storage_t_ha)) * 100, 1), "%)\n")
cat("  Monitoring Data:\n")
cat("    - NDVI values:", sum(is.na(monitoring_data$ndvi_value)), "missing (",
    round(mean(is.na(monitoring_data$ndvi_value)) * 100, 1), "%)\n")
cat("    - Moisture values:", sum(is.na(monitoring_data$moisture_value)), "missing (",
    round(mean(is.na(monitoring_data$moisture_value)) * 100, 1), "%)\n")
cat("    - Carbon sequestration:", sum(is.na(monitoring_data$carbon_sequestration)), "missing (",
    round(mean(is.na(monitoring_data$carbon_sequestration)) * 100, 1), "%)\n")

cat("\nNote: All data is synthetic and generated for demonstration purposes only.\n")
cat("Missing values simulate real-world data collection challenges (cloud cover, sensor issues, etc.)\n")
