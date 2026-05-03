## code to prepare `wb_project_themes` dataset goes here
library(dplyr)
library(readr)
library(here)

# extracted from https://dataexplorer.worldbank.org/data/details?id=DS04463&t=Preview%20Data
# on: 2026-04-29
wb_project_themes_raw <- read_csv(
  here(
    "data-raw", "input", "wb-data-explorer",
    "PROJECT_THEME_V3_04_29_2026.csv"
  ),
  skip = 4
) |>
  janitor::clean_names()

# theme reference table: maps theme_code to level and parent theme name
# THEME_CDE is numeric; zero-pad to 6 chars to match PROJECT_THEME_V3 codes
theme_ref <- read_csv(
  here(
    "data-raw", "input", "wb-data-explorer",
    "THEME_04_29_2026.csv"
  ),
  skip = 4
) |>
  janitor::clean_names() |>
  filter(lang_cde == "EN") |>
  mutate(
    theme_code = stringr::str_pad(
      as.character(theme_cde), width = 6, pad = "0"
    )
  ) |>
  select(
    theme_code,
    theme_level       = ref_type_cde,
    parent_theme_name = parent_theme_name
  )

wb_project_themes <- wb_project_themes_raw |>
  select(
    proj_id,
    theme_code,
    theme_name,
    theme_percentage
  ) |>
  left_join(theme_ref, by = "theme_code")

usethis::use_data(wb_project_themes, overwrite = TRUE)
