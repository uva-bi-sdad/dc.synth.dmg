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

# upload data new geography informations
geo_infos <- sf::st_read("https://github.com/uva-bi-sdad/dc.geographies/blob/main/data/va059_geo_ffxct_gis_2022_zip_codes/distribution/va059_geo_ffxct_gis_2022_zip_codes.geojson?raw=T")


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

# Compute the percentage (not the overall size of the population) by new geography 
fairfax_dmg_dt_geo <- fairfax_dmg_dt_geo %>% mutate(prct_afr_amer_alone = afr_amer_alone/sum(afr_amer_alone),
                                                    prct_amr_ind_alone = amr_ind_alone/sum(amr_ind_alone),
                                                    prct_asian_alone = asian_alone/sum(asian_alone),
                                                    prct_wht_alone = wht_alone/sum(wht_alone),
                                                    prct_male = male/sum(male),
                                                    prct_male0_4 = male0_4/sum(male0_4),
                                                    prct_male5_9 = male5_9/sum(male5_9),
                                                    prct_male10_14 = male10_14/sum(male10_14),
                                                    prct_male15_17 = male15_17/sum(male15_17),
                                                    prct_female = female/sum(female),
                                                    prct_female0_4 = female0_4/sum(female0_4),
                                                    prct_female5_9 = female5_9/sum(female5_9),
                                                    prct_female10_14 = female10_14/sum(female10_14),
                                                    prct_female15_17 = female15_17/sum(female15_17))


## add broadband measure

# load data on broadband
con <- get_db_conn()
ookla_va_bg <- RPostgreSQL::dbGetQuery(conn = con,
                                       statement = "SELECT * FROM dc_digital_communications.va_bg_ookla_2019_2021_speed_measurements")
ookla_va_bg <- st_read(con, query = "SELECT * FROM dc_digital_communications.va_bg_ookla_2019_2021_speed_measurements")
DBI::dbDisconnect(con)

# filter the year (same year than the census)

# identify the fairfax county measure in 2019.
ookla_va_bg <- ookla_va_bg %>% filter(year==2019)
ookla_fairfax_bg <- ookla_va_bg %>% filter(str_detect(region_name, "Fairfax"))

# reshape long to wide
ookla_fairfax_bg_dt <- data.table::as.data.table(ookla_fairfax_bg)
ookla_fairfax_bg_dt_wide <-  data.table::dcast(ookla_fairfax_bg_dt, geoid ~ measure, value.var = "value")

# add geography and parcels. After the merge parcels within the same block group have the same broadband speed.
ookla_fairfax_geo_dt_wide_geo <- merge(fairfax_acs_dmg_dt_geo, ookla_fairfax_bg_dt_wide, by.x = "bg_geoid", by.y="geoid")

# aggregate the broadband measure to the new geography
ookla_fairfax_new_geo_dt_wide <- ookla_fairfax_geo_dt_wide_geo %>%
  select(geoid=new_geoid,
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
  group_by(geoid) %>%
  summarise(avg_down_using_devices = mean(avg_down_using_devices, na.rm=T),
            avg_down_using_tests = mean(avg_down_using_tests, na.rm=T),
            avg_lat_using_devices = mean(avg_lat_using_devices, na.rm=T),
            avg_lat_using_tests = mean(avg_lat_using_tests, na.rm=T),
            avg_up_using_devices = mean(avg_up_using_devices, na.rm=T),
            avg_up_using_tests = mean(avg_up_using_tests, na.rm=T),
            devices = sum(mult*devices, na.rm=T),
            tests = sum(mult*tests, na.rm=T))

# Comments: devices are distributed according to the proportion of living units.
plot(ookla_fairfax_new_geo_dt_wide['devices'])



## Combine demographics and broadband information/ cast long
ookla_fairfax_dt_wide <- data.table::as.data.table(ookla_fairfax_new_geo_dt_wide)
dmg_fairfax_dt_wide <- data.table::as.data.table(fairfax_dmg_dt_geo)
ookla_fairfax_dt_wide$geometry <- NULL
dmg_fairfax_dt_wide$geometry <- NULL



# merge the two data
fairfax_zip_code_dt <- merge(dmg_fairfax_dt_wide, ookla_fairfax_dt_wide, by="geoid")

# Cast long
fairfax_zip_code_dt_long <-  melt(setDT(fairfax_zip_code_dt), id.vars = c("geoid"))
fairfax_zip_code_dt_long$year <- 2019
fairfax_zip_code_dt_long$state <- "51"
fairfax_zip_code_dt_long$county <- "059"
fairfax_zip_code_dt_long$geography <- "zip codes"

# change variable position and rename
fairfax_zip_code_dt_long <- fairfax_zip_code_dt_long %>% select(year,state,county,geography,variable,value)
colnames(fairfax_zip_code_dt_long) <- c("year", "state", "county", "geography", "variables","value")


# save to DB
#con <- get_db_conn()
#dc_dbWriteTable(con, "dc_working", "fairfax_planning_district", fairfax_planning_district_dt_long)
#DBI::dbDisconnect(con)

