#' Generate demographic estimates given the block-level address counts
#'
#' @param acs_data ACS data from get_data.
#' @param bac_data Block-level address counts from get_data.
#' @param block_measure Measure to use from the bac_data
#' @param acs_var_list Named list of ACS Codes.
#' @import data.table
#' @export
generate_block_dmgs <-
  function(acs_data,
           bac_data,
           block_measure = "total_housing_units",
           acs_var_list = .GlobalEnv$named_acs_var_list) {
    
    if (is.null(acs_data)) {
      print("missing ACS data.")
      return()
    } 
    if (is.null(bac_data)) {
      print("missing block address count data.")
      return()
    }
    #browser()
    bg_list <- unique(acs_data$GEOID)
    for (i in 1:length(bg_list)) {
      bg_id <- paste0("^", bg_list[i])
      bg_hous_units <-
        bac_data[geoid %like% as.name(bg_id) &
                   measure == block_measure, sum(value)]
      for (j in 1:length(acs_var_list)) {
        bg_tot_pop <-
          acs_data[GEOID %like% bg_id & variable == names(acs_var_list[j]), estimate]
        bk_tot_pop_unit <- bg_tot_pop / bg_hous_units
        bk_pop <-
          unique(bac_data[geoid %like% as.name(bg_id) &
                            measure == "total_housing_units", .(geoid,
                                                                var = names(acs_var_list[j]),
                                                                value = (value * bk_tot_pop_unit))])
        if (!exists("dt_out", inherits = FALSE)) {
          dt_out <- bk_pop
        } else {
          dt_out <- data.table::rbindlist(list(dt_out, bk_pop))
        }
      }
    }
    if (exists("dt_out", inherits = FALSE)) {
      return(dt_out)
    }
  }
