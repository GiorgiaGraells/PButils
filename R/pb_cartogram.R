#' Planetary-boundary cartogram for a selected boundary
#'
#' Build a Dorling-style area cartogram (via \pkg{cartogramR}) where each country
#' is resized according to a selected planetary-boundary metric (overshoot or a
#' transformation thereof), and returns the cartogram geometry, label positions,
#' a \pkg{ggplot2} map, and intermediate joined/projected data.
#'
#' The function joins `PB_df` to `world_sf` by `location_name`, replaces missing
#' overshoot values with 0, clips negative overshoot to 0, projects to an equal-area
#' CRS to compute polygon areas, constructs a cartogram "count" variable based on
#' `count_mode`, computes the cartogram, and labels the top `top_n` countries by
#' original `overshoot` value.
#'
#' @param PB_df A data frame/tibble with at least columns `location_name`,
#'   `boundary_studied`, and `overshoot` (coercible to numeric).
#' @param world_sf An `sf` object of country polygons with a `location_name`
#'   column matching `PB_df$location_name`.
#' @param boundary Character. The planetary boundary to filter to; matched against
#'   `PB_df$boundary_studied`. Default is `"Nitrogen"`.
#' @param count_mode Character. How to compute the cartogram resizing variable:
#'   \describe{
#'     \item{`"weight_area"`}{Area-weighted allocation of total map area based on
#'       `overshoot + eps` (so all countries have non-zero weight).}
#'     \item{`"overshoot"`}{Use `overshoot` directly as the cartogram count.}
#'     \item{`"log1p"`}{Use `log1p(overshoot)` as the cartogram count.}
#'   }
#' @param crs_equal_area Integer or character. CRS passed to [sf::st_transform()]
#'   for area computations. Defaults to `8857`.
#' @param eps Numeric. Small constant added to overshoot when `count_mode =
#'   "weight_area"` to avoid zero weights. Default `1e-9`.
#' @param top_n Integer. Number of top countries (by `overshoot`) to label.
#'   Default `15`.
#' @param with_ties Logical. Passed to [dplyr::slice_max()] when selecting top
#'   labels. Default `TRUE`.
#' @param viridis_option Character. Option passed to
#'   [ggplot2::scale_fill_viridis_c()]. Default `"H"`.
#' @param title Character or `NULL`. Plot title. If `NULL`, a title is generated
#'   as `"<boundary> (<count_mode>)"`.
#'
#' @return A named list with:
#' \describe{
#'   \item{`carto_sf`}{`sf` object of cartogram geometries.}
#'   \item{`top_labels_sf`}{`sf` object of centroid points for labeled countries.}
#'   \item{`plot`}{A `ggplot` object of the cartogram map.}
#'   \item{`data_joined`}{Pre-cartogram `sf` with `overshoot` joined and cleaned.}
#'   \item{`data_ea`}{Equal-area projected `sf` with `area_m2` and `count_carto`.}
#' }
#'
#' @details
#' Label placement uses [sf::st_centroid()] on the cartogram geometries for the
#' top `top_n` locations (by original `overshoot`). For multipart geometries or
#' very irregular polygons, centroids may fall outside the intended visual region;
#' consider alternatives such as [sf::st_point_on_surface()] if needed.
#'
#' @examples
#' \dontrun{
#' data(PBData)
#' data(World)
#' res <- pb_cartogram(
#'   PB_df = PBData,
#'   world_sf = World,
#'   boundary = "Climate change",
#'   count_mode = "overshoot"
#' )
#'
#' res$plot
#' }
#'
#' @importFrom dplyr filter mutate select left_join if_else case_when slice_max
#' @importFrom sf st_transform st_area st_centroid
#' @importFrom cartogramR cartogramR as.sf
#' @importFrom ggplot2 ggplot geom_sf geom_sf_text scale_fill_viridis_c labs
#'
#' @export
pb_cartogram <- function(
    PB_df,
    world_sf,
    boundary = "Nitrogen",
    count_mode = c("weight_area", "overshoot", "log1p"),
    crs_equal_area = 8857,
    eps = 1e-9,
    top_n = 15,
    with_ties = TRUE,
    viridis_option = "H",
    title = NULL
) {
  count_mode <- match.arg(count_mode)

  # --- filter PB to boundary and keep needed cols ---
  PB_sub <- PB_df |>
    dplyr::filter(boundary_studied == boundary) |>
    dplyr::mutate(overshoot = as.numeric(overshoot)) |>
    dplyr::select(location_name, overshoot, boundary_studied)

  # --- join to world, fill missing overshoot with 0 ---
  world_joined <- world_sf |>
    dplyr::left_join(PB_sub, by = "location_name") |>
    dplyr::mutate(
      overshoot = dplyr::if_else(is.na(overshoot), 0, overshoot),
      overshoot = pmax(overshoot, 0)
    )

  # --- project + compute areas ---
  world_ea <- sf::st_transform(world_joined, crs_equal_area) |>
    dplyr::mutate(area_m2 = as.numeric(sf::st_area(geometry)))

  # --- choose cartogram count variable ---
  world_ea <- dplyr::mutate(
    world_ea,
    count_carto = dplyr::case_when(
      count_mode == "overshoot" ~ overshoot,
      count_mode == "log1p" ~ log1p(overshoot),
      count_mode == "weight_area" ~ {
        w <- overshoot + eps
        (w / sum(w)) * sum(area_m2)
      }
    )
  )

  # --- cartogram ---
  carto_obj <- cartogramR::cartogramR(world_ea, count = "count_carto")
  carto_sf <- cartogramR::as.sf(carto_obj)

  # --- top label centroids (based on original overshoot) ---
  top_labels_sf <- carto_sf |>
    dplyr::slice_max(order_by = overshoot, n = top_n, with_ties = with_ties) |>
    sf::st_centroid()

  # --- plot ---
  if (is.null(title)) {
    title <- paste0(boundary, " (", count_mode, ")")
  }

  p <- ggplot2::ggplot() +
    ggplot2::geom_sf(data = carto_sf, ggplot2::aes(fill = overshoot)) +
    ggplot2::geom_sf_text(
      data = top_labels_sf,
      ggplot2::aes(label = location_name),
      check_overlap = TRUE
    ) +
    ggplot2::scale_fill_viridis_c(option = viridis_option) +
    ggplot2::labs(x = "", y = "", title = title)

  list(
    carto_sf = carto_sf,
    top_labels_sf = top_labels_sf,
    plot = p,
    data_joined = world_joined,
    data_ea = world_ea
  )
}
