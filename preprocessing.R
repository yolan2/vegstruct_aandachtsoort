# Load libraries
library(sf)
library(raster)
library(readxl)
library(dplyr)

setwd("C:/Users/yolan/OneDrive/Documenten/UGENT/Master/Stage/R/")

canopy_height <- raster("wh_vh1m.tif")

#laden bestanden en omzetten naar geografische entiteiten
species_points <- read_excel("2025_DePanne_pnt.xlsx")|>
  st_as_sf(coords = c("X_Lambert", "Y_Lambert"), crs = 31370)|>
  st_transform(crs = crs(canopy_height))

polygon_data <- st_read("C:/Users/yolan/OneDrive/Documenten/UGENT/Master/Stage/PBGIS11_StageYolan/PBGIS11_StageYolan/Flora_Vlak_DePanne.shp")
#interactieve viewer
#tmap_mode("view")
#tm_shape(canopy_height) +
#  tm_raster(title = "Canopy Height") +
#  tm_shape(species_points) +
#  tm_dots(col = "red", size = 0.5)

lookup_table <- read_excel("Detailkartering_Codes.xlsx", sheet = 2)

#abundances berekenen voor species_points
species_points <- species_points |> 
  left_join(lookup_table, by = c("ABUND" = "Code"))

#filter punten op extent
raster_extent <- st_as_sf(as(raster::extent(canopy_height), "SpatialPolygons"))
st_crs(raster_extent) <- st_crs(species_points)
species_points <- species_points[st_intersects(species_points, raster_extent, sparse = FALSE), ]
st_write(species_points, "species_points_processed.shp", row.names = FALSE, append = FALSE)


# Calculate abundances for polygon data
polygon_data <- polygon_data |>
  left_join(lookup_table, by = c("ABUNDANTIE" = "Code"))|>
  mutate(abundance_m2 = Mediaan / Shape_Area)

# Filter polygons by extent of canopy height raster
raster_extent <- st_as_sf(as(extent(canopy_height), "SpatialPolygons"))
st_crs(raster_extent) <- st_crs(polygon_data)
polygon_data <- polygon_data[st_intersects(polygon_data, raster_extent, sparse = FALSE,append=FALSE), ]


# Write processed polygon data to a shapefile
st_write(polygon_data, "plant_vlakken_processed.shp", row.names = FALSE, append=FALSE)

print("Data pre-processing completed.")
