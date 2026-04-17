#' Separate values and units from one or more dataframe columns
#'
#' Enhanced version of `separate_unit_value()` that:
#' - cleans common formatting problems before parsing,
#' - extracts a numeric value when possible,
#' - keeps both raw and harmonized unit text,
#' - adds flags for ranges, context text, non-physical indicators, and review needs.
#'
#' This function is intentionally conservative. It harmonizes units when the
#' equivalence is reasonably safe (for example `m³` -> `m3`, `tons` -> `t`,
#' `/year` -> `/yr`, `CO2-eq` -> `CO2eq`), but it does not attempt to resolve
#' ranges or contextual commentary into a single numeric value.
#'
#' @param df A dataframe containing the columns to separate.
#' @param columns Character vector with the names of columns to separate.
#'   Defaults to `c("territorial_footprint", "territorial_boundary",
#'   "footprint_percapita", "boundary_percapita")`.
#' @param add_flags Logical. If `TRUE`, adds diagnostic flag columns.
#' @param keep_cleaned_input Logical. If `TRUE`, adds a `{column}_cleaned` column.
#'
#' @return The same dataframe with new columns appended after each parsed column.
#'
#' Added columns per input column:
#' - `{column}_value`: numeric value when a single value can be parsed.
#' - `{column}_unit_raw`: extracted raw unit text.
#' - `{column}_unit`: harmonized unit text.
#' - `{column}_cleaned`: cleaned source string used for parsing (optional).
#' - `{column}_is_range`: whether the entry looks like a numeric range.
#' - `{column}_has_context`: whether the extracted unit contains likely commentary.
#' - `{column}_is_non_physical`: whether the unit looks like an index / indicator.
#' - `{column}_unit_harmonized`: whether the unit changed during harmonization.
#' - `{column}_needs_manual_review`: whether the entry should be reviewed manually.
#'
#' @examples
#' data("Nitrogen_Data")
#' separate_unit_value2(df = Nitrogen_Data)
#' separate_unit_value2(
#'   df = Nitrogen_Data,
#'   columns = c("global_limit_considered", "boundary_percapita")
#' )
#'
#' @author Derek Corcoran <derek.corcoran.barrios@gmail.com>
#' @author Giorgia Graells <gygraell@gmail.com>
#' @export
separate_unit_value2 <- function(
  df,
  columns = c(
    "territorial_footprint",
    "territorial_boundary",
    "footprint_percapita",
    "boundary_percapita"
  ),
  add_flags = TRUE,
  keep_cleaned_input = FALSE
) {
  stopifnot(is.data.frame(df))
  stopifnot(is.character(columns))
  stopifnot(is.logical(add_flags), length(add_flags) == 1)
  stopifnot(is.logical(keep_cleaned_input), length(keep_cleaned_input) == 1)

  if (length(columns) == 0) return(df)

  missing_cols <- setdiff(columns, names(df))
  if (length(missing_cols) > 0) {
    stop(
      "These columns are not in `df`: ",
      paste(missing_cols, collapse = ", "),
      call. = FALSE
    )
  }

  for (col in columns) {
    x <- df[[col]]
    x_chr <- if (is.null(x)) rep(NA_character_, nrow(df)) else as.character(x)
    x_clean <- clean_value_unit_string(x_chr)

    value_col <- paste0(col, "_value")
    unit_raw_col <- paste0(col, "_unit_raw")
    unit_col <- paste0(col, "_unit")

    df[[value_col]] <- extract_value2(x_clean)
    df[[unit_raw_col]] <- extract_unit2(x_clean)
    df[[unit_col]] <- harmonize_unit_text(df[[unit_raw_col]])

    if (keep_cleaned_input) {
      df[[paste0(col, "_cleaned")]] <- x_clean
    }

    if (add_flags) {
      df[[paste0(col, "_is_range")]] <- detect_range(x_clean)
      df[[paste0(col, "_has_context")]] <- detect_context(df[[unit_raw_col]])
      df[[paste0(col, "_is_non_physical")]] <- detect_non_physical(df[[unit_raw_col]])
      df[[paste0(col, "_unit_harmonized")]] <- !same_text(df[[unit_raw_col]], df[[unit_col]])
      df[[paste0(col, "_needs_manual_review")]] <- (
        df[[paste0(col, "_is_range")]] |
          df[[paste0(col, "_has_context")]] |
          is.na(df[[value_col]]) & !is.na(x_clean) & nzchar(x_clean) |
          detect_suspicious_unit(df[[unit_raw_col]])
      )
    }

    col_pos <- match(col, names(df))

    inserted <- c(value_col, unit_raw_col, unit_col)
    if (keep_cleaned_input) inserted <- c(inserted, paste0(col, "_cleaned"))
    if (add_flags) {
      inserted <- c(
        inserted,
        paste0(col, "_is_range"),
        paste0(col, "_has_context"),
        paste0(col, "_is_non_physical"),
        paste0(col, "_unit_harmonized"),
        paste0(col, "_needs_manual_review")
      )
    }

    new_order <- c(
      names(df)[seq_len(col_pos)],
      inserted,
      names(df)[-seq_len(col_pos)]
    )
    new_order <- new_order[!duplicated(new_order)]

    df <- df[, new_order, drop = FALSE]
  }

  df
}

#' Clean strings before value/unit parsing
#'
#' @param x Character vector.
#' @return Character vector with common formatting problems normalized.
#' @export
clean_value_unit_string <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- NA_character_

  # Drop anything after line breaks
  x <- stringr::str_replace_all(x, "[\r\n]+.*$", "")

  # Normalize spaces and dashes
  x <- stringr::str_replace_all(x, "\u00A0", " ")
  x <- stringr::str_replace_all(x, "\u2009|\u202F", " ")
  x <- stringr::str_replace_all(x, "[–—−]", "-")
  x <- stringr::str_squish(x)

  # Remove apostrophe thousands separators: 2'770 -> 2770
  x <- stringr::str_replace_all(x, "(?<=\\d)'(?=\\d)", "")

  # Remove comma thousands separators: 45,000 -> 45000 ; 5,082 -> 5082
  x <- stringr::str_replace_all(x, "(?<=\\d),(?=\\d{3}(\\D|$))", "")

  # Remove space thousands separators: 74 328 -> 74328
  x <- stringr::str_replace_all(x, "(?<=\\d)\\s(?=\\d{3}(\\D|$))", "")

  x
}

#' Detect entries that look like numeric ranges
#'
#' @param x Character vector.
#' @return Logical vector.
#' @export
#'
detect_range <- function(x) {
  x <- clean_value_unit_string(x)
  out <- stringr::str_detect(
    x,
    paste0(
      "^\\s*\\[?\\s*[+-]?(?:\\d+(?:\\.\\d+)?|\\.\\d+)(?:[eE][+-]?\\d+)?",
      "\\s*-\\s*",
      "[+-]?(?:\\d+(?:\\.\\d+)?|\\.\\d+)(?:[eE][+-]?\\d+)?"
    )
  )
  out[is.na(out)] <- FALSE
  out
}

#' Extract numeric values from strings with value + unit
#'
#' @param x Character vector.
#' @return Numeric vector. Returns `NA` for ranges and non-parseable entries.
#' @export
extract_value2 <- function(x) {
  x <- clean_value_unit_string(x)
  is_range <- detect_range(x)

  out <- rep(NA_real_, length(x))

  single_idx <- which(!is_range & !is.na(x))
  if (length(single_idx) > 0) {
    m <- stringr::str_match(
      x[single_idx],
      "^\\s*([+-]?(?:\\d+(?:\\.\\d+)?|\\.\\d+)(?:[eE][+-]?\\d+)?)\\s*(.*)$"
    )
    out[single_idx] <- suppressWarnings(as.numeric(m[, 2]))
  }

  out
}

#' Extract unit text from strings with value + unit
#'
#' @param x Character vector.
#' @return Character vector with extracted unit text.
#' @export
extract_unit2 <- function(x) {
  x <- clean_value_unit_string(x)
  is_range <- detect_range(x)

  out <- rep(NA_character_, length(x))

  single_idx <- !is_range & !is.na(x)
  if (any(single_idx)) {
    m1 <- stringr::str_match(
      x[single_idx],
      "^\\s*[+-]?(?:\\d+(?:\\.\\d+)?|\\.\\d+)(?:[eE][+-]?\\d+)?\\s*(.*?)\\s*$"
    )
    out[single_idx] <- stringr::str_trim(m1[, 2])
  }

  range_idx <- which(is_range)

  if (length(range_idx) > 0) {
    m2 <- stringr::str_match(
      x[range_idx],
      paste0(
        "^\\s*\\[?\\s*[+-]?(?:\\d+(?:\\.\\d+)?|\\.\\d+)(?:[eE][+-]?\\d+)?",
        "\\s*-\\s*",
        "[+-]?(?:\\d+(?:\\.\\d+)?|\\.\\d+)(?:[eE][+-]?\\d+)?\\s*\\]?\\s*(.*?)\\s*$"
      )
    )
    out[range_idx] <- stringr::str_trim(m2[, 2])
  }

  out[out == ""] <- ""
  out
}

#' Harmonize unit text conservatively
#'
#' @param u Character vector of extracted unit text.
#' @return Character vector of harmonized units.
#' @export
harmonize_unit_text <- function(u) {
  u <- as.character(u)
  u[is.na(u)] <- NA_character_

  # Normalize spaces / unicode first
  u <- stringr::str_replace_all(u, "\u00A0", " ")
  u <- stringr::str_replace_all(u, "\u2009|\u202F", " ")
  u <- stringr::str_replace_all(u, "[–—−]", "-")
  u <- stringr::str_replace_all(u, "µ", "μ")
  u <- stringr::str_squish(u)

  # Basic unicode / typography cleanup
  u <- stringr::str_replace_all(u, fixed("m³"), "m3")
  u <- stringr::str_replace_all(u, fixed("′"), "'")

  # Spelling / casing cleanup used in the dataset
  u <- stringr::str_replace_all(u, stringr::regex("\\bKgN\\b"), "kgN")
  u <- stringr::str_replace_all(u, stringr::regex("\\bmg/l\\b", ignore_case = TRUE), "mg/L")
  u <- stringr::str_replace_all(u, stringr::regex("\\bug/m3\\b", ignore_case = TRUE), "μg/m3")
  u <- stringr::str_replace_all(u, stringr::regex("\\bµg/m3\\b", ignore_case = TRUE), "μg/m3")

  # Time denominator normalization
  u <- stringr::str_replace_all(u, stringr::regex("\\s*/\\s*year\\b", ignore_case = TRUE), "/yr")
  u <- stringr::str_replace_all(u, stringr::regex("\\s*/\\s*y\\b", ignore_case = TRUE), "/yr")
  u <- stringr::str_replace_all(u, stringr::regex("\\byear-1\\b", ignore_case = TRUE), "yr-1")
  u <- stringr::str_replace_all(u, stringr::regex("\\by-1\\b", ignore_case = TRUE), "yr-1")
  u <- stringr::str_replace_all(u, stringr::regex("\\ba\\b", ignore_case = FALSE), "yr")

  # Equivalent notation
  u <- stringr::str_replace_all(u, stringr::regex("equivalents?", ignore_case = TRUE), "eq")
  u <- stringr::str_replace_all(u, stringr::regex("\\bCO2 e\\b", ignore_case = TRUE), "CO2e")
  u <- stringr::str_replace_all(u, stringr::regex("\\bCO2-eq\\b", ignore_case = TRUE), "CO2eq")
  u <- stringr::str_replace_all(u, stringr::regex("\\bCo2-eq\\b", ignore_case = TRUE), "CO2eq")
  u <- stringr::str_replace_all(u, stringr::regex("\\bCO2eq\\b", ignore_case = TRUE), "CO2eq")

  # Standardize CO2 capitalization first
  u <- stringr::str_replace_all(u, stringr::regex("Co2", ignore_case = TRUE), "CO2")

  # Standardize eq/e notation
  u <- stringr::str_replace_all(u, stringr::regex("CO2\\s*e\\b", ignore_case = TRUE), "CO2e")
  u <- stringr::str_replace_all(u, stringr::regex("CO2\\s*-\\s*eq\\b", ignore_case = TRUE), "CO2eq")
  u <- stringr::str_replace_all(u, stringr::regex("CO2eq\\b", ignore_case = TRUE), "CO2eq")
  u <- stringr::str_replace_all(u, stringr::regex("CO2e\\b", ignore_case = TRUE), "CO2e")

  # Unify CO2e and CO2eq notation to one canonical form
  u <- stringr::str_replace_all(u, stringr::regex("CO2e\\b", ignore_case = TRUE), "CO2eq")

  # Tons / tonnes
  u <- stringr::str_replace_all(u, stringr::regex("\\btons?\\b", ignore_case = TRUE), "t")
  u <- stringr::str_replace_all(u, stringr::regex("\\btonnes\\b", ignore_case = TRUE), "t")

  # Compact common greenhouse-gas styles
  u <- stringr::str_replace_all(u, stringr::regex("\\bt CO2\\b"), "tCO2")
  u <- stringr::str_replace_all(u, stringr::regex("\\bt CO2e\\b"), "tCO2e")
  u <- stringr::str_replace_all(u, stringr::regex("\\bt CO2eq\\b"), "tCO2eq")
  u <- stringr::str_replace_all(u, stringr::regex("\\bMt CO2\\b"), "MtCO2")
  u <- stringr::str_replace_all(u, stringr::regex("\\bMt CO2e\\b"), "MtCO2e")
  u <- stringr::str_replace_all(u, stringr::regex("\\bMt CO2eq\\b"), "MtCO2eq")
  u <- stringr::str_replace_all(u, stringr::regex("\\bGt CO2\\b"), "GtCO2")
  u <- stringr::str_replace_all(u, stringr::regex("\\bkg CO2eq\\b", ignore_case = TRUE), "kgCO2eq")

  # Per capita notation
  u <- stringr::str_replace_all(u, stringr::regex("/ capita /", ignore_case = TRUE), "/cap/")
  u <- stringr::str_replace_all(u, stringr::regex("/capita\\b", ignore_case = TRUE), "/cap")
  u <- stringr::str_replace_all(u, stringr::regex("\\bcapita\\b", ignore_case = TRUE), "cap")

  # Common compact style cleanups
  u <- stringr::str_replace_all(u, stringr::regex("\\s+/\\s+"), "/")
  u <- stringr::str_replace_all(u, stringr::regex("\\s+\\*\\s+"), "*")
  u <- stringr::str_squish(u)

  # Normalize spaces around slashes
  u <- stringr::str_replace_all(u, stringr::regex("\\s*/\\s*"), "/")

  # Normalize spaces before yr-1
  u <- stringr::str_replace_all(u, stringr::regex("\\s+yr-1\\b", ignore_case = TRUE), "/yr")

  # Normalize "X yr-1" to "X/yr" for common units
  u <- stringr::str_replace_all(u, stringr::regex("\\b(MtCO2eq|MtCO2|GtC|tC|kg P|kgN|Gg P|GgN|km3)\\s+yr-1\\b"), "\\1/yr")

  # Normalize kt casing
  u <- stringr::str_replace_all(u, stringr::regex("\\bKt\\b"), "kt")

  # Remove spaces between mass unit and element/gas where appropriate
  u <- stringr::str_replace_all(u, stringr::regex("\\bkg\\s+P\\b"), "kgP")
  u <- stringr::str_replace_all(u, stringr::regex("\\bkg\\s+N\\b"), "kgN")
  u <- stringr::str_replace_all(u, stringr::regex("\\bGg\\s+P\\b"), "GgP")
  u <- stringr::str_replace_all(u, stringr::regex("\\bGg\\s+N\\b"), "GgN")
  u <- stringr::str_replace_all(u, stringr::regex("\\bTg\\s+P\\b"), "TgP")
  u <- stringr::str_replace_all(u, stringr::regex("\\bTg\\s+N\\b"), "TgN")
  u <- stringr::str_replace_all(u, stringr::regex("\\bt\\s+P\\b"), "tP")
  u <- stringr::str_replace_all(u, stringr::regex("\\bt\\s+N\\b"), "tN")
  u <- stringr::str_replace_all(u, stringr::regex("\\bMt\\s+C\\b"), "MtC")
  u <- stringr::str_replace_all(u, stringr::regex("\\bt\\s+C\\b"), "tC")

  # Normalize PM units
  u <- stringr::str_replace_all(u, stringr::regex("\\bkg\\s+PM2\\.5\\s+eq\\b", ignore_case = TRUE), "kgPM2.5eq")

  # Some highly specific safe normalizations seen in the uploaded unit table
  u <- dplyr::case_when(
    u %in% c("kg N/y", "kg N/yr", "kgN/year", "kgN/y", "kgN/yr", "KgN/year") ~ "kgN/yr",
    u %in% c("kg P/y", "kg P/yr", "kg P/year") ~ "kgP/yr",
    u %in% c("ktN/yr", "ktN/year") ~ "ktN/yr",
    u %in% c("ktP/yr", "ktP/year") ~ "ktP/yr",
    u %in% c("m3 / y", "m3/y", "m3/year", "m3/yr", "m3 yr-1", "m3 y-1") ~ "m3/yr",
    u %in% c("Mm3/a", "Mm3/yr") ~ "Mm3/yr",
    u %in% c("million m3/y") ~ "million m3/yr",
    u %in% c("ha/capita") ~ "ha/cap",
    u %in% c("kgN/cap", "kg P/cap", "kgP/cap") ~ gsub(" ", "", u, fixed = TRUE),
    TRUE ~ u
  )

  u
}

#' Detect likely context/commentary mixed into the unit string
#'
#' @param u Character vector.
#' @return Logical vector.
#' @export

detect_context <- function(u) {
  u <- as.character(u)
  out <- stringr::str_detect(
    u,
    stringr::regex(
      paste(
        c(
          "\\band\\b",
          "\\brespectively\\b",
          "\\buntil\\b",
          "\\bmeans\\b",
          "\\bbecomes\\b",
          "\\bafter this date\\b",
          "\\bin\\s+\\d{4}\\b",
          "\\bsamples\\b",
          "\\bsubbasin\\b",
          ">\\s*\\d",
          "\\bout of\\b"
        ),
        collapse = "|"
      ),
      ignore_case = TRUE
    )
  )
  out[is.na(out)] <- FALSE
  out
}

#' Detect likely non-physical indicators / indices
#'
#' @param u Character vector.
#' @return Logical vector.
#' @export

detect_non_physical <- function(u) {
  u <- as.character(u)
  out <- stringr::str_detect(
    u,
    stringr::regex(
      paste(
        c(
          "^$",
          "^\\(unitless\\)$",
          "\\bunitless\\b",
          "\\bindex\\b",
          "\\bPDF\\b",
          "\\bE/MSY\\b",
          "\\bout of\\b",
          "\\bdisease incidents\\b",
          "\\bcolapse marine extraction system\\b",
          "\\bcatchments above sustainable groundwater use\\b"
        ),
        collapse = "|"
      ),
      ignore_case = TRUE
    )
  )
  out[is.na(out)] <- FALSE
  out
}

#' Detect suspicious units that likely need manual review
#'
#' @param u Character vector.
#' @return Logical vector.
#' @export

detect_suspicious_unit <- function(u) {
  u <- as.character(u)
  out <- stringr::str_detect(
    u,
    stringr::regex(
      paste(
        c(
          "^,",
          "^'",
          "^\\[",
          "\\]$",
          "\\bCO3\\b",
          "\\bCO4\\b",
          "\\bCO5\\b",
          "\\bCO6\\b",
          "\\b10\\^4t\\b",
          "\\bbillion m3\\b",
          "\\bbillion m3/yr\\b"
        ),
        collapse = "|"
      ),
      ignore_case = TRUE
    )
  )
  out[is.na(out)] <- FALSE
  out
}

#' Compare two character vectors after trimming and NA handling
#'
#' @param x Character vector.
#' @param y Character vector.
#' @return Logical vector.
#' @keywords internal
same_text <- function(x, y) {
  x <- as.character(x)
  y <- as.character(y)
  x <- ifelse(is.na(x), NA_character_, stringr::str_squish(x))
  y <- ifelse(is.na(y), NA_character_, stringr::str_squish(y))
  same <- x == y
  same[is.na(x) & is.na(y)] <- TRUE
  same[is.na(same)] <- FALSE
  same
}
