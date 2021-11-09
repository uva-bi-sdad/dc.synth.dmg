# Test
library(dc.synth.dmg)
# Get ACS and Block Address Count Data
mydata <- get_data(state_abbrev = "VA", county_fips = "013")
# Generate Demographic Estimates per Census Block
bk_dmgs <- generate_block_dmgs(acs_data = mydata$acs_data_51013, bac_data = mydata$bac_data_51013)
