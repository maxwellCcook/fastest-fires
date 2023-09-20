
"""
Calculate the sum of BUPR property records within fire perimeters
and at 1- and 4-km distances from perimeters
"""

globals().clear()

# Modules
import os
import glob
import pandas as pd
import geopandas as gpd
import rasterstats as rs
from functools import reduce
import rioxarray as rxr


# Define zonal statistics function
def get_zonal_stats(vector, raster, stats):
    # Run zonal statistics, store result in geopandas dataframe
    result = rs.zonal_stats(vector, raster, stats=stats, geojson_out=True)
    return gpd.GeoDataFrame.from_features(result)


# Load the data
maindir = '/Users/max/Library/CloudStorage/OneDrive-Personal/mcook/'
buprdir = os.path.join(maindir,'data/hisdac_us/BUPR')
grids = glob.glob(buprdir+"/*.tif", recursive=True)
# Open one to get the projection information
img = rxr.open_rasterio(grids[0], masked=True)  # open the image for its CRS

# Read in the fast FIRED events
# /Users/max/Library/CloudStorage/OneDrive-Personal/mcook/ics209-plus-fired/data/spatial/mod/ics-fired/final
# gdf_path = os.path.join(maindir,'earth-lab/fastest-fires/data/spatial/mod/conus_fast-fires_2001to2020.gpkg')
# 'ics209-plus-fired/data/spatial/mod/ics-fired/final/ics209plus_fired_events_combined.gpkg'
# "FIRED/data/spatial/mod/event-updates/conus-ak_to2022_events_qc.gpkg"
gdf_path = os.path.join(
    maindir,"FIRED/data/spatial/mod/event-updates/conus-ak_to2022_events_qc.gpkg")

gdf = gpd.read_file(gdf_path)
gdf = gdf[['geometry','id','ig_year']]
gdf = gdf.to_crs(crs=img.rio.crs.to_proj4())  # match the projection of the grid

del img

# Create list of buffer distances
dists = [0,1000,4000]
buffered = []  # empty list to store the output
for i in range(len(dists)):
    dist = dists[i]
    if dist == 0:
        print("Event-level (no buffer) ...")
        buffered.append(gdf)
    else:
        print("Event buffer at distance: "+str(str(dist))+" meters")
        gdf_ = gdf.copy()  # make a copy
        gdf_['geometry'] = gdf_.geometry.buffer(dist)
        gdf_['ig_year'] = gdf_['ig_year'].astype(int)
        buffered.append(gdf_)
# # Make sure the buffer distance worked ...
# buffered[0][buffered[0]['id'] == 48].plot()
# buffered[1][buffered[1]['id'] == 48].plot()
# buffered[2][buffered[2]['id'] == 48].plot()

# Get the HISDAC_US years and filter the geodataframe
bupr_years = [int(os.path.basename(grid)[5:9]) for grid in grids]
bupr_years.sort()
# Grab the ignition years
evt_years = list(gdf['ig_year'].unique())
evt_years.sort()  # sort ascending
for i in range(0, len(evt_years)):
    evt_years[i] = int(evt_years[i])
print("min burn year: "+str(min(evt_years)))
print("max burn year: "+str(max(evt_years)))


# Now, perform zonal statistics for each semi-decade
labs = ['','1km','4km']
sums = []  # Empty list for results
for y in bupr_years:
    bupr = os.path.join(buprdir, 'BUPR_'+str(y)+'.tif')
    print(f'Starting on {bupr}')
    if y < 2015:
        end = y + 4  # the range for HISDAC years
    else:
        end = y + 5
    outs = []
    for ii in range(len(buffered)):
        _gdf = buffered[ii]  # Get the first buffered layer
        print(f'Beginning with buffer distance: {dists[ii]}')
        _gdf = _gdf[(_gdf['ig_year'] >= y) & (_gdf['ig_year'] <= end)]
        print(list(_gdf['ig_year'].unique()))
        # Calculate the zonal statistics
        zs = get_zonal_stats(_gdf, bupr, stats='sum')
        print(f'bupr_sum{labs[ii]}')
        zs = zs.rename(columns={'sum': f'bupr_sum{labs[ii]}'})
        zs = zs[['id',f'bupr_sum{labs[ii]}']]
        zs['id'] = zs['id'].astype(int)
        # zs = zs[['FIRED_ID',f'bupr_sum{labs[ii]}']]
        # zs['id'] = zs['FIRED_ID'].astype(int)
        outs.append(zs)
    out_df = reduce(lambda a, b: pd.merge(a, b, on='id'), outs)
    print(out_df.head())
    sums.append(out_df)
print(len(sums))

# Merge results into one dataframe
# Combine the data frames
print("Merging data frames ...")
gdf_out = pd.concat(sums)

# Write to file
print("Writing output file ...")
# out_file = os.path.join(maindir,'earth-lab/fastest-fires/data/tabular/bupr_sums.csv')
# out_file = os.path.join(maindir,'ics209-plus-fired/data/tabular/mod/ics-fired_bupr_sums.csv')
out_file = os.path.join(maindir,'ics209-plus-fired/data/tabular/mod/fired_qc_bupr_sums.csv')

gdf_out.to_csv(out_file)

# # Join back to the spatial data frame and write out
# ff = gpd.read_file(gdf_path)
# ff['id'] = ff['id'].astype(int)
# ff_ = pd.merge(ff,gdf_out,on='id')
# print(ff_.head())
# ff_.to_file(gdf_path)
