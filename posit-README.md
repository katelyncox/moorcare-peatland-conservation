# Peatland Restoration Demo - Internal Guide

**Demo for**: Department for Environment, Food and Rural Affairs (Defra)
**Customer Status**: Current Customer
**Target Audience**: DASH Platform (Data Analytics and Science Hub) Users
**Use Case**: Peatland Restoration Identification using AI and satellite imagery

## Quick Start

This 10-minute read provides everything you need to successfully demonstrate this project to Defra.

## Background

### Customer Context

**Defra** is a UK government department responsible for environmental protection, food production, and rural affairs. Their **DASH platform** (Data Analytics and Science Hub) processes large-scale environmental data including:

- Aerial photography and satellite imagery
- Environmental monitoring indicators
- Earth observation data for conservation

### The Use Case

**Peatland Restoration** is a flagship DASH project that:
- Analyzes satellite and aerial imagery to identify degraded peatlands
- Prioritizes sites for restoration based on environmental indicators
- Supports the 25 Year Environment Plan's conservation goals
- Previously difficult due to data fragmentation - now solved with scalable AI

**Why it matters**: Healthy peatlands store massive amounts of carbon. Degraded peatlands release CO2, contributing to climate change. Identifying and restoring these sites is critical for environmental conservation.

## Project Overview

This demo showcases an end-to-end workflow for peatland restoration analysis:

1. **Synthetic Data Generation**: 500 peatland sites with realistic environmental indicators
2. **ML Model**: Random forest classifier (76% accuracy) predicting restoration priority
3. **Quarto Report**: Comprehensive EDA with visualizations and insights
4. **Shiny Dashboard**: Interactive exploration and real-time ML predictions
5. **REST API**: Programmatic access for integration with other systems
6. **Databricks Integration**: Scalable data processing with row-level security

## Setup (5 minutes)

### First Time Setup

```bash
cd MoorCare_Conservation_EnvironmentalConservation

# In R console:
renv::restore()
source("data/generate_data.R")
```

### Pre-Demo Checklist

- [ ] Synthetic data generated (`data/` folder has 3 CSV files)
- [ ] ML model trained (`ml/peatland_priority_model/` folder exists)
- [ ] EDA report rendered (`eda.html` exists)
- [ ] Test Shiny app launches: `shiny::runApp("app.R")`
- [ ] Test API starts: `plumber::pr("api.R") |> plumber::pr_run(port=8000)`

**Troubleshooting**:
- If data files missing: Run `source("data/generate_data.R")`
- If ML model missing: Run `source("ml/train_model.R")`
- If packages missing: Run `renv::restore()`

## Demo Script (15-20 minutes)

### Part 1: The Problem & Data (3 min)

**Open**: `eda.html` in browser

**Script**:
> "Defra's DASH platform processes vast amounts of satellite and aerial imagery to identify peatlands needing restoration. This demo shows how Posit tools enable this analysis at scale."
>
> "We're analyzing 500 peatland sites across the UK with satellite-derived indicators like NDVI (vegetation health), moisture content, drainage status, and erosion severity."

**Highlight**:
- Show the Executive Summary with key findings
- Point out 134 critical priority sites
- Note regional variations (Scotland vs England)

### Part 2: Environmental Analysis (4 min)

**Stay in**: `eda.html`

**Script**:
> "The analysis combines multiple environmental indicators to assess peatland health. Let's look at some key relationships..."

**Highlight** these specific visualizations:
1. **Priority Distribution** - Show 4-tier priority system
2. **Drainage Impact** - Demonstrate how drainage correlates with degradation
3. **NDVI vs Moisture** - Show healthy vs degraded peatlands
4. **Regional Comparison** - Scotland has highest need

**Key Talking Point**:
> "This Quarto report auto-generates with latest data. You can schedule it to run weekly, monthly, etc. and email stakeholders automatically."

### Part 3: Machine Learning Model (3 min)

**Open**: Terminal and show `ml/train_model.R` briefly

**Script**:
> "We trained a random forest model that predicts restoration priority with 76% accuracy using 14 environmental features from satellite imagery."

**Highlight**:
- Feature importance: Drainage status and bare peat % are top predictors
- Model is saved with vetiver for easy deployment
- Can be retrained as new data arrives

**Demo Value**:
> "Posit Workbench lets your data scientists develop models in their preferred environment - R or Python - then deploy them seamlessly."

### Part 4: Interactive Dashboard (5 min)

**Launch**: `shiny::runApp("app.R")`

**Script**:
> "Decision-makers need interactive tools to explore the data. This Shiny dashboard provides real-time access to all 500 sites and live ML predictions."

**Walk through each tab**:

1. **Overview Tab**:
   - Value boxes: 500 sites, 134 critical, 23 active projects
   - Show interactive plots updating in real-time

2. **Site Explorer Tab**:
   - Filter by region (select "Scotland")
   - Filter by priority (select "Critical")
   - "This filtered table shows the 47 highest-priority sites in Scotland"

3. **Priority Predictor Tab**:
   - Change inputs: Set drainage to "Fully Drained", erosion to "Severe", bare peat to 50%
   - Click "Predict Priority"
   - Show prediction result with probability distribution
   - "The model instantly classifies this site as Critical priority"

4. **Projects Tab**:
   - Show 80 restoration projects
   - Mix of Planned, In Progress, and Completed
   - Highlight intervention types and costs

**Key Talking Points**:
- Branded with MoorCare Conservation colors (`_brand.yml`)
- Deploy to Posit Connect for stakeholder access
- Can add authentication for sensitive data

### Part 5: API & Automation (3 min)

**Start API**: `plumber::pr("api.R") |> plumber::pr_run(port=8000)`
**Open**: `http://localhost:8000/__docs__/`

**Script**:
> "For integration with other systems or automated workflows, we've exposed the model and data through a REST API."

**Demo**:
1. Show Swagger docs interface
2. Test `/health` endpoint
3. Test `/data/summary` - shows JSON response
4. Show `/predict` endpoint structure

**Key Talking Point**:
> "Your GIS teams, web developers, or other systems can now query predictions programmatically. Deploy this to Posit Connect and it scales automatically."

### Part 6: Databricks Integration (2 min)

**Show**: `databricks_ddl.sql` and `upload_to_databricks.py`

**Script**:
> "For customers using Databricks, we can load this data directly and apply row-level security."

**Highlight**:
- Data uploaded to Databricks volumes
- Tables created in `sol_eng_demo_nickp.moorcare` schema
- Row access policy limits `demo_databricks_user@posit.co` to Scotland only
- Both R and Python can connect via ODBC

**Show in code** (briefly):
- Point to commented Databricks code in `app.R` and `eda.qmd`
- "Uncomment these lines to query Databricks instead of local CSV files"

## Key Value Propositions for Defra/DASH

### 1. End-to-End Platform
> "From data ingestion through Databricks, to analysis in Workbench, to deployment on Connect - all in one platform."

### 2. Scalability
> "DASH processes vast amounts of imagery. Posit scales from prototype on a laptop to production serving thousands of analysts."

### 3. Collaboration
> "Data scientists work in R or Python - their choice. Stakeholders access via web dashboards. No code required for end users."

### 4. Reproducibility
> "Every analysis is code-based. Quarto reports show exactly what was done. Version control with Git built-in."

### 5. Deployment
> "One-click publish from Workbench to Connect. Automatic scaling. Authentication. Scheduled updates."

## Q&A Preparation

**Q: Is this real peatland data?**
> No, this is synthetic data generated for demonstration. The patterns and relationships are realistic based on published research, but no actual Defra data was used.

**Q: Can we adapt this for our actual DASH data?**
> Absolutely! This serves as a template. Replace the data generation with your actual data pipelines. The analysis structure transfers directly.

**Q: What about illegal forest felling detection mentioned in their projects?**
> This template works for that too! Change the response variable from "restoration priority" to "deforestation risk" and use similar satellite features. The workflow is identical.

**Q: How does this integrate with our existing tools?**
> The API provides RESTful endpoints. Your GIS systems, web portals, or workflow automation can call these endpoints. We can also export to any format you need.

**Q: What about the 25 Year Environment Plan indicators?**
> The dashboard structure easily adapts to track multiple indicators. Create tabs for each indicator framework with automated monthly reports.

## Technical Details (For Deep Dives)

### Data Context
- **500 peatland sites** across 5 UK regions
- **Environmental indicators**: NDVI, moisture, drainage, erosion, vegetation
- **Time series**: 7 years (2018-2024) for 50 monitored sites
- **Projects**: 80 restoration initiatives with costs and timelines

### Model Performance
- Algorithm: Random Forest (500 trees, mtry=5, min_n=10)
- Accuracy: 76.2%
- Top Features: Drainage status, bare peat %, erosion severity
- Deployed with vetiver for easy versioning

### Databricks Row-Level Security
- Filter function: `peatland_filter(region)`
- Rule: `demo_databricks_user@posit.co` sees only Scotland records
- Applied to: `synthetic_peatland_sites` table
- Demonstrates data governance for multi-tenant environments

## Next Steps & Call to Action

After the demo, suggest:

1. **Pilot Project**: Start with one DASH use case (e.g., peatland or forest monitoring)
2. **Training**: Posit Academy courses for DASH team upskilling
3. **Architecture Review**: Discuss integration with existing Databricks setup
4. **POC Timeline**: 4-6 weeks to adapt this template to actual DASH data

**Close with**:
> "This demonstrates the art of the possible. With your actual DASH data, we can create similar workflows for peatland restoration, forest monitoring, water quality assessment - any use case where you're analyzing earth observation data at scale."

## Helpful Resources

- [Posit Connect](https://posit.co/products/enterprise/connect/)
- [Quarto Documentation](https://quarto.org)
- [Shiny for R](https://shiny.posit.co)
- [vetiver Documentation](https://vetiver.rstudio.com)
- [Databricks with Posit](https://solutions.posit.co/connections/db/databases/databricks/)

---

**Demo Prepared By**: Claude AI via Posit Demo Generator
**Last Updated**: 2025-11-05
**Questions?**: Contact your Posit account team
