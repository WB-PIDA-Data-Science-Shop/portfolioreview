## code to prepare `wb_projects_gov` dataset goes here
# set-up -----------------------------------------------------------------
library(dplyr)
library(stringr)

theme_set(
  theme_minimal()
)

devtools::load_all()

# read-in data -----------------------------------------------------------
# investigate why projects have more than a PAD
wb_documents <- portfolioreview::wb_documents |> 
  distinct(proj_id, .keep_all = TRUE) |>
  transmute(
    proj_id,
    doc_month,
    owner_label,
    pad_available = 1
  )

wb_project_components <- portfolioreview::wb_project_components |> 
  distinct(proj_id) |>
  mutate(
    project_component_available = 1
  )

wb_project_indicators <- portfolioreview::wb_project_indicators |> 
  distinct(proj_id) |>
  mutate(
    project_indicator_available = 1
  )

wb_project_themes <- portfolioreview::wb_project_themes |> 
  distinct(proj_id) |>
  mutate(
    project_theme_available = 1
  )

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

# note: 72.2 percent of lending projects have components available
wb_projects_ida <- portfolioreview::wb_projects |> 
  # only count active projects
  filter(
    proj_status == "Active"
  ) |> 
  # subset to IDA countries
  # worried about regional projects that include multiple countries, some of which are IDA
  inner_join(
    wb_country_ida,
    by = c("country_code")
  )

# check coverage
portfolioreview::wb_projects |> 
  filter(
    proj_status == "Active"
  ) |> 
  left_join(
    wb_project_components |> select(proj_id, project_component_available),
    by = "proj_id"
  ) |>
  left_join(
    wb_project_indicators |> select(proj_id, project_indicator_available),
    by = "proj_id"
  ) |> 
  left_join(
    wb_project_themes |> select(proj_id, project_theme_available),
    by = "proj_id"
  ) |> 
  mutate(
    across(ends_with("available"), ~ if_else(is.na(.x), 0, .x))
  ) |> 
  group_by(lending_instrument) |> 
  summarise(
    rate_indicator = mean(project_component_available),
    rate_theme = mean(project_theme_available),
    total = n()
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
      proj_approval_fy > 2018 &
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

wb_projects_gov <- portfolioreview::wb_projects |> 
  filter(
    proj_approval_fy >= 2018 &
      proj_status == "Active" &
      lead_gp == "GOV"
  ) |> 
  # only IDA and blend countries
  left_join(
    portfolioreview::wb_income_and_region |> select(country_code, lending_category),
    by = "country_code"
  ) |> 
  filter(
    lending_category %in% c("IDA", "Blend")
  ) |>
  left_join(
    wb_projects_gov_theme,
    by = "proj_id"
  )

# classify procurement with components data, since procurement is a novel theme (post-2025)
wb_projects_gov <- wb_projects_gov |> 
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
  "Middle East, North Africa, Afghanistan and Pakistan" = "menaap"
)

wb_projects_gov <- wb_projects_gov |>
  filter(theme_pfm | theme_procurement | theme_public_admin | theme_env_social)

usethis::use_data(wb_projects_gov, overwrite = TRUE)
