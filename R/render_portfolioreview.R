#' A function to render the portfolio review
#' @importFrom rmarkdown render
#' @export
render_portfolioreview <- function(){
  rmarkdown::render("analysis/2026-07-mtr/ida21_policy_commitment.Rmd")
}