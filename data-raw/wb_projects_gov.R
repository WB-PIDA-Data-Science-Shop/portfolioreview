## code to prepare `wb_projects_gov` dataset goes here
# #ave a list of projects that we drop because we classify them 
# as not contributing (e.g., HRM or public procurement)
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
      lead_gp == "GOV" &
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
  "Middle East, North Africa, Afghanistan, and Pakistan" = "mena"
)

# prune
wb_projects_gov_out <- wb_projects_gov |> 
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
  )

wb_projects_gov_out |> 
  readr::write_csv(
    here::here(
      "inst", "extdata",
      "wb_projects_gov.csv"
    )
  )

# write out regional subsets to inst extdata in csv format and using group_walk
wb_projects_gov |> 
  mutate(
    region_acronym = recode(region, !!!region_acronyms)
  ) |> 
  group_by(region_acronym) |> 
  group_walk(
    ~ readr::write_csv(
      .x,
      here::here(
        "inst", "extdata",
        paste0("wb_projects_gov_", .y$region_acronym, ".csv")
      )
    )
  )

usethis::use_data(wb_projects_gov, overwrite = TRUE)
