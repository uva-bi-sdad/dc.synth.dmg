library(sf)
library(data.table)

civ_assoc <- st_read("../../projects_data/mc/data_commons/arl_civic_association_polygons/Civic_Association_Polygons.shp")
plot(st_geometry(civ_assoc))

civ_assoc_wgs84 <-st_transform(civ_assoc, 4326)
plot(st_geometry(civ_assoc_wgs84))

# intersect with parcels to assign parcels to civic associations
int <- st_intersects(civ_assoc_wgs84, va_arl_block_parcels_cnts_dmgs_dt_wide_geo_sf)

plot(st_geometry(va_arl_block_parcels_cnts_dmgs_dt_wide_geo_sf[int[[1]],]))
plot(st_geometry(va_arl_block_parcels_cnts_dmgs_dt_wide_geo_sf[int[[2]],]))

i = 1

setDT(va_arl_block_parcels_cnts_dmgs_dt_wide_geo_sf)
for (i in 1:length(int)) {
  cv <- civ_assoc_wgs84[i,]$CIVIC
  va_arl_block_parcels_cnts_dmgs_dt_wide_geo_sf[int[[i]], civ_assoc := cv]
}
va_arl_block_parcels_cnts_dmgs_dt_wide_geo_sf <- st_as_sf(va_arl_block_parcels_cnts_dmgs_dt_wide_geo_sf)

con <- get_db_conn()
dc_dbWriteTable(con, "dc_working", "va_arl_block_parcels_cnts_dmgs_civ_dt_wide_geo_sf", va_arl_block_parcels_cnts_dmgs_dt_wide_geo_sf)
DBI::dbDisconnect(con)

plot(va_arl_block_parcels_cnts_dmgs_dt_wide_geo_sf[va_arl_block_parcels_cnts_dmgs_dt_wide_geo_sf$civ_assoc == "Williamsburg", c("afr_amer_alone_pct")])
plot(va_arl_block_parcels_cnts_dmgs_dt_wide_geo_sf[va_arl_block_parcels_cnts_dmgs_dt_wide_geo_sf$civ_assoc == "Williamsburg", c("wht_alone_pct")])

setDT(va_arl_block_parcels_cnts_dmgs_dt_wide_geo_sf)
civ_dmg <- va_arl_block_parcels_cnts_dmgs_dt_wide_geo_sf[, .(wht_alone_pct = mean(wht_alone_pct), afr_amer_alone_pct = mean(afr_amer_alone_pct) ), c("civ_assoc")]
setDT(civ_assoc_wgs84)
civ_dmg_geo <- merge(civ_dmg, civ_assoc_wgs84, by.x = "civ_assoc", by.y = "CIVIC")
civ_dmg_geo_sf <- st_as_sf(civ_dmg_geo)
plot(civ_dmg_geo_sf[, c("wht_alone_pct")])
