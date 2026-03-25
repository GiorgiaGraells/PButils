#' Separates units from values in a dataframe
#'
#' The separate_unit_value function takes one or more columns from a dataframe that
#' contain a value and a unit, and creates two new columns per input column:
#' `{column}_value` and `{column}_unit`, without removing the original column.
#'
#' @param df A dataframe which contains the columns to separate
#' @param columns A character vector with the names of columns to separate, it
#' defaults to
#' @return Returns the same dataframe with the new columns appended
#' @examples
#' data("Nitrogen_Data")
#' # By default it will separate columns  territorial_footprint, territorial_boundary,
#' # footprint_percapita, boundary_percapita
#' separate_unit_value(df = Nitrogen_Data)
#' # but can be changed if needed with more than one variable
#' separate_unit_value(df = Nitrogen_Data,
#'                 columns = c("global_limit_considered","boundary_percapita"))
#' @author Derek Corcoran <derek.corcoran.barrios@gmail.com>
#' @author Giorgia Graells <gygraell@gmail.com>
#' @export
separate_unit_value <- function(df, columns = c("territorial_footprint", "territorial_boundary", "footprint_percapita", "boundary_percapita")) {
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

  for (col in columns) {
    x <- df[[col]]
    x_chr <- if (is.null(x)) rep(NA_character_, nrow(df)) else as.character(x)

    value_col <- paste0(col, "_value")
    unit_col  <- paste0(col, "_unit")

    # compute new columns
    df[[value_col]] <- extract_value(x_chr)
    df[[unit_col]]  <- extract_unit(x_chr)

    # reorder columns: insert new cols right after original
    col_pos <- match(col, names(df))

    new_order <- c(
      names(df)[seq_len(col_pos)],
      value_col,
      unit_col,
      names(df)[-seq_len(col_pos)]
    )

    # remove duplicates caused by re-inserting names
    new_order <- new_order[!duplicated(new_order)]

    df <- df[, new_order, drop = FALSE]
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
#' @importFrom stringr str_replace_all str_match
#' @author Derek Corcoran <derek.corcoran.barrios@gmail.com>
#' @author Giorgia Graells <gygraell@gmail.com>
#' @export


extract_value <- function(x) {
  x <- str_replace_all(x, "[\r\n]+.*$", "")   # drop notes after line breaks
  out <- str_match(
    x,
    "^\\s*([+-]?(?:\\d+(?:\\.\\d+)?|\\.\\d+)(?:[eE][+-]?\\d+)?)"
  )[, 2]
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
#' @importFrom stringr str_replace_all str_match str_trim
#' @author Derek Corcoran <derek.corcoran.barrios@gmail.com>
#' @author Giorgia Graells <gygraell@gmail.com>
#' @export

extract_unit <- function(x) {
  x <- str_replace_all(x, "[\r\n]+.*$", "")   # drop notes after line breaks
  out <- str_match(
    x,
    "^\\s*[+-]?(?:\\d+(?:\\.\\d+)?|\\.\\d+)(?:[eE][+-]?\\d+)?\\s*(.*?)\\s*$"
  )[, 2]
  str_trim(out)
}
