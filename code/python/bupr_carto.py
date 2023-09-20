
"""
Build a database of points using the BUPR grids
For Figure 1 to replace the ztrax points
"""

import os, glob
import rioxarray as rxr
import geopandas as gpd
from shapely.geometry import Point
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt


# Functions

def generate_random_points(pixel_value, pixel_size):
    # Generate random points within a pixel, with count equal to pixel_value
    rand_pts = [Point(np.random.rand() * pixel_size, np.random.rand() * pixel_size) for _ in range(pixel_value)]
    return gpd.GeoDataFrame(geometry=rand_pts)


# Load the data
maindir = '/Users/max/Library/CloudStorage/OneDrive-Personal/mcook/'
buprdir = os.path.join(maindir,'data/hisdac_us/BUPR')
grids = glob.glob(buprdir+"/*.tif", recursive=True)
# Open one to get the projection information
img = rxr.open_rasterio(grids[0], masked=True)  # open the image for its CRS
print(img.rio.crs.to_proj4())
# Read in the fastest FIRED
fired = gpd.read_file(
    os.path.join(maindir,'earth-lab/fastest-fires/data/spatial/mod/conus_fast-fires_2001to2020.gpkg'))
fired_clip = fired.to_crs(crs=img.rio.crs.to_proj4())
# Plot to double check
fired_clip.plot()
plt.show()

# Loop through HISDAC-US BUPR, clip to FIRED perims, convert to points for non-zero pixels

for grid in grids:
    print(f"Starting for grid: {grid}")
    # Grab a naming convention
    name = os.path.basename(grid)[:-4]
    # Open the raster
    img = rxr.open_rasterio(grid, masked=True, cache=False).squeeze()
    img.plot()
    clipped = img.rio.clip(fired_clip)
    # Create an empty GeoDataFrame to store the random points
    random_points_gdf = gpd.GeoDataFrame(columns=['geometry'])
    # Iterate through each pixel and generate random points
    for y in range(clipped.rio.height):
        print(clipped.rio.height)
        for x in range(clipped.rio.width):
            pval = clipped.values[y][x]
            psize = 250  # Adjust based on your specific pixel size
            if pval > 0:
                random_points = generate_random_points(pval, psize)
                # Save random points within the pixel
                random_points_gdf = pd.concat([random_points_gdf, random_points])
    # Save the random points as a GeoPackage
    output_random_points_path = os.path.join(
        maindir,f'earth-lab/fastest-fires/data/spatial/mod/{name}_points.gpkg',
    )
    random_points_gdf.to_file(output_random_points_path, driver="GPKG")
    print("Random points saved to:", output_random_points_path)

