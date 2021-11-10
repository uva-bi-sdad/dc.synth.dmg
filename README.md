dc.synth.dmg
================
Aaron Schroeder
11/10/2021

## A Data Commons Package for Generating Block and Parcel-Level Demographics from ACS Estimates

### Installation

``` r
remotes::install_github("uva-bi-sdad/dc.synth.dmg")
```

``` r
library(dc.synth.dmg)
```

### Get ACS and Block Address Count Data

#### get_data() returns a list of 2 datasets, one of ACS data, the other a count of total housing units per Census block

``` r
mydata <- get_data(state_abbrev = "VA", county_fips = "013")

print(mydata)
```

    $acs_data_51013
                 GEOID                                                         NAME
       1: 510131001001 Block Group 1, Census Tract 1001, Arlington County, Virginia
       2: 510131001001 Block Group 1, Census Tract 1001, Arlington County, Virginia
       3: 510131001001 Block Group 1, Census Tract 1001, Arlington County, Virginia
       4: 510131001001 Block Group 1, Census Tract 1001, Arlington County, Virginia
       5: 510131001001 Block Group 1, Census Tract 1001, Arlington County, Virginia
      ---                                                                          
    2349: 510139802001 Block Group 1, Census Tract 9802, Arlington County, Virginia
    2350: 510139802001 Block Group 1, Census Tract 9802, Arlington County, Virginia
    2351: 510139802001 Block Group 1, Census Tract 9802, Arlington County, Virginia
    2352: 510139802001 Block Group 1, Census Tract 9802, Arlington County, Virginia
    2353: 510139802001 Block Group 1, Census Tract 9802, Arlington County, Virginia
                variable estimate moe
       1:      total_pop     1209 279
       2:           male      629 159
       3:        male0_4       42  33
       4:        male5_9       48  37
       5:      male10_14        0  12
      ---                            
    2349:      female5_9        0  12
    2350:    female10_14        0  12
    2351:    female15_17        0  12
    2352:      wht_alone        4   5
    2353: afr_amer_alone        0  12

    $bac_data_51013
                    geoid year              measure value
       1: 510131001001000 2021  total_housing_units    74
       2: 510131001001001 2021  total_housing_units     6
       3: 510131001001002 2021  total_housing_units    12
       4: 510131001001003 2021  total_housing_units    27
       5: 510131001001004 2021  total_housing_units    13
      ---                                                
    4288: 510139802001008 2021 total_group_quarters     0
    4289: 510139802001009 2021 total_group_quarters     0
    4290: 510139802001010 2021 total_group_quarters     0
    4291: 510139802001011 2021 total_group_quarters     0
    4292: 510139802001012 2021 total_group_quarters     0

### Generate Demographic Estimates per Census Block

``` r
bk_dmgs <-
  generate_block_dmgs(acs_data = mydata$acs_data_51013,
                      bac_data = mydata$bac_data_51013)

print(head(bk_dmgs[order(geoid)]))
```

                 geoid            var      value
    1: 510131001001000      total_pop 215.580723
    2: 510131001001000      wht_alone 182.057831
    3: 510131001001000 afr_amer_alone   3.922892
    4: 510131001001000           male 112.159036
    5: 510131001001000        male0_4   7.489157
    6: 510131001001000        male5_9   8.559036

### To change the default ACS variables set your own named list of variables

``` r
set_acs_variables(list(my_total_population = "B01001_001",
                       my_male_population = "B01001_002"))

mydata <- get_data(state_abbrev = "VA", county_fips = "013")

bk_dmgs <-
  generate_block_dmgs(acs_data = mydata$acs_data_51013,
                      bac_data = mydata$bac_data_51013)

print(head(bk_dmgs[order(geoid)]))
```

                 geoid                 var      value
    1: 510131001001000 my_total_population 215.580723
    2: 510131001001000  my_male_population 112.159036
    3: 510131001001001 my_total_population  17.479518
    4: 510131001001001  my_male_population   9.093976
    5: 510131001001002 my_total_population  34.959036
    6: 510131001001002  my_male_population  18.187952
