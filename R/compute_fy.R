#' Compute World Bank fiscal year
#'
#' Returns the World Bank fiscal year for a given date. The fiscal year starts
#' on July 1st and ends on June 30th, so dates from July onwards belong to the
#' following calendar year (e.g., 2025-08-11 → FY2026).
#'
#' @param date A `Date` or `POSIXct` vector.
#'
#' @return An integer vector of fiscal years.
#'
#' @examples
#' compute_fy(as.Date("2025-08-11")) # FY2026
#' compute_fy(as.Date("2025-06-30")) # FY2025
#'
#' @importFrom lubridate year month
#' @export
compute_fy <- function(date) {
  year  <- lubridate::year(date)
  month <- lubridate::month(date)
  ifelse(month >= 7, year + 1L, year)
}