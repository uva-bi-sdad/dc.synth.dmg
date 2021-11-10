library(dc.synth.dmg)
# Get ACS and Block Address Count Data
mydata <- get_data(state_abbrev = "VA", county_fips = "013")
# Generate Demographic Estimates per Census Block
bk_dmgs <- generate_block_dmgs(acs_data = mydata$acs_data_51013, bac_data = mydata$bac_data_51013)
# Load the Arlington VA Master Housing Unit Database
va_arl_housing_unit_db <- sf::st_read("https://opendata.arcgis.com/datasets/628f6de7205641169273ea684a74fb0f_0.geojson")

bk_dmg_1 <- bk_dmgs[geoid=="510131001001006"]
arl_hus <- va_arl_housing_units[va_arl_housing_units$Full_Block=="510131001001006",]
