## code to prepare `wb_operations` dataset goes here
library(dplyr)
library(readr)

# extracted from https://dataexplorer.worldbank.org/data/details?id=DS04442&t=Preview%20Data
# on: 2026-04-21
wb_operations <- read_csv(
  "data/input/operations/PROJECT_MASTER_V3_04_21_2026.csv",
  skip = 4
) |>
  janitor::clean_names()

usethis::use_data(wb_operations, overwrite = TRUE)
