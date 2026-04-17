#' Harmonize parsed value/unit columns to canonical units
#'
#' `harmonize_units()` is designed to run after [separate_unit_value2()]. It
#' takes the parsed `{column}_value` and `{column}_unit` columns, and creates
#' harmonized value/unit columns when a safe dimensional conversion is possible.
#'
#' The function is intentionally conservative:
#' - it skips rows flagged for manual review by default,
#' - it skips non-physical indicators by default,
#' - it rescales only when the unit family is clearly compatible,
#' - it preserves semantic distinctions such as `CO2` vs `CO2eq`, `N` vs `N-eq`,
#'   and `P` vs `P-eq`.
#'
#' Canonical internal targets used by this function are:
#' - mass-like quantities -> metric tonnes (`t`) while preserving the substance
#'   suffix, for example `tCO2eq`, `tN`, `tP`, `tC`,
#' - volume-like quantities -> cubic metres (`m3`),
#' - area-like quantities -> hectares (`ha`).
#'
#' Denominators such as `/yr`, `/cap`, and `/cap/yr` are preserved.
#'
#' @param df A data frame that already contains parsed value/unit columns,
#'   typically produced by [separate_unit_value2()].
#' @param columns Character vector with base column names to harmonize.
#'   Defaults to `c("territorial_footprint", "territorial_boundary",
#'   "footprint_percapita", "boundary_percapita")`.
#' @param skip_manual_review Logical. If `TRUE`, rows flagged by
#'   `{column}_needs_manual_review` are not harmonized.
#' @param skip_non_physical Logical. If `TRUE`, rows flagged by
#'   `{column}_is_non_physical` are not harmonized.
#' @param keep_components Logical. If `TRUE`, adds parsed harmonization helper
#'   columns such as multiplier, family, and denominator.
#'
#' @return The input data frame with new columns appended after each base column:
#' - `{column}_value_harmonized`
#' - `{column}_unit_canonical`
#' - `{column}_harmonized`
#' - `{column}_harmonization_failed`
#' - `{column}_harmonization_note`
#'
#' If `keep_components = TRUE`, also adds:
#' - `{column}_unit_family`
#' - `{column}_unit_substance`
#' - `{column}_unit_denominator`
#' - `{column}_unit_multiplier`
#'
#' @examples
#' data("Nitrogen_Data")
#' x <- separate_unit_value2(Nitrogen_Data)
#' x2 <- harmonize_units(x)
#'
#' @author Derek Corcoran <derek.corcoran.barrios@gmail.com>
#' @author Giorgia Graells <gygraell@gmail.com>
#' @export
harmonize_units <- function(
  df,
  columns = c(
    "territorial_footprint",
    "territorial_boundary",
    "footprint_percapita",
    "boundary_percapita"
  ),
  skip_manual_review = TRUE,
  skip_non_physical = TRUE,
  keep_components = FALSE
) {
  stopifnot(is.data.frame(df))
  stopifnot(is.character(columns))
  stopifnot(is.logical(skip_manual_review), length(skip_manual_review) == 1)
  stopifnot(is.logical(skip_non_physical), length(skip_non_physical) == 1)
  stopifnot(is.logical(keep_components), length(keep_components) == 1)

  if (length(columns) == 0) return(df)

  for (col in columns) {
    value_col <- paste0(col, "_value")
    unit_col <- paste0(col, "_unit")
    review_col <- paste0(col, "_needs_manual_review")
    nonphys_col <- paste0(col, "_is_non_physical")

    required_cols <- c(value_col, unit_col)
    missing_required <- setdiff(required_cols, names(df))
    if (length(missing_required) > 0) {
      stop(
        "Missing required parsed columns for `", col, "`: ",
        paste(missing_required, collapse = ", "),
        ". Run `separate_unit_value2()` first.",
        call. = FALSE
      )
    }

    n <- nrow(df)
    x_value <- df[[value_col]]
    x_unit <- as.character(df[[unit_col]])

    block_review <- rep(FALSE, n)
    if (skip_manual_review && review_col %in% names(df)) {
      block_review <- df[[review_col]] %in% TRUE
      block_review[is.na(block_review)] <- FALSE
    }

    block_nonphys <- rep(FALSE, n)
    if (skip_non_physical && nonphys_col %in% names(df)) {
      block_nonphys <- df[[nonphys_col]] %in% TRUE
      block_nonphys[is.na(block_nonphys)] <- FALSE
    }

    parsed <- parse_canonical_unit(x_unit)

    can_harmonize <- !is.na(x_value) &
      !is.na(x_unit) &
      nzchar(x_unit) &
      !block_review &
      !block_nonphys &
      !is.na(parsed$family) &
      !is.na(parsed$multiplier)

    harmonized_value <- rep(NA_real_, n)
    harmonized_unit <- rep(NA_character_, n)
    harmonized_flag <- rep(FALSE, n)
    harmonized_failed <- rep(FALSE, n)
    harmonized_note <- rep(NA_character_, n)

    if (any(can_harmonize)) {
      harmonized_value[can_harmonize] <- x_value[can_harmonize] * parsed$multiplier[can_harmonize]
      harmonized_unit[can_harmonize] <- build_canonical_unit(
        family = parsed$family[can_harmonize],
        substance = parsed$substance[can_harmonize],
        denominator = parsed$denominator[can_harmonize]
      )
      harmonized_flag[can_harmonize] <- TRUE
      harmonized_note[can_harmonize] <- "Harmonized to canonical unit"
    }

    attempted_but_failed <- !is.na(x_value) &
      !is.na(x_unit) &
      nzchar(x_unit) &
      !block_review &
      !block_nonphys &
      !can_harmonize

    harmonized_failed[attempted_but_failed] <- TRUE
    harmonized_note[attempted_but_failed] <- "No safe harmonization rule matched"

    harmonized_note[block_review & !is.na(x_unit) & nzchar(x_unit)] <- "Skipped: manual review flag"
    harmonized_note[block_nonphys & !is.na(x_unit) & nzchar(x_unit)] <- "Skipped: non-physical indicator"
    harmonized_note[is.na(x_value) & !is.na(x_unit) & nzchar(x_unit) & is.na(harmonized_note)] <- "Skipped: missing parsed numeric value"
    harmonized_note[(!is.na(x_unit) & x_unit == "") & is.na(harmonized_note)] <- "Skipped: empty unit"

    new_cols <- c(
      paste0(col, "_value_harmonized"),
      paste0(col, "_unit_canonical"),
      paste0(col, "_harmonized"),
      paste0(col, "_harmonization_failed"),
      paste0(col, "_harmonization_note")
    )

    df[[new_cols[1]]] <- harmonized_value
    df[[new_cols[2]]] <- harmonized_unit
    df[[new_cols[3]]] <- harmonized_flag
    df[[new_cols[4]]] <- harmonized_failed
    df[[new_cols[5]]] <- harmonized_note

    if (keep_components) {
      comp_cols <- c(
        paste0(col, "_unit_family"),
        paste0(col, "_unit_substance"),
        paste0(col, "_unit_denominator"),
        paste0(col, "_unit_multiplier")
      )
      df[[comp_cols[1]]] <- parsed$family
      df[[comp_cols[2]]] <- parsed$substance
      df[[comp_cols[3]]] <- parsed$denominator
      df[[comp_cols[4]]] <- parsed$multiplier
      new_cols <- c(new_cols, comp_cols)
    }

    col_pos <- match(col, names(df))
    new_order <- c(
      names(df)[seq_len(col_pos)],
      new_cols,
      names(df)[-seq_len(col_pos)]
    )
    new_order <- new_order[!duplicated(new_order)]
    df <- df[, new_order, drop = FALSE]
  }

  df
}

#' Parse harmonizable units into canonical components
#'
#' @param u Character vector of already text-harmonized units.
#'
#' @return A data frame with columns:
#' - `family`
#' - `substance`
#' - `denominator`
#' - `multiplier`
#'
#' @importFrom stringr str_match str_detect str_replace str_replace_all str_trim str_squish
#' @keywords internal
parse_canonical_unit <- function(u) {
  u <- as.character(u)
  n <- length(u)

  family <- rep(NA_character_, n)
  substance <- rep(NA_character_, n)
  denominator <- rep(NA_character_, n)
  multiplier <- rep(NA_real_, n)

  u_clean <- u
  u_clean[is.na(u_clean)] <- NA_character_
  u_clean <- stringr::str_squish(u_clean)

  denominator <- extract_denominator(u_clean)
  unit_core <- strip_denominator(u_clean)

  mass_patterns <- list(
    list(pattern = "^(kg)(CO2eq|CO2|N-eq|N|P-eq|P|C)?$", mult = 1e-3),
    list(pattern = "^(t)(CO2eq|CO2|N-eq|N|P-eq|P|C)?$", mult = 1),
    list(pattern = "^(kt)(CO2eq|CO2|N|P)?$", mult = 1e3),
    list(pattern = "^(Gg)(N|P)?$", mult = 1e3),
    list(pattern = "^(Mt)(CO2eq|CO2|CH4|C)?$", mult = 1e6),
    list(pattern = "^(Gt)(CO2eq|CO2|C)?$", mult = 1e9),
    list(pattern = "^(Tg)(N|P)?$", mult = 1e6)
  )

  for (spec in mass_patterns) {
    idx <- is.na(family) & !is.na(unit_core)
    if (!any(idx)) next
    m <- stringr::str_match(unit_core[idx], spec$pattern)
    hit <- !is.na(m[, 1])
    if (any(hit)) {
      target <- which(idx)[hit]
      family[target] <- "mass"
      substance[target] <- normalize_substance_token(m[hit, 3])
      multiplier[target] <- spec$mult
    }
  }

  area_patterns <- list(
    list(pattern = "^(ha)$", mult = 1),
    list(pattern = "^(Mha)$", mult = 1e6),
    list(pattern = "^(km2)$", mult = 100)
  )

  for (spec in area_patterns) {
    idx <- is.na(family) & !is.na(unit_core)
    if (!any(idx)) next
    m <- stringr::str_match(unit_core[idx], spec$pattern)
    hit <- !is.na(m[, 1])
    if (any(hit)) {
      target <- which(idx)[hit]
      family[target] <- "area"
      substance[target] <- NA_character_
      multiplier[target] <- spec$mult
    }
  }

  volume_patterns <- list(
    list(pattern = "^(m3)$", mult = 1),
    list(pattern = "^(Mm3)$", mult = 1e6),
    list(pattern = "^(million m3)$", mult = 1e6),
    list(pattern = "^(billion m3)$", mult = 1e9),
    list(pattern = "^(km3)$", mult = 1e9)
  )

  for (spec in volume_patterns) {
    idx <- is.na(family) & !is.na(unit_core)
    if (!any(idx)) next
    m <- stringr::str_match(unit_core[idx], spec$pattern)
    hit <- !is.na(m[, 1])
    if (any(hit)) {
      target <- which(idx)[hit]
      family[target] <- "volume"
      substance[target] <- NA_character_
      multiplier[target] <- spec$mult
    }
  }

  data.frame(
    family = family,
    substance = substance,
    denominator = denominator,
    multiplier = multiplier,
    stringsAsFactors = FALSE
  )
}

#' Extract canonical denominator fragment
#'
#' @param x Character vector of units.
#'
#' @return Character vector such as `""`, `"/yr"`, `"/cap"`, `"/cap/yr"`,
#'   `"/ha"`, `"/ha/yr"`, or `"/km2"`.
#' @keywords internal
extract_denominator <- function(x) {
  x <- as.character(x)
  out <- rep(NA_character_, length(x))
  out[!is.na(x)] <- ""

  out[!is.na(x) & stringr::str_detect(x, "/cap/yr$")] <- "/cap/yr"
  out[!is.na(x) & stringr::str_detect(x, "/cap$") & out == ""] <- "/cap"
  out[!is.na(x) & stringr::str_detect(x, "/yr$") & out == ""] <- "/yr"
  out[!is.na(x) & stringr::str_detect(x, "/ha\\*yr$")] <- "/ha/yr"
  out[!is.na(x) & stringr::str_detect(x, "/ha$") & out == ""] <- "/ha"
  out[!is.na(x) & stringr::str_detect(x, "/km2$") & out == ""] <- "/km2"

  out
}

#' Remove canonical denominator fragment from unit text
#'
#' @param x Character vector of units.
#'
#' @return Character vector of unit cores.
#' @keywords internal
strip_denominator <- function(x) {
  x <- as.character(x)
  x <- stringr::str_replace(x, "/cap/yr$", "")
  x <- stringr::str_replace(x, "/cap$", "")
  x <- stringr::str_replace(x, "/yr$", "")
  x <- stringr::str_replace(x, "/ha\\*yr$", "")
  x <- stringr::str_replace(x, "/ha$", "")
  x <- stringr::str_replace(x, "/km2$", "")
  stringr::str_squish(x)
}

#' Normalize parsed substance token
#'
#' @param x Character vector.
#'
#' @return Character vector.
#' @keywords internal
normalize_substance_token <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  x <- stringr::str_replace_all(x, "\\s+", "")
  x <- stringr::str_replace_all(x, "^CO2e$", "CO2eq")
  x[x == ""] <- NA_character_
  x
}

#' Build canonical unit string from parsed components
#'
#' @param family Character vector such as `"mass"`, `"area"`, `"volume"`.
#' @param substance Character vector of substance suffixes, for example
#'   `"CO2eq"` or `"N"`.
#' @param denominator Character vector such as `"/yr"` or `"/cap"`.
#'
#' @return Character vector of canonical units.
#' @keywords internal
build_canonical_unit <- function(family, substance, denominator) {
  family <- as.character(family)
  substance <- as.character(substance)
  denominator <- as.character(denominator)

  out <- rep(NA_character_, length(family))

  mass_idx <- !is.na(family) & family == "mass"
  if (any(mass_idx)) {
    subst <- substance[mass_idx]
    subst[is.na(subst)] <- ""
    den <- denominator[mass_idx]
    den[is.na(den)] <- ""
    out[mass_idx] <- paste0("t", subst, den)
  }

  area_idx <- !is.na(family) & family == "area"
  if (any(area_idx)) {
    den <- denominator[area_idx]
    den[is.na(den)] <- ""
    out[area_idx] <- paste0("ha", den)
  }

  volume_idx <- !is.na(family) & family == "volume"
  if (any(volume_idx)) {
    den <- denominator[volume_idx]
    den[is.na(den)] <- ""
    out[volume_idx] <- paste0("m3", den)
  }

  out
}
