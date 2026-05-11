## code to prepare `wb_projects_gov` dataset goes here
# date: 5/11/2026
# set-up -----------------------------------------------------------------
library(dplyr)
library(stringr)
library(readr)
library(here)

devtools::load_all()

# read-in data -----------------------------------------------------------
wb_country_ida <- portfolioreview::wb_country_list |> 
  distinct(country_code, country_name) |> 
  left_join(
    portfolioreview::wb_income_and_region |> select(country_code, lending_category),
    by = "country_code"
  ) |> 
  filter(
    lending_category %in% c("IDA", "Blend")
  ) |> 
  select(country_code, lending_category)

projects_ida_20 <- read_csv(
  here("data-raw", "input", "ida-20", "consolidated_project_codes.csv")
)

wb_projects_gov <- portfolioreview::wb_projects |> 
  filter(
      proj_status == "Active" &
      (lead_gp == "GOV" | proj_id == "P174620") & # add Digital-led but GOV contribution project in CAR
      (agreement_type != "RETF" | is.na(agreement_type))
  ) |> 
  # only IDA and blend countries
  inner_join(
    wb_country_ida,
    by = c("country_code")
  ) |>
  # exclude ida-20 projects that were already approved in the previous cycle
  anti_join(
    projects_ida_20,
    by = c("proj_id" = "Project ID")
  )

# classify projects based on themes --------------------------------------
gov_pc_themes <- portfolioreview::wb_project_themes |> 
  mutate(
    across(
      c(theme_name, parent_theme_name),
      \(string) str_remove(string, "FY17 - ")
    )
  ) |> 
  distinct(proj_id, theme_name) |> 
  # classify topics with theme level 3
  filter(
    theme_name %in% c(
      # Public Financial Management
      "Public Expenditure Management",
      "Debt Management",
      "Domestic Revenue Administration",
      "Budget and Treasury Management",
      "Public Assets and Investment Management",
      "Government Financial Reporting and Balance Sheets",
      "Oversight, Accountability, and Supreme Audit Institutions",
      # Public Procurement
      "Procurement",
      # Public Administration
      "Administrative and Civil Service Reform",
      "Govtech",
      "E-Government, incl. e-services",
      "Transparency, Accountability and Good Governance",
      # Institutional dimensions of social and environmental aspects
      "Adaptation",
      "Mitigation",
      "Disaster Risk Management Governance",
      "Citizen Engagement and Social Accountability Policy, Programs, and Capacity Building",
      "Community and Local Infrastructure and Service Delivery",
      "Community Livelihoods and Local Economic Development",
      "Community and Local Governance"
    )
  ) |> 
  # classify topics into broader categories
  mutate(
    theme_category = case_when(
      theme_name %in% c(
        "Public Expenditure Management",
        "Debt Management",
        "Domestic Revenue Administration",
        "Budget and Treasury Management",
        "Public Assets and Investment Management",
        "Government Financial Reporting and Balance Sheets",
        "Oversight, Accountability, and Supreme Audit Institutions"
      ) ~ "Public Finance Management",

      theme_name == "Procurement" ~ "Public Procurement",
      
      theme_name %in% c(
        "Administrative and Civil Service Reform",
        "Govtech",
        "E-Government, incl. e-services",
        "Transparency, Accountability and Good Governance"
      ) ~ "Public Administration",
      
      theme_name %in% c(
        "Adaptation",
        "Mitigation",
        "Disaster Risk Management Governance",
        "Citizen Engagement and Social Accountability Policy, Programs, and Capacity Building",
        "Community and Local Infrastructure and Service Delivery",
        "Community Livelihoods and Local Economic Development",
        "Community and Local Governance"
      ) ~ "Institutional dimensions of social and environmental aspects",
      
      TRUE ~ NA_character_
    )
  )

wb_projects_gov_theme <- portfolioreview::wb_projects |>
  filter(
    proj_status == "Active" &
      lead_gp == "GOV"
  ) |> 
  left_join(
    gov_pc_themes |> select(proj_id, theme_category),
    by = "proj_id",
    relationship = "many-to-many"
  ) |>
  summarise(
    theme_pfm            = any(theme_category == "Public Finance Management",                        na.rm = TRUE),
    theme_procurement    = any(theme_category == "Public Procurement",                               na.rm = TRUE),
    theme_public_admin   = any(theme_category == "Public Administration",                            na.rm = TRUE),
    theme_env_social  = any(theme_category == "Institutional dimensions of social and environmental aspects", na.rm = TRUE),
    .by = proj_id
  )

# classify procurement with components data, since procurement is a novel theme (post-2025)
wb_projects_gov <- wb_projects_gov |> 
  left_join(
    wb_projects_gov_theme,
    by = "proj_id"
  ) |>
  left_join(
    portfolioreview::wb_project_components |> 
      filter(
        str_detect(comp_name, "procurement|Procurement")
      ) |> 
      distinct(proj_id) |> 
      mutate(
        component_procurement = 1
      ),
    by = "proj_id"
  ) |> 
  mutate(
    theme_procurement = if_else(
      !is.na(component_procurement) | theme_procurement,
      TRUE,
      FALSE
    )
  ) |> 
  select(-component_procurement)

# validation
wb_projects_gov_validated <- wb_projects_gov |>
  # exclude projects flagged by regional teams
  filter(
    !(
      proj_id %in% c(
        # Eastern and Southern Africa
        "P171762", # counted in the IDA 20 cycle
        "P173178", # counted in the IDA 20 cycle
        # Western and Central Africa
        "P506528", # primarily a human capital project
        "P513735",
        # Middle East, North Africa, Afghanistan, and Pakistan
        "P166978", # already completed in 2023
        # South Asia
        "P515116" # will be dropped by June
      )
    )
  )

# write-out --------------------------------------------------------------
region_acronyms <- c(
  "East Asia and Pacific"                            = "eap",
  "Europe and Central Asia"                          = "eca",
  "Latin America and Caribbean"                      = "lac",
  "Middle East and North Africa"                     = "mena",
  "South Asia"                                       = "sar",
  "Sub-Saharan Africa"                               = "afr",
  "Eastern and Southern Africa"                      = "afe",
  "Western and Central Africa"                       = "afw",
  "Middle East, North Africa, Afghanistan, and Pakistan" = "menaap"
)

# prune
wb_projects_gov_validated <- wb_projects_gov_validated |> 
  select(
    proj_id,
    proj_name,
    pdo,
    region,
    country_name,
    proj_approval_fy,
    proj_url,
    product_line_type,
    lending_instrument,
    lead_gp,
    ttl,
    agreement_type,
    commitment_amount
  ) |> 
  arrange(
    region, country_name, proj_approval_fy
  )

wb_projects_gov_validated |> 
  readr::write_csv(
    here::here(
      "inst", "extdata",
      "wb_projects_gov.csv"
    )
  )

# write out regional subsets as xlsx with two sheets (Lending, ASA)
wb_projects_gov_validated |>
  mutate(
    region_acronym = recode(region, !!!region_acronyms),
    comments = ""
  ) |>
  group_by(region_acronym) |>
  group_walk(
    ~ {
      wb <- openxlsx::createWorkbook()

      wrap_style <- openxlsx::createStyle(wrapText = TRUE, valign = "top")

      write_sheet <- function(wb, sheet_name, data) {
        openxlsx::addWorksheet(wb, sheet_name)
        openxlsx::writeData(wb, sheet_name, data)
        openxlsx::addStyle(
          wb, sheet_name,
          style     = wrap_style,
          rows      = seq_len(nrow(data) + 1),
          cols      = seq_len(ncol(data)),
          gridExpand = TRUE
        )
        openxlsx::setColWidths(
          wb, sheet_name,
          cols   = seq_len(ncol(data)),
          widths = "auto"
        )
        # override auto-width for known wide columns
        openxlsx::setColWidths(wb, sheet_name, cols = which(names(data) == "pdo"),       widths = 60)
        openxlsx::setColWidths(wb, sheet_name, cols = which(names(data) == "proj_name"), widths = 40)
      }

      write_sheet(wb, "Lending", .x |> filter(product_line_type == "Lending Product"))
      write_sheet(wb, "ASA",     .x |> filter(product_line_type == "Analytic and Advisory Activities Product"))

      openxlsx::saveWorkbook(
        wb,
        here::here("inst", "extdata", paste0("wb_projects_gov_", .y$region_acronym, ".xlsx")),
        overwrite = TRUE
      )
    }
  )

usethis::use_data(wb_projects_gov, overwrite = TRUE)
