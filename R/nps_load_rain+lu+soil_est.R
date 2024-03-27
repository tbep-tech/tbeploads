library(haven)
library(sf)
library(readxl)
library(tidyverse)
library(rnoaa)
library(esri2sf) # yonghah/esri2sf on github
library(tbeptools)
library(zoo)
library(FedData)
library(httr)
library(jsonlite)

noaa_key <- Sys.getenv('NOAA_KEY')

# NAD83(2011) / Florida West (ftUS)
# this is the projection used in original report
prj <- 6443

tb_fullshed <- st_read("./data-raw/TBEP/gis/TBEP_Watershed_Correct_Projection.shp") %>%
  st_transform(prj) %>%
  st_union(by_feature = T) %>%
  st_buffer(dist = 0) %>%
  select(Name, Hectares)

tbep_bb <- st_bbox(tb_fullshed)

tbshed <- st_read("./data-raw/TBEP/gis/TBEP_dBasins_Correct_Projection.shp") %>%
  st_transform(prj) %>%
#  st_union(by_feature = T) %>%
  st_buffer(dist = 0) %>%
  group_by(BAY_SEGMEN, NEWGAGE) %>%
  summarise() %>%
  rename(bay_seg = BAY_SEGMEN,
         basin = NEWGAGE) %>%
  arrange(bay_seg, basin)

tbjuris <- st_read("./data-raw/TBEP/gis/TB_Juris.shp") %>%
  st_transform(prj) %>%
#  st_union(by_feature = T) %>%
  st_buffer(dist = 0) %>%
  rename(entity = NAME_FINAL) %>%
  select(entity)

# Download latest DISTRICT LULC zip file and subset accordingly
tblu2020 <- st_read("./data-raw/SWFWMD_REG/lulc2020/LANDUSELANDCOVER2020.shp") %>%
  st_transform(prj) %>%
  st_intersection(tb_fullshed) %>%
#  st_union(by_feature = T) %>%
  st_buffer(dist = 0) %>%
  group_by(FLUCCSCODE, FLUCSDESC) %>%
  summarise()

tb_base <- st_union(tbshed, tbjuris)



## Alternatively, begin download of SWFWMD soil and lulc data, constructed from their ArcGIS REST URL and the TBEP bounding box parameters above

# soil_url <- "https://www25.swfwmd.state.fl.us/arcgis12/rest/services/BaseVector/Soils/MapServer/0/query"
# lulc2020_url <- "https://www25.swfwmd.state.fl.us/arcgis12/rest/services/OpenData/LandUseLandCoverPost2014/MapServer/2/query"

# params <- list(
#   f = "json", # Response format
#  geometryType = "esriGeometryEnvelope", # Bounding box geometry type
#  geometry = paste0('{"xmin":', tbep_bb[1], ',"ymin":', tbep_bb[2], ',"xmax":', tbep_bb[3], ',"ymax":', tbep_bb[4], '}'),
#  spatialRel = "esriSpatialRelIntersects", # Spatial relationship
#  outFields = "*", # Fields to include in the response
#  returnGeometry = F # Return geometry information
#)

# Make the API request to SWFWMD servers
# soil_response <- GET(soil_url, query = params)
# lulc_response <- GET(lulc2020_url, query = params)

# Download the data
# tbsoil_raw <- fromJSON(content(soil_response, "text", encoding = "UTF-8"))
# tblu2020_raw <- fromJSON(content(lulc_response, "text", encoding = "UTF-8"))


## Alternatively, download directly from USDA-NRCS, requires library(FedData) -- I couldn't get this fully working

# tbsoil_raw <- get_ssurgo(template = c("FL057", "FL081", "FL101", "FL103", "FL105", "FL115"),
#                     label = "TBEP_Watershed",
#                     raw.dir = paste0(tempdir(), "./data-raw/USDA/raw/ssurgo"),
#                     extraction.dir = paste0("./data-raw/USDA/"),
#                     force.redo = F)

# tbsoil <- tbsoil_raw$spatial %>%
#            st_transform(prj) %>%
#            st_intersection(tb_fullshed) %>%
#            st_union(by_feature = T) %>%
#            st_buffer(dist = 0)
#
## End optional download from USDA -- I couldn't figure out how to get to a muid or HSG from the databases downloaded



##This section assimilates rainfall data and parses to NPS drainage basins

# Placeholder section to improve future AD calculations by utilizing any active
# rainfall stations within TB region over the time period of interest, you would then:
# 1) pass these stations to the NCDC function to get daily data (to sum to monthly totals)
# 2) still need to identify and assign UTM coordinates to these "new" stations
# 3) find the invdist2 value to each segment grid point in the targetxy dataframe using the loop starting on line 98
#
# flrain <- read_sas("./data-raw/fl_rain_por_220223v93.sas7bdat")
#
# cenflrainid <- ncdc_stations(extent=c(27.2,-83,28.7,-81.5), datasetid='GHCND', startdate = "2022-01-01", enddate = "2023-12-31", limit = 1000)
# tbrainid <- cenflrainid$data %>%
#               mutate(stationid = unique(id)) %>%
#               select(stationid, name)

stationid <- c("GHCND:USC00080228", "GHCND:USC00080478", "GHCND:USC00080520", "GHCND:USC00080940", "GHCND:USC00080945",
               "GHCND:USC00081046", "GHCND:USC00081163", "GHCND:USC00081632", "GHCND:USC00081641", "GHCND:USW00092806",
               "GHCND:USC00083153", "GHCND:USC00083986", "GHCND:USC00084707", "GHCND:USC00085973", "GHCND:USC00086065",
               "GHCND:USC00086880", "GHCND:USC00087205", "GHCND:USC00087851", "GHCND:USC00087886", "GHCND:USW00012842",
               "GHCND:USC00088824", "GHCND:USC00089176", "GHCND:USC00089401")
station <- c(228, 478, 520, 940, 945,
             1046, 1163, 1632, 1641, 2806,
             3153, 3986, 4707, 5973, 6065,
             6880, 7205, 7851, 7886, 8788,
             8824, 9176, 9401)

rainid <- data.frame(stationid, station)

rain_results <- list()  # list as storage variable for the loop results
i <- 1              # indexing variable

for(sid in unique(rainid$stationid)) { # each station in your stationid dataframe **tbrainid can be substituted here to get all active sites in the TB region from the NCDC
  for(year in 2022:2023) { # each year you care about, this can be scripted/updated to the entire RA period
    data <- ncdc(datasetid='GHCND', stationid = sid,
                 datatypeid='PRCP', startdate = paste0(year, '-01-01'),
                 enddate = paste0(year, '-12-31'), limit=400, add_units = TRUE,
                 token = noaa_key)$data # subset the returned list right away here with $data

    # add info from each loop iteration
    data$stationid <- rainid[rainid$stationid == sid,]$stationid
    data$station <- rainid[rainid$stationid == sid,]$station
    data$year <- year

    rain_results[[i]] <- data # store it
    i <- i + 1 # rinse and repeat
  }
}

new_rain <- do.call(rbind, results) %>% # stack all of the data frames together rowwise
  dplyr::mutate(date = date(date), yr = year(date), mo = month(date), day = day(date), rainfall = round((value/254),digits = 2)) %>%
  dplyr::select(stationid, station, date, yr, mo, day, rainfall)


tbrain <- flrain %>%
  filter(COOPID %in% c(228, 478, 520, 940, 945, 1046, 1163, 1632, 1641, 2806, 3153, 3986, 4707, 5973, 6065, 6880, 7205, 7851, 7886, 8788, 8824, 9176, 9401)) %>%
  mutate(station = COOPID, yr = year(date), mo = month(date), day = day(date), rainfall = Prcp) %>%
  select(station, date, yr, mo, day, rainfall)

tbrain <-    right_join(rainid, tbrain, by = "station") #Add true NCDC stationid
tbrain <-    bind_rows(tbrain, new_rain) #Add new data from RA period

tb_mo_rain <- tbrain %>%
  group_by(station, yr, mo) %>%
  summarise(tpcp_in = sum(rainfall), n=n())

# Load data frame for NWS rainfall station coordinates
nwssite <- read.csv(file = "./data-raw/nwssite.csv")

# Create data frame for target coordinates
targetxy <- read.csv(file = "./data-raw/nps_targetxy.csv")

# Create a data frame to store distance calculations
distance <- data.frame(target = numeric(),
                       targ_x = numeric(),
                       targ_y = numeric(),
                       matchsit = character(),
                       distance = numeric(),
                       invdist2 = numeric(),
                       stringsAsFactors = FALSE)

# Loop through each target location
for (i in 1:nrow(targetxy)) {
  # Loop through each National Weather Service (NWS) site
  for (j in 1:nrow(nwssite)) {
    # Calculate distance between the target and NWS site
    distance_ij <- sqrt((targetxy$targ_x[i] - nwssite$nws_x[j])^2 + (targetxy$targ_y[i] - nwssite$nws_y[j])^2)

    # Check if the distance is within the radius
    if (distance_ij < 50000) {
      # Store the information in the distance data frame
      distance[nrow(distance) + 1, ] <- c(targetxy$target[i],
                                          targetxy$targ_x[i],
                                          targetxy$targ_y[i],
                                          nwssite$nwssite[j],
                                          distance_ij,
                                          1/(distance_ij^2))
    }
  }
}

# Merge distance and precipitation datasets
all_data <- merge(distance, tb_mo_rain, by.x = "matchsit", by.y = "station")

# Sort the data frame by specified columns
all <- all_data %>% arrange(target, yr, mo) %>%
  drop_na(tpcp_in)

# Calculate weighted mean of 'tpcp_in' using 'invdist2' as weight
db <- all %>%
  group_by(target, yr, mo) %>%
  summarise(tpcp = weighted.mean(tpcp_in, as.numeric(invdist2), na.rm = T), .groups = "drop") %>%
  filter(yr >= 2020) %>%
  rename(basin = target)

db2 <- db %>%
  save(file = "./data/nps_rain_2021-2023.Rdata")

trdb <- db %>%
  pivot_wider(names_from = c(yr,mo), values_from = tpcp, names_sort = TRUE) %>%
  rowwise() %>%
  mutate(annual_2020 = sum(across("2020_1":"2020_12"), na.rm = T),
         annual_2021 = sum(across("2021_1":"2021_12"), na.rm = T),
         annual_2022 = sum(across("2022_1":"2022_12"), na.rm = T),
         annual_2023 = sum(across("2023_1":"2023_12"), na.rm = T),)

npsrain <- db %>%
  group_by(basin) %>%
  mutate(lag1rain = lag(tpcp, n = 1, order_by = basin),
         lag2rain = lag(tpcp, n = 2, order_by = basin)) %>%
  filter(yr >= 2021) %>%
  rename(rain = tpcp)

rain <- npsrain %>%
  filter(basin != "02301500" & basin != "02303330" & basin != "02304500")

rainnest <- npsrain %>%
  filter(basin %in% c("02301500", "02301000", "02301300",
                      "02303000", "02303330", "02304500")) %>%
  mutate(landarea = case_when(basin == "02301000" ~ 34978.50,
                              basin == "02301300" ~ 14599.80,
                              basin == "02301500" ~ 38517.64,
                              basin == "02303000" ~ 62612.93,
                              basin == "02303330" ~ 42463.05,
                              basin == "02304500" ~ 62025.35,
                              TRUE ~ NA_real_)) %>%              # Handle unmatched basins
  mutate(basin = case_when(basin == "02301000" ~ "02301500",
                           basin == "02301300" ~ "02301500",
                           basin == "02303330" ~ "02304500",
                           basin == "02303000" ~ "02303330",
                           TRUE ~ basin)) %>%                    # Keep original basin if not matched
  filter(!(basin == "02301000" | basin == "02301300"))           # Exclude original basins from output

tbnestr <- rainnest %>%
  group_by(basin, yr, mo) %>%
  summarise(rain = weighted.mean(rain, landarea, na.rm = TRUE),
            lag1rain = weighted.mean(lag1rain, landarea, na.rm = TRUE),
            lag2rain = weighted.mean(lag2rain, landarea, na.rm = TRUE), .groups = "drop")

tbnestr_202x <- bind_rows(rain, tbnestr) %>%
  arrange(basin, yr, mo) %>%
  save(file = "./data/nps_nestr_2021-2023.Rdata")

## End rainfall data section

## Begin TBEP subbasin, TBNMC jurisdictions, DISTRICT landuse, and SSURGO Soils GIS merge
