# Machine Learning Model Training Script
# Predicting Peatland Restoration Priority
# This script uses synthetic data for demonstration purposes only.

library(tidymodels)
library(readr)
library(dplyr)
library(vetiver)

set.seed(123)

# Check if data exists, if not generate it
if (!file.exists("data/synthetic-peatland-sites.csv")) {
  message("Generating synthetic data...")
  source("data/generate_data.R")
}

# Load data
cat("Loading peatland sites data...\n")
peatland_sites <- read_csv("data/synthetic-peatland-sites.csv",
                           show_col_types = FALSE,
                           na = "null")

# Prepare data for modeling
model_data <- peatland_sites |>
  select(
    restoration_priority,
    area_hectares,
    peat_depth_cm,
    ndvi_mean,
    ndvi_std,
    moisture_index,
    red_band,
    nir_band,
    swir_band,
    drainage_status,
    land_use,
    vegetation_type,
    erosion_severity,
    bare_peat_percent,
    carbon_storage_t_ha
  ) |>
  mutate(
    restoration_priority = factor(restoration_priority,
                                  levels = c("Low", "Moderate", "High", "Critical"))
  )

# Split data
cat("Splitting data into training and testing sets...\n")
data_split <- initial_split(model_data, prop = 0.75, strata = restoration_priority)
train_data <- training(data_split)
test_data <- testing(data_split)

cat("  Training set:", nrow(train_data), "samples\n")
cat("  Test set:", nrow(test_data), "samples\n")

# Create recipe
cat("\nCreating feature engineering recipe...\n")
cat("  - Handling missing values with median imputation\n")
priority_recipe <- recipe(restoration_priority ~ ., data = train_data) |>
  step_impute_median(all_numeric_predictors()) |>
  step_dummy(all_nominal_predictors()) |>
  step_normalize(all_numeric_predictors()) |>
  step_zv(all_predictors())

# Define model specification (using random forest with fixed parameters)
cat("Defining model specification...\n")
rf_spec <- rand_forest(
  mtry = 5,
  trees = 500,
  min_n = 10
) |>
  set_mode("classification") |>
  set_engine("ranger", importance = "impurity")

# Create workflow
priority_workflow <- workflow() |>
  add_recipe(priority_recipe) |>
  add_model(rf_spec)

# Fit model
cat("Training model...\n")
final_fit <- priority_workflow |>
  fit(data = train_data)

cat("✓ Model training complete\n")

# Evaluate on test set
cat("\nEvaluating model performance...\n")
test_predictions <- final_fit |>
  augment(test_data)

# Calculate metrics
test_metrics <- test_predictions |>
  metrics(truth = restoration_priority, estimate = .pred_class)

cat("\n=== Model Performance Metrics ===\n")
print(test_metrics)

# Calculate multi-class ROC AUC (if all classes are present)
pred_cols <- names(test_predictions)[grepl("^\\.pred_", names(test_predictions)) &
                                      !names(test_predictions) %in% ".pred_class"]

# Only calculate ROC AUC if we have matching prediction columns for each level
truth_levels <- levels(test_predictions$restoration_priority)
pred_level_cols <- paste0(".pred_", truth_levels)

if (all(pred_level_cols %in% names(test_predictions))) {
  test_roc <- test_predictions |>
    roc_auc(truth = restoration_priority, all_of(pred_level_cols))
  cat("\nROC AUC Score:", round(test_roc$.estimate, 3), "\n")
  roc_score <- test_roc$.estimate
} else {
  cat("\nNote: ROC AUC not calculated (not all prediction columns present)\n")
  roc_score <- NA
}

# Confusion matrix
cat("\n=== Confusion Matrix ===\n")
conf_mat_result <- test_predictions |>
  conf_mat(truth = restoration_priority, estimate = .pred_class)
print(conf_mat_result)

# Feature importance
cat("\n=== Top 10 Most Important Features ===\n")
feature_importance <- final_fit |>
  extract_fit_parsnip() |>
  vip::vi() |>
  slice_head(n = 10)

print(feature_importance)

# Save model using vetiver
cat("\nSaving model with vetiver...\n")
v_model <- vetiver_model(final_fit, "peatland_priority_model")
vetiver_pin_write(board = pins::board_folder("ml"), v_model)

# Save model metrics
model_metrics <- list(
  test_accuracy = test_metrics |>
    filter(.metric == "accuracy") |>
    pull(.estimate),
  test_roc_auc = roc_score,
  n_train = nrow(train_data),
  n_test = nrow(test_data),
  feature_importance = feature_importance,
  confusion_matrix = conf_mat_result
)

saveRDS(model_metrics, "ml/model_metrics.rds")

cat("\n✓ Model training and evaluation complete!\n")
cat("  - Model saved to: ml/peatland_priority_model/\n")
cat("  - Metrics saved to: ml/model_metrics.rds\n")
cat("  - Test Accuracy:", round(model_metrics$test_accuracy, 3), "\n")
if (!is.na(roc_score)) {
  cat("  - Test ROC AUC:", round(model_metrics$test_roc_auc, 3), "\n")
}
cat("\nModel ready for deployment via API or Shiny app.\n")
