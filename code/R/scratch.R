OLD:
 
 ```{r}

# Grab the range of burn days
range <- range(modis_burn_dates[],na.rm=TRUE)
breaks <- abs(range[1]-range[2])
start <- as.numeric(range[1])
# Convert to days since ignition
modis_burn_dates <- modis_burn_dates - start
range <- range(modis_burn_dates[],na.rm=TRUE)
# Extract as DF
modis_burn_dates <- as.data.frame(modis_burn_dates, xy = TRUE)
# Plot
nw_ok_complex_map <- ggplot() +
 geom_raster(data = modis_burn_dates , aes(x = x, y = y, fill=annual_burndate_y2017)) +
 scale_fill_fermenter(n.breaks=5, palette="Reds", na.value="white") +
 geom_sf(data=oks_fire_mtbs, fill="transparent", size=0.65)+
 geom_sf(data=ztrax_ext, color=alpha("black",0.3), size=0.85, shape=18, show.legend = TRUE)+
 labs(title="OKS-Starbuck Fire, OK (2017)",
      fill="Days Since Ignition")+
 theme_void()+
 theme(legend.position="bottom",
       plot.title = element_text(hjust = 0.5))+
 guides(fill = guide_colourbar(title.position="top", title.hjust = 0.5,
                               barwidth = 12, barheight = 0.5,
                               ticks=FALSE, draw.llim=FALSE))+
 ggsn::scalebar(oks_fire_mtbs, dist = 10, st.size=2.5, height=0.01, 
                dist_unit="km", model = 'WGS84', transform=TRUE)+
 coord_sf()
nw_ok_complex_map
```

```{r}

# North Complex fire data
north.mtbs <- mtbs %>% filter(Incid_Name=="NORTH COMPLEX")
north.fired <- fired.fast %>% filter(id==135490)

# Fire duration
startDate <- north.fired$ig_date
endDate <- north.fired$last_date

# Grab MODIS burned pixels/dates
year <- '2020'
fire_dir <- paste("C:/Users/mccoo/OneDrive/mcook/fast-fires/data/burndate/", year, "/", sep="")
modis_burn_dates <- raster::raster(file.path(paste(fire_dir, 'annual_burndate_y', year, '.tif', sep=""))) %>%
 raster::crop(north.mtbs) %>%
 raster::mask(north.mtbs)

# Grab the range of burn days
range <- range(modis_burn_dates[],na.rm=TRUE)
breaks <- abs(range[1]-range[2])
start <- as.numeric(range[1])
end <- as.numeric(range[2])
modis_burn_dates <- modis_burn_dates - start
range <- range(modis_burn_dates[],na.rm=TRUE)

# Extract as DF
modis_burn_dates <- as.data.frame(modis_burn_dates, xy = TRUE) %>% na.omit()
# Plot
north.map <- ggplot() +
 geom_tile(data = modis_burn_dates , aes(x = x, y = y, fill=annual_burndate_y2020)) +
 # scico::scale_fill_scico(palette = "lajolla", na.value="white", alpha=0.9,
 #                         breaks=seq(0,35,5), labels=c(0,5,10,15,20,25,30,35))+
 # scale_fill_distiller(palette = 'YlOrRd', direction=-2, breaks=seq(0,35,5),
 #                      na.value="white")+
 scale_fill_fermenter(n.breaks=10, palette="Reds", na.value="white") +
 geom_sf(data=north.mtbs, fill="transparent", size=0.65)+
 # geom_sf(data=ztrax_ext, color=alpha("black",0.05), size=0.65, shape=18, show.legend = TRUE)+
 labs(title="North Complex, CA (2020)",
      fill="Days Since Ignition")+
 theme_void()+
 theme(legend.position="bottom",
       plot.title = element_text(hjust = 0.5))+
 guides(fill = guide_colourbar(title.position="top", title.hjust = 0.5,
                               barwidth = 12, barheight = 0.5,
                               ticks=FALSE, draw.llim=FALSE))+
 ggsn::scalebar(north.mtbs, dist = 5, st.size=2.5, height=0.01, 
                dist_unit="km", model = 'WGS84', transform=TRUE)+
 coord_sf()

north.map

```

1. Hayman Fire, CO (2003)

```{r fig.height=4, fig.width=3}
###MTBS
hayman.mtbs <- mtbs %>%
 filter(Event_ID == 'CO3922010528720020608')
###FIRED
hayman.fired <- fired %>% filter(id == 6161)
###Grab some info for the plot
burn_year <- '2002'
ig_date <- hayman.fired$ig_day
ig_day <- hayman.fired$ig_day
###Get the annual burn date raster
fire_dir <- paste(burnrasts, burn_year, "/", sep="")
###Find ranges and set up plot
modis_burn_dates <- 
 raster::raster(file.path(paste(fire_dir, 'annual_burndate_y', burn_year, '.tif', sep=""))) %>%
 raster::crop(hayman.mtbs) %>%
 raster::mask(hayman.mtbs)
#Grab the range of burn days
range <- range(modis_burn_dates[], na.rm=TRUE)
start <- as.numeric(range[1])
breaks <- abs(range[1]-range[2])
# Update raster values to get "day since ignition"
modis_burn_dates <- modis_burn_dates - start
range <- range(modis_burn_dates[],na.rm=TRUE)
# A function to plot our raster data
f1 <- rasterVis::levelplot(
 modis_burn_dates,
 par.settings = list(layout.heights=list(xlab.key.padding=1),
                     axis.line = list(col = "transparent"),
                     strip.background = list(col = 'transparent'),
                     strip.border = list(col = 'transparent')),
 margin=FALSE, region = TRUE,
 xlab = list(label = 'Days Since Ignition', cex = 1.5), 
 main = 'Hayman Fire, CO, 2002',
 scales = list(draw = FALSE),
 ylab=NULL,
 col.regions = colorRampPalette(brewer.pal(8, 'YlOrRd'))(breaks),
 colorkey = list(col = colorRampPalette(brewer.pal(8, 'YlOrRd'))(breaks), space="bottom")) +
 latticeExtra::layer(
  sp.polygons(as(hayman.mtbs, 'Spatial'), lwd = 1, scales=list(axes=FALSE)))
f1
```

Fire spread plot for the Hayman Fire, CO (2002)

```{r hayman}
# MTBS
hayman.mtbs <- mtbs %>%
 filter(Event_ID == 'CO3922010528720020608')
# Filter the ztrax
ztrax.ext <- ztrax %>% filter(YearBuilt<=2002) %>%
 st_intersection(., hayman.mtbs)
# Filter the ICS-209s
hayman.ics <- inci209 %>% filter(INCIDENT_NAME=="HAYMAN" & START_YEAR==2002)
# Filter FIRED
hayman.fired <- fired %>% filter(id==6161)

# Grab some info for the plot
burn_year <- '2002'
ignition_date <- hayman.fired$ignition_date
ignition_day <- hayman.fired$ignition_day

###Get the annual burn date raster
fire.dir <- paste("C:/Users/mccoo/OneDrive/mcook/fast-fires/data/burndate/", burn_year, "/", sep="")

# Find ranges and set up plot
modis.dates <- raster::raster(
 file.path(paste(fire.dir, 'annual_burndate_y', burn_year, '.tif', sep=""))
) %>%
 raster::crop(hayman.mtbs) %>%
 raster::mask(hayman.mtbs)

#Grab the range of burn days
range <- range(modis.dates[],na.rm=TRUE)
start <- as.numeric(range[1])
breaks <- abs(range[1]-range[2])

#Update raster values to get "day since ignition"
modis.dates <- modis.dates - start
range <- range(modis.dates[],na.rm=TRUE)

#Extract as DF
modis.dates <- as.data.frame(modis.dates, xy = TRUE)

#Plot
hayman.map <- ggplot() +
 geom_raster(data = modis.dates , aes(x = x, y = y, fill=annual_burndate_y2002)) +
 scale_fill_fermenter(n.breaks=10, palette="Reds", na.value="white") +
 geom_sf(data=tubbs_fire_mtbs, fill="transparent", size=0.65)+
 geom_sf(data=ztrax_ext, color=alpha("black",0.1), size=0.5, size=0.75, shape=18, show.legend = TRUE)+
 labs(title="Tubbs Fire, CA (2017)",
      fill="Days Since Ignition")+
 theme_void()+
 theme(legend.position="bottom",
       plot.title = element_text(hjust = 0.5))+
 guides(fill = guide_colourbar(title.position="top", title.hjust = 0.5,
                               barwidth = 12, barheight = 0.5,
                               ticks=FALSE, draw.llim=FALSE))+
 ggsn::scalebar(tubbs_fire_mtbs, dist = 2, st.size=3, height=0.01, 
                dist_unit="km", model = 'WGS84', transform=TRUE)+
 coord_sf()

hayman.map
```

```{r tubbs}
###MTBS
tubbs_fire_mtbs <- mtbs %>%
 filter(Event_ID == 'CA3859812261820171009')

###ZTRAX
ztrax_ext <- ztrax %>% filter(YearBuilt<=2017)%>%
 st_intersection(., tubbs_fire_mtbs)

#FIRED
tubbs_fire_evt <- fired %>% filter(id==117157)

###Params
year <- '2017'
fire_dir <- paste("C:/Users/mccoo/OneDrive/mcook/fast-fires/data/burndate/", year, "/", sep="")

###Tubbs fire example
modis_burn_dates <- raster::raster(file.path(paste(fire_dir, 'annual_burndate_y', year, '.tif', sep=""))) %>%
 raster::crop(tubbs_fire_mtbs) %>%
 raster::mask(tubbs_fire_mtbs)

#Grab the range of burn days
range <- range(modis_burn_dates[],na.rm=TRUE)
start <- range[1]
breaks <- abs(range[1]-range[2])

#Update cells to be "days since ignition
modis_burn_dates <- modis_burn_dates - start
range <- range(modis_burn_dates[],na.rm=TRUE)

#Extract as DF
modis_burn_dates <- as.data.frame(modis_burn_dates, xy = TRUE)
#Plot
tubbs_fire_map <- ggplot() +
 geom_raster(data = modis_burn_dates , aes(x = x, y = y, fill=annual_burndate_y2017)) +
 scale_fill_fermenter(n.breaks=10, palette="Reds", na.value="white") +
 geom_sf(data=tubbs_fire_mtbs, fill="transparent", size=0.65)+
 geom_sf(data=ztrax_ext, color=alpha("black",0.1), size=0.5, size=0.75, shape=18, show.legend = TRUE)+
 labs(title="Tubbs Fire, CA (2017)",
      fill="Days Since Ignition")+
 theme_void()+
 theme(legend.position="bottom",
       plot.title = element_text(hjust = 0.5))+
 guides(fill = guide_colourbar(title.position="top", title.hjust = 0.5,
                               barwidth = 12, barheight = 0.5,
                               ticks=FALSE, draw.llim=FALSE))+
 ggsn::scalebar(tubbs_fire_mtbs, dist = 2, st.size=3, height=0.01, 
                dist_unit="km", model = 'WGS84', transform=TRUE)+
 coord_sf()

tubbs_fire_map
```

```{r camp}
#FIRED
camp_fire_evt <- fired%>%filter(id==124486)
ignition_date <- camp_fire_evt$ignition_date
last_date <- camp_fire_evt$last_date

#MTBS
camp_fire_mtbs <- mtbs %>%
 filter(Event_ID == 'CA3982012144020181108')

###ZTRAX
ztrax_ext <- ztrax %>% filter(YearBuilt<=2018) %>%
 st_intersection(., camp_fire_mtbs)

year <- '2018'
fire_dir <- paste("C:/Users/mccoo/OneDrive/mcook/fast-fires/data/burndate/", year, "/", sep="")

# proj <- "+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=23 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +towgs84=1,1,-1,0,0,0,0 +units=m +no_defs"
modis_burn_dates <- raster::raster(file.path(paste(fire_dir, 'annual_burndate_y', year, '.tif', sep=""))) %>%
 raster::crop(camp_fire_mtbs) %>%
 raster::mask(camp_fire_mtbs)

#Grab the range of burn days
range <- range(modis_burn_dates[],na.rm=TRUE)
breaks <- abs(range[1]-range[2])
start <- as.numeric(range[1])
end <- as.numeric(range[2])

modis_burn_dates <- modis_burn_dates - start
range <- range(modis_burn_dates[],na.rm=TRUE)

##Handle possible error dates
modis_burn_dates[modis_burn_dates>31] <- NA

#Extract as DF
modis_burn_dates <- as.data.frame(modis_burn_dates, xy = TRUE)
#Plot
camp_fire_map <- ggplot() +
 geom_raster(data = modis_burn_dates , aes(x = x, y = y, fill=annual_burndate_y2018)) +
 # scico::scale_fill_scico(palette = "lajolla", na.value="white", alpha=0.9,
 #                         breaks=seq(0,35,5), labels=c(0,5,10,15,20,25,30,35))+
 # scale_fill_distiller(palette = 'YlOrRd', direction=-2, breaks=seq(0,35,5),
 #                      na.value="white")+
 scale_fill_fermenter(n.breaks=10, palette="Reds", na.value="white") +
 geom_sf(data=camp_fire_mtbs, fill="transparent", size=0.65)+
 geom_sf(data=ztrax_ext, color=alpha("black",0.05), size=0.65, shape=18, show.legend = TRUE)+
 labs(title="Camp Fire, CA (2018)",
      fill="Days Since Ignition")+
 theme_void()+
 theme(legend.position="bottom",
       plot.title = element_text(hjust = 0.5))+
 guides(fill = guide_colourbar(title.position="top", title.hjust = 0.5,
                               barwidth = 12, barheight = 0.5,
                               ticks=FALSE, draw.llim=FALSE))+
 ggsn::scalebar(camp_fire_mtbs, dist = 5, st.size=2.5, height=0.01, 
                dist_unit="km", model = 'WGS84', transform=TRUE)+
 coord_sf()

camp_fire_map
```

```{r woolsy}
#FIRED
woolsey_fire_evt <- fired %>% filter(id==124525)
ignition_date <- camp_fire_evt$ignition_date
last_date <- camp_fire_evt$last_date

#MTBS
woolsey_fire_mtbs <- mtbs %>%
 filter(Event_ID == 'CA3424011870020181108')

###ZTRAX
ztrax_ext <- ztrax %>% filter(YearBuilt<=2018) %>%
 st_intersection(., woolsey_fire_mtbs)

year <- '2018'
fire_dir <- paste("C:/Users/mccoo/OneDrive/mcook/fast-fires/data/burndate/", year, "/", sep="")

# proj <- "+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=23 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +towgs84=1,1,-1,0,0,0,0 +units=m +no_defs"
modis_burn_dates <- raster::raster(file.path(paste(fire_dir, 'annual_burndate_y', year, '.tif', sep=""))) %>%
 raster::crop(woolsey_fire_mtbs) %>%
 raster::mask(woolsey_fire_mtbs)
plot(modis_burn_dates)

#Grab the range of burn days
range <- range(modis_burn_dates[],na.rm=TRUE)
breaks <- abs(range[1]-range[2])
start <- as.numeric(range[1])
end <- as.numeric(range[2])

modis_burn_dates <- modis_burn_dates - start
range <- range(modis_burn_dates[],na.rm=TRUE)

#Extract as DF
modis_burn_dates <- as.data.frame(modis_burn_dates, xy = TRUE)
#Plot
woolsey_fire_map <- ggplot() +
 geom_raster(data = modis_burn_dates , aes(x = x, y = y, fill=annual_burndate_y2018)) +
 # scico::scale_fill_scico(palette = "lajolla", na.value="white", alpha=0.9,
 #                         breaks=seq(0,35,5), labels=c(0,5,10,15,20,25,30,35))+
 # scale_fill_distiller(palette = 'YlOrRd', direction=-2, breaks=seq(0,35,5),
 #                      na.value="white")+
 scale_fill_fermenter(n.breaks=5, palette="Reds", na.value="white") +
 geom_sf(data=woolsey_fire_mtbs, fill="transparent", size=0.65)+
 geom_sf(data=ztrax_ext, color=alpha("black",0.1), size=0.65, shape=18, show.legend = TRUE)+
 labs(title="Woolsey Fire, CA (2018)",
      fill="Days Since Ignition")+
 theme_void()+
 theme(legend.position="bottom",
       plot.title = element_text(hjust = 0.5))+
 guides(fill = guide_colourbar(title.position="top", title.hjust = 0.5,
                               barwidth = 12, barheight = 0.5,
                               ticks=FALSE, draw.llim=FALSE))+
 ggsn::scalebar(woolsey_fire_mtbs, dist = 5, st.size=2.5, height=0.01, 
                dist_unit="km", model = 'WGS84', transform=TRUE)+
 coord_sf()

woolsey_fire_map
```

```{r king fire}
king_fire <- inci209 %>%
 filter(INCIDENT_ID == "2014_983669_KING")
# Create the spatial
king_fire_pt <- oks_fire %>%
 mutate(POO_LONGITUDE = ifelse(is.na(POO_LONGITUDE),0,as.numeric(POO_LONGITUDE)),
        POO_LATITUDE = ifelse(is.na(POO_LATITUDE),0,as.numeric(POO_LATITUDE))) %>%
 st_as_sf(., coords = c("POO_LONGITUDE", "POO_LATITUDE"),
          crs = st_crs(conus)) %>%
 st_transform(crs = st_crs(conus))

king_fire_mtbs <- mtbs %>%
 filter(Event_ID == 'CA3878212060420140913')

#FIRED
king_fire_evt <- fired%>%filter(id==95950)

year <- '2014'
fire_dir <- paste("C:/Users/mccoo/OneDrive/mcook/fast-fires/data/burndate/", year, "/", sep="")

###Hayman fire example
# proj <- "+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=23 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +towgs84=1,1,-1,0,0,0,0 +units=m +no_defs"
modis_burn_dates <- raster::raster(file.path(paste(fire_dir, 'annual_burndate_y', year, '.tif', sep=""))) %>%
 raster::crop(king_fire_mtbs) %>%
 raster::mask(king_fire_mtbs)

#Grab the range of burn days
range <- range(modis_burn_dates[],na.rm=TRUE)
breaks <- abs(range[1]-range[2])
start <- as.numeric(range[1])

modis_burn_dates <- modis_burn_dates - start
range <- range(modis_burn_dates[],na.rm=TRUE)

# A function to plot our raster data
king_fire_map <- rasterVis::levelplot(modis_burn_dates,
                                      par.settings = list(layout.heights=list(xlab.key.padding=1),
                                                          axis.line = list(col = "transparent"),
                                                          strip.background = list(col = 'transparent'),
                                                          strip.border = list(col = 'transparent')),
                                      margin=FALSE, region = TRUE,
                                      xlab = list(label = 'Days Since Ignition', cex = 1.5), 
                                      main = 'King Fire, CA, 2014',
                                      scales = list(draw = FALSE),
                                      ylab=NULL,
                                      col.regions = colorRampPalette(brewer.pal(breaks, 'YlOrRd')),
                                      colorkey = list(col = colorRampPalette(brewer.pal(breaks, 'YlOrRd')),
                                                      space="bottom")) +
 latticeExtra::layer(sp.polygons(as(king_fire_mtbs, 'Spatial'), lwd = 1, scales=list(axes=FALSE)))

king_fire_map
```

```{r witch}
###MTBS
witch_fire_mtbs <- mtbs %>%
 filter(Event_ID == 'CA3307911676620071021')

###ZTRAX
ztrax_ext <- ztrax %>% filter(YearBuilt<=2007) %>%
 st_intersection(., witch_fire_mtbs)

dissolve <- st_union(witch_fire_mtbs)%>%st_sf()

#FIRED
witch_fire_evt <- fired%>%filter(id==46183)

year <- '2007'
fire_dir <- paste("C:/Users/mccoo/OneDrive/mcook/fast-fires/data/burndate/", year, "/", sep="")

###Hayman fire example
# proj <- "+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=23 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +towgs84=1,1,-1,0,0,0,0 +units=m +no_defs"
modis_burn_dates <- raster::raster(file.path(paste(fire_dir, 'annual_burndate_y', year, '.tif', sep=""))) %>%
 raster::crop(witch_fire_mtbs) %>%
 raster::mask(witch_fire_mtbs)

#Grab the range of burn days
range <- range(modis_burn_dates[],na.rm=TRUE)
breaks <- abs(range[1]-range[2])
start <- as.numeric(range[1])

modis_burn_dates <- modis_burn_dates - start
range <- range(modis_burn_dates[],na.rm=TRUE)

#Extract as DF
modis_burn_dates <- as.data.frame(modis_burn_dates, xy = TRUE)
#Plot
witch_fire_map <- ggplot() +
 geom_raster(data = modis_burn_dates , aes(x = x, y = y, fill=annual_burndate_y2007)) +
 # scico::scale_fill_scico(palette = "lajolla", na.value="white", alpha=0.9,
 #                         breaks=seq(0,35,5), labels=c(0,5,10,15,20,25,30,35))+
 # scale_fill_distiller(palette = 'YlOrRd', direction=-2, breaks=seq(0,35,5),
 #                      na.value="white")+
 scale_fill_fermenter(n.breaks=5, palette="Reds", na.value="white") +
 geom_sf(data=witch_fire_mtbs, fill="transparent", size=0.65)+
 geom_sf(data=ztrax_ext, color=alpha("black",0.1), size=0.5, shape=18, show.legend = TRUE)+
 labs(title="Witch-Poomacha Fire, CA (2007)",
      fill="Days Since Ignition")+
 theme_void()+
 theme(legend.position="bottom",
       plot.title = element_text(hjust = 0.5))+
 guides(fill = guide_colourbar(title.position="top", title.hjust = 0.5,
                               barwidth = 12, barheight = 0.5,
                               ticks=FALSE, draw.llim=FALSE))+
 ggsn::scalebar(witch_fire_mtbs, dist = 5, st.size=2.5, height=0.01, 
                dist_unit="km", model = 'WGS84', transform=TRUE)+
 coord_sf()

witch_fire_map
```

```{r cold springs}
cold_springs_cmplx <- nifc %>%
 filter(LocalIncid == "000594" |
         LocalIncid == "200130" |
         LocalIncid == "002144") %>%
 st_transform(crs = st_crs(mtbs))

dissolve <- st_union(cold_springs_cmplx)%>%st_sf()

###ZTRAX
ztrax_ext <- ztrax %>% filter(YearBuilt<=2020) %>%
 st_intersection(., dissolve)

year <- '2020'
fire_dir <- paste("C:/Users/mccoo/OneDrive/mcook/fast-fires/data/burndate/", year, "/", sep="")

modis_burn_dates <- raster::raster(file.path(paste(fire_dir, 'annual_burndate_y', year, '.tif', sep=""))) %>%
 raster::crop(dissolve) %>%
 raster::mask(dissolve)

modis_burn_dates[modis_burn_dates<245] <- NA

#Grab the range of burn days
range <- range(modis_burn_dates[],na.rm=TRUE)
breaks <- abs(range[1]-range[2])
start <- as.numeric(range[1])

modis_burn_dates <- modis_burn_dates - start
range <- range(modis_burn_dates[],na.rm=TRUE)

#Extract as DF
modis_burn_dates <- as.data.frame(modis_burn_dates, xy = TRUE)
#Plot
cold_springs_cmplx_map <- ggplot() +
 geom_raster(data = modis_burn_dates , aes(x = x, y = y, fill=annual_burndate_y2020)) +
 # scico::scale_fill_scico(palette = "lajolla", na.value="white", alpha=0.9,
 #                         breaks=seq(0,35,5), labels=c(0,5,10,15,20,25,30,35))+
 # scale_fill_distiller(palette = 'YlOrRd', direction=-2, breaks=seq(0,35,5),
 #                      na.value="white")+
 scale_fill_fermenter(n.breaks=5, palette="Reds", na.value="white") +
 geom_sf(data=cold_springs_cmplx, fill="transparent", size=0.65)+
 geom_sf(data=ztrax_ext, color=alpha("black",0.2), size=0.65, shape=18, show.legend = TRUE)+
 labs(title="Cold Springs Complex Fire, WA (2020)",
      fill="Days Since Ignition")+
 theme_void()+
 theme(legend.position="bottom",
       plot.title = element_text(hjust = 0.5))+
 guides(fill = guide_colourbar(title.position="top", title.hjust = 0.5,
                               barwidth = 12, barheight = 0.5,
                               ticks=FALSE, draw.llim=FALSE))+
 ggsn::scalebar(dissolve, dist = 10, st.size=2.5, height=0.01, 
                dist_unit="km", model = 'WGS84', transform=TRUE,
                location="bottomleft")+
 coord_sf()

cold_springs_cmplx_map
```

```{r claremont bear}
claremont_bear <- nifc %>%
 filter(LocalIncid == "001308") %>%
 st_transform(crs = st_crs(mtbs))

###ZTRAX
ztrax_ext <- ztrax %>% filter(YearBuilt<=2020) %>%
 st_intersection(., claremont_bear)

year <- '2020'
fire_dir <- paste("C:/Users/mccoo/OneDrive/mcook/fast-fires/data/burndate/", year, "/", sep="")

modis_burn_dates <- raster::raster(file.path(paste(fire_dir, 'annual_burndate_y', year, '.tif', sep=""))) %>%
 raster::crop(claremont_bear) %>%
 raster::mask(claremont_bear)

##Handle possible error dates
modis_burn_dates[modis_burn_dates>279] <- NA

#Grab the range of burn days
range <- range(modis_burn_dates[],na.rm=TRUE)
breaks <- abs(range[1]-range[2])
start <- as.numeric(range[1])

modis_burn_dates <- modis_burn_dates - start
range <- range(modis_burn_dates[],na.rm=TRUE)
breaks <- abs(range[1]-range[2])

#Extract as DF
modis_burn_dates <- as.data.frame(modis_burn_dates, xy = TRUE)
#Plot
claremont_bear_map <- ggplot() +
 geom_raster(data = modis_burn_dates , aes(x = x, y = y, fill=annual_burndate_y2020)) +
 # scico::scale_fill_scico(palette = "lajolla", na.value="white", alpha=0.9,
 #                         breaks=seq(0,35,5), labels=c(0,5,10,15,20,25,30,35))+
 # scale_fill_distiller(palette = 'YlOrRd', direction=-2, breaks=seq(0,60,10),
 #                      na.value="white")+
 scale_fill_fermenter(n.breaks=8, palette="Reds", na.value="white") +
 geom_sf(data=claremont_bear, fill="transparent", size=0.65)+
 geom_sf(data=ztrax_ext, color=alpha("black",0.25), size=0.75, shape=18, show.legend = TRUE)+
 labs(title="Claremont-Bear Fire, CA (2020)",
      fill="Days Since Ignition")+
 theme_void()+
 theme(legend.position="bottom",
       plot.title = element_text(hjust = 0.5))+
 guides(fill = guide_colourbar(title.position="top", title.hjust = 0.5,
                               barwidth = 12, barheight = 0.5,
                               ticks=FALSE, draw.llim=FALSE))+
 ggsn::scalebar(claremont_bear, dist = 10, st.size=2.5, height=0.01, 
                dist_unit="km", model = 'WGS84', transform=TRUE)+
 coord_sf()

claremont_bear_map

```

```{r august}
august_cmplx <- nifc %>%
 filter(LocalIncid == "000753") %>%
 st_transform(crs = st_crs(mtbs))

###ZTRAX
ztrax_ext <- ztrax %>% filter(YearBuilt<=2020) %>%
 st_intersection(., august_cmplx)

year <- '2020'
fire_dir <- paste("C:/Users/mccoo/OneDrive/mcook/fast-fires/data/burndate/", year, "/", sep="")

modis_burn_dates <- raster::raster(file.path(paste(fire_dir, 'annual_burndate_y', year, '.tif', sep=""))) %>%
 raster::crop(august_cmplx) %>%
 raster::mask(august_cmplx)

#Grab the range of burn days
range <- range(modis_burn_dates[],na.rm=TRUE)
breaks <- abs(range[1]-range[2])
start <- as.numeric(range[1])

modis_burn_dates <- modis_burn_dates - start
range <- range(modis_burn_dates[],na.rm=TRUE)
breaks <- abs(range[1]-range[2])

#Extract as DF
modis_burn_dates <- as.data.frame(modis_burn_dates, xy = TRUE)
#Plot
august_cmplx_map <- ggplot() +
 geom_raster(data = modis_burn_dates , aes(x = x, y = y, fill=annual_burndate_y2020)) +
 # scico::scale_fill_scico(palette = "lajolla", na.value="white", alpha=0.9,
 #                         breaks=seq(0,35,5), labels=c(0,5,10,15,20,25,30,35))+
 # scale_fill_distiller(palette = 'YlOrRd', direction=-2, breaks=seq(0,70,10),
 #                      na.value="white")+
 scale_fill_fermenter(n.breaks=10, palette="Reds", na.value="white") +
 geom_sf(data=august_cmplx, fill="transparent", size=0.65)+
 geom_sf(data=ztrax_ext, color=alpha("black",0.3), size=1, shape=18, show.legend = TRUE)+
 labs(title="August Complex Fire, CA (2020)",
      fill="Days Since Ignition")+
 theme_void()+
 theme(legend.position="bottom",
       plot.title = element_text(hjust = 0.5))+
 guides(fill = guide_colourbar(title.position="top", title.hjust = 0.5,
                               barwidth = 12, barheight = 0.5,
                               ticks=FALSE, draw.llim=FALSE))+
 ggsn::scalebar(august_cmplx, dist = 10, st.size=2.5, height=0.01, 
                dist_unit="km", model = 'WGS84', transform=TRUE)+
 coord_sf()

august_cmplx_map

```

# Panel figure

```{r, fig.width=10, fig.height=6, warning=False}
ggarrange(hayman_fire_map, witch_fire_map, oks_fire_map, camp_fire_map, claremont_bear_map, cold_springs_cmplx_map,
          common.legend = TRUE, legend="bottom", nrow = 2, ncol = 3)+
 theme(plot.margin = unit(c(1.2,1.2,1.2,1.2), "lines"))

# ggarrange(hayman_fire_map, witch_fire_map, oks_fire_map, 
#           tubbs_fire_map, camp_fire_map, woolsey_fire_map, 
#           august_cmplx_map, claremont_bear_map, cold_springs_cmplx_map,
#           common.legend = TRUE, legend="bottom", nrow = 3, ncol = 3)+
#    theme(plot.margin = unit(c(1,1,1,1), "lines"))

# grid.arrange(hayman_fire_map, witch_fire_map, oks_fire_map, 
#              camp_fire_map, august_cmplx_map, cold_springs_cmplx_map,
#              ncol=3, nrow=2)

# library(latticeExtra)
# c(camp_fire_map, hayman_fire_map, tubbs_fire_map, 
#   oks_fire_map, cold_springs_cmplx_map, claremont_bear_map)

# cowplot::plot_grid(camp_fire_map, hayman_fire_map, tubbs_fire_map, 
#                    oks_fire_map, cold_springs_cmplx_map, claremont_bear_map,
#                    align = "v", ncol = 3, rel_heights = c(1/4, 1/4, 1/4))
```

```{r, fig.width=10, fig.height=9, warning=False}
grid.arrange(hayman_fire_map, witch_fire_map, oks_fire_map, 
             tubbs_fire_map, camp_fire_map, woolsey_fire_map,
             august_cmplx_map, cold_springs_cmplx_map, claremont_bear_map,
             ncol=3, nrow=3)
```

# Plot BUPR sum through burn days

## Here, we will test various methods for temporal autocorrelation between burn area and housing density. We will also test the relationship between maximum growth and maximum housing density.

```{r, fig.caption="Test"}
###Create daily fired subset
#####Let's take an example fire, the Rim Fire in CA
ex <- daily %>% filter(id==57206) %>%
 #daily hectares
 mutate(daily_area_ha = daily_area_km2*100)

###Create a simple time-series plot
p1 <- ggplot(ex)+
 geom_line(aes(date, daily_area_km2), na.rm=TRUE)+
 xlab("")+
 ylab("Daily Growth (km2)")+
 scale_x_date(breaks=date_breaks("5 days"),
              labels=date_format("%b %d"))+
 theme_light()
p2 <- ggplot(ex, aes(date, bupr_sum))+
 geom_bar(stat="identity")+
 xlab("Burn Date")+
 ylab("Built-up Property Records")+
 scale_x_date(breaks=date_breaks("5 days"),
              labels=date_format("%b %d"))+
 theme_light()

arr <- ggarrange(p1, p2, nrow = 2, ncol = 1)

annotate_figure(arr, top="Daily Burn Area and Property Density for the Rim Fire, CA")

```

Table 1. Top 20 fastest fires in CONUS (2000-2020)

Retrieve the ICS209-PLUS records for the top 20 fastest fires, where possible. Some fires identified in the top 100 fastest FIRED perimeters do not have a certain match in ICS209-PLUS. So, this list had to be manually quality controlled.

```{r}

# "2005_NV-LVD-000042_SOUTHERN NEVADA COMPLEX"

# INCIDENT_ID list for the top 20 fastest fires"
qc_list <- c("2020_COLD SPRINGS COMPLEX","2020_11850821_LNU LIGHTNING COMPLEX")
incid_list <- c("2017_7155675_NW OKLAHOMA COMPLEX", "2012_OR-VAD-000067_LONG DRAW", "2017_7161319_PERRYTON",
                "2016_4258135_ANDERSON CREEK FIRE", "2007_ID-TFD-002030_MURPHY COMPLEX",
                "2006_TX-TXS-066077_EAST AMARILLO COMPLEX","2018_9206799_MARTIN", "2007_UT-SWS-070312_MILFORD FLAT",
                "2008_TX-TXS-88071_GLASS FIRE", "2014_634805_BUZZARD COMPLEX", "2020_11843929_AUGUST COMPLEX",
                "2012_ID-TFD-000263_KINYON ROAD", "2015_2880290_SODA", "2018_9021840_RHEA",
                "2020_11865970_NORTH COMPLEX", "2003_CA-CNF-003056_CEDAR", "2011_TX-TXS-011088_COOPER MOUNTAIN RANCH",
                "2007_CA-MVU-010432_WITCH")

# Grab the ICS209-PLUS records
ics.t <- ics %>% filter(INCIDENT_ID %in% incid_list)

# Grab the "QC" fires
ics.t.a <- st_read(paste0(maindir,"/home-loss/data/spatial/mod/ics-fired_spatial_west_mod.gpkg")) %>%
 st_transform(st_crs(lambert.prj)) %>%
 filter(INCIDENT_ID %in% qc_list) %>%
 st_set_geometry(NULL) %>% as_tibble()

# Export the table of top 20 fastest fires (QCd)
ics.t %>%
 bind_rows(ics.t.a) %>%
 write_csv('../../data/tabular/fastest20_qc_table.csv')

rm(ics.t,ics.t.a,qc_list,incid_list,fired.t100,ics.fired.t100)
gc()
```

