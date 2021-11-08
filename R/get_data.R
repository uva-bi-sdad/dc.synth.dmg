# name                                                                                              label concept
# B02001_001                                                                                   Estimate!!Total:    RACE
# B02001_002                                                                      Estimate!!Total:!!White alone    RACE
# B02001_003                                                  Estimate!!Total:!!Black or African American alone    RACE
# B02001_004                                          Estimate!!Total:!!American Indian and Alaska Native alone    RACE
# B02001_005                                                                      Estimate!!Total:!!Asian alone    RACE
# B02001_006                                 Estimate!!Total:!!Native Hawaiian and Other Pacific Islander alone    RACE
# B02001_007                                                            Estimate!!Total:!!Some other race alone    RACE
# B02001_008                                                               Estimate!!Total:!!Two or more races:    RACE
# B02001_009                          Estimate!!Total:!!Two or more races:!!Two races including Some other race    RACE
# B02001_010 Estimate!!Total:!!Two or more races:!!Two races excluding Some other race, and three or more races    RACE
# name                                        label    concept
# 1: B01001_001                             Estimate!!Total: SEX BY AGE
# 2: B01001_002                      Estimate!!Total:!!Male: SEX BY AGE
# 3: B01001_003       Estimate!!Total:!!Male:!!Under 5 years SEX BY AGE
# 4: B01001_004        Estimate!!Total:!!Male:!!5 to 9 years SEX BY AGE
# 5: B01001_005      Estimate!!Total:!!Male:!!10 to 14 years SEX BY AGE
# 6: B01001_006      Estimate!!Total:!!Male:!!15 to 17 years SEX BY AGE
# 7: B01001_007     Estimate!!Total:!!Male:!!18 and 19 years SEX BY AGE
# 8: B01001_008            Estimate!!Total:!!Male:!!20 years SEX BY AGE
# 9: B01001_009            Estimate!!Total:!!Male:!!21 years SEX BY AGE
# 10: B01001_010      Estimate!!Total:!!Male:!!22 to 24 years SEX BY AGE
# 11: B01001_011      Estimate!!Total:!!Male:!!25 to 29 years SEX BY AGE
# 12: B01001_012      Estimate!!Total:!!Male:!!30 to 34 years SEX BY AGE
# 13: B01001_013      Estimate!!Total:!!Male:!!35 to 39 years SEX BY AGE
# 14: B01001_014      Estimate!!Total:!!Male:!!40 to 44 years SEX BY AGE
# 15: B01001_015      Estimate!!Total:!!Male:!!45 to 49 years SEX BY AGE
# 16: B01001_016      Estimate!!Total:!!Male:!!50 to 54 years SEX BY AGE
# 17: B01001_017      Estimate!!Total:!!Male:!!55 to 59 years SEX BY AGE
# 18: B01001_018     Estimate!!Total:!!Male:!!60 and 61 years SEX BY AGE
# 19: B01001_019      Estimate!!Total:!!Male:!!62 to 64 years SEX BY AGE
# 20: B01001_020     Estimate!!Total:!!Male:!!65 and 66 years SEX BY AGE
# 21: B01001_021      Estimate!!Total:!!Male:!!67 to 69 years SEX BY AGE
# 22: B01001_022      Estimate!!Total:!!Male:!!70 to 74 years SEX BY AGE
# 23: B01001_023      Estimate!!Total:!!Male:!!75 to 79 years SEX BY AGE
# 24: B01001_024      Estimate!!Total:!!Male:!!80 to 84 years SEX BY AGE
# 25: B01001_025   Estimate!!Total:!!Male:!!85 years and over SEX BY AGE
# 26: B01001_026                    Estimate!!Total:!!Female: SEX BY AGE
# 27: B01001_027     Estimate!!Total:!!Female:!!Under 5 years SEX BY AGE
# 28: B01001_028      Estimate!!Total:!!Female:!!5 to 9 years SEX BY AGE
# 29: B01001_029    Estimate!!Total:!!Female:!!10 to 14 years SEX BY AGE
# 30: B01001_030    Estimate!!Total:!!Female:!!15 to 17 years SEX BY AGE
# 31: B01001_031   Estimate!!Total:!!Female:!!18 and 19 years SEX BY AGE
# 32: B01001_032          Estimate!!Total:!!Female:!!20 years SEX BY AGE
# 33: B01001_033          Estimate!!Total:!!Female:!!21 years SEX BY AGE
# 34: B01001_034    Estimate!!Total:!!Female:!!22 to 24 years SEX BY AGE
# 35: B01001_035    Estimate!!Total:!!Female:!!25 to 29 years SEX BY AGE
# 36: B01001_036    Estimate!!Total:!!Female:!!30 to 34 years SEX BY AGE
# 37: B01001_037    Estimate!!Total:!!Female:!!35 to 39 years SEX BY AGE
# 38: B01001_038    Estimate!!Total:!!Female:!!40 to 44 years SEX BY AGE
# 39: B01001_039    Estimate!!Total:!!Female:!!45 to 49 years SEX BY AGE
# 40: B01001_040    Estimate!!Total:!!Female:!!50 to 54 years SEX BY AGE
# 41: B01001_041    Estimate!!Total:!!Female:!!55 to 59 years SEX BY AGE
# 42: B01001_042   Estimate!!Total:!!Female:!!60 and 61 years SEX BY AGE
# 43: B01001_043    Estimate!!Total:!!Female:!!62 to 64 years SEX BY AGE
# 44: B01001_044   Estimate!!Total:!!Female:!!65 and 66 years SEX BY AGE
# 45: B01001_045    Estimate!!Total:!!Female:!!67 to 69 years SEX BY AGE
# 46: B01001_046    Estimate!!Total:!!Female:!!70 to 74 years SEX BY AGE
# 47: B01001_047    Estimate!!Total:!!Female:!!75 to 79 years SEX BY AGE
# 48: B01001_048    Estimate!!Total:!!Female:!!80 to 84 years SEX BY AGE
# 49: B01001_049 Estimate!!Total:!!Female:!!85 years and over SEX BY AGE

get_data <-
  function(state_abbrev = "",
           county_fips = "",
           geo_level = "block group") {
    state_fips <-
      unique(data.table::setDT(tigris::fips_codes)[state == state_abbrev, state_code])
    
    acs_data <- data.table::setDT(
      tidycensus::get_acs(
        state = state_fips,
        county = county_fips,
        geography = geo_level,
        variables = c(
          "B01001_001",
          "B02001_002",
          "B02001_003",
          "B01001_002",
          "B01001_026",
          "B28005_002"
        )
      )
    )
    
    assign(paste0("acs_data_", state_fips, county_fips), acs_data, envir = .GlobalEnv)
    
    blkcnt_data <-
      data.table::setDT(dc.census.block.address.counts::get_address_block_counts(state_abbrev))
    st_co_fips <- paste0("^", state_fips, county_fips)
    blkcnt_data_co <- blkcnt_data[geoid %like% as.name(st_co_fips)]
    
    assign(paste0("bac_data_", state_fips, county_fips), blkcnt_data_co, envir = .GlobalEnv)
  }


get_data(state_abbrev = "VA", county_fips = "013")


co_bk_grps <- unique(acs_data_51013$GEOID)

for (i in 1:length(co_bk_grps)) {
  bg_id <- paste0("^", co_bk_grps[i])
  bg_hous_units <- bac_data_51013[geoid %like% as.name(bg_id) & measure == "total_housing_units", sum(value)]
  
  bg_tot_pop <- acs_data_51013[GEOID %like% bg_id & variable == "B01001_001", estimate]
  bk_tot_pop_unit <- bg_tot_pop/bg_hous_units
  
  bk_tot_pops <- unique(bac_data_51013[geoid %like% as.name(bg_id) & measure == "total_housing_units", .(geoid, tot_pop = (value * bk_tot_pop_unit))])
  print(bk_tot_pops)
}


co_bk_cnt <- length(unique(bac_data_51013$geoid))


