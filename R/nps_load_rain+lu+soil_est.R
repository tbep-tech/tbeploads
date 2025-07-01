# library(haven)
# library(sf)
# library(readxl)
# library(tidyverse)
# library(rnoaa)
# library(esri2sf) # yonghah/esri2sf on github
# library(tbeptools)
# library(zoo)
# library(httr)
# library(units)
# library(sjlabelled)
# #library(jsonlite)
# #library(tmap)
# #library(terra)
#
# noaa_key <- Sys.getenv('NOAA_KEY')
#
## Begin TBEP subbasin, TBNMC jurisdictions, DISTRICT landuse, and SSURGO Soils GIS merge
## Ignore this for now as the R union process to join all these layers isn't working
## Circumvented by developing a tb_base.shp file within ArcGIS using these layer source files
## Note: tb_juris.shp file contains geometry/projection errors for municipalities in Pinellas County

# NAD83(2011) / Florida West (ftUS)
# this is the projection used in original report
# prj <- 6443
#
# data(tbfullshed)
# data(tbshed)
# data(tbjuris)
# data(tblu2020)
# data(tblu2023)
#
# # Alternatively, begin download of SWFWMD soil and lulc data, constructed from their ArcGIS REST URL and the TBEP bounding box parameters above

##End raw GIS layer inputs

# ## Union not working in R, so imported GIS layer from ArcGIS union instead ...
# #tb_base <- st_union(tbshed, tbjuris)
# #tb_base1 <- st_union(tbshed, tbjuris) %>%
# #            group_by(bay_seg, basin, drnfeat, entity) %>%
# #            summarise()
# #tb_base2 <- st_union(tb_base1, tblu2020) %>%
# #            group_by(bay_seg, basin, drnfeat, entity, FLUCCSCODE) %>%
# #            summarise()
# #tb_base3 <- st_union(tb_base2, tb_soils) %>%
# #            group_by(bay_seg, basin, drnfeat, entity, FLUCCSCODE, hydrgrp) %>%
# #            summarise()
#
# #tb_base <- tb_base3 %>%
# #              dplyr::mutate(FLUCCSCODE = replace_na(FLUCCSCODE,0),
# #                            hydrgrp = replace_na(hydrgrp, "D"))
#
# tb_base1 <- st_read("./data-raw/TBEP/gis/tb_base.shp") %>%
#            st_transform(prj) %>%
#            group_by(bay_seg, basin, drnfeat, entity, FLUCCSCODE, CLUCSID, IMPROVED, hydrgrp) %>%
#            mutate(CLUCSID = case_when(FLUCCSCODE == 2100 ~ 10,
#                                       TRUE ~ CLUCSID)) %>%
#            summarise()
#
# tb_base1$area_ha <- sf::st_area(tb_base1) * 0.000009290304 # Projection is in feet, converting to ha
#
# #st_write(tb_base, "./data/tb_base.shp")
#
# #JEI SAS NPS Protocols pickup at 11_F3D... here
#
# tb_base <- tb_base1 %>%
#              sf::st_drop_geometry() %>%
#              drop_units() %>%
#              mutate(drnfeat = ifelse(is.na(drnfeat), "CON", drnfeat))
#
# tbbase_202x <- tb_base %>%
#   saveRDS(file = "./data/tb_base.rds")
#
# lsd <- tb_base %>%
#         mutate(drnfeat = case_when(drnfeat != "NONCON" ~ "CON",
#                          TRUE ~ drnfeat)) %>%
#         mutate(hydrgrp = case_when(hydrgrp == "A/D" ~ "A",
#                                    hydrgrp == "B/D" ~ "B",
#                                    hydrgrp == "C/D" ~ "C",
#                          TRUE ~ hydrgrp)) %>%
#         rename(clucsid = CLUCSID,
#                improved = IMPROVED) %>%
#         group_by(bay_seg, basin, drnfeat, clucsid, hydrgrp, improved) %>%
#         summarise(area = sum(area_ha))
#
# tbland_202x <- lsd %>%
#                 saveRDS(file = "./data/npsag3.rds")
#
# f3d <- lsd %>%
#        mutate(bay_seg = case_when(basin == "206-5" ~ 55,
#               TRUE ~ bay_seg)) %>%
#        mutate(grp = case_when(drnfeat == "CON" & clucsid < 10 ~ paste0("C_C0",as.character(clucsid),as.character(hydrgrp)),
#                               drnfeat == "CON" & clucsid > 9 ~ paste0("C_C",as.character(clucsid),as.character(hydrgrp)),
#                               drnfeat == "NONCON" & clucsid < 10 ~ paste0("NC_C0",as.character(clucsid),as.character(hydrgrp)),
#                               drnfeat == "NONCON" & clucsid > 9 ~ paste0("NC_C",as.character(clucsid),as.character(hydrgrp)),
#                     TRUE ~ NA))
# tbland <- f3d %>%
#           group_by(bay_seg, basin, grp) %>%
#           summarise(area = sum(area)) %>%
#           spread(grp, area)
#
# tbland2 <- f3d %>%
#            group_by(bay_seg, basin) %>%
#            summarise(tot_area = sum(area))
#
# tbland <- left_join(tbland,tbland2, by = c("bay_seg", "basin"))
#
# write.csv(as.data.frame(tbland), file = "./data/tbland.csv")
#
# #Nests and combines certain basins for logistic model
# tbnestland <- tbland %>%
#               mutate(original_basin = basin) %>%
#               bind_rows(
#                 filter(., basin == "02301000") %>% mutate(basin = "02301500"),
#                 filter(., basin == "02301300") %>% mutate(basin = "02301500"),
#                 filter(., basin == "02303330") %>% mutate(basin = "02304500"),
#                 filter(., basin == "02303000") %>%
#                   bind_rows(
#                     mutate(., basin = "02304500"),
#                     mutate(., basin = "02303330")),
#                 filter(., basin == "02307359") %>% mutate(basin = "LTARPON")
#               ) %>%
#               group_by(bay_seg, basin) %>%
#               summarise(across(.cols = where(is.numeric), .fns = sum))
#
# write.csv(as.data.frame(tbnestland), file = "./data/tbnestland.csv")
#
# tbnestl_202x <- tbnestland %>%
#   saveRDS(file = "./data/nps_nestl_2021-2023.rds")
#
# ##This section assimilates rainfall data and parses to NPS drainage basins
#
# # Placeholder section to improve future AD calculations by utilizing any active
# # rainfall stations within TB region over the time period of interest, you would then:
# # 1) pass these stations to the NCDC function to get daily data (to sum to monthly totals)
# # 2) still need to identify and assign UTM coordinates to these "new" stations
# # 3) find the invdist2 value to each segment grid point in the targetxy dataframe using the loop starting on line 98
# #
#
# flrain <- read_sas("./data-raw/JEI_PRIOR/fl_rain_por_220223v93.sas7bdat") #Import historic JEI rainfall dataset
#
# cenflrainid <- ncdc_stations(extent=c(27.2,-83,28.7,-81.5), datasetid='GHCND', startdate = "2022-01-01", enddate = "2023-12-31", limit = 1000) #Change the date range to match load estimate period w/ all available data
# tbrainid <- cenflrainid$data %>%
#                mutate(stationid = unique(id)) %>%
#                select(stationid, name)
#
# stationid <- c("GHCND:USC00080228", "GHCND:USC00080478", "GHCND:USC00080520", "GHCND:USC00080940", "GHCND:USC00080945",
#                 "GHCND:USC00081046", "GHCND:USC00081163", "GHCND:USC00081632", "GHCND:USC00081641", "GHCND:USW00092806",
#                 "GHCND:USC00083153", "GHCND:USC00083986", "GHCND:USC00084707", "GHCND:USC00085973", "GHCND:USC00086065",
#                 "GHCND:USC00086880", "GHCND:USC00087205", "GHCND:USC00087851", "GHCND:USC00087886", "GHCND:USW00012842",
#                 "GHCND:USC00088824", "GHCND:USC00089176", "GHCND:USC00089401")
# station <- c(228, 478, 520, 940, 945,
#               1046, 1163, 1632, 1641, 2806,
#               3153, 3986, 4707, 5973, 6065,
#               6880, 7205, 7851, 7886, 8788,
#               8824, 9176, 9401)
#
# rainid <- data.frame(stationid, station)
#
# ## rNOAA package may no longer work in the future, for now it is
# rain_results <- list()  # list as storage variable for the loop results
# i <- 1              # indexing variable
#
# for(sid in unique(rainid$stationid)) { # each station in your stationid dataframe **tbrainid can be substituted here to get all active sites in the TB region from the NCDC
#   for(year in 2022:2023) { # each year you care about, this can be scripted/updated to the entire RA period
#     data <- ncdc(datasetid='GHCND', stationid = sid,
#                  datatypeid='PRCP', startdate = paste0(year, '-01-01'),
#                  enddate = paste0(year, '-12-31'), limit=366, add_units = TRUE,
#                  token = noaa_key)$data # subset the returned list right away here with $data
#
#     # add info from each loop iteration
#     data$stationid <- rainid[rainid$stationid == sid,]$stationid
#     data$station <- rainid[rainid$stationid == sid,]$station
#     data$year <- year
#
#     rain_results[[i]] <- data # store it
#     i <- i + 1 # rinse and repeat
#   }
# }
#
# new_rain <- do.call(rbind, rain_results) %>% # stack all of the data frames together rowwise
#   dplyr::mutate(date = date(date), yr = year(date), mo = month(date), day = day(date), rainfall = round((value/254),digits = 2)) %>%
#   dplyr::select(stationid, station, date, yr, mo, day, rainfall)
#
# tbrain <- flrain %>%
#   filter(COOPID %in% c(228, 478, 520, 940, 945, 1046, 1163, 1632, 1641, 2806, 3153, 3986, 4707, 5973, 6065, 6880, 7205, 7851, 7886, 8788, 8824, 9176, 9401)) %>%
#   mutate(station = COOPID, yr = year(date), mo = month(date), day = day(date), rainfall = Prcp) %>%
#   select(station, date, yr, mo, day, rainfall)
#
# tbrain <-    right_join(rainid, tbrain, by = "station") #Add true NCDC stationid
# tbrain <-    bind_rows(tbrain, new_rain) #Add new data from RA period
#
# tb_mo_rain <- tbrain %>%
#    group_by(station, yr, mo) %>%
#    summarise(tpcp_in = sum(rainfall), n=n())
#
# # Load data frame for NWS rainfall station coordinates
# nwssite <- read.csv(file = "./data-raw/nwssite.csv")
#
# # Create data frame for target coordinates
# targetxy <- read.csv(file = "./data-raw/nps_targetxy.csv")
#
# # Create a data frame to store distance calculations
# distance <- data.frame(target = numeric(),
#                        targ_x = numeric(),
#                        targ_y = numeric(),
#                        matchsit = character(),
#                        distance = numeric(),
#                        invdist2 = numeric(),
#                        stringsAsFactors = FALSE)
#
# # Loop through each target location
# for (i in 1:nrow(targetxy)) {
#   # Loop through each National Weather Service (NWS) site
#   for (j in 1:nrow(nwssite)) {
#     # Calculate distance between the target and NWS site
#     distance_ij <- sqrt((targetxy$targ_x[i] - nwssite$nws_x[j])^2 + (targetxy$targ_y[i] - nwssite$nws_y[j])^2)
#
#     # Check if the distance is within the radius
#     if (distance_ij < 50000) {
#       # Store the information in the distance data frame
#       distance[nrow(distance) + 1, ] <- c(targetxy$target[i],
#                                           targetxy$targ_x[i],
#                                           targetxy$targ_y[i],
#                                           nwssite$nwssite[j],
#                                           distance_ij,
#                                           1/(distance_ij^2))
#     }
#   }
# }
#
# # Merge distance and precipitation datasets
# all_data <- merge(distance, tb_mo_rain, by.x = "matchsit", by.y = "station")
#
# # Sort the data frame by specified columns
# all <- all_data %>% arrange(target, yr, mo) %>%
#   drop_na(tpcp_in)
#
# # Calculate weighted mean of 'tpcp_in' using 'invdist2' as weight
# db <- all %>%
#   group_by(target, yr, mo) %>%
#   summarise(tpcp = weighted.mean(tpcp_in, as.numeric(invdist2), na.rm = T), .groups = "drop") %>%
#   filter(yr >= 2020) %>%
#   rename(basin = target)
#
# db2 <- db %>%
#   saveRDS(file = "./data/nps_rain_2020-2023.rds")
#
# trdb <- db %>%
#   pivot_wider(names_from = c(yr,mo), values_from = tpcp, names_sort = TRUE) %>%
#   rowwise() %>%
#   mutate(annual_2020 = sum(across("2020_1":"2020_12"), na.rm = T),
#          annual_2021 = sum(across("2021_1":"2021_12"), na.rm = T),
#          annual_2022 = sum(across("2022_1":"2022_12"), na.rm = T),
#          annual_2023 = sum(across("2023_1":"2023_12"), na.rm = T),)
#
# npsrain <- db %>%
#   group_by(basin) %>%
#   mutate(lag1rain = lag(tpcp, n = 1, order_by = basin),
#          lag2rain = lag(tpcp, n = 2, order_by = basin)) %>%
#   filter(yr >= 2021) %>%
#   rename(rain = tpcp)
#
# rain <- npsrain %>%
#   filter(basin != "02301500" & basin != "02303330" & basin != "02304500")
#
# rainnest <- npsrain %>%
#   filter(basin %in% c("02301500", "02301000", "02301300",
#                       "02303000", "02303330", "02304500")) %>%
#   mutate(landarea = case_when(basin == "02301000" ~ 34978.50,
#                               basin == "02301300" ~ 14599.80,
#                               basin == "02301500" ~ 38517.64,
#                               basin == "02303000" ~ 62612.93,
#                               basin == "02303330" ~ 42463.05,
#                               basin == "02304500" ~ 62025.35,
#                               TRUE ~ NA_real_)) %>%              # Handle unmatched basins
#   mutate(basin = case_when(basin == "02301000" ~ "02301500",
#                            basin == "02301300" ~ "02301500",
#                            basin == "02303330" ~ "02304500",
#                            basin == "02303000" ~ "02303330",
#                            TRUE ~ basin)) %>%                    # Keep original basin if not matched
#   filter(!(basin == "02301000" | basin == "02301300"))           # Exclude original basins from output
#
# tbnestr <- rainnest %>%
#   group_by(basin, yr, mo) %>%
#   summarise(rain = weighted.mean(rain, landarea, na.rm = TRUE),
#             lag1rain = weighted.mean(lag1rain, landarea, na.rm = TRUE),
#             lag2rain = weighted.mean(lag2rain, landarea, na.rm = TRUE), .groups = "drop")
#
# tbnestr_202x <- bind_rows(rain, tbnestr) %>%
#   arrange(basin, yr, mo) %>%
#   saveRDS(file = "./data/nps_nestr_2021-2023.rds")
#
# ## End rainfall data section
#
# ## This section begins import of daily discharge data for select tributary sites
#
# lman <- read_xlsx("./data-raw/MAN_CO/Daily Discharge 2021-2023.xlsx") %>%
#   rename(date = 1, flow_cfs = 2) %>%
#   mutate(site_no = "LMANATEE") %>%
#   select(site_no, date, flow_cfs)
#
# s160 <- read_xlsx("./data-raw/TBW/TBW Device ID 957 Data (2021-2023).xlsx") %>%
#   rename(date = MeasureDateTime) %>%
#   mutate(site_no = "TBYPASS",
#          flow_cfs = round(Value*1.53723, digits = 4)) %>%
#   select(site_no, date, flow_cfs)
#
# TBW_BellSHWD <- read_xls("./data-raw/SWFWMD_REG/Withdrawal_Pumpage_Report_TBW-AR-BS.xls", sheet = "Pumpage") %>%  #SWFWMD WMIS Pumpage Reports for Permit 11794 OR Optional: You can substitute TBW reported withdrawals for Site 4626 here instead (Cathleen Jonas, cjonas@tampabaywater.org)
#   filter(`DID#` == 1) %>%
#   rename(date = `RECORDED DATE`) %>%
#   mutate(site_no = "02301500",
#          wd_cfs = round(`DAILY AVG`/1000000*1.54723, digits = 4)) %>%
#   select(site_no, date, wd_cfs) %>%
#   filter(year(date) >= 2021 & year(date) <= 2023)
#
# fl_results <- list()  # list as storage variable for the loop results
# i <- 1              # indexing variable
#
# usgsid <-       c("02299950", "02300042", "02300500", "02300700", "02301000",
#                   "02301300", "02301500", "02301750", "02303000", "02303330",
#                   "02304500", "02306647", "02307000", "02307359", "02307498")
# usgs <- data.frame(usgsid)
#
# for(sid in unique(usgs$usgsid)) {         # Each station in your usgsid dataframe
#   data <- dataRetrieval::readNWISdv(sid, "00060", "2021-01-01", "2023-12-31") %>%
#     dataRetrieval::renameNWISColumns()
#
#   fl_results[[i]] <- data # store it
#   i <- i + 1 # rinse and repeat
# }
#
# new_flow <- do.call(rbind, fl_results) %>%
#   dplyr::mutate(date = date(Date), flow_cfs = Flow) %>%
#   dplyr::select(site_no, date, flow_cfs) %>%
#   rbind(s160) %>%                                         #Add in S160 (TBW) & Lake Manatee (Man. Co.) flows here
#   rbind(lman) %>%
#   dplyr::full_join(TBW_BellSHWD, by = c("site_no", "date"))  #Add in TBW AR-Bell Shoals withdrawals here
#
# new_flow_corrected <- new_flow %>%
#   mutate(flow_cfs = case_when(site_no == "02301500" ~ flow_cfs-wd_cfs, # Subtract TBW AR-Bell Shoals withdrawals from site 02301500 flows
#                               TRUE ~ flow_cfs)) %>%
#   select(site_no, date, flow_cfs) %>%
#   complete(date, nesting(site_no), fill = list(flow_cfs = NA)) %>%     # Fill in missing dates, if any
#   arrange(site_no, date) %>%
#   mutate(flow_cfs = zoo::na.approx(flow_cfs), .by = site_no) %>%       # Linear interpolate missing daily values
#   mutate(basin = case_when(site_no == "02307498" ~ "LTARPON",
#                            site_no == "02300042" ~ "EVERSRES",
#                            TRUE ~ site_no),
#          yr = year(date),
#          mo = month(date)) %>%
#   select(basin, date, yr, mo, flow_cfs)
#
# check_plots <- new_flow_corrected %>%
#   ggplot(aes(x = date, y = flow_cfs)) +
#   geom_line() +
#   facet_wrap(~ basin, scales = "free")
# check_plots
#
# flow_monthly_means <- new_flow_corrected %>%
#   group_by(basin, yr, mo) %>%
#   summarise(flow_cfs = mean(flow_cfs))
#
# tbnestf_202x <- flow_monthly_means %>%
#   arrange(basin, yr, mo) %>%
#   saveRDS(file = "./data/nps_nestf_2021-2023.rds")
#
# ## End assemble all flow location data
#
# ##Start assembling NPS model parameters
#
# rainflow <- full_join(npsrain,flow_monthly_means, by = c("basin", "yr", "mo"))
#
# rainflow <- rainflow %>%
#               mutate(bay_seg = case_when(
#                                  basin %in% c("02306647", "02307000", "02307359", "LTARPON", "206-1") ~ 1,
#                                  basin %in% c("02300700", "02301000", "02301300", "02301500", "02301695", "02301750",
#                                               "02303000", "02303330", "02304500", "TBYPASS", "204-2", "205-2", "206-2") ~ 2,
#                                  basin %in% c("02300500", "02300530", "203-3", "206-3C", "206-3E", "206-3W") ~ 3,
#                                  basin == "206-4" ~ 4,
#                                  basin == "207-5" ~ 5,
#                                  basin == "206-5" ~ 55,
#                                  basin == "206-6" ~ 6,
#                                  basin %in% c("02299950", "202-7", "EVERSRES", "LMANATEE") ~ 7,
#                TRUE ~ NA))  # Retain existing bay_seg if no condition is met
#
# rainflowextra <- rainflow %>%
#                  filter(basin == "207-5") %>%
#                  mutate(bay_seg=55)
#
# rainflow1 <- bind_rows(rainflow, rainflowextra)
#
# npsmod1 <- left_join(tbnestland, rainflow1, by = c("bay_seg", "basin"))
#
# dbasing1 <- read_sas("./data-raw/JEI_PRIOR/dbasing_1214.sas7bdat")
#
# dbasinbcbs <- dbasing1 %>%
#               filter(BAY_SEG == 5 & COAST_NO %in% c(580, 602, 1003, 1031)) %>%
#               mutate(HECTARE = if_else(COAST_NO == 580, HECTARE * 0.411, HECTARE),
#               BAY_SEG = 55)
#
# dbasinbcb5 <- dbasing1 %>%
#               filter(BAY_SEG == 5 & COAST_NO %in% c(501, 524, 529, 545, 556, 580, 587, 1001)) %>%
#               mutate(HECTARE = if_else(COAST_NO == 580, HECTARE * 0.589, HECTARE))
#
# dbasing <- dbasing1 %>%
#            filter(BAY_SEG != 5) %>%
#            bind_rows(dbasinbcb5, dbasinbcbs) %>%
#            rename(basin = NEWGAGE,
#                   gagetype = GAGETYPE,
#                   bay_seg = BAY_SEG) %>%
#            distinct(bay_seg, basin, gagetype) %>%
#            arrange(bay_seg, basin)
#
# tbshydro <- full_join(dbasing, npsmod1, by = c("bay_seg", "basin"))
#
# #Remove 'Non-connected' basins, saltwater features and wetland CLUCs from basins' total area calculation
# #CLUC-Soil category areas and the Total area calculated under this effort deviate from JEI's prior efforts
# #This needs to be researched/QC'd a bit more based on total available land area in each basin, for now proceeding with model calculations
#
# explan <- tbshydro %>%
#               #Remove non-connected basins
#               mutate(bas_area = tot_area - rowSums(select(.,
#                                               starts_with("NC_C")), na.rm = TRUE)) %>%
#               #Remove saltwater and wetlands
#               mutate(bas_area = tot_area - rowSums(select(.,
#                                               starts_with("C_C17"), starts_with("C_C21"), starts_with("C_C22")), na.rm = TRUE)) %>%
#               #Calculate CLUCs percentages
#               mutate(lu01 = (rowSums(select(., starts_with("C_C01")), na.rm = TRUE)) / bas_area) %>%
#               mutate(lu02 = (rowSums(select(., starts_with("C_C02")), na.rm = TRUE)) / bas_area) %>%
#               mutate(lu03 = (rowSums(select(., starts_with("C_C03")), na.rm = TRUE)) / bas_area) %>%
#               mutate(lu04 = (rowSums(select(., starts_with("C_C04")), na.rm = TRUE)) / bas_area) %>%
#               mutate(lu05 = (rowSums(select(., starts_with("C_C05")), na.rm = TRUE)) / bas_area) %>%
#               mutate(lu06 = (rowSums(select(., starts_with("C_C06")), na.rm = TRUE)) / bas_area) %>%
#               mutate(lu07 = (rowSums(select(., starts_with("C_C07")), na.rm = TRUE)) / bas_area) %>%
#               mutate(lu08 = (rowSums(select(., starts_with("C_C08")), na.rm = TRUE)) / bas_area) %>%
#               mutate(lu09 = (rowSums(select(., starts_with("C_C09")), na.rm = TRUE)) / bas_area) %>%
#               mutate(lu10 = (rowSums(select(., starts_with("C_C10")), na.rm = TRUE)) / bas_area) %>%
#               mutate(lu11 = (rowSums(select(., starts_with("C_C11")), na.rm = TRUE)) / bas_area) %>%
#               mutate(lu12 = (rowSums(select(., starts_with("C_C12")), na.rm = TRUE)) / bas_area) %>%
#               mutate(lu13 = (rowSums(select(., starts_with("C_C13")), na.rm = TRUE)) / bas_area) %>%
#               mutate(lu14 = (rowSums(select(., starts_with("C_C14")), na.rm = TRUE)) / bas_area) %>%
#               mutate(lu15 = (rowSums(select(., starts_with("C_C15")), na.rm = TRUE)) / bas_area) %>%
#               mutate(lu16 = (rowSums(select(., starts_with("C_C16")), na.rm = TRUE)) / bas_area) %>%
#               mutate(lu17 = (rowSums(select(., starts_with("C_C17")), na.rm = TRUE)) / bas_area) %>% #Not used in model - seawater
#               mutate(lu18 = (rowSums(select(., starts_with("C_C18")), na.rm = TRUE)) / bas_area) %>%
#               mutate(lu19 = (rowSums(select(., starts_with("C_C19")), na.rm = TRUE)) / bas_area) %>%
#               mutate(lu20 = (rowSums(select(., starts_with("C_C20")), na.rm = TRUE)) / bas_area) %>%
#               mutate(lu21 = (rowSums(select(., starts_with("C_C21")), na.rm = TRUE)) / bas_area) %>% #Not used in model - tidal flats
#               mutate(lu22 = (rowSums(select(., starts_with("C_C22")), na.rm = TRUE)) / bas_area) %>% #Not used NPDES areas
#               #Calculate aggregated land use (%)
#               mutate(urb = lu01 + lu02 + lu03 + lu04 + lu05 + lu07,
#                      ag  = lu06 + lu11 + lu12 + lu13 + lu14,
#                      wet = lu16 + lu18 + lu19 + lu20,
#                      frs = lu08 + lu09 + lu10 + lu15) %>%
#               #Calculate forest land cover (%) by HSG
#               mutate(for_ab = (rowSums(select(.,c("C_C08A", "C_C08B", "C_C09A", "C_C09B", "C_C15A", "C_C15B")), na.rm = TRUE)) / bas_area) %>%  #C_C10A + C_C10B excluded/missing -- need to QC CLUCs-FLUCCs crosswalk for 'Pasture Lands'
#               mutate(for_cd = (rowSums(select(.,c("C_C08C", "C_C08D", "C_C09C", "C_C09D", "C_C15C", "C_C15D")), na.rm = TRUE)) / bas_area) %>%  #C_C10C + C_C10D excluded/missing -- need to QC CLUCs-FLUCCs crosswalk for 'Pasture Lands'
#               #Unit conversions and additional variable assignments
#               mutate(flow = ((flow_cfs * 0.0283) / (bas_area *10000)) * 60 * 60 * 24 * (365/12)) %>%  #Convert from cfs to meters per month
#               mutate(rain = rain * 0.0254) %>%  #Convert from inches to meters per month
#               mutate(lag1rain = lag1rain * 0.0254) %>%  #Convert from inches to meters per month
#               mutate(lag2rain = lag2rain * 0.0254) %>%  #Convert from inches to meters per month
#               mutate(grp = case_when(urb <= 0.19 ~ "A",
#                                      urb > 0.19  ~ "B",
#                            TRUE ~ NA)) %>%
#               mutate(season = case_when(mo %in% c(7, 8, 9, 10) ~ "wet",
#                                         mo %in% c(1, 2, 3, 4, 5, 6, 11, 12) ~ "dry",
#                               TRUE ~ NA)) %>%
#               select(bay_seg, basin, gagetype, grp, season, mo, yr, flow, rain, lag1rain, lag2rain,
#                      bas_area, tot_area,
#                      urb, ag, wet, frs, for_ab, for_cd, num_range("lu0", 1:9), num_range("lu", 10:22))
# npsmod2 <- explan %>%
#               mutate(lflowhat = case_when(season == "dry" & grp == "A" ~
#                                             rain * 4.59483000 + lag1rain * 6.26892755 + lag2rain * 4.29704324 +
#                                             urb * -4.86110475 + ag * -2.97134608 + wet * -16.90735157 + frs * -3.04320707,
#                                           season == "wet" & grp == "A" ~
#                                             rain * 7.21891992 + lag1rain * 3.59249568 + lag2rain * 2.24675993 +
#                                             urb * -5.62930983 + ag * -3.85343456 + wet * -11.76932936 + frs * -5.00397713,
#                                           season == "dry" & grp == "B" ~
#                                             rain * 5.93231559 + lag1rain * 6.16790364 + lag2rain * 3.58033336 +
#                                             urb * -5.98227539 + ag * -5.48850473 + wet * -1.44922321 + frs * -10.14869568,
#                                           season == "wet" & grp == "B" ~
#                                             rain * 7.60247189 + lag1rain * 1.70865432 + lag2rain * 2.78577463 +
#                                             urb * -4.66502277 + ag * -5.38936557 + wet * -2.79156203 + frs * -10.21741924,
#                                           TRUE ~ NA_real_),
#                      flowhat = exp(lflowhat),
#                      outlier = if_else(rain > 38.1, 1, 0))
# npsmod2_202x <- npsmod2 %>%
#   arrange(bay_seg, basin, yr, mo) %>%
#   saveRDS(file = "./data/npsmod2_2021-2023.rds")
#
# flowhat <- npsmod2 %>%
#            filter(! basin %in% c("02301000", "02301300", "02303000", "02303330", "02307359")) %>%  #Remove 02307359 when LTARPON missing
#            select(bay_seg, basin, bas_area, yr, mo, flow, flowhat)
#
# landsoil1 <- readRDS("./data/npsag3.rds") %>% # or lsd in this long script
#              filter(drnfeat != "NONCON") %>%
#              mutate(basin = case_when(basin == "02303000" ~ "02304500",
#                                       basin == "02303330" ~ "02304500",
#                                       basin == "02301000" ~ "02301500",
#                                       basin == "02301300" ~ "02301500",
#                                       TRUE ~ basin)) %>%
#              filter(! basin %in% c("02301000", "02301300", "02303000", "02303330", "02307359")) %>%
#              select(bay_seg, basin, drnfeat, clucsid, hydrgrp, area)
#
# rc <- read.csv(file="./data-raw/rc_clucsid.csv") %>%
#       rename(hydrgrp = hsg)
#
# landsoil_rc <- landsoil1 %>%
#                inner_join(rc, by = c("clucsid", "hydrgrp"))
#
# landsoil2 <- landsoil_rc %>%
#               tidyr::expand_grid(mo = 1:12) %>%
#               mutate(rc = ifelse(mo %in% c(7, 8, 9, 10), wet_rc, dry_rc),
#               rca = rc * area)
#
# tot_rca <- landsoil2 %>%
#              group_by(basin, bay_seg, mo) %>%
#              summarise(tot_rca = sum(rca, na.rm = TRUE), .groups = 'drop')
#
# landsoil <- landsoil2 %>%
#              left_join(tot_rca, by = c("bay_seg", "basin", "mo")) %>%
#              tidyr::expand_grid(yr = 2021:2023)
#
# pflow1 <- flowhat %>%
#            left_join(landsoil, by = c("yr", "mo", "bay_seg", "basin")) %>%
#            mutate(flow = ifelse(is.na(flow), flowhat, flow)) %>%
#            mutate(pflow = case_when(basin %in% c("02299950", "02300500", "02300700", "02301500",
#                                                  "02301750", "02304500", "02306647", "02307000",
#                                                  "EVERSRES", "LMANATEE", "LTARPON", "TBYPASS",
#                                                  "02307359") ~ ((rca/tot_rca)*flow),
#                                     basin %in% c("02300530", "02301695", "202-7", "203-3", "204-2",
#                                                  "205-2", "206-1", "206-2", "206-3C", "206-3E", "206-3W",
#                                                  "206-4", "206-5", "206-6", "207-5") ~ ((rca/tot_rca)*flowhat),
#                           TRUE ~ NA))
#
# pflow <- pflow1 %>%
#            group_by(yr, mo, bay_seg, basin, clucsid, bas_area) %>%
#            summarise(pflow = sum(pflow, na.rm = TRUE),
#                      area = sum(area, na.rm = TRUE)) %>%
#            select(yr, mo, bay_seg, basin, clucsid, pflow, area, bas_area)
#
# npspol <- haven::read_sas("./data-raw/JEI_PRIOR/npspol3.sas7bdat") %>%
#           rename(clucsid = CLUCSID,
#                  mean_tn = MEAN_TN,
#                  mean_tp = MEAN_TP,
#                  mean_tss = MEAN_TSS,
#                  mean_bod = BOD) %>%
#           mutate(sm_tn = case_when(clucsid %in% c(18, 20) ~ 0,
#                                    TRUE ~ mean_tn),
#                  sm_tp = case_when(clucsid %in% c(18, 20) ~ 0,
#                                    TRUE ~ mean_tp),
#                  sm_tss =case_when(clucsid %in% c(18, 20) ~ 0,
#                                    TRUE ~ mean_tss)) %>%
#           select(clucsid, mean_tn, mean_tp, mean_tss, mean_bod, sm_tn, sm_tp, sm_tss)
#
# nps1 <- pflow %>%
#          left_join(npspol, by = "clucsid") %>%
#          mutate(h2oload = pflow * bas_area * 10000,
#                 tnload = mean_tn * 1000 * h2oload * 0.001 * 0.001,
#                 tpload = mean_tp * 1000 * h2oload * 0.001 * 0.001,
#                 tssload = mean_tss * 1000 * h2oload * 0.001 * 0.001,
#                 bodload = mean_bod * 1000 * h2oload * 0.001 * 0.001,
#                 stnload = sm_tn * 1000 * h2oload * 0.001 * 0.001,
#                 stpload = sm_tp * 1000 * h2oload * 0.001 * 0.001,
#                 stssload = sm_tss * 1000 * h2oload * 0.001 * 0.001) %>%
#          group_by(bay_seg, basin, yr, mo, clucsid) %>%
#          summarise(h2oload = sum(h2oload, na.rm=TRUE),
#                    tnload = sum(tnload, na.rm=TRUE),
#                    tpload = sum(tpload, na.rm=TRUE),
#                    tssload = sum(tssload, na.rm=TRUE),
#                    stnload = sum(stnload, na.rm=TRUE),
#                    stpload = sum(stpload, na.rm=TRUE),
#                    stssload = sum(stssload, na.rm=TRUE),
#                    bodload = sum(bodload, na.rm=TRUE),
#                    area = sum(area, na.rm=TRUE),
#                    bas_area = first(bas_area))
#
# obsloads <- readRDS("./data/nps_gaged_loads_2021-2023.rds") %>% #Saved from nps_load_Q+WQ_calc.R script
#               mutate(oh2oload = h2oload,
#                      otnload = tnload,
#                      otpload = tpload,
#                      otssload = tssload,
#                      obodload = bodload) %>%
#               select(basin, yr, mo, oh2oload, otnload, otpload, otssload, obodload)
#
# #Acquire and read-in Verna NTN atmospheric deposition concentration data over the period of interest from: https://nadp.slh.wisc.edu/sites/ntn-FL41/
# verna <- read.csv(file = "./data-raw/NADP/NTN-fl41-m-s-mgl.csv") %>%
#            mutate(across(everything(),  ~ case_when(.x >=0 ~ .x))) %>%
#            mutate(mo = month(seas),
#                   date = as.yearmon(paste(yr, mo), "%Y %m"),
#                   nh4 = NH4,
#                   no3 = NO3) %>%
#            mutate(nh4 = nh4*0.78,   #NADP data are reported as mg NO3 and mg NH4, this corrects for % of ions that is N;
#                   no3 = no3*0.23,
#                   TNConc = nh4+no3,
#                   TPConc = 0.01262*TNConc+0.00110) %>%  #from regression relationship between TBADS TN and TP, applied to Verna; #JEI methods set to static 0.195 mg/L under NPS steps?
#            group_by(yr, mo) %>%
#            select(date, yr, mo, TNConc, TPConc) %>%
#            arrange(date, yr, mo, TNConc, TPConc)
#
# fill_TNConc_with_5yr_avg <- function(data) {
#   data %>%
#     mutate(date = date, year = year(date), month = month(date)) %>%
#     group_by(month, year_group = cut(year, breaks = seq(min(year), max(year), by = 5), labels = FALSE)) %>%
#     mutate(five_year_avg = ifelse(is.na(TNConc), mean(TNConc, na.rm = TRUE), TNConc)) %>%
#     ungroup() %>%
#     select(-year_group) %>%
#     arrange(date) %>%
#     mutate(TNConc = ifelse(is.na(TNConc), lag(five_year_avg, n = which.max(!is.na(TNConc))), TNConc))
# }
#
# fill_TPConc_with_5yr_avg <- function(data) {
#   data %>%
#     mutate(date = date, year = year(date), month = month(date)) %>%
#     group_by(month, year_group = cut(year, breaks = seq(min(year), max(year), by = 5), labels = FALSE)) %>%
#     mutate(five_year_avg = ifelse(is.na(TPConc), mean(TPConc, na.rm = TRUE), TPConc)) %>%
#     ungroup() %>%
#     select(-year_group) %>%
#     arrange(date) %>%
#     mutate(TPConc = ifelse(is.na(TPConc), lag(five_year_avg, n = which.max(!is.na(TPConc))), TPConc))
# }
#
#
# verna_filled1 <- fill_TNConc_with_5yr_avg(verna)
# verna_filled <- fill_TPConc_with_5yr_avg(verna_filled1) %>%
#                 rename(tn_ppt = TNConc,
#                        tp_ppt = TPConc) %>%
#                 select(yr, mo, tn_ppt, tp_ppt)
# nps2 <- nps1 %>%
#         left_join(verna_filled, by = c("yr", "mo")) %>%
#         mutate(tnload_a = tnload,
#               tnload_b = tnload,
#               tpload_a = tpload,
#               tpload_b = tpload,
#               h2oload2 = h2oload * 1000) %>%
#        mutate(tnload_a = case_when(clucsid %in% c(18, 20) ~ 0,
#                                    TRUE ~ tnload_a),
#               tnload_b = case_when(clucsid %in% c(18, 20) ~ h2oload2 * tn_ppt * 3.04 * 0.001 * 0.001,
#                                    TRUE ~ tnload_b),
#               tpload_a = case_when(clucsid %in% c(18, 20) ~ 0,
#                                    TRUE ~ tpload_a),
#               tpload_b = case_when(clucsid %in% c(18, 20) ~ h2oload2 * tp_ppt * 3.04 * 0.001 * 0.001,
#                                    TRUE ~ tpload_b)) %>%
#        group_by(yr, mo, bay_seg, basin) %>%
#        summarise(h2oload = sum(h2oload, na.rm=TRUE),
#                  tnload = sum(tnload, na.rm=TRUE),
#                  tpload = sum(tpload, na.rm=TRUE),
#                  tssload = sum(tssload, na.rm=TRUE),
#                  bodload = sum(bodload, na.rm=TRUE),
#                  tnload_a = sum(tnload_a, na.rm = TRUE),
#                  tnload_b = sum(tnload_b, na.rm = TRUE),
#                  tpload_a = sum(tpload_a, na.rm = TRUE),
#                  tpload_b = sum(tpload_b, na.rm = TRUE),
#                  area = sum(area, na.rm=TRUE),
#                  bas_area = first(bas_area))
# nps <- nps2 %>%
#         filter(!basin %in% c("02303000", "02303330", "02301000", "02301300")) %>% # Remove nested basins
#         mutate(basin = ifelse(basin == "02299950", "LMANATEE", basin)) %>%  # Rename basin
#         group_by(yr, mo, bay_seg, basin) %>%
#         summarise(h2oload = sum(h2oload, na.rm=TRUE),
#                   tnload = sum(tnload, na.rm=TRUE),
#                   tpload = sum(tpload, na.rm=TRUE),
#                   tssload = sum(tssload, na.rm=TRUE),
#                   bodload = sum(bodload, na.rm=TRUE),
#                   tnload_a = sum(tnload_a, na.rm = TRUE),
#                   tnload_b = sum(tnload_b, na.rm = TRUE),
#                   tpload_a = sum(tpload_a, na.rm = TRUE),
#                   tpload_b = sum(tpload_b, na.rm = TRUE),
#                   area = sum(area, na.rm=TRUE),
#                   bas_area = first(bas_area))
# estloads <- nps %>%
#           mutate(eh2oload = h2oload,
#                  etnload = tnload,
#                  etpload = tpload,
#                  etnloada = tnload_a,
#                  etploada = tpload_a,
#                  etnloadb = tnload_b,
#                  etploadb = tpload_b,
#                  etssload = tssload,
#                  ebodload = bodload) %>%
#           select(yr, mo, basin, bay_seg, bas_area,
#                  eh2oload, etnload, etpload, etssload, ebodload,
#                  etnloada, etploada, etnloadb, etploadb)
#
# npsfinal <- estloads %>%
#              full_join(obsloads, by = c("yr", "mo", "basin")) %>%
#              mutate(h2oload = ifelse(is.na(oh2oload), eh2oload, oh2oload),
#                     tnload = ifelse(is.na(otnload), etnload, otnload),
#                     tpload = ifelse(is.na(otpload), etpload, otpload),
#                     tssload = ifelse(is.na(otssload), etssload, otssload),
#                     bodload = ifelse(is.na(obodload), ebodload, obodload),
#                     tnload_a = ifelse(is.na(otnload), etnloada, otnload),
#                     tpload_a = ifelse(is.na(otpload), etploada, otpload),
#                     tnload_b = ifelse(is.na(otnload), etnloadb, otnload),
#                     tpload_b = ifelse(is.na(otpload), etploadb, otpload),
#                     source = "NPS") %>%
#              mutate(segment = case_when(basin %in% c("LTARPON", "02306647", "02307000", "02307359", "206-1") ~ 1,
#                                         basin %in% c("TBYPASS", "02301750", "206-2", "02300700") ~ 2,
#                                         basin %in% c("02301000", "02301300", "02303000", "02303330") ~ 2,
#                                         basin %in% c("02301500", "02301695", "204-2") ~ 2,
#                                         basin %in% c("02304500", "205-2") ~ 2,
#                                         basin %in% c("02300500", "02300530", "203-3") ~ 3,
#                                         basin %in% c("206-3C", "206-3E", "206-3W") ~ 3,
#                                         basin == "206-4" ~ 4,
#                                         basin == "206-5" | basin == "207-5" & bay_seg == 55 ~ 55,
#                                         basin == "207-5" & bay_seg == 5 ~ 5,
#                                         basin == "206-6" ~ 6,
#                                         basin %in% c("EVERSRES", "LMANATEE", "202-7", "02299950") ~ 7,
#                                         TRUE ~ NA),
#                     majbasin = case_when(basin %in% c("LTARPON", "02306647", "02307000", "02307359", "206-1") ~ "Coastal Old Tampa Bay",
#                                          basin %in% c("TBYPASS", "02301750", "206-2", "02300700") ~ "Coastal Hillsborough Bay",
#                                          basin %in% c("02301000", "02301300", "02303000", "02303330") ~ "Error!!!",
#                                          basin %in% c("02301500", "02301695", "204-2") ~ "Alafia River",
#                                          basin %in% c("02304500", "205-2") ~ "Hillsborough River",
#                                          basin %in% c("02300500", "02300530", "203-3") ~ "Little Manatee River",
#                                          basin %in% c("206-3C", "206-3E", "206-3W") ~ "Coastal Middle Tampa Bay",
#                                          basin == "206-4" ~ "Coastal Lower Tampa Bay",
#                                          basin == "206-5" | basin == "207-5" & bay_seg == 55 ~ "Boca Ciega Bay South",
#                                          basin == "207-5" & bay_seg == 5 ~ "Boca Ciega Bay North",
#                                          basin == "206-6" ~ "Terra Ceia Bay",
#                                          basin %in% c("EVERSRES", "LMANATEE", "202-7", "02299950") ~ "Manatee River",
#                                          TRUE ~ NA)) %>%
#                   select(yr, mo, segment, majbasin, bay_seg, basin, bas_area, source,
#                          h2oload, tnload, tpload, tssload, bodload,
#                          tnload_a, tpload_a, tnload_b, tpload_b)
#
# npsmod4 <- npsfinal %>%
#             group_by(yr, mo, bay_seg, basin) %>%
#             summarise(h2oload = sum(h2oload, na.rm=TRUE),
#                       tnload = sum(tnload, na.rm=TRUE),
#                       tpload = sum(tpload, na.rm=TRUE),
#                       tssload = sum(tssload, na.rm=TRUE),
#                       bodload = sum(bodload, na.rm=TRUE),
#                       bas_area = sum(bas_area, na.rm=TRUE),
#                       segment = first(segment),
#                       majbasin = first(majbasin),
#                       source = first(source)) %>%
#             arrange(segment, basin, yr)
#
# tbnpsloads_202x <- npsmod4 %>%
#      saveRDS(file = "./data/nps_loads_2021-2023.rds")
#
# nps_check <- npsmod4 %>%
#               filter(yr == 2021) %>%
#               group_by (segment, mo) %>%
#               summarise(h2oload = sum(h2oload, na.rm=TRUE),
#                         tnload = sum(tnload, na.rm=TRUE),
#                         tpload = sum(tpload, na.rm=TRUE),
#                         tssload = sum(tssload, na.rm=TRUE),
#                         bodload = sum(bodload, na.rm=TRUE),
#                         bas_area = sum(bas_area, na.rm=TRUE),
#                         source = first(source)) %>%
#               write.csv(file = "./data/load_check_2021.csv")
