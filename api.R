# Peatland Restoration Priority API
# REST API for accessing data and predictions
# This project contains synthetic data created for demonstration purposes only.

library(plumber)
library(dplyr)
library(readr)
library(vetiver)
library(pins)

# Check if data exists, if not generate it
if (!file.exists("data/synthetic-peatland-sites.csv")) {
  message("Generating synthetic data...")
  source("data/generate_data.R")
}

# Load data (recognize "null" as missing values)
peatland_sites <- read_csv("data/synthetic-peatland-sites.csv", show_col_types = FALSE, na = "null")
monitoring_data <- read_csv("data/synthetic-monitoring-data.csv", show_col_types = FALSE, na = "null")
restoration_projects <- read_csv("data/synthetic-restoration-projects.csv", show_col_types = FALSE, na = "null")

# Load ML model
board <- board_folder("ml")
v_model <- vetiver_pin_read(board, "peatland_priority_model")

#* @apiTitle Peatland Restoration Priority API
#* @apiDescription API for accessing peatland data and generating restoration priority predictions. This project contains synthetic data and analysis created for demonstration purposes only.
#* @apiVersion 1.0.0

#* Health check endpoint
#* @get /health
#* @serializer unboxedJSON
function() {
  list(
    status = "healthy",
    timestamp = Sys.time(),
    message = "Peatland Restoration API is running"
  )
}

#* Get all peatland sites
#* @get /data/sites
#* @param region Optional filter by region
#* @param priority Optional filter by restoration priority (Low, Moderate, High, Critical)
#* @param limit Maximum number of records to return (default: 100)
#* @serializer json
function(region = NULL, priority = NULL, limit = 100) {

  data <- peatland_sites

  # Apply filters
  if (!is.null(region)) {
    data <- data |> filter(region == !!region)
  }

  if (!is.null(priority)) {
    data <- data |> filter(restoration_priority == !!priority)
  }

  # Apply limit
  limit <- as.numeric(limit)
  if (!is.na(limit) && limit > 0) {
    data <- data |> slice_head(n = limit)
  }

  data
}

#* Get site by ID
#* @get /data/sites/<site_id>
#* @param site_id The site identifier
#* @serializer json
function(site_id) {
  site <- peatland_sites |> filter(site_id == !!site_id)

  if (nrow(site) == 0) {
    stop("Site not found")
  }

  site
}

#* Get monitoring data
#* @get /data/monitoring
#* @param site_id Optional filter by site ID
#* @param year Optional filter by year
#* @serializer json
function(site_id = NULL, year = NULL) {

  data <- monitoring_data

  if (!is.null(site_id)) {
    data <- data |> filter(site_id == !!site_id)
  }

  if (!is.null(year)) {
    year_num <- as.numeric(year)
    if (!is.na(year_num)) {
      data <- data |> filter(year == year_num)
    }
  }

  data
}

#* Get restoration projects
#* @get /data/projects
#* @param status Optional filter by project status (Planned, In Progress, Completed)
#* @serializer json
function(status = NULL) {

  data <- restoration_projects

  if (!is.null(status)) {
    data <- data |> filter(project_status == !!status)
  }

  data
}

#* Get summary statistics
#* @get /data/summary
#* @serializer unboxedJSON
function() {

  list(
    total_sites = nrow(peatland_sites),
    total_area_ha = sum(peatland_sites$area_hectares),
    priority_counts = peatland_sites |>
      count(restoration_priority) |>
      tibble::deframe(),
    regional_summary = peatland_sites |>
      group_by(region) |>
      summarise(
        sites = n(),
        avg_priority_score = round(mean(priority_score), 2),
        .groups = "drop"
      ),
    active_projects = sum(restoration_projects$project_status == "In Progress"),
    completed_projects = sum(restoration_projects$project_status == "Completed")
  )
}

#* Predict restoration priority for a site
#* @post /predict
#* @param area_hectares Area in hectares
#* @param peat_depth_cm Peat depth in centimeters
#* @param ndvi_mean Mean NDVI value
#* @param ndvi_std Standard deviation of NDVI
#* @param moisture_index Moisture index (0-1)
#* @param red_band Red band reflectance
#* @param nir_band NIR band reflectance
#* @param swir_band SWIR band reflectance
#* @param drainage_status Drainage status (Intact, Partially Drained, Heavily Drained, Fully Drained)
#* @param land_use Land use type (Natural, Grazing, Forestry, Agriculture, Abandoned)
#* @param vegetation_type Vegetation type (Sphagnum Moss, Cotton Grass, Heather, Mixed, Degraded)
#* @param erosion_severity Erosion severity (None, Low, Moderate, High, Severe)
#* @param bare_peat_percent Percentage of bare peat
#* @param carbon_storage_t_ha Carbon storage in tonnes per hectare
#* @serializer json
function(
  area_hectares,
  peat_depth_cm,
  ndvi_mean,
  ndvi_std = 0.1,
  moisture_index,
  red_band = 0.15,
  nir_band = 0.45,
  swir_band = 0.30,
  drainage_status,
  land_use,
  vegetation_type,
  erosion_severity,
  bare_peat_percent,
  carbon_storage_t_ha = 500
) {

  # Create input data frame
  new_data <- tibble(
    area_hectares = as.numeric(area_hectares),
    peat_depth_cm = as.numeric(peat_depth_cm),
    ndvi_mean = as.numeric(ndvi_mean),
    ndvi_std = as.numeric(ndvi_std),
    moisture_index = as.numeric(moisture_index),
    red_band = as.numeric(red_band),
    nir_band = as.numeric(nir_band),
    swir_band = as.numeric(swir_band),
    drainage_status = as.character(drainage_status),
    land_use = as.character(land_use),
    vegetation_type = as.character(vegetation_type),
    erosion_severity = as.character(erosion_severity),
    bare_peat_percent = as.numeric(bare_peat_percent),
    carbon_storage_t_ha = as.numeric(carbon_storage_t_ha)
  )

  # Get predictions
  predictions <- augment(v_model, new_data)
  pred_class_col <- names(predictions)[grepl("^\\.pred_class$", names(predictions))]
  pred_class <- predictions[[pred_class_col]][1]

  # Extract probability columns
  prob_cols <- names(predictions)[grepl("^\\.pred_", names(predictions)) &
                                   !grepl("^\\.pred_class", names(predictions))]
  probs <- predictions[1, prob_cols, drop = FALSE]

  # Format response
  list(
    predicted_priority = as.character(pred_class),
    probabilities = as.list(probs),
    input_features = as.list(new_data[1, ]),
    note = "Prediction based on synthetic training data for demonstration purposes only"
  )
}

#* Get model information
#* @get /model-info
#* @serializer unboxedJSON
function() {

  # Load model metrics if available
  if (file.exists("ml/model_metrics.rds")) {
    metrics <- readRDS("ml/model_metrics.rds")
  } else {
    metrics <- list(
      test_accuracy = NA,
      test_roc_auc = NA,
      n_train = NA,
      n_test = NA
    )
  }

  list(
    model_name = "Peatland Priority Classifier",
    model_type = "Random Forest",
    version = v_model$metadata$version,
    accuracy = round(metrics$test_accuracy, 3),
    roc_auc = if (!is.na(metrics$test_roc_auc)) round(metrics$test_roc_auc, 3) else NULL,
    training_samples = metrics$n_train,
    test_samples = metrics$n_test,
    features = c(
      "area_hectares", "peat_depth_cm", "ndvi_mean", "ndvi_std",
      "moisture_index", "red_band", "nir_band", "swir_band",
      "drainage_status", "land_use", "vegetation_type",
      "erosion_severity", "bare_peat_percent", "carbon_storage_t_ha"
    ),
    target_classes = c("Low", "Moderate", "High", "Critical"),
    note = "Model trained on synthetic data for demonstration purposes only"
  )
}

#* Error handler
#* @error
function(req, res, err) {
  res$status <- 500
  list(
    error = TRUE,
    message = as.character(err$message)
  )
}
