#' Separates units from values in a dataframe
#'
#' The separate_unit_value function, takes a column or columns from a dataframe that contain units and value,
#' . and separates it into two separate columns names `column_name_value` and `column_name_unit`
#'
#' @param df a dataframe which contains the columns to separate
#' @param columns a character with the options Mostconnected, Leastconnected and Ordered
#' @return returns the same dataframe with the new columns
#' @examples
#' # Mostconnected example
#' data("Nitrogen_Data")
#' separate_unit_value(df = Nitrogen_Data, columns = "boundary_percapita")
#' @author Derek Corcoran <derek.corcoran.barrios@gmail.com>
#' @author Giorgia Graells <gygraell@gmail.com>
#' @export
separate_unit_value <- function(df, columns)
{
  Results <- df
  return(Results)
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
#' @importFrom stringr str_extract
#' @author Derek Corcoran <derek.corcoran.barrios@gmail.com>
#' @author Giorgia Graells <gygraell@gmail.com>
#' @export

extract_unit <- function(x) {
  out <- str_extract(x, "(?<=\\d)\\s*[^0-9\\.]+$")
  str_trim(out)
}
