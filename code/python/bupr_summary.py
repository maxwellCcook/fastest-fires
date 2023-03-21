import os
import glob
import pandas as pd
import geopandas as gpd
import rasterstats as rs

###Directories
maindir = "C:/Users/mccoo/OneDrive/mcook/"
buprDir = os.path.join(maindir, 'data', 'hisdac_us', 'BUPR')
print(buprDir)

###List out the BUPR raster paths
rasters = glob.glob(buprDir+"/*.tif", recursive=True)
print(rasters)

###Read in the event shapefile
# evt_file = os.path.join(maindir, 'FIRED', 'data', '2020', 'edit', 'final', 'event_polys_albers_conus_w_eco_lc.gpkg')
evt_file = os.path.join(maindir, 'FIRED', 'data', 'update0621', 'fired_to2021091_events_albers_conus.shp')
# layer = 'event_polys_albers_conus_w_eco_lc'
layer = 'daily_polys_albers_conus_w_eco_lc'
evt = gpd.read_file(evt_file, driver="ESRI")


# ##Create buffer distance list

# buffers = list([0, 250, 1000, 4000])
# buf_out = []
# for i in range(0, len(buffers)):

#     if buffers[i]==0:
#         print("Event-level (no buffer) ...")
#         evt=evt
#         buf_out.append(evt)
#     else:
#         print("Event buffer at distance: "+str(buffers[i])+" meters")
#         evt['geometry'] = evt.geometry.buffer(int(buffers[i]))
#         buf_out.append(evt)

# print(len(buf_out))

# evt['geometry'] = evt.geometry.buffer(500)


###Define zonal statistics function
def get_zonal_stats(vector, raster, stats):
    # Run zonal statistics, store result in geopandas dataframe
    result = rs.zonal_stats(vector, raster, stats=stats, geojson_out=True)
    return gpd.GeoDataFrame.from_features(result)


###Get the years and filter the geodataframe
bupr_years = [int(os.path.basename(r)[5:9]) for r in rasters]
print(bupr_years)

evt_years = list(evt['ig_year'].unique())
for i in range(0, len(evt_years)):
    evt_years[i] = int(evt_years[i])
print("min burn year: "+str(min(evt_years)))
print("max burn year: "+str(max(evt_years)))


###Now, perform zonal statistics for each semi-decade
bupr_sums = [] #Empty list for results
for yr in bupr_years:

    bupr = os.path.join(buprDir, 'BUPR_'+str(yr)+'.tif')

    if yr == 2015:

        polys = evt[(evt['ig_year'] >= yr) & (evt['ig_year'] <= max(evt_years))]
        print(list(polys['ig_year'].unique()))

        zs = get_zonal_stats(polys, bupr, stats='sum')

        zs = zs.rename(columns={'sum': 'bupr_sum'})

        bupr_sums.append(zs)

    else:

        polys = evt[(evt['ig_year'] >= yr) & (evt['ig_year'] < yr+5)]
        print(list(polys['ig_year'].unique()))

        zs = get_zonal_stats(polys, bupr, stats='sum')

        zs = zs.rename(columns={'sum': 'bupr_sum'})

        bupr_sums.append(zs)

print(len(bupr_sums))


###Merge results into one dataframe
# Combine the data frames
print("Merging data frames ...")

gdf = pd.concat(bupr_sums)
print(type(gdf))

# Write to file
print("Writing output file ...")
out_file = os.path.join(maindir, 'FIRED', 'data', 'update0621', 'fired_to2021091_events_albers_conus_bupr_MaxMed.shp')
gdf.to_file(out_file)
