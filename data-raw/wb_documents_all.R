## code to prepare `wb_documents_all` dataset goes here
library(dplyr)
library(purrr)
library(tidyr)
library(stringr)
library(here)
library(readr)

devtools::load_all()

# document types ---------------------------------------------------------
# document type names must match the API exactly
diagnostic_types <- c(
  "Country Economic Memorandum",
  "Country Growth and Jobs Report",
  "Systematic Country Diagnostic"
)

# IPF, PforR and DPO documents, including additional financing and
# restructuring papers (Project Paper)
lending_types <- c(
  "Project Information Document",
  "Project Appraisal Document",
  "Project Paper",
  "Project Document",
  "Program Information Document",
  "Program Appraisal Document",
  "Program Document",
  "Staff Appraisal Report"
)

# ASA outputs filed as publications; only kept when linked to a project ID
publication_types <- c(
  "Report",
  "Publication"
)

# fetch documents --------------------------------------------------------
fetch_all_pages <- function(..., n_rows = 1000) {
  total <- fetch_wb_documents_json(rows = 1, ...) |>
    pluck("total")

  skip_rows <- 0
  documents_tbl <- tibble()

  while (skip_rows < total) {
    resp_json <- fetch_wb_documents_json(
      os = skip_rows,
      rows = n_rows,
      ...
    )

    # flatten authors and lending instruments to avoid extra rows
    docs_tbl <- extract_wb_documents(resp_json)

    documents_tbl <- documents_tbl |>
      dplyr::bind_rows(
        docs_tbl
      )

    skip_rows <- skip_rows + n_rows

    message("Fetched ", nrow(documents_tbl), " / ", total)
    Sys.sleep(2) # pause
  }

  documents_tbl
}

fl <- "id,count,abstracts,authr,docdt,origu,owner,projectid,theme,topic,docty,majdocty,lndinstr"
enddate <- format(Sys.Date())

documents_tbl <- bind_rows(
  fetch_all_pages(
    doc_type = c(diagnostic_types, lending_types, publication_types),
    fl = fl,
    enddate = enddate
  ),
  # all ASA product types (CEM, PER, CCDR, Poverty Assessment, etc.)
  fetch_all_pages(
    majdocty_exact = "Economic & Sector Work",
    fl = fl,
    enddate = enddate
  )
) |>
  distinct(id, .keep_all = TRUE)

# process documents ------------------------------------------------------
wb_documents_all <- documents_tbl |>
  rename(
    document_id = id,
    doc_type = docty,
    major_doc_type = majdocty,
    lending_instrument = lndinstr,
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
  ) |>
  # drop publications that are not linked to a project
  filter(
    !(doc_type %in% publication_types) | (!is.na(proj_id) & proj_id != "")
  ) |>
  mutate(
    doc_category = case_when(
      doc_type %in% diagnostic_types ~ "diagnostic",
      doc_type %in% lending_types ~ "lending",
      TRUE ~ "asa"
    )
  )

wb_documents_all <- wb_documents_all |>
  # simplify dates
  mutate(
    doc_month = lubridate::round_date(
      lubridate::ymd_hms(doc_date),
      unit = "month"
    )
  )

usethis::use_data(wb_documents_all, overwrite = TRUE)
