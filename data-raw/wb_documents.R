## code to prepare `wb_documents` dataset goes here
## code to prepare `wb_documents` dataset goes here
library(dplyr)
library(purrr)
library(tidyr)
library(stringr)
library(here)
library(readr)

devtools::load_all()

# fetch documents --------------------------------------------------------
total <- fetch_wb_documents_json(
  doc_type = c(
    "Project Appraisal Document",
    "Staff Appraisal Report",
    "Project Information Document",
    "Program Information Document",
    "Program Document"
  )
) |>
  pluck("total")

skip_rows <- 0
n_rows <- 1000
documents_tbl <- tibble()

while (skip_rows < total) {
  resp_json <- fetch_wb_documents_json(
    os = skip_rows,
    rows = n_rows,
    doc_type = c(
      "Project Appraisal Document",
      "Staff Appraisal Report",
      "Project Information Document",
      "Program Information Document",
      "Program Document"
    )
  )

  # flatten authors to avoid extra rows
  docs_tbl <- extract_wb_documents(resp_json)

  documents_tbl <- documents_tbl |>
    dplyr::bind_rows(
      docs_tbl
    )

  skip_rows <- skip_rows + n_rows

  message("Fetched ", nrow(documents_tbl), " / ", total)
  Sys.sleep(2) # pause
}

# process documents ------------------------------------------------------
wb_documents <- documents_tbl |>
  rename(
    document_id = id,
    doc_type = docty,
    doc_date = docdt,
    orig_unit = origu,
    abstract = abstracts,
    proj_id = projectid
  ) |>
  # fix abstracts
  mutate(
    abstract = purrr::map(
      abstract,
      ~ if (is.null(.x)) NA_character_ else .x
    ) |>
      unlist()
  )

gov_unit <- wb_documents |>
  mutate(
    stringr::str_squish(owner)
  ) |>
  distinct(owner) |>
  separate_rows(
    owner,
    sep = ";"
  ) |>
  filter(
    grepl("GOV|Inst", owner) &
      grepl("^efi|^prosperity", owner, ignore.case = TRUE)
  ) |>
  mutate(
    owner_code = str_extract(owner, "(?<=\\().*?(?=\\))")
  ) |>
  distinct(owner, owner_code) |>
  select(
    owner,
    owner_code
  ) |>
  mutate(
    owner_label = "gov"
  )

# tag reports and ICRs produced by GOV units
wb_documents <- wb_documents |>
  left_join(
    gov_unit,
    by = "owner"
  ) |>
  mutate(
    owner_label = if_else(
      is.na(owner_label),
      "other",
      owner_label
    )
  ) |>
  # simplify dates
  mutate(
    doc_month = lubridate::round_date(
      lubridate::ymd_hms(doc_date),
      unit = "month"
    )
  )

usethis::use_data(wb_documents, overwrite = TRUE)
usethis::use_data(gov_unit, overwrite = TRUE)
