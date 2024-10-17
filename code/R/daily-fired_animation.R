
# Libraries
library(tidyverse)
library(sf)
library(scales)
library(ggmap)
library(ggspatial)
library(gganimate)
library(gifski)
library(transformr)
library(grid)

getwd()

target_crs <- 5070

# Data

# Daily polygons (fast fires)
fired.daily <- st_read('data/spatial/mod/fired_daily_overlap_fast.gpkg')
fired.daily$date <- as.Date(fired.daily$date)  # Ensure Date format
fired.daily <- st_transform(fired.daily, target_crs)  # Ensure consistent projection

# Create a list of FIRED IDs to plot
fire_ids = c(
 132111, # NW Oklahoma Complex, OK (2017)
 159406, # August Complex, CA (2020)
 132267, # Perryton Fire, TX (2017)
 159426, # North Complex, CA (2020)
 159618 # Cold Springs Complex, WA (2020)
)

# Names for titles
fire_names <- c(
 "NW Oklahoma Complex, OK (2017)",
 "August Complex Fire, CA (2020)",
 "Perryton Fire, TX (2017)",
 "North Complex, CA (2020)",
 "Cold Springs Complex, WA (2020)"
)
 
 
# Subset to testing fire (August Complex)
daily.gdf <- fired.daily %>% filter(FIRED_ID == fire_ids[2] & ig_year == 2020)

###################
# Create static map

static <- ggplot() +
  annotation_map_tile(type = "osm", zoom = 10) +   # OpenStreetMap tiles
  geom_sf(data = daily.gdf, aes(fill=event_day), color=NA, alpha=0.8) +
  scale_fill_viridis_c(option = "plasma", direction=-1) + 
  guides(fill = guide_colourbar(direction = "horizontal", 
                                barwidth = 6, barheight = 0.5, 
                                ticks.colour = NA, title.position = "top"),
         label.theme = element_text(angle = 0, size = 10),
         size="none") +
  ggspatial::annotation_scale(height=unit(1.2, "mm")) +
  labs(fill="Day of Burn") +
  geom_label(aes(x = Inf, y = Inf, label = fire_names[2]), 
             hjust = 1, vjust = 1, fill = alpha("black", 0.5), 
             color = "white", size = 6, fontface = "bold", 
             label.padding = unit(0.5, "lines")) +
  theme_void() +
  theme(
   legend.title = element_text(angle = 0, size=10, face = "italic", 
                               margin = margin(t = 0, r = 0, b = 3, l = 0)),
   legend.text = element_text(size=10),
   legend.position=c(0.85, 0.90),
   plot.title = element_text(size = 12, face = "bold", hjust = 0.5, vjust = 1),
  )
static

# Grab number of frames = burn dates
ndays <- length(unique((daily.gdf$date))) * 2
sum(is.na(daily.gdf$date))  # Check for NA values
length(unique(daily.gdf$date)) == nrow(daily.gdf)

# Animate it !
animap <- static +
 transition_time(date) +
 
 labs(caption = "Burn Date: {frame_time}") + # dynamic label
 
 gganimate::enter_fade() +
 gganimate::shadow_mark(past = TRUE, alpha = 0.8) +
 
 theme(
  plot.caption = element_text(
   size = 12, face = "bold", 
   color = "black", 
   hjust = 0.90, vjust = 10)
 )

# Create the animation
gganimate::animate(
  animap, nframes = ndays, fps=10,
  start_pause = 0, end_pause = 10,
  renderer = gifski_renderer(),
  dpi=300)

# Save GIF file.
anim_save("figures/animations/daily-FIRED-AugustComplex_animation.gif")
