
# Packages
import warnings
warnings.filterwarnings('ignore')
import os, sys, time, glob
import geopandas as gpd
import pandas as pd
import matplotlib.pyplot as plt
import pylandstats as pls
import rasterio as rio
import xarray as xr
import rioxarray as rxr
from xrspatial import zonal_stats
from rasterstats import zonal_stats
from tqdm.auto import tqdm

# FUNCTIONS


# Zonal stats
def get_zonal_stats(vector, raster, stats):
    # Run zonal statistics, store result in geopandas dataframe
    result = zonal_stats(vector, raster, stats=stats, geojson_out=True)
    return gpd.GeoDataFrame.from_features(result)


# Set up the data

maindir = '/Users/max/Library/CloudStorage/OneDrive-Personal/mcook/'

# HISDAC-US rasters
buas = glob.glob(os.path.join(maindir,'data/hisdac_us/BUA/')+"*.tif",recursive=True)
bprs = glob.glob(os.path.join(maindir,'data/hisdac_us/BUPR/mod/')+"*.tif",recursive=True)
print([os.path.basename(f) for f in buas])
print([os.path.basename(r) for r in bprs])

# Get the years and filter the geodataframe
hisdac_years = [int(os.path.basename(r)[4:8]) for r in buas]

# ICS+FIRED
ics_fired = gpd.read_file(os.path.join(maindir,'home-loss/data/spatial/mod/ics-fired_spatial_west_mod.gpkg'))
crs = ics_fired.crs

# Get the fire years
evt_years = list(ics_fired['ig_year'].unique())
evt_years = [int(i) for i in evt_years]
# Grab a list of event IDs
evt_ids = list(ics_fired['FIRED_ID'].unique())

# Subset columns
gdf = ics_fired[['FIRED_ID','HISDAC_YR','geometry']]
gdf.info()


##################

# GRAB THE BUPR DIRECTORY PATH
bupr_dir = os.path.join(os.path.join(maindir,'data/hisdac_us/BUPR/mod/'))

# EMPTY LIST TO HOLD THE OUTPUTS
zonal_st = []
# LOOP THROUGH HISDAC-US IMAGES
for i in tqdm(
        range(len(hisdac_years)),
        desc="LOOPING HISDAC-US IMAGES",
        position=0,
        leave=True):

    yr = hisdac_years[i]

    # Prep the images
    filep = os.path.join(bupr_dir, 'BUPR_' + str(yr) + '_sn.tif')
    img = rxr.open_rasterio(filep, masked=True)
    outshape = img.shape[1:]  # new shape
    trans = img.rio.transform()  # transform

    # Prep the fire perimeters
    evt = gdf[gdf['HISDAC_YR'] == yr]
    evt_ = evt.to_crs(crs=img.rio.crs.to_proj4())
    evt_ = evt_.explode(index_parts=True)

    # Grab the buffer distance,
    # buffer the fire events
    evt_['geometry'] = evt_.buffer(3000)

    # Retrieve the zonal statistics
    zs = get_zonal_stats(evt_, filep, stats="sum mean median max")
    zonal_st.append(zs)

print(len(zonal_st))
df = pd.concat(zonal_st)
df.info()
df.to_csv(os.path.join(maindir,"home-loss/data/tabular/mod/outputs/ics-fired_west_bupr3km_zs_exp.csv"))

globals().clear()