library(haven)
library(tidyverse)
library(rnoaa)
library(tbeptools)

noaa_key <- Sys.getenv('NOAA_KEY')

flrain <- read_sas("./data-raw/fl_rain_por_220223v93.sas7bdat")

cenflrainid <- ncdc_stations(extent=c(27.2,-83,28.7,-81.5), datasetid='GHCND', startdate = "2022-01-01", enddate = "2023-12-31", limit = 1000)
tbrainid <- cenflrainid$data %>%
              mutate(stationid = unique(id)) %>%
              select(stationid, name)

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

results <- list()  # list as storage variable for the loop results
i <- 1              # indexing variable

for(sid in unique(rainid$stationid)) { # each station in your stationid dataframe **tbrainid can be substituted here to get all active sites in the TB region from the NCDC
  for(year in 2022:2023) { # each year you care about, this can be updated to the entire RA period
    data <- ncdc(datasetid='GHCND', stationid = sid,
                 datatypeid='PRCP', startdate = paste0(year, '-01-01'),
                 enddate = paste0(year, '-12-31'), limit=400, add_units = TRUE,
                 token = noaa_key)$data # subset the returned list right away here with $data

    # add info from each loop iteration
    data$stationid <- rainid[rainid$stationid == sid,]$stationid
    data$station <- rainid[rainid$stationid == sid,]$station
    data$year <- year

    results[[i]] <- data # store it
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

tb_mo_rain_2022 <- tb_mo_rain %>%
                     filter(yr == 2022)

# Create data frame for NWS station coordinates
nwssite <- data.frame(
  nwssite = c(228, 478, 520, 940, 945, 1046, 1163, 1632, 1641, 3153, 3986, 4707, 5973, 6065, 6880, 7205, 7851, 7886, 8788, 8824, 9176, 9401, 2806),
  nws_x = c(415826, 417986, 352595, 343572, 355056, 366389, 394141, 327864, 423324, 388119, 378897, 427950, 440969, 369648, 360167, 388579, 377469, 339071, 349179, 324855, 356254, 419381, 339071),
  nws_y = c(3010551, 3086233, 3105324, 3040799, 3036965, 3166106, 3171362, 3094572, 3150822, 3049544, 3114262, 3106479, 3089791, 3014643, 3051678, 3099395, 3134590, 3074100, 3094285, 3113086, 2998172, 3049298, 3074100)
)


# Create data frame for target coordinates
targetxy <- read.csv(file = "./data-raw/ad_targetxy.csv") %>%
            select(-c(X))

# Create a data frame to store distance calculations
distance <- data.frame(target = numeric(),
                       targ_x = numeric(),
                       targ_y = numeric(),
                       matchsit = character(),
                       distance = numeric(),
                       invdist2 = numeric(),
                       stringsAsFactors = FALSE)

# Define labels for the variables
names(distance) <- c("target", "targ_x", "targ_y", "matchsit", "distance", "invdist2")

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
all <- all_data[order(all_data$target, all_data$targ_x, all_data$targ_y, all_data$yr, all_data$mo), ]

# Calculate weighted mean of 'tpcp_in' using 'invdist2' as weight
db <- all %>%
  group_by(target, targ_x, targ_y, yr, mo) %>%
  summarise(tpcp = weighted.mean(tpcp_in, w = invdist2, na.rm = T), .groups = "drop")

# Compute average rainfall at all grid points
db2 <- db %>%
  group_by(target, yr, mo) %>%
  summarise(tpcp = mean(tpcp), .groups = "drop") %>%
  filter(yr >= 2021) %>%
  rename(segment = target)

db3 <- db2 %>%
       save(file = "./data/ad_rain_2021-2023.Rdata")

trdb <- db2 %>%
  pivot_wider(names_from = c(yr,mo), values_from = tpcp, names_sort = TRUE) %>%
  rowwise() %>%
  mutate(annual_2021 = sum(across("2021_1":"2021_12"), na.rm = T),
         annual_2022 = sum(across("2022_1":"2022_12"), na.rm = T),
         annual_2023 = sum(across("2023_1":"2023_12"), na.rm = T),)

rain <- db2 %>%
          mutate(area = case_when(segment == 1 ~ 23407.05,
                                  segment == 2 ~ 10778.41,
                                  segment == 3 ~ 29159.64,
                                  segment == 4 ~ 24836.54,
                                  segment == 5 ~ 9121.87,
                                  segment == 6 ~ 1619.89,
                                  segment == 7 ~ 4153.22,
                                  TRUE ~ NA)) %>%
          mutate(h2oload = (tpcp*10000*area/39.37),
                 source = "Atmospheric Deposition")

#Acquire and read-in Verna NTN atmospheric deposition concentration data over the period of interest from: https://nadp.slh.wisc.edu/sites/ntn-FL41/
verna <- read.csv(file = "./data-raw/NTN-fl41-i-mgl.csv") %>%
          mutate(mo = seas+ 0) %>%
          mutate(nh4 = case_when(yr == 2022 & mo == 12 ~ mean(c(0.046, 0.063, 0.09, 0.105, 0.173)), #Dec. NH4 mean from 2017-2021 to fill in missing data
                                 TRUE ~ NH4)) %>%
          mutate(no3 = case_when(yr == 2022 & mo == 12 ~ mean(c(0.194, 0.257, 0.364, 0.327, 1.41)), #Dec. NO3 mean from 2017-2021 to fill in missing data
                         TRUE ~ NO3)) %>%
          mutate(nh4 = nh4*0.78,   #NADP data are reported as mg NO3 and mg NH4, this corrects for % of ions that is N;
                 no3 = no3*0.23,
                 TNConc = nh4+no3,
                 TPConc = 0.01262*TNConc+0.00110) %>%  #from regression relationship between TBADS TN and TP, applied to Verna;
          select(yr, mo, TNConc, TPConc)

load <- left_join(rain, verna, by = c("yr", "mo")) %>%
          mutate(tnwet = TNConc*h2oload/1000,
                 tpwet = TPConc*h2oload/1000) %>%
          mutate(tndry = case_when(mo<=6 ~ tnwet*1.05,
                                   mo>=11 ~ tnwet*1.05,
                                   mo >= 7 & mo <= 10 ~ tnwet*0.66,
                                   TRUE ~ NA),
                 tpdry = case_when(mo<=6 ~ tpwet*1.05,
                                   mo>=11 ~ tpwet*1.05,
                                   mo >= 7 & mo <= 10 ~ tpwet*0.66,
                                   TRUE ~ NA)) %>%
          mutate(tntot = tnwet+tndry,
                 tptot = tpwet+tpdry)

annual_load <- load %>%
               group_by(segment, yr) %>%
               summarise(tntot = sum(tntot, na.rm = T),
                         tptot = sum(tptot, na.rm = T)) %>%
               mutate(tntons = tntot*0.0011023113,
                      tptons = tptot*0.0011023113,
                      source = "Atmospheric Deposition")
ann_load <- annual_load %>%
            save(file = "./data/ad_loads_2021-2023.Rdata")
