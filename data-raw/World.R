library(sf)

World <- sf::read_sf("data-raw/World.shp")

colnames(World) <- c("iso_a3", "location_name", "geometry")

usethis::use_data(World, overwrite = T)
