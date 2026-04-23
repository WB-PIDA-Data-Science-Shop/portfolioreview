## code to prepare `wb_project_components` dataset goes here
library(dplyr)
library(readr)

# extracted from https://dataexplorer.worldbank.org/data/details?id=DS04463&t=Preview%20Data
# on: 2026-04-22
wb_project_components <- read_csv(
  here(
    "data", "input", "wb-data-explorer",
    "PROJECT_COMPONENT_LIST_V3_04_22_2026.csv"
),
  skip = 4
) |>
  janitor::clean_names()

# remove deleted components
wb_project_components <- wb_project_components |> 
  filter(
    !(cmpnt_actn_code %in% c("TO BE DELETED", "Marked for Deletion"))
) |> 
  select(
    proj_id,
    comp_id = cmpnt_id,
    comp_name = cmpnt_name,
    rating_code
  )

usethis::use_data(wb_project_components, overwrite = TRUE)