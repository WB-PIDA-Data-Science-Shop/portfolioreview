#' World Bank Documents API: 2025 document catalog (flattened)
#'
#' A tibble of documents retrieved from the World Bank Documents & Reports API,
#' with authors flattened to a single semicolon-separated string per document
#' and selected metadata fields standardized. Data were fetched for the period
#' 2025-01-01 to 2025-12-31 using the v3 API.
#'
#' @format A tibble with one row per document and the following columns:
#' \describe{
#'   \item{document_id}{Character. Unique document identifier (id).}
#'   \item{authors}{Character. Semicolon-separated list of authors extracted from the nested authors/authr field.}
#'   \item{count}{Character. Country or count field as returned by the API (often country name).}
#'   \item{doc_type}{Character. Document type (docty).}
#'   \item{theme}{Character. Comma-separated themes associated with the document.}
#'   \item{theme_category}{Character. Tab separated thematic categories associated with the document. Programmatically encoded using World Bank theme taxonomy.}
#'   \item{lang}{Character. Language code/name.}
#'   \item{doc_date}{Character or date-time string. Document date (docdt) as returned by the API.}
#'   \item{display_title}{Character. Human-readable title.}
#'   \item{pdfurl}{Character. Direct URL to the PDF if available.}
#'   \item{projectid}{Character. Project identifier when applicable.}
#'   \item{guid}{Character. Global unique identifier.}
#'   \item{url}{Character. Landing page URL.}
#'   \item{orig_unit}{Character. Originating unit (origu).}
#'   \item{owner}{Character. Owning unit/department.}
#'   \item{gov_unit}{Numeric. Flag for whether the owning unit is mapped to Governance.}
#'   \item{abstract}{Character. Abstract text(s) as returned by the API; may include multiple language versions.}
#' }
#'
#' @details
#' - Data are retrieved via the World Bank Documents & Reports Search API (v3).
#' - The nested `authors`/`authr` field is collapsed to a single character string
#'   per document using semicolons as separators.
#'
#' @source World Bank Documents & Reports API:
#'   https://documents.worldbank.org/en/publication/documents-reports/api
#'
#' @seealso
#' - API search endpoint: https://search.worldbank.org/api/v3/wds
#' - API field list parameter (`fl`) for selecting returned fields
#'
"wb_documents"

#' Governance and Institutional Units mapping
#'
#' A tibble mapping World Bank owning units (from Documents & Reports API)
#' to their short unit codes extracted from the unit label.
#'
#' @format A tibble with 2 columns:
#' \describe{
#'   \item{owner}{Character. Owning unit label from the API (e.g., "EFI-AFR1-GOV-FM & PS-1 (EAEG1)").}
#'   \item{owner_code}{Character. Short unit code parsed from parentheses (e.g., "EAEG1").}
#' }
#'
#' @source Derived from World Bank Documents & Reports API unit labels.
"gov_unit"

#' World Bank Operations: Governance Portfolio (2015–present)
#'
#' A tibble of World Bank lending and advisory operations filtered to those
#' led by or contributing to the Governance (GOV) Global Practice.
#'
#' @format A tibble with 796 rows and 16 columns:
#' \describe{
#'   \item{proj_id}{Character. Unique World Bank project identifier (e.g., \"P123456\").}
#'   \item{proj_name}{Character. Display name of the project.}
#'   \item{proj_status}{Character. Current project status: \"Active\" or \"Pipeline\".}
#'   \item{pdo}{Character. Project Development Objective description.}
#'   \item{proj_approval_fy}{Double. Fiscal year in which the project was approved.}
#'   \item{proj_url}{Character. URL to the project page on the World Bank Operations Portal.}
#'   \item{product_line_type}{Character. Product line type: \"Lending Product\" or
#'     \"Analytic and Advisory Activities Product\".}
#'   \item{product_line_name}{Character. Name of the product line (e.g., \"IBRD/IDA\").}
#'   \item{country_code}{Character. ISO 3-letter country code, or World Bank regional/group code
#'     where no ISO code is available.}
#'   \item{country_name}{Character. Full country or territory name.}
#'   \item{region}{Character. World Bank region name.}
#'   \item{lending_instrument}{Character. Lending instrument code (e.g., \"IPF\", \"PforR\").}
#'   \item{lead_gp}{Character. Code of the lead Global Practice (e.g., \"GOV\").}
#'   \item{contrib_gp}{Character. Space-separated list of contributing Global Practice codes.
#'     `NA` where no contributing practices are recorded.}
#'   \item{ttl}{Character. Full name and role of the Task Team Leader.}
#'   \item{commitment_amount}{Double. Total commitment amount in USD.}
#' }
#'
#' @details
#' Filtered to operations where:
#' - `proj_status` is \"Active\" or \"Pipeline\"
#' - The Governance GP (`GOV`) is either the lead (`lead_gp`) or a contributing practice (`contrib_gp`)
#' - `product_line_type` is \"Lending Product\" or \"Analytic and Advisory Activities Product\"
#'
#' Country codes are sourced from the World Bank COUNTRY reference dataset and joined on
#' `cntry_code`. Where an ISO 3-letter code is available it replaces the original 2-character
#' World Bank code; otherwise the original code is retained.
#'
#' @source World Bank Data Explorer, Project Master V3 dataset, extracted 2026-04-21:
#'   https://dataexplorer.worldbank.org/data/details?id=DS04442
"wb_projects"

#' World Bank Project Components
#'
#' A tibble of World Bank project components extracted from the Project
#' Component List V3 dataset, with deleted and marked-for-deletion components
#' removed.
#'
#' @format A tibble with 31,463 rows and 6 columns:
#' \describe{
#'   \item{proj_id}{Character. Unique World Bank project identifier (e.g., \"P123456\").}
#'   \item{comp_id}{Character. Unique component identifier (e.g., \"DLV0151682\", \"COM0003869\").}
#'   \item{comp_name}{Character. Full name/description of the component.}
#'   \item{rating_code}{Character. Implementation progress rating code (e.g., \"S\" = Satisfactory,
#'     \"MS\" = Moderately Satisfactory, \"MU\" = Moderately Unsatisfactory, \"U\" = Unsatisfactory,
#'     \"HS\" = Highly Satisfactory). `NA` where no rating has been assigned.}
#' }
#'
#' @details
#' Components with `cmpnt_actn_code` of `"TO BE DELETED"` or `"Marked for Deletion"`
#' are excluded (251 records removed). The remaining records include components with
#' action codes `NA` (standard), `"Revised"`, and `"New"`.
#'
#' @source World Bank Data Explorer, Project Component List V3 dataset, extracted 2026-04-22:
#'   https://dataexplorer.worldbank.org/data/details?id=DS04463
"wb_project_components"