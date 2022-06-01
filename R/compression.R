library(RPostgreSQL)
library(DBI)
library(tidyr)
library(here)
library(dplyr)
library(stringr)

all_geos_file_name <- "va059_hsr_sdad_2019_demographics"
va059_hsr_sdad_2019_demographics <- read.csv("~/Github/dc.sdad.demographics/data/va059_hsr_sdad_2019_demographics.csv") #%>% mutate(value = ifelse(str_detect(measure, "^perc"), value*100, value))
dat_file_path <- paste0("/home/yhu2bk/Github/dc.sdad.demographics/data/", all_geos_file_name, ".csv.xz")
readr::write_csv(get(all_geos_file_name), xzfile(dat_file_path, compression = 9))

all_geos_file_name <- "va059_spd_sdad_2019_demographics"
va059_spd_sdad_2019_demographics <- read.csv("~/Github/dc.sdad.demographics/data/va059_spd_sdad_2019_demographics.csv") #%>% mutate(value = ifelse(str_detect(measure, "^perc"), value*100, value))
dat_file_path <- paste0("/home/yhu2bk/Github/dc.sdad.demographics/data/", all_geos_file_name, ".csv.xz")
readr::write_csv(get(all_geos_file_name), xzfile(dat_file_path, compression = 9))


all_geos_file_name <- "va059_pd_sdad_2019_demographics"
va059_pd_sdad_2019_demographics <- read.csv("~/Github/dc.sdad.demographics/data/va059_pd_sdad_2019_demographics.csv") #%>% mutate(value = ifelse(str_detect(measure, "^perc"), value*100, value))
dat_file_path <- paste0("/home/yhu2bk/Github/dc.sdad.demographics/data/", all_geos_file_name, ".csv.xz")
readr::write_csv(get(all_geos_file_name), xzfile(dat_file_path, compression = 9))

all_geos_file_name <- "va059_zp_sdad_2019_demographics"
va059_zp_sdad_2019_demographics <- read.csv("~/Github/dc.sdad.demographics/data/va059_zp_sdad_2019_demographics.csv") #%>% mutate(value = ifelse(str_detect(measure, "^perc"), value*100, value))
dat_file_path <- paste0("/home/yhu2bk/Github/dc.sdad.demographics/data/", all_geos_file_name, ".csv.xz")
readr::write_csv(get(all_geos_file_name), xzfile(dat_file_path, compression = 9))
