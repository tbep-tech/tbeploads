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
# # get combined subwatershed, drainage basin, jurisdiction, land use, and soils data
# data(tblu2023)
# data(tbsoil)
# tbbase <- util_nps_tbbase(tbsubshed, tbjuris, tblu2023, tbsoil, gdal_path = "C:/OSGeo4W/bin", chunk_size = 1000)
#
# # ungaged
# data(tbbase)
# data(rain)
# lakemanpth <- system.file('extdata/nps_extflow_lakemanatee.xlsx', package = 'tbeploads')
# tampabypth <- system.file('extdata/nps_extflow_tampabypass.xlsx', package = 'tbeploads')
# bellshlpth <- system.file('extdata/nps_extflow_bellshoals.xls', package = 'tbeploads')
#
# anlz_nps_ungaged(tbbase, rain, lakemanpth, tampabypth, bellshlpth)

# # gaged
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
