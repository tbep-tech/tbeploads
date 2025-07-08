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
# # NAD83(2011) / Florida West (ftUS)
# # this is the projection used in original report
# prj <- 6443
#
# # get combined subwatershed, drainage basin, jurisdiction, land use, and soils data
# data(tblu2023)
# data(tbsoil)
# tbbase <- util_nps_tbbase(tbsubshed, tbjuris, tblu2023, tbsoil, gdal_path = "C:/OSGeo4W/bin", chunk_size = 1000)
#
# # get data prepped for logistic regression
# tbnestland <- util_nps_preplog(tbbase)
#
#
# # get inverse weighted distance data from rainfall to sub-bains
# `nps_nestr_2021-2023` <- util_nps_preprain(rain)
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
# # this is from util_nps_landsoilrc
# landsoil <- util_nps_landsoilrc(tbbase)
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
