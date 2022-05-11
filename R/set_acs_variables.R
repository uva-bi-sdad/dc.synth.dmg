#' Sets the ACS variables that will be used by get_data and generate_block_demographics.
#'
#' @param named_acs_var_list Optional. Named list of ACS variables.
#' @export
set_acs_variables <- function(named_acs_var_list = "") {
  if (named_acs_var_list == "") {
      named_acs_var_list <- list(
        total_pop = "B01001_001",
        wht_alone = "B02001_002",
        afr_amer_alone = "B02001_003",
        amr_ind_alone = "B02001_004",
        asian_alone = "B02001_005",
        male = "B01001_002",
        male0_4 = "B01001_003",
        male5_9 = "B01001_004",
        male10_14 = "B01001_005",
        male15_17 = "B01001_006",
        female = "B01001_026",
        female0_4 = "B01001_027",
        female5_9 = "B01001_028",
        female10_14 = "B01001_029",
        female15_17 = "B01001_030"
      )
  }
  assign("named_acs_var_list",
         named_acs_var_list,
         envir = .GlobalEnv)
}
