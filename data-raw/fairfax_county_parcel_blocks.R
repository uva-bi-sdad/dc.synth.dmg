library(tigris)
library(sf)
library(data.table)

fairfax_blocks <- blocks("VA", "059", 2020)
fairfax_blocks_wgs84 <-st_transform(fairfax_blocks, 4326)
saveRDS(fairfax_blocks_wgs84, "data-raw/fairfax_blocks_wgs84.RDS")

fairfax_address_points <- st_read("data-raw/Fairfax Address_Points/Address_Points.shp")
fairfax_address_points_wgs84 <- st_transform(fairfax_address_points, 4326)
saveRDS(fairfax_address_points_wgs84, "data-raw/fairfax_address_points_wgs84.RDS")

fairfax_parcels <- st_read("data-raw/Fairfax County Parcels/Parcels.shp")
fairfax_parcels_wgs84 <-st_transform(fairfax_parcels, 4326)
saveRDS(fairfax_parcels_wgs84, "data-raw/fairfax_parcels_wgs84.RDS")


fairfax_address_points_blocks_wgs84 <- st_join(fairfax_address_points_wgs84, fairfax_blocks_wgs84, join = st_within)
saveRDS(fairfax_address_points_blocks_wgs84, "data-raw/fairfax_address_points_blocks_wgs84.RDS")


# Drop geometry and set as data.table for easier filtering
fairfax_address_points_blocks <- setDT(st_drop_geometry(fairfax_address_points_blocks_wgs84))
# Eliminate duplicates - Group by PARCEL_PIN and select the first one in each group
fairfax_address_points_blocks_unq <- fairfax_address_points_blocks[, .SD[1], "PARCEL_PIN"]

# Merge (Left Join) Parcels
fairfax_parcels_blocks_wgs84 <- merge(fairfax_parcels_wgs84, fairfax_address_points_blocks_unq, by.x = "PIN", by.y = "PARCEL_PIN", all.x = TRUE)
saveRDS(fairfax_parcels_blocks_wgs84, "data-raw/fairfax_parcels_blocks_wgs84.RDS")

