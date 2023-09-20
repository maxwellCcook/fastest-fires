
# Libraries
library(tidyverse)
library(sf)

firedir <- '/Users/max/Library/CloudStorage/OneDrive-Personal/mcook/FIRED'

# Define Lambert projection
lambert.prj <- "+proj=laea +lat_0=45 +lon_0=-100 +x_0=0 +y_0=0 +a=6370997 +b=6370997 +units=m +no_defs"

# Read in the BUPR summary
bupr <- read_csv("../../ics209-plus-fired/data/tabular/mod/fired_qc_bupr_sums.csv") %>%
 select(id,bupr_sum,bupr_sum1km,bupr_sum4km)
# Read in the landcover summary
lc <- read_csv("data/tabular/FIRED_qc_MCD12Q1.csv") %>%
 select(id,LC_Type1) %>%
 mutate(LC_Type1 = as.integer(LC_Type1))
 
# Read the lookup table for LC
lookup <- read_csv("../../data/landcover/MODIS/MCD12Q1_LegendDesc_Type1.csv") %>%
 rename(LC_Type1 = Value)

# Join the lc name
lc <- lc %>%
 left_join(lookup,by="LC_Type1") %>%
 select(id,lc_name,lc_description)

# Read in the FIRED QC (matches ICS-FIRED latest)
fired.qc.fast <- st_read(paste0(firedir,"/data/spatial/mod/event-updates/conus-ak_to2022_events_qc.gpkg")) %>%
 filter(ig_year < 2021) %>%
 mutate(tot_ar_ha = tot_ar_km2*100,
        mx_grw_ha = mx_grw_km2*100,
        mx_grw_pct = (mx_grw_ha / tot_ar_ha)*100) %>% 
 filter(mx_grw_ha >= 1620) %>%
 left_join(bupr,by="id") %>%
 left_join(lc,by="id") %>%
 # Filter out croplands
 filter(lc_name != 'Croplands') %>%
 st_transform(st_crs(lambert.prj))

# Write out for consistency
st_write(fired.qc.fast,"data/spatial/mod/conus_fast-fires_qc_2001to2020.gpkg",delete_dsn=T)
# # Write out a cleaned version for GEE
# fired.qc.fast <- fired.qc.fast %>% select(id, ig_year) %>% st_transform(st_crs(wgs.prj))
# st_write(fired.qc.fast, "../../data/spatial/mod/conus_fast-fires_qc_2001to2020.shp",delete_dsn=T)
# rm(fired.qc.fast)
