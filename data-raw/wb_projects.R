## code to prepare `wb_operations` dataset goes here
library(dplyr)
library(readr)
library(stringr)
library(countrycode)
library(here)

# extracted from https://dataexplorer.worldbank.org/data/details?id=DS04442&t=Preview%20Data
# on: 2026-04-21
wb_projects <- read_csv(
  here(
    "data-raw", "input", "wb-data-explorer",
    "PROJECT_MASTER_V3_04_21_2026.csv"
  ),
  skip = 4
) |>
  janitor::clean_names()

# extracted from https://dataexplorer.worldbank.org/data/details?id=DS04532&t=Preview%20Data
# on: 2026-04-22
country_list <- read_csv(
  here(
    "data-raw", "input", "wb-data-explorer",
    "COUNTRY_04_22_2026.csv"
  ),
  skip = 4
) |>
  janitor::clean_names() |> 
  filter(
    str_count(cntry_cde) == 2 *
      !is.na(iso3_cntry_cde)
  ) |> 
  distinct(cntry_cde, iso3_cntry_cde)

# extracted from https://standardreports.worldbank.org/reports/ASA/A0801
# on: 5-12-2026
asa_active_details <- readxl::read_xlsx(
  here("data-raw", "input", "standard-report", "A8.1 ASA Activity Details - Active.xlsx")
) |> 
  select(
    proj_id = `Task ID`,
    asa_cn_approval_date = `CN Approval`
  )

wb_projects <- wb_projects |> 
  select(
    proj_id,
    proj_name = proj_display_name,
    proj_status = proj_stat_name,
    pdo = proj_dev_objective_desc,
    proj_approval_fy = proj_apprvl_fy,
    proj_url = proj_portal_url,
    product_line_type = prod_line_type_name,
    product_line_name = prod_line_name,
    task_type = task_type_name, # for ASAs to identify advisory vs. analytical
    country_code = cntry_code,
    country_name = cntry_long_name,
    region = rgn_name,
    lending_instrument = lndng_instr_type_name,
    lead_gp = lead_gp_code,
    contrib_gp = proj_mgd_contrib_practice_list,
    ttl = team_lead_full_name,
    agreement_type = agrmnt_type_code,
    commitment_amount = cmt_amt
  ) |> 
  filter(
    proj_status %in% c("Active", "Pipeline") &
      # only retain operations that are either GOV led or contributed to by GOV
      (str_detect(lead_gp, "GOV") |str_detect(contrib_gp, "GOV")) &
      product_line_type %in% c("Lending Product", "Analytic and Advisory Activities Product") &
      proj_approval_fy > 0
  ) |>
  # fix country code
  left_join(
    country_list |> select(country_code = cntry_cde, country_code_clean = iso3_cntry_cde),
    by = c("country_code")
  ) |> 
  mutate(
    country_code = coalesce(country_code_clean, country_code)
  ) |> 
  select(-country_code_clean) |> 
  # add ASA approval date
  left_join(
    asa_approved_current_fy,
    by = "proj_id"
  )

usethis::use_data(wb_projects, overwrite = TRUE)
