
###########
# Libraries

library(tidyverse)
library(dplyr)
library(sf)
library(lubridate)
library(scales)
library(gridExtra)
library(ggpubr)
library(ggthemes)
library(formattable)
library(raster)
library(rasterVis)
library(scales)
library(RColorBrewer)
library(ggsn)
library(ggspatial)

maindir = getwd()

proj = 5070

######
# Data

# ICS-209-PLUS (1999-2020)
ics209s <- st_read("../../ics209-plus-fired/data/spatial/raw/wf-incidents/ics-209-plus-2.0/ics209plus-wf_incidents_spatial_us_1999to2020.gpkg")

# FIRED (2001-2020)
fired <- st_read("../../fired/data/spatial/mod/fired_events_conus_to2021091.gpkg")

# ICS-FIRED (2001-2020)
ics.fired <-  st_read("../../ics209-plus-fired/data/spatial/mod/ics-fired/final/ics209plus_fired_events_cleaned.gpkg")

# NIFC fire perimeters
nifc <- st_read("data/spatial/raw/nifc/public_nifc_perims.gpkg")

# Bring in MTBS perims
mtbs <- st_read("../../data/mtbs/mtbs_perimeter_data/mtbs_perims_conus.gpkg") %>% mutate(
 Incid_Year = lubridate::year(Ig_Date)
) %>% filter(Incid_Year>=2000 & Incid_Year<=2020)

# boundaries
states <- st_read("../../data/boundaries/political/TIGER/tl19_us_states_conus.gpkg")

# ZTRAX
ztrax <- st_read("data/spatial/mod/ztrax/extract/zasmt_fast_fires_extract.shp")%>%
 st_transform(st_crs(mtbs))
