con <- get_db_conn()
va_tr_nces_2020_community_college_computer_sciences_fca <- DBI::dbReadTable(con, c("dc_education_training", "va_tr_nces_2020_community_college_computer_sciences_fca"))
DBI::dbDisconnect(con)

con <- get_db_conn()
va_tr_nces_2020_community_college_engineering_related_fca <- DBI::dbReadTable(con, c("dc_education_training", "va_tr_nces_2020_community_college_engineering_related_fca"))
DBI::dbDisconnect(con)



con <- get_db_conn()
va_arl_census_tracts <- sf::st_read(dsn = con, query = "select * from gis_census_cb.cb_2018_51_tract_500k")
DBI::dbDisconnect(con) 

data.table::setDT(va_tr_nces_2020_community_college_computer_sciences_fca)
data.table::setDT(va_arl_census_tracts)

va_tr_nces_2020_community_college_computer_sciences_fca_geo <- merge(va_tr_nces_2020_community_college_computer_sciences_fca, va_arl_census_tracts, by.x = "geoid", by.y = "GEOID")

va_tr_nces_2020_community_college_computer_sciences_3fca_geo <- va_tr_nces_2020_community_college_computer_sciences_fca_geo[measure=="3sfca_capacity"]
va_tr_nces_2020_community_college_computer_sciences_3fca_geo_sf <- sf::st_as_sf(va_tr_nces_2020_community_college_computer_sciences_3fca_geo)


data.table::setDT(va_tr_nces_2020_community_college_engineering_related_fca)
data.table::setDT(va_arl_census_tracts)

va_tr_nces_2020_community_college_engineering_related_fca_geo <- merge(va_tr_nces_2020_community_college_engineering_related_fca, va_arl_census_tracts, by.x = "geoid", by.y = "GEOID")

va_tr_nces_2020_community_college_engineering_related_3fca_geo <- va_tr_nces_2020_community_college_engineering_related_fca_geo[measure=="3sfca_capacity"]
va_tr_nces_2020_community_college_engineering_related_3fca_geo_sf <- sf::st_as_sf(va_tr_nces_2020_community_college_engineering_related_3fca_geo)



box = c(xmin = -77.1, ymin = 36.54074, xmax = -75.24227, ymax = 38)
plot(sf::st_crop(va_tr_nces_2020_community_college_computer_sciences_3fca_geo_sf[,c("value")], box))
plot(sf::st_crop(va_tr_nces_2020_community_college_engineering_related_3fca_geo_sf[,c("value")], box))



plot(va_tr_nces_2020_community_college_computer_sciences_2fcae_geo_sf[,c("value")])








tidewater <- c("51115", "51073", "51131", "51001", "51700", "51800", "51093", "51650", "51735", "51810", "51550", "51710", "51740")
va_tr_nces_2020_community_college_computer_sciences_3fca_geo_tw <- va_tr_nces_2020_community_college_computer_sciences_fca_geo[measure=="norm_3sfca" & substr(geoid, 1, 5) %in% tidewater,]
va_tr_nces_2020_community_college_computer_sciences_3fca_geo_tw_sf <- sf::st_as_sf(va_tr_nces_2020_community_college_computer_sciences_3fca_geo_tw)
plot(va_tr_nces_2020_community_college_computer_sciences_3fca_geo_tw_sf[, c("value")])

bbox_new <- sf::st_bbox(va_tr_nces_2020_community_college_computer_sciences_3fca_geo_tw_sf)


plot(sf::st_crop(va_tr_nces_2020_community_college_computer_sciences_3fca_geo_tw_sf[, c("value")], box))
