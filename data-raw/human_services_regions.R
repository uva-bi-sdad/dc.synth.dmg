library(dplyr)
library(sf)
library(stringr)
library(data.table)

get_db_conn <- function(db_name = "sdad",
                        db_host = "postgis1",
                        db_port = "5432",
                        db_user = Sys.getenv(x = "db_userid"), # requires you to setup environmental vars (above)
                        db_pass = Sys.getenv(x = "db_pwd")) {
  RPostgreSQL::dbConnect(
    drv = RPostgreSQL::PostgreSQL(),
    dbname = "sdad",
    host = "10.250.124.195",
    port = 5432,
    user = db_user,
    password = db_pass)
}


dc_dbWriteTable <-
  function(
    db_conn,
    schema_name,
    table_name,
    table_data,
    table_owner = "data_commons"
  ) {
    # check for geometry/geography columns
    tf <- sapply(table_data, {function(x) inherits(x, 'sfc')})
    # if TRUE, use sf
    if (TRUE %in% tf) {
      sf_write_result <- sf::st_write(obj = table_data, dsn = db_conn, layer = c(schema_name, table_name), row.names = FALSE)
      print(sf_write_result)
      # if FALSE, use DBI
    } else {
      write_result <- DBI::dbWriteTable(conn = db_conn, name = c(schema_name, table_name), value = table_data, row.names = FALSE)
      print(write_result)
    }
    # change table owner
    chgown_result <- DBI::dbSendQuery(conn = db_conn, statement = paste0("ALTER TABLE ", schema_name, ".", table_name, " OWNER TO ", table_owner))
    print(chgown_result)
  }


# upload data new geographies
geo_infos <- sf::st_read("https://github.com/uva-bi-sdad/dc.geographies/blob/main/data/va059_geo_ffxct_gis_2022_human_services_regions/distribution/va059_geo_ffxct_gis_2022_human_services_regions.geojson?raw=T")




## upload demographic characteristics per parcels
# Load demographics data per parcels
con <- get_db_conn()
fairfax_parcels_blocks_cnts_dmgs_dt_wide_geo <- sf::st_read(con, c("dc_working", "fairfax_parcels_blocks_cnts_dmgs_dt_wide_geo"))
DBI::dbDisconnect(con)

# merge the two data using intercept
sf::sf_use_s2(FALSE)
fairfax_acs_dmg_dt <- st_join(geo_infos, fairfax_parcels_blocks_cnts_dmgs_dt_wide_geo, join = st_intersects)

# connect the new geography with block group and parcels
fairfax_acs_dmg_dt_geo <- fairfax_acs_dmg_dt %>% select(parid, new_geoid=geoid.x, geoid=geoid.y, mult)
fairfax_acs_dmg_dt_geo$bg_geoid <- substr(fairfax_acs_dmg_dt_geo$geoid, 1, 12)

# Estimate the demographics information by  result by human services regions
fairfax_dmg_dt_geo <- fairfax_acs_dmg_dt %>%
  select(geoid=geoid.x,
         total_pop,
         region_name,
         afr_amer_alone,
         amr_ind_alone,
         asian_alone,
         wht_alone,
         hispanic,
         male,
         female,
         pop_under_20,
         pop_20_64,
         pop_65_plus,
         geometry) %>%
  group_by(geoid) %>%
  summarise(total_pop = sum(total_pop, na.rm=T),
            afr_amer_alone = sum(afr_amer_alone, na.rm=T),
            amr_ind_alone = sum(amr_ind_alone, na.rm=T),
            asian_alone = sum(asian_alone, na.rm=T),
            wht_alone = sum(wht_alone, na.rm=T),
            hispanic = sum(hispanic, na.rm=T),
            male = sum(male, na.rm=T),
            female = sum(female, na.rm=T),
            pop_under_20 = sum(pop_under_20, na.rm=T),
            pop_20_64 = sum(pop_20_64, na.rm=T),
            pop_65_plus = sum(pop_65_plus, na.rm=T))

# Compute the percentage (not the overall size of the population) by new geography 
fairfax_dmg_dt_geo <- fairfax_dmg_dt_geo %>% mutate(prct_afr_amer_alone = 100*afr_amer_alone/total_pop,
                                                    prct_amr_ind_alone = 100*amr_ind_alone/total_pop,
                                                    prct_asian_alone = 100*asian_alone/total_pop,
                                                    prct_wht_alone = 100*wht_alone/total_pop,
                                                    prct_hispanic = 100*hispanic/total_pop,
                                                    prct_male = 100*male/total_pop,
                                                    prct_female = 100*female/total_pop,
                                                    prct_pop_under_20 = 100*pop_under_20/total_pop,
                                                    prct_pop_20_64 = 100*pop_20_64/total_pop,
                                                    prct_pop_65_plus = 100*pop_65_plus/total_pop)


# rename all variables
fairfax_dmg_dt_geo <- fairfax_dmg_dt_geo %>% 
                          rename(pop_black = "afr_amer_alone",
                                 pop_native = "amr_ind_alone",
                                 pop_AAPI = "asian_alone",
                                 pop_white = "wht_alone",
                                 pop_hispanic_or_latino = "hispanic",
                                 pop_male = "male",
                                 pop_female = "female",
                                 pop_under_20 = "pop_under_20",
                                 pop_20_64 = "pop_20_64",
                                 pop_65_plus = "pop_65_plus",
                                 perc_black = "prct_afr_amer_alone",
                                 perc_native = "prct_amr_ind_alone",
                                 perc_AAPI = "prct_asian_alone",
                                 perc_white = "prct_wht_alone",
                                 perc_hispanic_or_latino = "prct_hispanic",
                                 perc_male = "prct_male",
                                 perc_female = "prct_female",
                                 perc_under_20 = "prct_pop_under_20",
                                 perc_20_64 = "prct_pop_20_64",
                                 perc_65_plus = "prct_pop_65_plus")

# Comments: devices are distributed according to the proportion of living units.
plot(fairfax_dmg_dt_geo['perc_under_20'])

# Cast long
fairfax_dmg_dt_geo <- data.table::as.data.table(fairfax_dmg_dt_geo)
fairfax_dmg_dt_geo$geometry <- NULL

fairfax_dmg_dt_geo_long <-  melt(setDT(fairfax_dmg_dt_geo), id.vars = c("geoid"))
geo_infos_id <- data.table::as.data.table(geo_infos) %>% select(geoid,region_name,region_type,year)

fairfax_dmg_dt_geo_long <- merge(fairfax_dmg_dt_geo_long, geo_infos_id, by="geoid")
fairfax_dmg_dt_geo_long <- fairfax_dmg_dt_geo_long %>% select(geoid,region_type,region_name,year,variable,value)
colnames(fairfax_dmg_dt_geo_long) <- c("geoid", "region_type", "region_name", "year", "measure","value")

# change variables names and year
fairfax_dmg_dt_geo_long$year <- "2019"

# save to DB
write.csv(fairfax_dmg_dt_geo_long,"~/Github/dc.sdad.demographics/data/va059_hsr_sdad_2019_demographics.csv", row.names = FALSE)



## add broadband measure

# load data on broadband
con <- get_db_conn()
ookla_va_bg <- RPostgreSQL::dbGetQuery(conn = con,
                                       statement = "SELECT * FROM dc_digital_communications.va_bg_ookla_2019_2021_speed_measurements")
ookla_va_bg <- st_read(con, query = "SELECT * FROM dc_digital_communications.va_bg_ookla_2019_2021_speed_measurements")
DBI::dbDisconnect(con)


# identify the fairfax county between 2019-2021.
ookla_va_bg_2019_2021 <- ookla_va_bg 
ookla_fairfax_bg_2019_2021 <- ookla_va_bg_2019_2021 %>% filter(str_detect(region_name, "Fairfax"))

# reshape long to wide
ookla_fairfax_bg_dt_2019_2021 <- data.table::as.data.table(ookla_fairfax_bg_2019_2021)
ookla_fairfax_bg_dt_wide_2019_2021 <-  data.table::dcast(ookla_fairfax_bg_dt_2019_2021, geoid + year ~ measure, value.var = "value")

# add geography and parcels. After the merge parcels within the same block group have the same broadband speed.
ookla_fairfax_geo_dt_wide_geo_2019_2021 <- merge(fairfax_acs_dmg_dt_geo, ookla_fairfax_bg_dt_wide_2019_2021, by.x = "bg_geoid", by.y="geoid")

# aggregate the broadband measure to the new geography
ookla_fairfax_new_geo_dt_wide_2019_2021 <- ookla_fairfax_geo_dt_wide_geo_2019_2021 %>%
  select(geoid=new_geoid,
         year,
         mult,
         avg_down_using_devices,
         avg_down_using_tests,
         avg_lat_using_devices,
         avg_lat_using_tests,
         avg_up_using_devices,
         avg_up_using_tests,
         devices,
         tests,
         geometry) %>%
  group_by(geoid,year) %>%
  summarise(avg_down_using_devices = mean(avg_down_using_devices, na.rm=T),
            avg_down_using_tests = mean(avg_down_using_tests, na.rm=T),
            avg_lat_using_devices = mean(avg_lat_using_devices, na.rm=T),
            avg_lat_using_tests = mean(avg_lat_using_tests, na.rm=T),
            avg_up_using_devices = mean(avg_up_using_devices, na.rm=T),
            avg_up_using_tests = mean(avg_up_using_tests, na.rm=T),
            devices = sum(mult*devices, na.rm=T),
            tests = sum(mult*tests, na.rm=T))


# Comments: devices are distributed according to the proportion of living units.
plot(ookla_fairfax_new_geo_dt_wide_2019_2021[ookla_fairfax_new_geo_dt_wide_2019_2021$year==2021,'devices'])

## Combine demographics and broadband information/ cast long
ookla_fairfax_dt_wide_2019_2021 <- data.table::as.data.table(ookla_fairfax_new_geo_dt_wide_2019_2021)
ookla_fairfax_dt_wide_2019_2021$geometry <- NULL

# merge the two data
#fairfax_human_services_regions_dt_2019_2021 <- merge(dmg_fairfax_dt_wide_2019_2021, ookla_fairfax_dt_wide_2019_2021, by="geoid")

ookla_fairfax_dt_wide_long_2019_2021 <-  melt(setDT(ookla_fairfax_dt_wide_2019_2021), id.vars = c("geoid","year"))
geo_infos_id <- data.table::as.data.table(geo_infos) %>% select(geoid,region_name,region_type)

ookla_fairfax_dt_wide_long_2019_2021 <- merge(ookla_fairfax_dt_wide_long_2019_2021, geo_infos_id, by="geoid")
ookla_fairfax_dt_wide_long_2019_2021 <- ookla_fairfax_dt_wide_long_2019_2021 %>% select(geoid,region_type,region_name,year,variable,value)
colnames(ookla_fairfax_dt_wide_long_2019_2021) <- c("geoid", "region_type", "region_name", "year", "measure","value")

# save to DB
write.csv(ookla_fairfax_dt_wide_long_2019_2021,"~/Github/dc.ookla.broadband/data/va059_hsr_sdad_2019_2021_speed_measurements.csv", row.names = FALSE)



