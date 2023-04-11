
library(tidyverse)
library(sf)

# Define Lambert projection

lambert.prj <- "+proj=laea +lat_0=45 +lon_0=-100 +x_0=0 +y_0=0 +a=6370997 +b=6370997 +units=m +no_defs"

# Load the data

ecosum <- read_csv("data/tabular/trend_coeff_ecoregion.csv")

west.states <- st_read("../../data/boundaries/political/TIGER/tl19_us_states_west_nad83.gpkg") %>%
 st_transform(st_crs(lambert.prj))

ecoregions <- st_read("../../data/boundaries/ecological/ecoregion/na_cec_eco_l3.gpkg") %>%
 st_transform(st_crs(lambert.prj))

# Filter to western ecoregions (spatial)

ecoregions <- st_intersection(ecoregions, west.states)

# Filter max growth trends to west ecoregions

ecosum.west <- ecosum %>%
 filter(Level_1 %in% ecoregions$NA_L1KEY) %>%
 rename(coeff_max_growth = `coeff_max_growth (ha/day/year)`)

# Grab a median estimate by ecoregion level III
ecosum.west %>%
 group_by(Level_3) %>%
 summarize(coeff_max_grow_med = median(coeff_max_growth),
           coeff_max_grow_avg = mean(coeff_max_growth))

# Grab the westwide summaries

mean(ecosum.west$coeff_max_growth,na.rm=T)
median(ecosum.west$coeff_max_growth,na.rm=T)


