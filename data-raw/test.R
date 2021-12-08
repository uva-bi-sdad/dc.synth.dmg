library(dc.synth.dmg)
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

# Get ACS and Block Address Count Data
if (exists("dt_out")) rm(dt_out)
for (i in 1:length(cnty_fips)) {
  mydata <- get_data(state_abbrev = cnty_fips[[i]][1], county_fips = cnty_fips[[i]][2])
  bk_dmgs <- generate_block_dmgs(acs_data = mydata[[1]], bac_data = mydata[[2]])
  if(exists("dt_out")) {
    dt_out <- data.table::rbindlist(list(dt_out, bk_dmgs))
  } else {
    dt_out <- bk_dmgs
  }
}

readr::write_csv(dt_out, "data-raw/census_block_acs_demographics.csv")
# write to db
con <- get_db_conn()
dc_dbWriteTable(con, "dc_working", "capital_region_census_block_acs_demographics", unique(dt_out))

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
