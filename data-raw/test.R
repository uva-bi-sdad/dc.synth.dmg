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


# Generate Demographic Estimates per Census Block
bk_dmgs <- generate_block_dmgs(acs_data = mydata$acs_data_11001, bac_data = mydata$bac_data_11001)




# Load the Arlington VA Master Housing Unit Database
va_arl_housing_unit_db <- sf::st_read("https://opendata.arcgis.com/datasets/628f6de7205641169273ea684a74fb0f_0.geojson")

bk_dmg_1 <- bk_dmgs[geoid=="510131001001006"]
arl_hus <- va_arl_housing_units[va_arl_housing_units$Full_Block=="510131001001006",]
