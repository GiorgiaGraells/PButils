## code to prepare `Nitrogen_Data` dataset goes here
library(readr)
library(janitor)

Nitrogen_Data <- read_delim("data-raw/Review_search(Nitrogen).csv", delim = ";", escape_double = FALSE, trim_ws = TRUE,
                   col_types = cols(.default = "c")) |>  clean_names()

usethis::use_data(Nitrogen_Data, overwrite = TRUE)
