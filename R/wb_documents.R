#' Fetch a single page from World Bank Documents API
#'
#' @param base_url Character. API endpoint URL.
#' @param fl Character. Comma-separated list of fields to return.
#' @param strdate Character. Start date in "YYYY-MM-DD" format.
#' @param enddate Character. End date in "YYYY-MM-DD" format.
#' @param os Integer. Offset (starting row).
#' @param doc_type Character. A vector of document types, to be matched exactly.
#' @param rows Integer. Number of rows to return.
#' @param ... Additional query parameters passed to the API (e.g., `majdocty_exact`).
#'
#' @return A list from the parsed JSON response.
#'
#' @importFrom httr2 request req_url_query req_perform resp_body_json
fetch_wb_documents_json <- function(
    base_url = "https://search.worldbank.org/api/v3/wds",
    fl = "id,count,abstracts,authr,docdt,origu,owner,projectid,theme,topic,docty",
    strdate = "2000-01-01",
    enddate = "2026-04-22",
    doc_type = NULL,
    os = 0,
    rows = 200,
    ...
) {
  if(is.null(doc_type)){
    httr2::request(base_url) |>
      httr2::req_url_query(
        format = "json",
        fl = fl,
        strdate = strdate,
        enddate = enddate,
        os = os,
        rows = rows,
        ...
      ) |>
      httr2::req_perform() |>
      httr2::resp_body_json()
  }else{
    httr2::request(base_url) |>
      httr2::req_url_query(
        format = "json",
        fl = fl,
        strdate = strdate,
        enddate = enddate,
        os = os,
        rows = rows,
        docty_exact = paste(doc_type, collapse = "^"),
        ...
      ) |>
      httr2::req_perform() |>
      httr2::resp_body_json()
  }
}

#' Extract World Bank API documents from JSON
#'
#' Extracts documents from a World Bank API JSON response, collapses the nested
#' `authors` and `lndinstr` (lending instrument) fields to semicolon-separated
#' strings, and returns a tibble with one row per document.
#'
#' @param json A list from `httr2::resp_body_json()`. See \code{\link{fetch_wb_documents_json}}.
#'
#' @return A tibble with one row per document. The `authors` column is a single
#'   character string with names separated by semicolons. Rows with missing `id`
#'   are removed.
#'
#' @importFrom purrr pluck map map_chr
#' @importFrom dplyr bind_rows filter .data
#'
#' @examples
#' \dontrun{
#' resp_json <- fetch_wb_documents_json(os = 0, rows = 100)
#' docs_tbl <- pluck_wb_documents(resp_json)
#' }
extract_wb_documents <- function(json) {
  documents <- json |>
    purrr::pluck("documents") |>
    purrr::map(\(doc) {
      author <- purrr::pluck(doc, "authors", .default = NULL)
      doc$authors <- if (is.null(author)) {
        NA_character_
      } else {
        purrr::map_chr(author, ~ purrr::pluck(.x, "author", .default = as.character(.x))) |>
          paste(collapse = ";")
      }
      # only present when requested in `fl`
      instrument <- purrr::pluck(doc, "lndinstr", .default = NULL)
      if (!is.null(instrument)) {
        doc$lndinstr <- purrr::map_chr(instrument, ~ purrr::pluck(.x, "lndinstr", .default = as.character(.x))) |>
          paste(collapse = ";")
      }
      doc
    })

  documents |>
    dplyr::bind_rows() |>
    dplyr::filter(!is.na(.data[["id"]]))
}

#' Fetch full text of World Bank documents
#'
#' Downloads the plain-text rendering of documents from the World Bank
#' Documents & Reports site and caches each one to disk as `{guid}.txt`.
#' The text URL is derived from `pdfurl` by swapping the `/pdf/...pdf` suffix
#' for `/txt/...txt`. Documents already in the cache are skipped, so the
#' function can be re-run to resume an interrupted download or retry failures.
#'
#' @param pdfurl Character. PDF URLs, as in the `pdfurl` column of \code{\link{wb_documents}}.
#' @param guid Character. Document GUIDs, used as cache file names.
#' @param cache_dir Character. Directory where text files are stored.
#' @param max_active Integer. Maximum number of simultaneous requests.
#'
#' @return A tibble with columns `guid`, `txt_url`, and `txt_path`. `txt_path`
#'   is `NA` when the text could not be retrieved.
#'
#' @importFrom httr2 request req_timeout req_retry req_error req_perform_parallel resp_status
#' @importFrom purrr map map_lgl
#' @importFrom dplyr tibble if_else
fetch_wb_document_text <- function(
    pdfurl,
    guid,
    cache_dir,
    max_active = 5
) {
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

  txt_url <- sub("^https?://documents\\d?\\.worldbank\\.org", "https://documents1.worldbank.org", pdfurl)
  txt_url <- sub("/pdf/([^/]+)\\.pdf$", "/txt/\\1.txt", txt_url)
  txt_url[!grepl("/txt/", txt_url)] <- NA_character_

  txt_path <- file.path(cache_dir, paste0(guid, ".txt"))
  todo <- !is.na(txt_url) & !file.exists(txt_path)

  if (any(todo)) {
    message("Downloading ", sum(todo), " documents")
    reqs <- purrr::map(
      txt_url[todo],
      \(url) httr2::request(url) |>
        httr2::req_timeout(120) |>
        httr2::req_retry(max_tries = 3) |>
        # keep going on 404s; failed bodies are removed below
        httr2::req_error(is_error = \(resp) FALSE)
    )
    # download to .part files so an interrupted run never leaves a truncated
    # file that would later be treated as cached
    part_path <- paste0(txt_path[todo], ".part")
    resps <- withCallingHandlers(
      httr2::req_perform_parallel(
        reqs,
        paths = part_path,
        on_error = "continue",
        max_active = max_active
      ),
      # some response headers are not valid UTF-8, which makes
      # curl::parse_headers() warn; status codes are unaffected
      warning = \(w) {
        if (grepl("unable to translate|input string \\d+ is invalid", conditionMessage(w))) {
          invokeRestart("muffleWarning")
        }
      }
    )
    failed <- purrr::map_lgl(
      resps,
      \(resp) !inherits(resp, "httr2_response") || httr2::resp_status(resp) != 200
    )
    file.rename(part_path[!failed], txt_path[todo][!failed])
    unlink(part_path)
    message("Failed: ", sum(failed))
  }

  dplyr::tibble(
    guid = guid,
    txt_url = txt_url,
    txt_path = dplyr::if_else(file.exists(txt_path), txt_path, NA_character_)
  )
}