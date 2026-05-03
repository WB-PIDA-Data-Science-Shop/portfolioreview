## code to prepare `wb_project_indicators` dataset goes here
library(dplyr)
library(readr)
library(here)

# extracted from https://dataexplorer.worldbank.org/data/details?id=DS04387&t=Preview%20Data
# on: 2026-04-29
wb_project_indicators <- read_csv(
  here(
    "data-raw", "input", "wb-data-explorer",
    "PROJECT_RESULT_IND_DETAIL_V2_04_29_2026.csv"
  ),
  skip = 4
) |>
  janitor::clean_names()

# inspect columns before selecting
# glimpse(wb_project_indicators)

wb_project_indicators <- wb_project_indicators |>
  select(
    proj_id,
    ind_code,
    ind_type_name,
    ind_name,
    baseline_date,
    baseline_val_text,
    progress_date,
    progress_val_text,
    progress_cmnts_text,
    rept_fy
  )

usethis::use_data(wb_project_indicators, overwrite = TRUE)
