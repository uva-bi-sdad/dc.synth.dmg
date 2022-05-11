#' Get ACS demographics and Census Block Address Counts for a County
#'
#' @param state_abbrv 2-letter state abbreviation.
#' @param county_fips 3 number FIPS Code.
#' @param geo_level The geographic level at which to estimate populations.
#' @import data.table
#' @import tidycensus
#' @export
#' @examples
#' mydata <- get_data(state_abbrev = "VA", county_fips = "013")
get_data <-
  function(state_abbrev = "",
           county_fips = "",
           geo_level = "block group",
           yr = 2020L,
           acs_var_list = .GlobalEnv$named_acs_var_list) {
    
    if (state_abbrev == "") {
      print("missing 2-letter state abbreviation")
      return()
    } 
    if (county_fips == "") {
      print("missing 3-number county fips code")
      return()
    }
    
    state_fips_codes <-  data.table::setDT(tigris::fips_codes)
    state_fips <-
      unique(state_fips_codes[state == state_abbrev, state_code])
    
    # ACS Data
    acs_data <- data.table::setDT(
      tidycensus::get_acs(
        state = state_fips,
        county = county_fips,
        geography = geo_level,
        year = yr,
        variables = acs_var_list
      )
    )
    acs_name <- paste0("acs_data_", state_fips, county_fips)
    assign(eval(acs_name), acs_data)
    
    # Census Block Address Count Data
    bk_cnt_data <- dc.census.block.address.counts::get_address_block_counts(state_abbrev)
    bk_cnt_data_dt <- data.table::setDT(bk_cnt_data$data)
    st_co_fips <- paste0("^", state_fips, county_fips)
    bkcnt_data_co <- bk_cnt_data_dt[geoid %like% as.name(st_co_fips)]
    
    bac_name <- paste0("bac_data_", state_fips, county_fips)
    assign(eval(bac_name), bkcnt_data_co)
    
    # Return list of both datasets
    out_list <- list()
    out_list[[eval(acs_name)]] <- get(acs_name)
    out_list[[eval(bac_name)]] <- get(bac_name)
    
    out_list
  }

# substr(bk_cnt_data$data$geoid, 1, 12)
