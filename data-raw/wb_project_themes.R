## code to prepare `wb_project_themes` dataset goes here
library(dplyr)
library(readr)
library(here)

# extracted from https://dataexplorer.worldbank.org/data/details?id=DS04938
# on: 2026-08-10
wb_project_themes_raw <- read_csv(
  here(
    "data-raw",
    "input",
    "wb-data-explorer",
    "Project_Theme_08_10_2026.csv"
  )
) |>
  janitor::clean_names()

# theme reference table: maps theme_code to level and parent theme name
# THEME_CDE is numeric; zero-pad to 6 chars to match PROJECT_THEME_V3 codes
theme_ref <- read_csv(
  here(
    "data-raw",
    "input",
    "wb-data-explorer",
    "THEME_04_29_2026.csv"
  ),
  skip = 4
) |>
  janitor::clean_names() |>
  filter(lang_cde == "EN") |>
  select(
    theme_code = theme_cde,
    theme_level = ref_type_cde,
    parent_theme_name = parent_theme_name
  )

wb_project_themes <- wb_project_themes_raw |>
  select(
    proj_id,
    theme_code = thm_code,
    theme_name = thm_name,
    theme_percentage = thm_pct
  ) |>
  left_join(theme_ref, by = "theme_code")

usethis::use_data(wb_project_themes, overwrite = TRUE)
