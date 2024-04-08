###############################################################################################
# Relationship between maximum growth and structure loss in both daily FIRED and ICS-209-PLUS #

library(tidyverse)
library(sf)

lambert.prj <- "+proj=laea +lat_0=45 +lon_0=-100 +x_0=0 +y_0=0 +a=6370997 +b=6370997 +units=m +no_defs"

projdir <- '/Users/max/Library/CloudStorage/OneDrive-Personal/mcook/earth-lab/fastest-fires'
firedir <- '/Users/max/Library/CloudStorage/OneDrive-Personal/mcook/FIRED'
icsdir <- '/Users/max/Library/CloudStorage/OneDrive-Personal/mcook/ics209-plus-fired'


###########################################################
# First we need to gather the daily polygons for fast fires
# B/c we do not have the daily polygons for the vintage used in the manuscript :(

# Fast FIRED events (from original manuscript) with ICS-209 attributes
fpath = paste0(paste0(projdir,"/data/spatial/mod/ics-fired_fast.gpkg"))
fired.events <- st_read(fpath) %>%
 st_transform(st_crs(lambert.prj)) %>%
 select(FIRED_ID, INCIDENT_ID, geom)

# FIRED daily (latest)
fpath = paste0(firedir,"/data/spatial/raw/events/events_040324/shapefiles/fired_conus_ak_2000_to_2024_daily.gpkg")
fired.daily <- st_read(fpath) %>%
 filter(ig_year >= 2001 | ig_year <= 2020) %>%
 st_transform(st_crs(lambert.prj)) %>%
 # Create the max growth DOY and event day
 mutate(mx_grw_dte_doy = lubridate::yday(mx_grw_dte)) %>%
 # Calculate the event day of maximum growth
 group_by(id) %>%
 mutate(mx_grw_dte_event_day = event_day[which(date == mx_grw_dte)[1]]) %>%
 ungroup() %>%
 # Select columns for tidy data frame
 select(did, id, date, ig_date, ig_month, ig_year, event_day, event_dur,
        dy_ar_km2, tot_ar_km2, mx_grw_km2, mx_grw_dte, mx_grw_dte_doy, 
        mx_grw_dte_event_day, last_date)
glimpse(fired.daily) 

#~~~ Find overlapping daily events ~~~#

st_agr(fired.daily) <- "constant"
st_agr(fired.events) <- "constant"

# Spatial join
overlap <- st_join(
 fired.daily, 
 fired.events, 
 join=st_intersects, 
 largest=TRUE
) 

# Filter out non-joins
overlap <- overlap %>%
 filter(!is.na(FIRED_ID))
# Free up memory
rm(fired.daily, fired.events)
gc()

# Do a filter by ignition year/month
fired.daily <- overlap %>%
 filter(ig_year == ig_year,
        ig_month == ig_month)
rm(overlap) # clean up
gc()

# # Check on duplicated daily IDs after the join, should be 0
# fired.daily %>%
#  group_by(did) %>%
#  summarize(count = n()) %>%
#  filter(count > 1) %>%
#  ungroup() %>%
#  nrow()

# # Only keep unique records if there are duplicates
# fired.daily <- fired.daily %>%
#  distinct("did",.keep_all=TRUE)

# Tidy the attributes
fired.daily <- fired.daily %>%
 select(FIRED_ID, INCIDENT_ID, did, id, ig_date, ig_month, ig_year,
        event_day, event_dur, dy_ar_km2, tot_ar_km2, mx_grw_km2,
        mx_grw_dte, mx_grw_dte_doy, mx_grw_dte_event_day, last_date) 

# Write to a file
st_write(fired.daily, "data/spatial/mod/fired_daily_overlap_fast.gpkg", 
         delete_dsn=TRUE, append=FALSE)

gc() # clear up unused memory

glimpse(fired.daily)


########################################################
# Load the ICS-209-PLUS wildfire daily situation reports
# Prep the data for analysis

sitreps <- read_csv(paste0(icsdir,'/data/tabular/raw/wf-incidents/ics209-plus_v2/ics209plus-wildfire/ics209-plus-wf_sitreps_1999to2020.csv'),
                    show_col_types = FALSE) %>%
 # Filter years and extract sitreps in matching the fast fire events
 filter(START_YEAR >= 2001,
        INCIDENT_ID %in% fired.daily$INCIDENT_ID) %>%
 # For each incident, calculate the first report day-of-year, total structures destroyed, and day of maximum structure loss reported
 group_by(INCIDENT_ID) %>%
 mutate(START_DOY = min(REPORT_DOY, na.rm=TRUE),
        STR_DESTROYED_TOTAL = max(STR_DESTROYED),
        MAX_STR_DAY_INDEX = which.max(STR_DESTROYED),
        MAX_STR_LOSS_DOY = REPORT_DOY[MAX_STR_DAY_INDEX]) %>%
 ungroup() %>%
 # Calculate the event day (the number of days since day 0 (ignition)) and the proportion of destroyed structures
 mutate(EVENT_DAY = REPORT_DOY - START_DOY + 1,
        STR_DESTROYED_PROP = STR_DESTROYED / STR_DESTROYED_TOTAL,
        EVENT_ACRES_PROP = NEW_ACRES / EVENT_FINAL_ACRES) %>%
 # Add the event day of max structure loss reported
 group_by(INCIDENT_ID) %>%
 mutate(MAX_STR_LOSS_EVENT_DAY = EVENT_DAY[which.max(STR_DESTROYED)]) %>%
 # Ensure MAX_STR_LOSS_EVENT_DAY is the first day the maximum is reported
 mutate(MAX_STR_LOSS_EVENT_DAY = min(MAX_STR_LOSS_EVENT_DAY[STR_DESTROYED == STR_DESTROYED_TOTAL])) %>%
 ungroup() %>%
 # Select the relevant columns for tidy data frame
 select(INCIDENT_ID,START_DOY,REPORT_DOY,REPORT_TO_DATE,STR_DESTROYED,STR_DESTROYED_TOTAL,
        STR_DESTROYED_PROP, MAX_STR_LOSS_DOY, MAX_STR_LOSS_EVENT_DAY,
        NEW_ACRES, EVENT_DAY, EVENT_FINAL_ACRES, EVENT_ACRES_PROP) %>% 
 # Now group by event day and recalculate (some days have multiple sitreps)
 group_by(INCIDENT_ID,EVENT_DAY) %>%
 summarize(across(c(START_DOY, REPORT_DOY, REPORT_TO_DATE, STR_DESTROYED, 
                    STR_DESTROYED_TOTAL, STR_DESTROYED_PROP, MAX_STR_LOSS_DOY, MAX_STR_LOSS_EVENT_DAY,
                    NEW_ACRES, EVENT_FINAL_ACRES, EVENT_ACRES_PROP), 
                  \(x) max(x, na.rm = TRUE)))
glimpse(sitreps)

# Make sure we have the expected number of incidents (or close to it)
length(unique(fired.daily$INCIDENT_ID))
length(unique(sitreps$INCIDENT_ID))


######################################################################################
# Plot the daily area burned and the daily structure loss reports for the Chetco Bar #

test.fired <- fired.daily %>% filter(id == 134)
test.ics <- sitreps %>% filter(INCIDENT_ID == "2017_7265708_CHETCO BAR")

p1 <- ggplot(data=test.fired) +
 geom_line(aes(x=event_day, y=dy_ar_km2)) +
 xlim(c(0,90)) +
 labs(tag="A",x="Event Day",y="Area Burned (km2)") +
 theme_bw()

p2 <- ggplot(data=test.ics) +
 geom_line(aes(x=EVENT_DAY, y=STR_DESTROYED)) + 
 xlim(c(0,90)) +
 labs(tag="B",x="Event Day",y="Structures Destroyed") +
 theme_bw()

ggpubr::ggarrange(p1,p2,nrow=2,ncol=1)

rm(test.fired, test.ics, p1, p2)


##########################################################
# Plot normalized event day of max growth / structure loss

# Function to normalize a column
normalize <- function(x) {
 (x - min(x, na.rm = TRUE)) / (max(x, na.rm = TRUE) - min(x, na.rm = TRUE))
}

# Normalize structures destroyed, also add a day of max structure loss reported

sitreps_ <- sitreps %>%
 # Filter to events that destroyed at least one building
 filter(STR_DESTROYED_TOTAL > 0) %>%
 mutate(STR_DESTROYED_NORM = normalize(STR_DESTROYED),
        EVENT_DAY_NORM = normalize(EVENT_DAY)) %>%
 group_by(INCIDENT_ID) %>%
 mutate(MX_INDEX = which.max(STR_DESTROYED),
        MAX_STR_LOSS_EVENT_DAY_NORM = EVENT_DAY_NORM[MX_INDEX]) %>%
 ungroup()

# Normalize the daily area burned (using log(ha))

fired.daily_ <- fired.daily %>%
 # Filter events to match
 filter(INCIDENT_ID %in% sitreps_$INCIDENT_ID) %>%
 mutate(dy_ar_ha = dy_ar_km2 * 100,
        dy_ar_ha_log = log(dy_ar_ha),
        dy_ar_ha_log_norm = normalize(dy_ar_ha_log),
        event_day_norm = normalize(event_day)) %>%
 group_by(id) %>%
 mutate(mx_index = which.max(dy_ar_ha),
        mx_grw_event_day_norm = event_day_norm[mx_index]) %>%
 ungroup() %>%
 rename(EVENT_DAY = event_day)

# Look at the histograms
hist(sitreps_$MAX_STR_LOSS_EVENT_DAY_NORM)
hist(fired.daily_$mx_grw_event_day_norm)

# Join the two data sets
join <- full_join(sitreps_,fired.daily_,by=c("INCIDENT_ID","EVENT_DAY")) %>%
 mutate(lag = MAX_STR_LOSS_EVENT_DAY - mx_grw_dte_event_day)

print(mean(join$lag, na.rm=TRUE))
print(median(join$lag, na.rm=TRUE))

# Plot the time lag between max growth and structure loss
(p1 <- ggplot(join, aes(x = lag)) +
 geom_histogram(binwidth = 5, fill = "blue", color = "black") +
 theme_bw() +
 labs(title = "Time Lag Between Maximum Growth and Structure Loss",
      x = "Time Lag (Days)",
      y = "Frequency"))

ggsave(p1, file = "figures/FigureX_mx_growth_mx_loss_lag.png",
       width=6, height=3, bg="white") # adjust dpi accordingly


########################################################################################################
# Plot the cumulative relationship between timing of maximum growth and timing of maximum structure loss

#################
# Cumulative plot

join_c <- join %>%
 group_by(EVENT_DAY) %>%
 summarise(
  area_burned = sum(dy_ar_km2, na.rm=TRUE),
  str_destroyed = sum(STR_DESTROYED, na.rm=TRUE)
 ) %>%
 mutate(area_burned_c = normalize(cumsum(area_burned)),
        str_destroyed_c = normalize(cumsum(str_destroyed)))
glimpse(join_c)

# Create cumulative curves
(p2 <- ggplot(join_c) +
 geom_line(aes(x = EVENT_DAY, y = area_burned_c, color = 'Area Burned')) +
 geom_line(aes(x = EVENT_DAY, y = str_destroyed_c, color = 'Structures Destroyed')) +
 scale_color_manual(values = c('Area Burned' = 'red', 'Structures Destroyed' = 'blue')) +
 theme_bw() +
 labs(x = 'Event Day', y = 'Normalized Cumulative Count', color = '') +
 theme(legend.position = 'bottom'))

ggsave(p2, file = "figures/FigureX_cumulative_growth_loss.png",
       width=4, height=3, bg="white") # adjust dpi accordingly


##################
# Survival plot. #

library(survival)

# Retain only positive lags
positive_lags <- join %>%
 filter(lag > 0)

# Create survival objects
surv_object <- with(positive_lags, Surv(time = lag, event = rep(1, nrow(positive_lags))))

# Fit a survival model (Kaplan-Meier estimate)
surv_fit <- survival::survfit(surv_object ~ 1)

# Extract survival curve data
surv_data <- data.frame(
 time = surv_fit$time,
 survival = surv_fit$surv,
 upper = surv_fit$upper,
 lower = surv_fit$lower
)

(p3 <- ggplot(surv_data, aes(x = time, y = survival)) +
 geom_line(color = "blue") + # Plot the survival curve
 geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 0.2, fill = "lightblue") + # Add a confidence interval
 labs(x = "Days After Maximum Growth (Lag)", 
      y = "Survival Probability of Structure Loss", 
      title = "Survival Curve") +
 theme_bw())

ggsave(p3, file = "figures/FigureX_survival_plot.png",
       width=4, height=3, bg="white") # adjust dpi accordingly



# # Apply normalization to each dataset
# overlap <- overlap %>%
#  mutate(Normalized_Area_Burned = normalize(dy_ar_km2))
# 
# sitreps <- sitreps %>%
#  mutate(Normalized_Structure_Loss = normalize(STR_DESTROYED))
# 
# # Combining datasets into one dataframe for plotting
# combined_data <- overlap %>%
#  select(INCIDENT_ID, event_day, Normalized_Area_Burned) %>%
#  full_join(sitreps %>% select(INCIDENT_ID, EVENT_DAY, Normalized_Structure_Loss),
#            by = c("INCIDENT_ID" = "INCIDENT_ID", "event_day" = "EVENT_DAY")) %>%
#  # Replace NA with 0 for plotting purposes
#  replace_na(list(Normalized_Area_Burned = 0, Normalized_Structure_Loss = 0))
# 
# # Create the scatter plot
# scatter_plot <- ggplot(combined_data, aes(x = Normalized_Area_Burned, y = Normalized_Structure_Loss)) +
#  geom_point(alpha = 0.3) +
#  geom_smooth(method = "lm", se = FALSE, color = "blue") +
#  theme_bw() +
#  labs(x = "Normalized Daily Area Burned", y = "Normalized Daily Structure Loss", title = "Relationship between Area Burned and Structure Loss across all Fires")
# 
# # Display the plot
# scatter_plot
#  
# ####################
# # Create a test plot
# 
# 
# 
# 
# ############################
# # Work with the full dataset
# # Normalize the attributes
# 
# # Normalizing function for min-max scaling
# normalize <- function(x) {
#  return((x - min(x, na.rm = TRUE)) / (max(x, na.rm = TRUE) - min(x, na.rm = TRUE)))
# }
# 
# # Normalize the attributes
# daily <- overlap %>%
#  mutate(dy_ar_norm = normalize(dy_ar_km2),
#         event_day_norm = normalize(event_day))
# 
# sitreps <- sitreps %>%
#  mutate(str_destr_prop = STR_DESTROYED / STR_DESTROYED_TOTAL)
#  
# 
# ggplot(data=daily, aes(x=event_day_norm,y=area_norm)) +
#  geom_point() +
#  # xlim(c(0,60)) +
#  labs(tag="A") +
#  theme_bw()


