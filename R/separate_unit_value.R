#' Separates units from values in a dataframe
#'
#' The separate_unit_value function takes one or more columns from a dataframe that
#' contain a value and a unit, and creates two new columns per input column:
#' `{column}_value` and `{column}_unit`, without removing the original column.
#'
#' @param df A dataframe which contains the columns to separate
#' @param columns A character vector with the names of columns to separate
#' @return Returns the same dataframe with the new columns appended
#' @examples
#' data("Nitrogen_Data")
#' separate_unit_value(df = Nitrogen_Data, columns = "boundary_percapita")
#' @author Derek Corcoran <derek.corcoran.barrios@gmail.com>
#' @author Giorgia Graells <gygraell@gmail.com>
#' @export
separate_unit_value <- function(df, columns) {
  stopifnot(is.data.frame(df))
  stopifnot(is.character(columns))
  if (length(columns) == 0) return(df)

  missing_cols <- setdiff(columns, names(df))
  if (length(missing_cols) > 0) {
    stop(
      "These columns are not in `df`: ",
      paste(missing_cols, collapse = ", "),
      call. = FALSE
    )
  }

  # Create new columns per selected column, preserving originals
  for (col in columns) {
    x <- df[[col]]

    # Coerce to character for extraction; keep NAs as NAs
    x_chr <- if (is.null(x)) rep(NA_character_, nrow(df)) else as.character(x)

    df[[paste0(col, "_value")]] <- extract_value(x_chr)
    df[[paste0(col, "_unit")]]  <- extract_unit(x_chr)
  }

  df
}


#' Extracts values from a string with values and Units
#'
#' The extract_value function, takes a vector that contain units and values,
#' extracts only the value
#'
#' @param x a character vector that contains a value and a unit
#' @return returns a vector with the values of the string as a numeric vector
#' @examples
#' data("Nitrogen_Data")
#' extract_value(Nitrogen_Data$boundary_percapita)
#' @importFrom stringr str_extract
#' @author Derek Corcoran <derek.corcoran.barrios@gmail.com>
#' @author Giorgia Graells <gygraell@gmail.com>
#' @export


extract_value <- function(x) {
  out <- str_extract(x, "[0-9\\.]+")
  as.numeric(out)
}


#' Extracts units from a string with values and Units
#'
#' The extract_unit function, takes a vector that contain units and values,
#' extracts only the value
#'
#' @param x a dcharacter vector that contains a value and a unit
#' @return returns a vector with the units of the string as a character vector
#' @examples
#' data("Nitrogen_Data")
#' extract_unit(Nitrogen_Data$boundary_percapita)
#' @importFrom stringr str_extract str_trim
#' @author Derek Corcoran <derek.corcoran.barrios@gmail.com>
#' @author Giorgia Graells <gygraell@gmail.com>
#' @export

extract_unit <- function(x) {
  out <- str_extract(x, "(?<=\\d)\\s*[^0-9\\.]+$")
  str_trim(out)
}
