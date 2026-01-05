#' A dataset for the Nitrogen planetary bounderies
#'
#' A subset of data from the review of planetary boundares
#'
#' @format ## `Nitrogen_Data`
#' A data frame with 576 rows and 23 columns:
#' \describe{
#'   \item{authors}{Authors of the publication}
#'   \item{title}{Title of the publication}
#'   \item{year}{Year}
#'   ...
#' }
#' @source <https://www.who.int/teams/global-tuberculosis-programme/data>
"Nitrogen_Data"

#' A conversion table for mass units
#'
#' A conversion table for mass units
#'
#' @format ## `conversions_mass`
#' A data frame with 6 rows and 3 columns:
#' \describe{
#'   \item{from}{Units to transform from}
#'   \item{to}{Units to transform to}
#'   \item{factor}{number to multiply the value to tranform from one unit to the other}
#' }
"conversions_mass"


conversions_mass <- data.frame(
  from   = c("kgN", "TgN", "GgN", "kg", "mg/L", "mgN/L"),
  to     = c("kgN", "kgN", "kgN", "kgN", "kgN", "kgN"),
  factor = c(1, 1e9, 1e6, 1, 1e-6, 1e-6)
)
