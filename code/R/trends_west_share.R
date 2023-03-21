install.packages('aws.s3')
library(aws.s3)
library(tidyverse)
library(rgdal)
library(scales)
library(sf)
install.packages('DescTools')
library(DescTools)
library(ggthemes)
library(foreach)
library(doParallel)
install.packages('mblm')
library(mblm)

getwd()

# Set up the parallel compute
numCores <- detectCores() - 1
cl <- parallel::makeCluster(numCores)
registerDoParallel(cl)

# Read in western states
west <- st_read('../../data/boundaries/political/TIGER/tl19_us_states_west_nad83.gpkg') %>%
 dplyr::select(STUSPS,geom)

# Read in FIRED
fired <- st_read('../../FIRED/data/spatial/mod/fired_events_conus_to2021091.gpkg') %>%
 filter(ig_year <= 2020,
        lc_name != "Croplands",
        lc_name != "Water Bodies") %>%
 # Join to states
 st_join(west,largest=TRUE) %>%
 filter(!is.na(STUSPS)) # keep western states
glimpse(fired)

# Export as a table without geometry
fired %>% st_set_geometry(NULL) %>% as_tibble() %>% 
 dplyr::select(id,ig_date,ig_year,event_dur,fsr_km2_dy,mx_grw_km2) %>%
 write_csv('data/fired_nocrops_west.csv')

# Sys.setenv(
#   "AWS_ACCESS_KEY_ID" = "",
#   "AWS_SECRET_ACCESS_KEY" = "",
#   "AWS_DEFAULT_REGION" = "us-west-2")
# bucketlist()


# Read back in the csv
# clear memory
rm(fired,west)
fire_nocrops <- read.csv('data/fired_nocrops_west.csv')


# Prep the DF
fire_nocrops <- fire_nocrops %>% 
  mutate(date = as.Date(ig_date))


# Shorten that list to duration > 4
fire_shorter <-filter(fire_nocrops, event_dur>4)
fire_shorter <- data.frame(fire_shorter) %>% 
  mutate(ig_year = as.numeric(ig_year),
         fsr_km2_dy = as.numeric(fsr_km2_dy)) %>%
 na.omit()
glimpse(fire_nocrops)
rm(fire_nocrops)
gc() # clear the memory


# Run the model ...
a <- mblm(mx_grw_km2~ig_year, dataframe = fire_shorter, repeated = F)
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

