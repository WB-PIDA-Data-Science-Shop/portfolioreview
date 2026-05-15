#' in IDA and Blend countries, with theme classification flags
#' derived from project themes and components. Reports API,
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

#' World Bank Operations: Governance Portfolio
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
#'   \item{task_type}{Character. Task type for ASAs: \"Advisory\" or \"Analytical\". `NA` for non-ASA operations.}
#'   \item{asa_approval_date}{Date. For ASAs, the effective approval date: AIN Sign Off Date for Track 1
#'     tasks, CN Approval date for Track 2 tasks. `NA` for lending operations and untracked tasks.}
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
#'   \item{agreement_type}{Character. Agreement type code (e.g., \"RETF\", \"IDA\").}
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

#' World Bank Project Result Indicators
#'
#' A tibble of World Bank project-level results indicators extracted from the
#' Project Result Indicator Detail V2 dataset, containing baseline, progress,
#' and target values for each reporting period.
#'
#' @format A tibble with 125,446 rows and 10 columns:
#' \describe{
#'   \item{proj_id}{Character. Unique World Bank project identifier (e.g., \"P123456\").}
#'   \item{ind_code}{Character. Unique indicator identifier (e.g., \"IND0057605\").}
#'   \item{ind_type_name}{Character. Indicator type: \"Intermediate Results Indicator\",
#'     \"PDO Indicator\", or \"Global Engagement Indicator\".}
#'   \item{ind_name}{Character. Full name/description of the indicator.}
#'   \item{baseline_date}{Character. Date of the baseline measurement (YYYY-MM-DD).}
#'   \item{baseline_val_text}{Character. Baseline value as a text string.}
#'   \item{progress_date}{Character. Date of the progress measurement (YYYY-MM-DD).}
#'   \item{progress_val_text}{Character. Progress value as a text string.}
#'   \item{progress_cmnts_text}{Character. Narrative comments on progress. `NA` where
#'     no comments are recorded.}
#'   \item{rept_fy}{Character. Fiscal year of the Implementation Status Report (ISR)
#'     in which this measurement was recorded.}
#' }
#'
#' @details
#' Each row represents one indicator measurement at a specific reporting date.
#' A single indicator (`ind_code`) may appear multiple times across reporting
#' periods (`rept_fy`). Indicator types break down as: Intermediate Results
#' Indicators (IO, n = 85,437), PDO Indicators (PD, n = 39,222), and Global
#' Engagement Indicators (GE, n = 787).
#'
#' @source World Bank Data Explorer, Project Result Indicator Detail V2 dataset,
#'   extracted 2026-04-29:
#'   https://dataexplorer.worldbank.org/data/details?id=DS04387
"wb_project_indicators"

#' @title World Bank Country and Lending Groups
#' @description A dataset containing the World Bank's standard country codes, country names, and their respective groups and group codes. This dataset is used to identify countries and their classifications in various World Bank reports and analyses.
#' @format A data frame with 762 rows and 4 variables:
#' \describe{
#'   \item{\code{country_code}}{character World Bank country code}
#'   \item{\code{country_name}}{character World Bank country name}
#'   \item{\code{group}}{character Country group}
#'   \item{\code{group_code}}{character Country group code}
#'}
#' @source https://ddh-openapi.worldbank.org/resources/DR0095333/download
"wb_country_list"

#' @title World Bank Country Group
#' @description DATASET_DESCRIPTION
#' @format A data frame with 18 rows and 2 variables:
#' \describe{
#'   \item{\code{group_name}}{character Group name}
#'   \item{\code{group_category}}{character Group category (e.g., Economic, Region)}
#'}
#' @source https://ddh-openapi.worldbank.org/resources/DR0095333/download
"wb_country_groups"

#' World Bank Country Classifications by Region and Income
#'
#' A dataset containing the most recent country-level classifications published by the World Bank.
#' Each country is assigned to both a regional grouping and an income group, following the World Bank's official taxonomy.
#' This version corresponds to the World Bank classifications as of August 2025.
#'
#' @format A tibble with 264 rows and 4 variables:
#' \describe{
#'   \item{country_code}{Character. Three-letter World Bank country code.}
#'   \item{country_name}{Character. World Bank country name.}
#'   \item{region}{Character. World Bank regional classification
#'                 (e.g., "South Asia", "Europe & Central Asia").}
#'   \item{income_group}{Character. World Bank income group classification
#'                       (e.g., "Low income", "Lower middle income",
#'                       "Upper middle income", "High income").}
#'   \item{lending_category}{Character. World Bank lending category classification}
#' }
#'
#' @details
#' The dataset is based on World Bank country groupings and provides a
#' standardized reference for linking countries to their region and
#' income group. It is commonly used for aggregating indicators,
#' stratifying analyses, and comparing outcomes across different
#' development levels.
#'
#' @source World Bank Group — \url{https://ddh-openapi.worldbank.org/resources/DR0095333/download}
"wb_income_and_region"

#' World Bank Project Themes
#'
#' A tibble of World Bank project-level theme assignments extracted from the
#' Project Theme V3 dataset, joined with the Theme reference table to add
#' theme hierarchy information.
#'
#' @format A tibble with 733,908 rows and 8 columns:
#' \describe{
#'   \item{proj_id}{Character. Unique World Bank project identifier (e.g., \"P123456\").}
#'   \item{theme_code}{Character. Six-digit zero-padded theme code (e.g., \"000653\").}
#'   \item{theme_name}{Character. Full name of the theme as assigned to the project
#'     (e.g., \"FY17 - Science and Technology\").}
#'   \item{theme_percentage}{Double. Percentage weight assigned to this theme for the
#'     project (0–100). Values of 0 indicate unweighted theme assignments.}
#'   \item{sort_order}{Double. Display sort order of the theme within the project.}
#'   \item{vsn_code}{Character. Version code indicating whether the theme assignment
#'     is \"F\" (Final) or \"I\" (Initial).}
#'   \item{theme_level}{Character. Hierarchical level of the theme from the Theme
#'     reference table: \"THEME_1\" (top-level), \"THEME_2\" (sub-theme), or
#'     \"THEME_3\" (detailed sub-theme). `NA` for 371 unmatched codes.}
#'   \item{parent_theme_name}{Character. Name of the parent theme one level up in
#'     the hierarchy. `NA` for top-level themes and unmatched codes.}
#' }
#'
#' @details
#' Each row represents one theme assignment for a project. A single project
#' (`proj_id`) typically has multiple theme assignments across different
#' `theme_level` values. Theme level breakdown: THEME_1 (n = 175,205),
#' THEME_2 (n = 245,714), THEME_3 (n = 312,618), unmatched (n = 371).
#'
#' @source World Bank Data Explorer, Project Theme V3 and Theme datasets,
#'   extracted 2026-04-29:
#'   \url{https://dataexplorer.worldbank.org/data/details?id=DS04463}
"wb_project_themes"

#' World Bank Governance Portfolio: Active IDA/Blend Projects
#'
#' A tibble of active World Bank lending operations led by the Governance (GOV)
#' Global Practice in IDA and Blend countries.
#'
#' @format A tibble with one row per project and 22 columns:
#' \describe{
#'   \item{proj_id}{Character. Unique World Bank project identifier (e.g., \"P123456\").}
#'   \item{proj_name}{Character. Display name of the project.}
#'   \item{proj_status}{Character. Current project status: \"Active\".}
#'   \item{pdo}{Character. Project Development Objective description.}
#'   \item{proj_approval_fy}{Double. Fiscal year in which the project was approved.}
#'   \item{task_type}{Character. Task type for ASAs: \"Advisory\" or \"Analytical\". `NA` for non-ASA operations.}
#'   \item{asa_approval_date}{Date. For ASAs, the effective approval date: AIN Sign Off Date for Track 1
#'     tasks, CN Approval date for Track 2 tasks. `NA` for lending operations and untracked tasks.}
#'   \item{proj_url}{Character. URL to the project page on the World Bank Operations Portal.}
#'   \item{product_line_type}{Character. Product line type (e.g., \"Lending Product\").}
#'   \item{product_line_name}{Character. Name of the product line (e.g., \"IBRD/IDA\").}
#'   \item{country_code}{Character. ISO 3-letter country code.}
#'   \item{country_name}{Character. Full country or territory name.}
#'   \item{region}{Character. World Bank region name.}
#'   \item{lending_instrument}{Character. Lending instrument code (e.g., \"IPF\", \"PforR\").}
#'   \item{lead_gp}{Character. Code of the lead Global Practice: always \"GOV\" in this dataset.}
#'   \item{contrib_gp}{Character. Space-separated list of contributing Global Practice codes.
#'     `NA` where no contributing practices are recorded.}
#'   \item{ttl}{Character. Full name and role of the Task Team Leader.}
#'   \item{commitment_amount}{Double. Total commitment amount in USD.}
#'   \item{lending_category}{Character. World Bank lending category: \"IDA\" or \"Blend\".}
#'   \item{ida_cycle_approval}{Character. IDA cycle identifier: \"Pre-IDA21\" or \"IDA21\", based on approval date (Concept Note for ASA, Board Approval for Lending) and product line. `NA` where not applicable.}
#'   \item{theme_pfm}{Logical. `TRUE` if the project is associated with Public Financial
#'     Management themes (e.g., budget management, debt, domestic revenue, audit).}
#'   \item{theme_procurement}{Logical. `TRUE` if the project is associated with Public
#'     Procurement, either via a project theme assignment or a procurement-related
#'     component name.}
#'   \item{theme_public_admin}{Logical. `TRUE` if the project is associated with Public
#'     Administration themes (e.g., civil service reform, GovTech, e-government,
#'     transparency and accountability).}
#'   \item{theme_env_social}{Logical. `TRUE` if the project is associated with Institutional
#'     dimensions of social and environmental aspects (e.g., adaptation, disaster risk
#'     governance, citizen engagement, community governance).}
#' }
#'
#' @details
#' Filtered to operations where:
#' - `proj_status` is \"Active\"
#' - `lead_gp` is \"GOV\"
#' - `proj_approval_fy` is a valid fiscal year (non-zero)
#' - `lending_category` is \"IDA\" or \"Blend\" (joined from `wb_income_and_region`)
#' - At least one of `theme_pfm`, `theme_procurement`, `theme_public_admin`,
#'   or `theme_es` is `TRUE`
#'
#' Theme flags are derived from `wb_project_themes` via `gov_pc_themes`, a filtered
#' and classified subset of THEME_3-level World Bank themes. `theme_procurement` is
#' supplemented by component-level keyword matching from `wb_project_components`,
#' since Procurement became a standalone theme only post-2025.
#'
#' @source Derived from \code{\link{wb_projects}}, \code{\link{wb_project_themes}},
#'   \code{\link{wb_project_components}}, and \code{\link{wb_income_and_region}}.
#'   See \code{data-raw/wb_projects_gov.R} for full preparation script.
"wb_projects_gov"