
# Libraries
library(tidyverse)
library(sf)
library(mblm)

getwd()

# Read in western states
west <- st_read('../../data/boundaries/political/TIGER/tl19_us_states_west_nad83.gpkg') %>%
 dplyr::select(STUSPS,geom)

# Read in ecoregions (Level 1)
ecol1 <- st_read('../../data/boundaries/ecological/ecoregion/na_cec_eco_l1.gpkg') %>%
 dplyr::select(NA_L1CODE,NA_L1NAME,geom) %>%
 st_join(west,join=st_intersects) %>%
 filter(!is.na(STUSPS))
glimpse(ecol1)

# Read in FIRED
fired <- st_read('../../FIRED/data/spatial/mod/fired_events_conus_to2021091.gpkg') %>%
 filter(ig_year <= 2020,
        lc_name != "Croplands",
        lc_name != "Water Bodies") %>%
 # Join to states
 st_join(west,largest=TRUE) %>%
 filter(!is.na(STUSPS)) %>% # keep western states
 # Join to ecoregion
 st_join(ecol1,)
glimpse(fired)

# Export as a table without geometry
fired %>% st_set_geometry(NULL) %>% as_tibble() %>%
 dplyr::select(id,ig_date,ig_year,event_dur,fsr_km2_dy,mx_grw_km2) %>%
 write_csv('data/fired_nocrops_west.csv')

rm(fired,west)


# Sys.setenv(
#   "AWS_ACCESS_KEY_ID" = "",
#   "AWS_SECRET_ACCESS_KEY" = "",
#   "AWS_DEFAULT_REGION" = "us-west-2")
# bucketlist()


# Read back in the csv
# clear memory

fire_nocrops <- read.csv('data/tabular/fired_nocrops_west.csv')

ggplot(data=fire_nocrops)+geom_histogram(aes(x=mx_grw_km2))

# Prep the DF
fire_nocrops <- fire_nocrops %>% 
 filter(mx_grw_km2 > 1) %>%
 mutate(date = as.Date(ig_date),
        ig_year = as.numeric(ig_year),
        log_mx_grw = log(mx_grw_km2))

ggplot(data=fire_nocrops)+geom_histogram(aes(x=log_mx_grw))

# Shorten that list to duration > 4
fire_shorter <-filter(fire_nocrops, event_dur>4)
glimpse(fire_shorter)
rm(fire_nocrops)
gc() # clear the memory

ggplot(data=fire_shorter)+geom_histogram(aes(x=log_mx_grw))

###################################################################

# Try to run using the average fire speed by year (just to see ...)
by.year <- fire_shorter %>%
 group_by(ig_year) %>%
 summarize(mean_fsr = mean(mx_grw_km2)) %>%
 ungroup()
glimpse(by.year)

a <- mblm(mean_fsr~ig_year, dataframe = by.year, repeated = F)
m <- as.data.frame(summary(a)$coefficients)
m

rm(by.year,a,m)

### Run by summarized Level-1



###################################################################

# Run the full model ...

a <- mblm(log_mx_grw~ig_year, dataframe = fire_shorter, repeated = F). # or mx_grw_km2
m <- as.data.frame(summary(a)$coefficients)

# write the output
write.csv(m, file.path(tempdir(), "mblm_west.csv"))


# put_object(
#   file = file.path(tempdir(), "mblm_west.csv"), 
#   object = "mblm_west.csv", 
#   bucket = "axa-xl"
# )


# # Test for California
# 
# fire_ca <- filter(fire_short, STATE_NAME %in% c('California'))
# 
# 
# a <- mblm(max_growth_km2~ignition_year, dataframe = fire_ca, repeated = F)
# m <- as.data.frame(summary(a)$coefficients)
# 
# write.csv(m, file.path(tempdir(), "mblm_ca.csv"))
# 
# put_object(
#   file = file.path(tempdir(), "mblm_ca.csv"), 
#   object = "mblm_ca.csv", 
#   bucket = "axa_xl"
# )

