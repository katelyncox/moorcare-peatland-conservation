# Peatland Restoration Priority Dashboard
# Interactive application for visualizing and predicting restoration priorities
# This project contains synthetic data created for demonstration purposes only.

library(shiny)
library(bslib)
library(dplyr)
library(ggplot2)
library(readr)
library(DT)
library(vetiver)
library(pins)
library(scales)

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

# UI
ui <- page_navbar(
  title = "Peatland Restoration Dashboard",
  theme = bs_theme(brand = "_brand.yml"),

  # Overview Tab
  nav_panel(
    "Overview",
    layout_columns(
      col_widths = c(3, 3, 3, 3),
      value_box(
        title = "Total Sites",
        value = nrow(peatland_sites),
        theme = "primary"
      ),
      value_box(
        title = "Critical Priority",
        value = sum(peatland_sites$restoration_priority == "Critical"),
        theme = "danger"
      ),
      value_box(
        title = "Active Projects",
        value = sum(restoration_projects$project_status == "In Progress"),
        theme = "success"
      ),
      value_box(
        title = "Total Area (ha)",
        value = format(round(sum(peatland_sites$area_hectares)), big.mark = ","),
        theme = "info"
      )
    ),

    layout_columns(
      col_widths = c(6, 6),
      card(
        card_header("Priority Distribution"),
        plotOutput("priority_plot", height = "300px")
      ),
      card(
        card_header("Regional Summary"),
        plotOutput("regional_plot", height = "300px")
      )
    ),

    card(
      card_header("Restoration Cost by Priority"),
      plotOutput("cost_plot", height = "300px")
    )
  ),

  # Site Explorer Tab
  nav_panel(
    "Site Explorer",
    layout_sidebar(
      sidebar = sidebar(
        title = "Filters",
        selectInput(
          "filter_region",
          "Region",
          choices = c("All", unique(peatland_sites$region)),
          selected = "All"
        ),
        selectInput(
          "filter_priority",
          "Priority",
          choices = c("All", "Critical", "High", "Moderate", "Low"),
          selected = "All"
        ),
        selectInput(
          "filter_drainage",
          "Drainage Status",
          choices = c("All", unique(peatland_sites$drainage_status)),
          selected = "All"
        )
      ),
      card(
        card_header("Peatland Sites"),
        DTOutput("sites_table")
      )
    )
  ),

  # ML Predictor Tab
  nav_panel(
    "Priority Predictor",
    layout_sidebar(
      sidebar = sidebar(
        title = "Site Characteristics",
        numericInput("pred_area", "Area (hectares)", value = 50, min = 1),
        numericInput("pred_depth", "Peat Depth (cm)", value = 120, min = 30),
        numericInput("pred_ndvi", "NDVI", value = 0.5, min = 0, max = 1, step = 0.01),
        numericInput("pred_moisture", "Moisture Index", value = 0.5, min = 0, max = 1, step = 0.01),
        numericInput("pred_bare_peat", "Bare Peat (%)", value = 20, min = 0, max = 100),
        selectInput("pred_drainage", "Drainage Status",
                   choices = c("Intact", "Partially Drained", "Heavily Drained", "Fully Drained")),
        selectInput("pred_erosion", "Erosion Severity",
                   choices = c("None", "Low", "Moderate", "High", "Severe")),
        selectInput("pred_vegetation", "Vegetation Type",
                   choices = c("Sphagnum Moss", "Cotton Grass", "Heather", "Mixed", "Degraded")),
        selectInput("pred_land_use", "Land Use",
                   choices = c("Natural", "Grazing", "Forestry", "Agriculture", "Abandoned")),
        actionButton("predict_btn", "Predict Priority", class = "btn-primary")
      ),
      card(
        card_header("Prediction Results"),
        uiOutput("prediction_output")
      ),
      card(
        card_header("Model Information"),
        p("Model Type: Random Forest Classifier"),
        p("Training Accuracy: 76.2%"),
        p("Features: 14 environmental and site characteristics"),
        p(strong("Note:"), "This model uses synthetic data for demonstration purposes only.")
      )
    )
  ),

  # Restoration Projects Tab
  nav_panel(
    "Projects",
    card(
      card_header("Restoration Projects"),
      DTOutput("projects_table")
    ),
    layout_columns(
      col_widths = c(6, 6),
      card(
        card_header("Project Status"),
        plotOutput("project_status_plot", height = "300px")
      ),
      card(
        card_header("Intervention Types"),
        plotOutput("intervention_plot", height = "300px")
      )
    )
  ),

  # Footer
  nav_spacer(),
  nav_item(
    tags$div(
      style = "padding: 10px;",
      tags$small(
        class = "text-muted",
        "This project contains synthetic data and analysis created for demonstration purposes only."
      )
    )
  )
)

# Server
server <- function(input, output, session) {

  # Databricks connection (commented out for local data)
  # pool_con <- reactive({
  #   con <- try(
  #     dbPool(
  #       odbc::databricks(),
  #       workspace = DATABRICKS_WORKSPACE_URL,
  #       httpPath = DATABRICKS_HTTPPATH
  #     )
  #   )
  #
  #   validate(need(class(con) != "try-error", "Issue connecting to Databricks"))
  #
  #   con
  # })

  # To use Databricks data, uncomment these lines:
  # peatland_sites <- tbl(pool_con(), in_catalog("demos", "moorcare", "synthetic_peatland_sites"))
  # monitoring_data <- tbl(pool_con(), in_catalog("demos", "moorcare", "synthetic_monitoring_data"))
  # restoration_projects <- tbl(pool_con(), in_catalog("demos", "moorcare", "synthetic_restoration_projects"))

  # Filtered data for site explorer
  filtered_sites <- reactive({
    data <- peatland_sites

    if (input$filter_region != "All") {
      data <- data |> filter(region == input$filter_region)
    }

    if (input$filter_priority != "All") {
      data <- data |> filter(restoration_priority == input$filter_priority)
    }

    if (input$filter_drainage != "All") {
      data <- data |> filter(drainage_status == input$filter_drainage)
    }

    data
  })

  # Overview plots
  output$priority_plot <- renderPlot({
    peatland_sites |>
      count(restoration_priority) |>
      mutate(restoration_priority = factor(restoration_priority,
                                           levels = c("Low", "Moderate", "High", "Critical"))) |>
      ggplot(aes(x = restoration_priority, y = n, fill = restoration_priority)) +
      geom_col() +
      scale_fill_manual(values = c("Low" = "#6B8E23", "Moderate" = "#4A90E2",
                                    "High" = "#D2691E", "Critical" = "#8B4513")) +
      labs(x = "Priority", y = "Number of Sites") +
      theme_minimal() +
      theme(legend.position = "none")
  })

  output$regional_plot <- renderPlot({
    peatland_sites |>
      group_by(region) |>
      summarise(avg_priority = mean(priority_score), .groups = "drop") |>
      ggplot(aes(x = reorder(region, avg_priority), y = avg_priority, fill = avg_priority)) +
      geom_col() +
      scale_fill_gradient(low = "#6B8E23", high = "#8B4513") +
      labs(x = "Region", y = "Average Priority Score") +
      coord_flip() +
      theme_minimal() +
      theme(legend.position = "none")
  })

  output$cost_plot <- renderPlot({
    peatland_sites |>
      mutate(total_cost = area_hectares * restoration_cost_per_ha / 1e6) |>
      group_by(restoration_priority) |>
      summarise(total = sum(total_cost), .groups = "drop") |>
      mutate(restoration_priority = factor(restoration_priority,
                                           levels = c("Low", "Moderate", "High", "Critical"))) |>
      ggplot(aes(x = restoration_priority, y = total, fill = restoration_priority)) +
      geom_col() +
      scale_fill_manual(values = c("Low" = "#6B8E23", "Moderate" = "#4A90E2",
                                    "High" = "#D2691E", "Critical" = "#8B4513")) +
      labs(x = "Priority", y = "Estimated Cost (£M)") +
      theme_minimal() +
      theme(legend.position = "none")
  })

  # Site explorer table
  output$sites_table <- renderDT({
    filtered_sites() |>
      select(site_id, region, area_hectares, restoration_priority,
             drainage_status, erosion_severity, priority_score) |>
      datatable(
        options = list(pageLength = 15, scrollX = TRUE),
        rownames = FALSE,
        colnames = c("Site ID", "Region", "Area (ha)", "Priority",
                    "Drainage", "Erosion", "Score")
      )
  })

  # ML Prediction
  prediction <- eventReactive(input$predict_btn, {
    new_data <- tibble(
      area_hectares = input$pred_area,
      peat_depth_cm = input$pred_depth,
      ndvi_mean = input$pred_ndvi,
      ndvi_std = 0.1,  # Default value
      moisture_index = input$pred_moisture,
      red_band = 0.15,  # Default value
      nir_band = 0.45,  # Default value
      swir_band = 0.30,  # Default value
      drainage_status = input$pred_drainage,
      land_use = input$pred_land_use,
      vegetation_type = input$pred_vegetation,
      erosion_severity = input$pred_erosion,
      bare_peat_percent = input$pred_bare_peat,
      carbon_storage_t_ha = 500  # Default value
    )

    predict(v_model, new_data, type = "prob")
  })

  output$prediction_output <- renderUI({
    req(input$predict_btn)

    pred <- prediction()
    pred_class <- names(pred)[which.max(pred)]
    pred_class <- gsub(".pred_", "", pred_class)
    pred_prob <- max(pred) * 100

    color_map <- c(
      "Low" = "success",
      "Moderate" = "info",
      "High" = "warning",
      "Critical" = "danger"
    )

    tagList(
      value_box(
        title = "Predicted Priority",
        value = pred_class,
        theme = color_map[[pred_class]]
      ),
      h4("Probability Distribution"),
      tags$div(
        class = "mt-3",
        lapply(names(pred), function(name) {
          level <- gsub(".pred_", "", name)
          prob <- round(pred[[name]] * 100, 1)
          tags$div(
            class = "mb-2",
            tags$strong(paste0(level, ":")),
            tags$div(
              class = "progress",
              style = "height: 25px;",
              tags$div(
                class = paste0("progress-bar bg-", color_map[[level]]),
                style = paste0("width: ", prob, "%"),
                paste0(prob, "%")
              )
            )
          )
        })
      )
    )
  })

  # Projects tab
  output$projects_table <- renderDT({
    restoration_projects |>
      select(project_id, site_id, project_status, intervention_type,
             total_cost, funding_source, start_date) |>
      mutate(total_cost = scales::dollar(total_cost, prefix = "£")) |>
      datatable(
        options = list(pageLength = 15, scrollX = TRUE),
        rownames = FALSE,
        colnames = c("Project ID", "Site ID", "Status", "Intervention",
                    "Cost", "Funding", "Start Date")
      )
  })

  output$project_status_plot <- renderPlot({
    restoration_projects |>
      count(project_status) |>
      ggplot(aes(x = "", y = n, fill = project_status)) +
      geom_col(width = 1) +
      coord_polar(theta = "y") +
      scale_fill_manual(values = c("Planned" = "#4A90E2", "In Progress" = "#D2691E",
                                    "Completed" = "#6B8E23")) +
      labs(fill = "Status") +
      theme_void()
  })

  output$intervention_plot <- renderPlot({
    restoration_projects |>
      count(intervention_type) |>
      ggplot(aes(x = reorder(intervention_type, n), y = n, fill = intervention_type)) +
      geom_col() +
      coord_flip() +
      labs(x = "Intervention Type", y = "Number of Projects") +
      theme_minimal() +
      theme(legend.position = "none")
  })
}

# Run the application
shinyApp(ui = ui, server = server)
