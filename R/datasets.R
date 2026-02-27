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


#' Planetary Boundaries Overshoot Dataset
#'
#' A dataset containing national overshoot estimates for multiple
#' planetary boundaries.
#'
#' Each row corresponds to a country–boundary combination.
#'
#' @format ## `PBData`
#' A tibble with 743 rows and 3 columns:
#' \describe{
#'   \item{location_name}{Character. Country name in lowercase (168 unique countries).}
#'   \item{overshoot}{Numeric. Overshoot value for the planetary boundary.
#'   Values may be negative (below boundary) or positive (exceeding boundary).}
#'   \item{boundary_studied}{Character. Name of the planetary boundary assessed.
#'   Includes: `"Climate change"`, `"Nitrogen"`, `"Phosphorus"`,
#'   `"Land-system_change"`, `"Freshwater"`,
#'   `"Ocean_acidification"`, `"Biosphere_integrity"`, and `"Aerosols"`.}
#' }
#'
#' Boundary frequency:
#' \itemize{
#'   \item Aerosols (1)
#'   \item Biosphere_integrity (42)
#'   \item Climate change (127)
#'   \item Freshwater (101)
#'   \item Land-system_change (122)
#'   \item Nitrogen (157)
#'   \item Ocean_acidification (42)
#'   \item Phosphorus (151)
#' }
#'
#' @source Compiled from a review of planetary boundary assessments.
"PBData"


#' World Country Polygons (Simple Features)
#'
#' A simplified world country polygon dataset used for mapping and
#' cartogram generation.
#'
#' @format ## `World`
#' An `sf` object with 242 features and 3 columns:
#' \describe{
#'   \item{iso_a3}{Character. ISO 3166-1 alpha-3 country code.}
#'   \item{location_name}{Character. Country name in lowercase (used for joins).}
#'   \item{geometry}{Multipolygon geometry column (`sfc_MULTIPOLYGON`).}
#' }
#'
#' The coordinate reference system (CRS) is geographic (longitude/latitude).
#'
#' @source Derived from publicly available global administrative boundary data.
"World"
