library(dplyr)
library(sf)



# upload data new geography informations
geo_infos <- sf::st_read("~/Github/dc.geographies/data/va059_geo_ffxct_gis_2022_human_services_regions/distribution/va059_geo_ffxct_gis_2022_human_services_regions.geojson")

# upload data from fairfax estimate at the parcel level
#fairfax_housing_units_cnts_dmgs_dt_wide_geo <- sf::st_as_sf(fairfax_housing_units_cnts_dmgs_dt_wide_geo)

# merge the two data using intercept
sf::sf_use_s2(FALSE)
fairfax_acs_human_services_regions <- st_join(geo_infos, fairfax_housing_units_cnts_dmgs_dt_wide_geo, join = st_intersects)

# Estimate the result by human services regions
fairfax_human_services_regions <- fairfax_acs_human_services_regions %>%
  select(geoid=geoid.x,
         region_name,
         afr_amer_alone,
         amr_ind_alone,
         asian_alone,
         wht_alone,
         male,
         male0_4,
         male5_9,
         male10_14,
         male15_17,
         female,
         female0_4,
         female5_9,
         female10_14,
         female15_17,
         geometry) %>%
  group_by(geoid) %>%
  summarise(afr_amer_alone = sum(afr_amer_alone, na.rm=T),
            amr_ind_alone = sum(amr_ind_alone, na.rm=T),
            asian_alone = sum(asian_alone, na.rm=T),
            wht_alone = sum(wht_alone, na.rm=T),
            male = sum(male, na.rm=T),
            male0_4 = sum(male0_4, na.rm=T),
            male5_9 = sum(male5_9, na.rm=T),
            male10_14 = sum(male10_14, na.rm=T),
            male15_17 = sum(male15_17, na.rm=T),
            female = sum(female, na.rm=T),
            female0_4 = sum(female0_4, na.rm=T),
            female5_9 = sum(female5_9, na.rm=T),
            female10_14 = sum(female10_14, na.rm=T),
            female15_17 = sum(female15_17, na.rm=T))

plot(fairfax_human_services_regions['asian_alone'])
