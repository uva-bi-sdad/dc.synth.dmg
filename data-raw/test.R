library(dc.synth.dmg)
library(dc.census.block.address.counts)
# DC Region County FIPS Codes
cnty_fips <- list(
  c("VA", "059"), # Fairfax
  c("VA", "600"), # Fairfax City
  c("VA", "013"), # Arlington
  c("VA", "107"), # Loudoun
  c("VA", "510"), # Alexandria
  c("VA", "683"), # Manassas
  c("VA", "610"), # Falls Church
  c("DC", "001"), # DC
  c("MD", "031"), # Montgomery
  c("MD", "033") # Prince Georges
)

set_acs_variables()

# Get ACS and Block Address Count Data
if (exists("dt_out")) rm(dt_out)
for (i in 1:length(cnty_fips)) {
  print(paste(cnty_fips[[i]][1], cnty_fips[[i]][2]))
  mydata <- get_data(state_abbrev = cnty_fips[[i]][1], county_fips = cnty_fips[[i]][2])
  bk_dmgs <- generate_block_dmgs(acs_data = mydata[[1]], bac_data = mydata[[2]])
  readr::write_csv(bk_dmgs, paste0("data-raw/", cnty_fips[[i]][1], cnty_fips[[i]][2], "_census_block_acs_demographics.csv"))
  # print(nrow(bk_dmgs))
  # if(exists("dt_out")) {
  #   dtf_out <- data.table::rbindlist(list(dtf_out, bk_dmgs))
  # } else {
  #   dtf_out <- bk_dmgs
  # }
}

file_paths <- list.files("data-raw", pattern = "*ics.csv", full.names = TRUE)
if (exists("dt_out")) rm(dt_out)
for (f in file_paths) {
  dt <- data.table::fread(f)
  if(exists("dt_out")) {
    dt_out <- data.table::rbindlist(list(dt_out, dt))
  } else {
    dt_out <- dt
  }
}
 
dt_out[is.na(value)]

readr::write_csv(dt_out, "data-raw/census_block_acs_demographics.csv")
# write to db
con <- get_db_conn()
dc_dbWriteTable(con, "dc_working", "capital_region_census_block_acs_demographics", dt_out)
DBI::dbDisconnect(con)

con <- get_db_conn()
census_block_acs_demographics <- DBI::dbReadTable(con, c("dc_working", "capital_region_census_block_acs_demographics"))
DBI::dbDisconnect(con)


# Load the Arlington VA Master Housing Unit Database
va_arl_housing_units <- sf::st_read("https://opendata.arcgis.com/datasets/628f6de7205641169273ea684a74fb0f_0.geojson")

# Block Parcels
va_arl_block_parcels <- unique(va_arl_housing_units[, c("RPC_Master", "Full_Block", "Total_Units")])

con <- get_db_conn()
dc_dbWriteTable(con, "dc_working", "va_arl_block_parcels", va_arl_block_parcels)
DBI::dbDisconnect(con)

con <- get_db_conn()
va_arl_block_parcels_sf <- sf::st_read(con, c("dc_working", "va_arl_block_parcels"))
DBI::dbDisconnect(con)

data.table::setDT(va_arl_block_parcels_sf)
arl_bg_prcel_cnt <- va_arl_block_parcels_sf[, .(cnt = sum(Total_Units)), substr(Full_Block, 1, 12)][nchar(substr)==12]
colnames(arl_bg_prcel_cnt) <- c("bg_geoid", "prcl_cnt")

va_arl_block_parcels_sf <- sf::st_as_sf(va_arl_block_parcels_sf)
va_arl_block_parcels_sf$bg_geoid <- substr(va_arl_block_parcels_sf$Full_Block, 1, 12)

va_arl_block_parcels_cnts_sf <- merge(va_arl_block_parcels_sf, arl_bg_prcel_cnt, by = "bg_geoid")
va_arl_block_parcels_cnts_sf$mult <- va_arl_block_parcels_cnts_sf$Total_Units/va_arl_block_parcels_cnts_sf$prcl_cnt


# ACS Data
acs_data <- data.table::setDT(
  tidycensus::get_acs(
    year = 2019,
    state = "51",
    county = "013",
    geography = "block group",
    variables = named_acs_var_list
  )
)
colnames(acs_data) <- c("bg_geoid", "name", "variable", "estimate", "moe")

va_arl_block_parcels_cnts_dmgs_sf <- merge(va_arl_block_parcels_cnts_sf, acs_data, by = "bg_geoid", allow.cartesian=TRUE)
va_arl_block_parcels_cnts_dmgs_sf$prcl_estimate <- va_arl_block_parcels_cnts_dmgs_sf$mult * va_arl_block_parcels_cnts_dmgs_sf$estimate

tp <- va_arl_block_parcels_cnts_dmgs_sf[va_arl_block_parcels_cnts_dmgs_sf$variable=="total_pop",]
plot(tp[, c("prcl_estimate")])

aaa <- va_arl_block_parcels_cnts_dmgs_sf[va_arl_block_parcels_cnts_dmgs_sf$variable=="afr_amer_alone",]
plot(aaa[10000:19000, c("prcl_estimate")])

con <- get_db_conn()
dc_dbWriteTable(con, "dc_working", "arl_parcel_demographics", va_arl_block_parcels_cnts_dmgs_sf)
DBI::dbDisconnect(con)

con <- get_db_conn()
va_arl_block_parcels_cnts_dmgs_sf <- sf::st_read(con, c("dc_working", "arl_parcel_demographics"))
DBI::dbDisconnect(con)

bbox_curr <- sf::st_bbox(va_arl_block_parcels_cnts_dmgs_sf)
print(bbox_curr)
bbox <- c(xmin = -77.17183, ymin = 38.82748, xmax = -77.1, ymax = 38.86)


# plot(va_arl_block_parcels_cnts_dmgs_sf[va_arl_block_parcels_cnts_dmgs_sf$variable=="wht_alone", c("estimate")])

white_only <- va_arl_block_parcels_cnts_dmgs_sf[va_arl_block_parcels_cnts_dmgs_sf$variable=="wht_alone",c("prcl_estimate")]


plot(sf::st_crop(white_only, bbox))
plot(sf::st_crop(va_arl_block_parcels_cnts_dmgs_sf[va_arl_block_parcels_cnts_dmgs_sf$variable=="afr_amer_alone",c("prcl_estimate")], bbox))


va_arl_block_parcels_cnts_dmgs_dt <- data.table::as.data.table(va_arl_block_parcels_cnts_dmgs_sf)

va_arl_block_parcels_cnts_dmgs_dt$geometry <- NULL
va_arl_block_parcels_cnts_dmgs_dt <- va_arl_block_parcels_cnts_dmgs_dt[, .(rpc_master = RPC_Master, geoid = Full_Block, measure = variable, value = prcl_estimate)]

va_arl_block_parcels_cnts_dmgs_dt_wide <- data.table::dcast(va_arl_block_parcels_cnts_dmgs_dt, rpc_master + geoid ~ measure, value.var = "value", fun.aggregate = sum)

va_arl_parcel_geo <- unique(va_arl_block_parcels_cnts_dmgs_sf[, c("RPC_Master")])
colnames(va_arl_parcel_geo) <- c("rpc_master", "geometry")

va_arl_block_parcels_cnts_dmgs_dt_wide_geo <- merge(va_arl_block_parcels_cnts_dmgs_dt_wide, va_arl_parcel_geo, by = "rpc_master")
va_arl_block_parcels_cnts_dmgs_dt_wide_geo[, wht_alone_pct := round(100*(wht_alone/total_pop), 2)]
va_arl_block_parcels_cnts_dmgs_dt_wide_geo[, afr_amer_alone_pct := round(100*(afr_amer_alone/total_pop), 2)]

va_arl_block_parcels_cnts_dmgs_dt_wide_geo_sf <- sf::st_as_sf(va_arl_block_parcels_cnts_dmgs_dt_wide_geo)

con <- get_db_conn()
dc_dbWriteTable(con, "dc_working", "va_arl_block_parcels_cnts_dmgs_dt_wide_geo_sf", va_arl_block_parcels_cnts_dmgs_dt_wide_geo_sf)
DBI::dbDisconnect(con)

plot(sf::st_crop(va_arl_block_parcels_cnts_dmgs_dt_wide_geo_sf[, c("wht_alone_pct")], bbox))
plot(sf::st_crop(va_arl_block_parcels_cnts_dmgs_dt_wide_geo_sf[, c("afr_amer_alone_pct")], bbox))






arl_blk_prcl_cnt <- data.table::setDT(va_arl_block_parcels)[, .N, c("Full_Block")]

arl_census_block_acs_demographics <- data.table::setDT(census_block_acs_demographics)[geoid %like% "^51013"]

arl_census_block_acs_demographics_prcl_cnt <- merge(arl_census_block_acs_demographics, arl_blk_prcl_cnt, by.x = "geoid", by.y = "Full_Block")

arl_census_block_acs_demographics_prcl_cnt[, value_per_prcl := value/N]


# Join arl_census_block_acs_demographics_prcl_cnt and block parcels for dmgs per parcel

# data.table::setDT(va_arl_block_parcels)
# dt_out[, geoid := as.character(geoid)]

va_arl_block_parcels_dmgs <- merge(arl_census_block_acs_demographics_prcl_cnt, va_arl_block_parcels, by.x = "geoid", by.y = "Full_Block", allow.cartesian = TRUE)

readr::write_csv(va_arl_block_parcels_dmgs[, .(rpc_master = RPC_Master, geoid, year = 2019, measure = var, value = value_per_prcl)], "data-raw/va_arl_block_parcels_dmgs.csv", quote = "all")


va_arl_block_parcels_dmgs_wide <- make_data_wide(va_arl_block_parcels_dmgs[, .(rpc_master = RPC_Master, geoid, year = 2019, measure = var, value = value_per_prcl)])
va_arl_block_parcels_dmgs_wide <- va_arl_block_parcels_dmgs_wide[trimws(rpc_master, "both") != "",]

va_arl_block_parcels_dmgs_wide[, wht_alone_pct := round(100*(wht_alone/total_pop), 2)]
va_arl_block_parcels_dmgs_wide[, not_wht_alone_pct := 100 - round(100*(wht_alone/total_pop), 2)]


plot(va_arl_housing_units[, c("Total_Units")])

va_arl_housing_units_dt <- data.table::as.data.table(va_arl_housing_units)
va_arl_block_parcels_dmgs_wide_geo <- merge(va_arl_block_parcels_dmgs_wide, va_arl_housing_units_dt, by.x = "rpc_master", by.y = "RPC_Master", all.y = TRUE)
va_arl_block_parcels_dmgs_wide_geo_sf <- sf::st_as_sf(va_arl_block_parcels_dmgs_wide_geo)

plot(va_arl_block_parcels_dmgs_wide_geo_sf[, c("wht_alone_pct")])




con <- get_db_conn()
va_arl_census_blocks <- sf::st_read(dsn = con, query = "select * from gis_census_tl.tl_2021_51_tabblock20 where \"COUNTYFP20\" = '013'")
DBI::dbDisconnect(con)

con <- get_db_conn()
va_arl_census_block_groups <- sf::st_read(dsn = con, query = "select * from gis_census_cb.cb_2018_51_bg_500k where \"COUNTYFP\" = '013'")
DBI::dbDisconnect(con)

plot(st_geometry(va_arl_census_block_groups))

va_arl_block_parcels_sf <- st_as_sf(va_arl_block_parcels)
