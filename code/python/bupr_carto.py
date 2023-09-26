
"""
Convert HISDAC-US BUPR to cartographic points based on pixel value
"""

import os
import numpy as np
import rioxarray as rxr
import geopandas as gpd
from shapely.geometry import Point

# Directories
maindir = '/Users/max/Library/CloudStorage/OneDrive-Personal/mcook/'
projdir = os.path.join(maindir,'earth-lab/fastest-fires/data/')

# Load the GeoTIFF raster file
bupr_path = os.path.join(maindir,'data/hisdac_us/BUPR/contemp/BUPR_contemporary.tif')
bupr_grid = rxr.open_rasterio(bupr_path, masked=True, cache=False).squeeze()
proj = bupr_grid.rio.crs  # grab the projection information

# Load the polygon boundaries
gdf_path = os.path.join(projdir,'spatial/mod/mtbs_case_study_perims.gpkg')
gdf = gpd.read_file(gdf_path).to_crs(proj)

# Check the CRS does match
if gdf.crs == bupr_grid.rio.crs:
    print("CRS matches")

    # Clip the raster layer
    clipped = bupr_grid.rio.clip(gdf.geometry)

    # Extract pixel values as a NumPy array
    vals = clipped.values.squeeze()

    res = 250

    lon, lat = np.meshgrid(
        clipped.x.values - res / 2,  # Adjust for pixel center
        clipped.y.values + res / 2  # Adjust for pixel center
    )

    # Generate random points based on pixel values
    random_points = []
    for value, x, y in zip(vals.flat, lon.flat, lat.flat):
        if value > 0:
            num_random_points = int(value)  # Generate points based on pixel value
            random_lon = np.random.uniform(x, x + res, size=(num_random_points,))
            random_lat = np.random.uniform(y, y - res, size=(num_random_points,))
            geometries = [Point(lon, lat) for lon, lat in zip(random_lon, random_lat)]
            random_points.extend(geometries)

    # Create a GeoDataFrame with the random points
    gdff = gpd.GeoDataFrame(geometry=random_points, crs=clipped.rio.crs)

    # Optionally, save the GeoDataFrame to a shapefile
    output_shapefile = os.path.join(projdir,'spatial/mod/hisdac/bupr_random_points_case_study.gpkg')
    gdff.to_file(output_shapefile)