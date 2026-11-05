# set-up -----------------------------------------------------------------
library(dplyr)
library(ggplot2)
library(purrr)
library(readr)
library(stringr)
devtools::load_all()

# CLIAR is recent, so restrict to FY21+ to limit downloads (set to "2000-01-01" to scan everything)
cliar_start_date <- "2020-07-01"
cache_dir <- here::here("data-raw/input/wb_documents_txt")

# matches "CLIAR", "CLIARs", and "Country[-] Level Institutional Assessment and Review"
cliar_pattern <- regex(
  "\\bCLIARs?\\b|country[\\s-]+level\\s+institutional\\s+assessment\\s+and\\s+review",
  ignore_case = TRUE
)

# fetch ------------------------------------------------------------------
wb_documents_cliar <- portfolioreview::wb_documents_all |>
  filter(
    doc_date >= cliar_start_date
  )

# cached to disk, so re-running only downloads missing documents
wb_documents_txt <- fetch_wb_document_text(
  pdfurl = wb_documents_cliar$pdfurl,
  guid = wb_documents_cliar$guid,
  cache_dir = cache_dir
)

# detect -----------------------------------------------------------------
# counts mentions in a cached text file and extracts a context window around
# each one, for manual validation
detect_cliar <- function(path, pattern, window = 150) {
  if (is.na(path)) {
    return(tibble(cliar_mentions = NA_integer_, cliar_context = NA_character_))
  }

  text <- read_file(path)
  # about half of the text files are Windows-1252 rather than UTF-8
  if (!validUTF8(text)) {
    text <- iconv(text, from = "windows-1252", to = "UTF-8", sub = " ")
  }
  text <- str_squish(text)
  loc <- str_locate_all(text, pattern)[[1]]

  context <- if (nrow(loc) == 0) {
    NA_character_
  } else {
    str_sub(text, pmax(loc[, "start"] - window, 1), loc[, "end"] + window) |>
      paste(collapse = " || ")
  }

  tibble(cliar_mentions = nrow(loc), cliar_context = context)
}

wb_documents_cliar <- wb_documents_cliar |>
  left_join(
    # a few documents share a guid, and so the same text file
    wb_documents_txt |> distinct(guid, .keep_all = TRUE),
    by = "guid"
  ) |>
  mutate(
    map(txt_path, \(path) detect_cliar(path, cliar_pattern), .progress = TRUE) |>
      list_rbind(),
    cliar_mention = cliar_mentions > 0
  )

# downloads --------------------------------------------------------------
# "Total Downloads" from the Documents & Reports Download Stats page;
# requires WB_DOCS_API_KEY in .Renviron
wb_documents_downloads <- fetch_wb_document_downloads(wb_documents_cliar$guid)

wb_documents_cliar <- wb_documents_cliar |>
  left_join(wb_documents_downloads, by = "guid")

# analyze ----------------------------------------------------------------
wb_documents_cliar |>
  count(
    doc_category,
    txt_available = !is.na(txt_path),
    cliar_mention
  )

wb_documents_cliar |>
  filter(cliar_mention) |>
  select(
    proj_id,
    count,
    doc_category,
    doc_type,
    lending_instrument,
    display_title,
    doc_date,
    cliar_mentions,
    cliar_context,
    downloads,
    url
  ) |>
  arrange(desc(doc_date)) |>
  write_csv(
    here::here("inst/extdata/adhoc/cliar_portfolio_review.csv")
  )
