# Peatland Restoration Priority Analysis

A comprehensive data science project demonstrating how to identify and prioritize peatland restoration sites using satellite imagery analysis, environmental indicators, and machine learning.

## Overview

This project showcases an end-to-end analytical workflow for environmental conservation, specifically focused on peatland restoration. It demonstrates:

- **Data Science Workflow**: From data generation to deployed machine learning models
- **Interactive Analytics**: Real-time dashboards for exploring restoration priorities
- **Automated Predictions**: REST API for programmatic access to ML predictions
- **Scalable Architecture**: Integration with Databricks for large-scale data processing
- **Reproducible Research**: Quarto-based reports with embedded code and visualizations

## Project Structure

```
MoorCare_Conservation_EnvironmentalConservation/
├── data/                           # Synthetic data files
│   ├── generate_data.R             # Data generation script
│   ├── synthetic-peatland-sites.csv
│   ├── synthetic-monitoring-data.csv
│   └── synthetic-restoration-projects.csv
├── ml/                             # Machine learning models
│   ├── train_model.R               # Model training script
│   ├── model_metrics.rds           # Model performance metrics
│   └── peatland_priority_model/    # Saved vetiver model
├── eda.qmd                         # Exploratory data analysis report
├── app.R                           # Interactive Shiny dashboard
├── api.R                           # REST API with Plumber
├── _brand.yml                      # MoorCare Conservation branding
├── databricks_ddl.sql              # Databricks table definitions
├── upload_to_databricks.py         # Databricks data upload script
├── renv/                           # R environment management
├── renv.lock                       # R package dependencies
├── README.md                       # This file
└── posit-README.md                 # Internal demo guide
```

## Getting Started

### Prerequisites

- R 4.5+ with renv installed
- Python 3.8+ (for Databricks integration)
- Quarto 1.3+
- RStudio (recommended)

### Installation

1. **Clone this repository**:
   ```bash
   git clone <repository-url>
   cd MoorCare_Conservation_EnvironmentalConservation
   ```

2. **Restore R environment**:
   ```r
   # In R console
   renv::restore()
   ```

3. **Generate synthetic data**:
   ```r
   # In R console
   source("data/generate_data.R")
   ```

## Using the Project

### 1. Exploratory Data Analysis

The `eda.qmd` file contains a comprehensive analysis of peatland sites, including:

- Site prioritization and regional analysis
- Environmental indicators and degradation patterns
- Restoration cost estimates
- Temporal trends in vegetation health

**Render the report**:
```bash
quarto render eda.qmd
```

This generates an HTML report (`eda.html`) with interactive visualizations and embedded analysis.

### 2. Machine Learning Model

Train a random forest classifier to predict restoration priority:

```r
# In R console
source("ml/train_model.R")
```

The model:
- Achieves 76%+ accuracy on test data
- Uses 14 environmental and site features
- Saved using vetiver for easy deployment
- Generates feature importance rankings

### 3. Interactive Dashboard

Launch the Shiny application for interactive exploration:

```r
# In R console
shiny::runApp("app.R")
```

The dashboard provides:
- **Overview**: Key metrics and regional summaries
- **Site Explorer**: Filterable table of all peatland sites
- **Priority Predictor**: Real-time ML predictions for new sites
- **Projects**: Restoration project tracking and analysis

### 4. REST API

Start the Plumber API for programmatic access:

```r
# In R console
plumber::pr("api.R") |> plumber::pr_run(port = 8000)
```

**Available endpoints**:

- `GET /health` - API health check
- `GET /data/sites` - Retrieve peatland sites (with filters)
- `GET /data/summary` - Summary statistics
- `GET /model-info` - ML model metadata
- `POST /predict` - Generate restoration priority predictions

View interactive API documentation at: `http://localhost:8000/__docs__/`

## Databricks Integration

This project includes scripts for loading data into Databricks with row-level security.

### Setup

1. **Install Python dependencies**:
   ```bash
   pip install databricks-sdk databricks-sql-connector
   ```

2. **Configure Databricks credentials**:
   ```bash
   export DATABRICKS_HOST="your-workspace.databricks.com"
   export DATABRICKS_TOKEN="your-access-token"
   export DATABRICKS_HTTP_PATH="/sql/1.0/warehouses/your-warehouse-id"
   ```

3. **Upload data**:
   ```bash
   python upload_to_databricks.py
   ```

This creates tables in the `sol_eng_demo_nickp.moorcare` schema with row-level security applied.

### Using Databricks Data

Update the analysis scripts to connect to Databricks:

**In R (eda.qmd or app.R)**:
```r
con <- dbConnect(odbc::databricks())
peatland_sites <- tbl(con, in_catalog("sol_eng_demo_nickp", "moorcare", "synthetic_peatland_sites"))
```

## Custom Branding

This project uses `_brand.yml` for consistent theming across all outputs. To customize for your organization:

1. Edit `_brand.yml` with your brand colors, fonts, and logo
2. Regenerate outputs (Quarto report, Shiny app)
3. All visualizations and UI elements automatically adopt your branding

## Adapting This Project

This demonstration provides a template for similar analytical workflows. To adapt for your needs:

1. **Replace synthetic data** with your actual environmental datasets
2. **Customize features** in `ml/train_model.R` for your specific indicators
3. **Update visualizations** in `eda.qmd` for your key metrics
4. **Modify dashboard** in `app.R` to match your workflow
5. **Extend API** in `api.R` with additional endpoints

## Technical Stack

- **R**: tidyverse, tidymodels, vetiver, shiny, bslib
- **Reporting**: Quarto, gt (tables)
- **ML**: Random Forest (ranger), vetiver (deployment)
- **API**: plumber
- **Data**: Databricks, ODBC
- **Version Control**: renv (R), uv (Python)

## Support

For questions about using this demonstration or implementing similar workflows:

- Review the `posit-README.md` for internal demo guidance
- Contact your Posit representative
- Visit [Posit Documentation](https://docs.posit.co)

---

## Important Disclaimer

**This project contains synthetic data and analysis created for demonstration purposes only.**

All data, insights, business scenarios, and analytics presented in this demonstration project have been artificially generated using AI. The data does not represent actual business information, performance metrics, customer data, or operational statistics.

### Key Points:

- **Synthetic Data**: All datasets are computer-generated and designed to illustrate analytical capabilities
- **Illustrative Analysis**: Insights and recommendations are examples of the types of analysis possible with Posit tools
- **No Actual Business Data**: No real business information or data was used or accessed in creating this demonstration
- **Educational Purpose**: This project serves as a technical demonstration of data science workflows and reporting capabilities
- **AI-Generated Content**: Analysis, commentary, and business scenarios were created by AI for illustration purposes
- **No Real-World Implications**: The scenarios and insights presented should not be interpreted as actual business advice or strategies

This demonstration showcases how Posit's data science platform and open-source tools can be applied to the environmental conservation industry. The synthetic data and analysis provide a foundation for understanding the potential value of implementing similar analytical workflows with actual business data.

For questions about adapting these techniques to your real business scenarios, please contact your Posit representative.

---

*This demonstration was created using Posit's commercial data science tools and open-source packages. All synthetic data and analysis are provided for evaluation purposes only.*
