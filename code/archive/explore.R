###########
# LIBRARIES
###########

library(tidyverse)
library(sf)

# ENV
## Environment variables and data
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
setwd("../")

# DATA
# Filter incidents, FIRED, and ICS-FIRED to fast fires

# ICS-209-PLUS table 1999-2020
incidents <- st_read("../ics209-plus-fired/data/spatial/raw/wf-incidents/pre-release_v2/ics209-plus-wf_incidents_spatial_conus_1999to2020.gpkg")
# Isolate fast fires
incidents.fast <- incidents %>%
 mutate(FINAL_HA = FINAL_ACRES*0.404686) %>% 
 filter(FINAL_HA >= 1620)

# FIRED
fired <- st_read("../fired/data/spatial/mod/fired_events_conus_to2021091.gpkg")
# subset to fast fires
fired.fast <- fired %>% filter(lc_name != "Croplands") %>% 
 mutate(mx_grw_ha = mx_grw_km2*100) %>% 
 filter(mx_grw_ha >= 1620)

# ICS-FIRED
ics.fired <- st_read("../ics209-plus-fired/data/spatial/mod/ics-fired/ics-fired_west_plus_2001to2020.gpkg")
# Select the top 100 fastest fires
ics.fired.fast <- ics.fired %>%
 mutate(FINAL_HA = FINAL_ACRES*0.404686) %>% 
 filter(FINAL_HA >= 1620)

#################

# Grab the top N fastest
t25 <- top_n(fired.fast, 25, mx_grw_ha)
t25 <- t25 %>% as_tibble() %>%
 left_join(ics.fired%>%as_tibble(), by="id") %>%
 st_as_sf()

# Print some info and write to gpkg
dim(ics.fired %>% filter(id %in% t25$id))
dim(t25 %>% filter(!id%in%ics.fired$id))
st_write(t25, "data/t25_fastest_fired_ics.gpkg", delete_dsn=TRUE)

##################

# Bring in the old incidents table
inci.old <- read_csv("../ics209-plus-fired/data/tabular/raw/wf-incidents/ics209plus_wf_incidents_conus_1999to2020.csv")
inci.old.fast <- inci.old %>%
 mutate(FINAL_HA = FINAL_ACRES*0.404686) %>% 
 filter(FINAL_HA >= 1620)
# Work with summaries of key attributes

# Number of fires requiring evacuations
dim(incidents.fast%>%filter(PEAK_EVACUATIONS>0))
sum(incidents.fast$PEAK_EVACUATIONS,na.rm=TRUE)
