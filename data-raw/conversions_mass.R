## code to prepare `conversions_mass` dataset goes here

conversions_mass <- data.frame(
  from   = c("kgN", "TgN", "GgN", "kg", "mg/L", "mgN/L"),
  to     = c("kgN", "kgN", "kgN", "kgN", "kgN", "kgN"),
  factor = c(1, 1e9, 1e6, 1, 1e-6, 1e-6)
)

usethis::use_data(conversions_mass, overwrite = TRUE)
