library(dplyr)
library(readr)
library(stringr)

# identify all GOV projects by thematic area
wb_projects_gov <- portfolioreview::wb_projects |>
  filter(
    proj_status == "Active" &
      (lead_gp == "GOV") &
      product_line_type %in% c("Lending Product", "Analytic and Advisory Activities Product")
  )

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
    theme_name %in%
      c(
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
      theme_name %in%
        c(
          "Public Expenditure Management",
          "Debt Management",
          "Domestic Revenue Administration",
          "Budget and Treasury Management",
          "Public Assets and Investment Management",
          "Government Financial Reporting and Balance Sheets",
          "Oversight, Accountability, and Supreme Audit Institutions"
        ) ~ "Public Finance Management",

      theme_name == "Procurement" ~ "Public Procurement",

      theme_name %in%
        c(
          "Administrative and Civil Service Reform",
          "Govtech",
          "E-Government, incl. e-services",
          "Transparency, Accountability and Good Governance"
        ) ~ "Public Administration",

      theme_name %in%
        c(
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

wb_projects_gov_theme <-  portfolioreview::wb_projects |>
  left_join(
    gov_pc_themes |> select(proj_id, theme_category),
    by = "proj_id",
    relationship = "many-to-many"
  ) |>
  summarise(
    theme_pfm = if_else(
      any(theme_category == "Public Finance Management", na.rm = TRUE),
      1L,
      0L
    ),
    theme_procurement = if_else(
      any(theme_category == "Public Procurement", na.rm = TRUE),
      1L,
      0L
    ),
    theme_public_admin = if_else(
      any(theme_category == "Public Administration", na.rm = TRUE),
      1L,
      0L
    ),
    theme_env_social = if_else(
      any(
        theme_category ==
          "Institutional dimensions of social and environmental aspects",
        na.rm = TRUE
      ),
      1L,
      0L
    ),
    .by = proj_id
  )

# classify procurement with components data, since procurement is a novel theme (post-2025)
wb_projects_gov <- wb_projects_gov |>
  select(-starts_with("theme")) |> 
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
      1,
      0
    )
  ) |>
  select(-component_procurement)

wb_projects_gov |>
  filter(
    country_code != "UKR"
  ) |>
  group_by(
    product_line_type,
    region
  ) |>
  summarise(
    total_projects = n(),
    total_commitment = sum(commitment_amount, na.rm = TRUE),
    theme_pfm = sum(theme_pfm),
    theme_procurement = sum(theme_procurement),
    theme_public_admin = sum(theme_public_admin),
    theme_env_social = sum(theme_env_social),
    .groups = "drop"
  ) |>
  write_csv(
    here::here("inst/extdata/adhoc/gov_portfolio_review_all.csv")
  )
