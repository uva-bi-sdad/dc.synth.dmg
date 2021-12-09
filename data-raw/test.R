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


census_block_acs_demographics <- dt_out

readr::write_csv(dt_out, "data-raw/census_block_acs_demographics.csv")
# write to db
con <- get_db_conn()
dc_dbWriteTable(con, "dc_working", "capital_region_census_block_acs_demographics", dt_out)
DBI::dbDisconnect(con)


# Load the Arlington VA Master Housing Unit Database
va_arl_housing_units <- sf::st_read("https://opendata.arcgis.com/datasets/628f6de7205641169273ea684a74fb0f_0.geojson")

# Block Parcels
va_arl_block_parcels <- unique(va_arl_housing_units[, c("GIS_Parcel_ID", "Full_Block")])

con <- get_db_conn()
dc_dbWriteTable(con, "dc_working", "va_arl_block_parcels", va_arl_block_parcels)
DBI::dbDisconnect(con)

arl_blk_prcl_cnt <- va_arl_block_parcels[, .N, c("Full_Block")]
arl_census_block_acs_demographics <- census_block_acs_demographics[geoid %like% "^51013"]

arl_census_block_acs_demographics_prcl_cnt <- merge(arl_census_block_acs_demographics, arl_blk_prcl_cnt, by.x = "geoid", by.y = "Full_Block")

arl_census_block_acs_demographics_prcl_cnt[, value_per_prcl := value/N]


# Join arl_census_block_acs_demographics_prcl_cnt and block parcels for dmgs per parcel

data.table::setDT(va_arl_block_parcels)
dt_out[, geoid := as.character(geoid)]

va_arl_block_parcels_dmgs <- merge(arl_census_block_acs_demographics_prcl_cnt, va_arl_block_parcels, by.x = "geoid", by.y = "Full_Block", allow.cartesian = TRUE)

readr::write_csv(va_arl_block_parcels_dmgs[, .(gis_prcl_id = GIS_Parcel_ID, geoid, year = 2019, measure = var, value = value_per_prcl)], "data-raw/va_arl_block_parcels_dmgs.csv", quote = "all")


va_arl_block_parcels_dmgs_wide <- make_data_wide(va_arl_block_parcels_dmgs[, .(gis_prcl_id = GIS_Parcel_ID, geoid, year = 2019, measure = var, value = value_per_prcl)])





###############
arl <- dt_out[geoid %like% "^51013"]
arl_black <- unique(arl[arl$var %like% "afr"])

# get block geo
con <- get_db_conn()
va_cblocks <- sf::st_read(con, c("gis_census_tl", "tl_2021_51_tabblock20"))
arl_cblocks <- data.table::setDT(va_cblocks[va_cblocks$COUNTYFP20=="013",])

# join to dmgs
jn <- merge(arl_cblocks, arl_black, by.x = "GEOID20", by.y = "geoid")
jn_sf <- sf::st_as_sf(jn)
# plot
plot(jn_sf[, c("value")])
