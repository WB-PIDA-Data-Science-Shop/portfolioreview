## code to prepare `wb_projects_gov` dataset goes here
# date: 8/10/2026
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
    portfolioreview::wb_income_and_region |>
      select(country_code, lending_category),
    by = "country_code"
  ) |>
  filter(
    lending_category %in% c("IDA", "Blend")
  ) |>
  select(country_code, lending_category)

projects_ida_20 <- read.csv(
  here("data-raw", "input", "ida-20", "consolidated_project_codes.csv")
)

# wb_projects_gov <- portfolioreview::wb_projects |>
#   filter(
#     proj_status == "Active" & # this filter is problematic: we need to also allow through projects that were closed during the IDA21 cycle
#       # only retain operations that are GOV led
#       (str_detect(lead_gp, "GOV") | proj_id == "P174620") & # add Digital-led but GOV contribution project in CAR
#       (agreement_type != "RETF" | is.na(agreement_type)) &
#       product_line_type %in% c("Lending Product", "Analytic and Advisory Activities Product")
#   ) |>
#   # drop ASAs without an AIN or CN approval date
#   filter(
#     !(is.na(asa_approval_date) & product_line_type == "Analytic and Advisory Activities Product")
#   ) |>
#   # only IDA and blend countries
#   inner_join(
#     wb_country_ida,
#     by = c("country_code")
#   ) |>
#   # exclude ida-20 projects that were already approved in the previous cycle
#   anti_join(
#     projects_ida_20,
#     by = c("proj_id")
#   )

# for now, only retain the original 64 projects which were extracted in April
# since those were the basis for the MTR validation
wb_projects_gov <- read_csv(
  here("inst", "extdata", "snapshot", "wb_projects_gov_2026-04-22.csv")
)

wb_projects_gov_pipeline <- portfolioreview::wb_projects |>
  filter(
    proj_status == "Pipeline" &
      (lead_gp == "GOV") &
      (agreement_type != "RETF" | is.na(agreement_type)) &
      product_line_type %in% c("Lending Product", "Analytic and Advisory Activities Product")
  ) |>
  # only IDA and blend countries
  inner_join(
    wb_country_ida,
    by = c("country_code")
  )

# include projects from MTR regional validation --------------------------
# validation conducted during the MTR exercise in July, 2026
# the final list has been validated by DE (development effectiveness)
regional_inputs <- fs::dir_ls(
  here("data-raw", "input", "regional-validation", "2026-07-mtr", "de"),
  glob = "*.xlsx"
) |> 
  purrr::map_dfr(
    \(file) openxlsx::read.xlsx(file, startRow = 3)
  ) |> 
  janitor::clean_names()

regional_inputs_ids <- regional_inputs |> 
  filter(
    !str_detect(
      p_code,
      # exclude PPA
      "^N/A"
    )
  ) |> 
  select(
    proj_id = p_code
  )

# identify regional validation inputs that were added
regional_inputs_added <- regional_inputs_ids |>
  anti_join(
    wb_projects_gov |> select(proj_id),
    by = "proj_id"
  )

# retrieve information from original wb_projects
regional_projects <- regional_inputs_added |> 
  inner_join(
    portfolioreview::wb_projects,
    by = "proj_id"
  )

# combine original gov projects and regional validation ------------------
wb_projects_gov <- bind_rows(
  wb_projects_gov,
  regional_projects
)

# fix project P502876 which has two rows, Bangladesh and Bhutan
wb_projects_gov_duplicate <- wb_projects_gov |>
  filter(
    proj_id == "P502876"
  ) |>
  distinct(
    proj_id, .keep_all = TRUE
  ) |>
  tidyr::separate_rows(
    country_name,
    sep = " and "
  ) |>
  mutate(
    country_name = case_when(
      country_name == "Bangladesh" ~ "People's Republic of Bangladesh",
      country_name == "Bhutan" ~ "Kingdom of Bhutan",
      T ~ country_name
    )
  )

wb_projects_gov <- wb_projects_gov |>
  filter(
    proj_id != "P502876"
  ) |>
  bind_rows(
    wb_projects_gov_duplicate
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

# manually add thematic classifications
wb_projects_gov <- wb_projects_gov |>
  mutate(
    theme_pfm = if_else(
      proj_id %in% c("P506552", "P507203"), # Yemen Strengthening Institutions, Myanmar Economic Monitoring
      1L,
      theme_pfm
    )
  )

# validation
wb_projects_gov_validated <- wb_projects_gov |>
  # exclude projects flagged by regional teams
  filter(
    !(proj_id %in%
      c(
        # Eastern and Southern Africa
        "P171762", # counted in the IDA 20 cycle
        "P173178", # counted in the IDA 20 cycle
        # Western and Central Africa
        "P506528", # primarily a human capital project
        "P513735", # primarily a human capital project
        "P511539", # remove duplicate
        # Middle East, North Africa, Afghanistan, and Pakistan
        "P166978", # already completed in 2023
        # South Asia
        "P515116" # will be dropped by June
      ))
  )

# write-out --------------------------------------------------------------
region_acronyms <- c(
  "East Asia and Pacific" = "eap",
  "Europe and Central Asia" = "eca",
  "Latin America and Caribbean" = "lac",
  "Middle East and North Africa" = "mena",
  "South Asia" = "sar",
  "Sub-Saharan Africa" = "afr",
  "Eastern and Southern Africa" = "afe",
  "Western and Central Africa" = "afw",
  "Middle East, North Africa, Afghanistan, and Pakistan" = "menaap"
)

# prune
wb_projects_gov_validated <- wb_projects_gov_validated |>
  select(
    proj_id,
    proj_name,
    pdo,
    region,
    country_code,
    country_name,
    proj_approval_fy,
    asa_approval_date,
    task_type,
    proj_url,
    product_line_type,
    lending_instrument,
    lead_gp,
    ttl,
    agreement_type,
    commitment_amount,
    starts_with("theme_")
  ) |>
  arrange(
    region,
    country_name,
    proj_approval_fy
  ) |>
  # add ida cycle identifier
  mutate(
    ida_cycle_approval = case_when(
      proj_approval_fy < 2026 ~ "Pre-IDA21",
      proj_approval_fy == 2026 ~ "IDA21",
      T ~ NA_character_
    )
  )

# write-out --------------------------------------------------------------
# write out regional subsets as xlsx with two sheets (Lending, ASA)
regional_dir_out <- here::here("inst", "extdata", "region", Sys.Date())

if(!dir.exists(regional_dir_out)) {
  dir.create(regional_dir_out, recursive = TRUE)
}

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
          wb,
          sheet_name,
          style = wrap_style,
          rows = seq_len(nrow(data) + 1),
          cols = seq_len(ncol(data)),
          gridExpand = TRUE
        )
        openxlsx::setColWidths(
          wb,
          sheet_name,
          cols = seq_len(ncol(data)),
          widths = "auto"
        )
        # override auto-width for known wide columns
        openxlsx::setColWidths(
          wb,
          sheet_name,
          cols = which(names(data) == "pdo"),
          widths = 60
        )
        openxlsx::setColWidths(
          wb,
          sheet_name,
          cols = which(names(data) == "proj_name"),
          widths = 40
        )
      }

      write_sheet(
        wb,
        "Lending",
        .x |> filter(product_line_type == "Lending Product")
      )
      write_sheet(
        wb,
        "ASA",
        .x |>
          filter(
            product_line_type == "Analytic and Advisory Activities Product"
          )
      )

      openxlsx::saveWorkbook(
        wb,
        paste0(
          regional_dir_out,
          "/wb_projects_gov_",
          .y$region_acronym,
          ".xlsx"
        ),
        overwrite = TRUE
      )
    }
  )

wb_projects_gov <- wb_projects_gov_validated

# snapshot
wb_projects_gov |>
  write_csv(
    here::here(
      "inst",
      "extdata",
      "snapshot",
      sprintf("wb_projects_gov_%s.csv", Sys.Date())
    )
  )

usethis::use_data(wb_projects_gov, overwrite = TRUE)
