# library(haven)
# library(readxl)
# library(tidyverse)
# library(rnoaa)
# library(tbeptools)
# library(zoo)
# library(foreign)
#
# noaa_key <- Sys.getenv('NOAA_KEY')
#
# ltoc_results <- list()  # list as storage variable for the loop results
# i <- 1              # indexing variable
#
# usgsid <-       c("02307498")
# usgs <- data.frame(usgsid)
#
# for(sid in unique(usgs$usgsid)) {         # Each station in your usgsid dataframe
#   data <- dataRetrieval::readNWISdv(sid, "00060", "1985-01-01", "2023-12-31") %>%
#     dataRetrieval::renameNWISColumns()
#
#   ltoc_results[[i]] <- data # store it
#   i <- i + 1 # rinse and repeat
# }
#
# ltoc_flow <- do.call(rbind, ltoc_results) %>%
#   dplyr::mutate(date = date(Date), flow_cfs = Flow) %>%
#   dplyr::select(site_no, date, flow_cfs)
#
# ltoc_flow_corrected <- ltoc_flow %>%
#   select(site_no, date, flow_cfs) %>%
#   complete(date, nesting(site_no), fill = list(flow_cfs = NA)) %>%     # Fill in missing dates, if any
#   arrange(site_no, date) %>%
#   mutate(flow_cfs = zoo::na.approx(flow_cfs), .by = site_no) %>%       # Linear interpolate missing daily values
#   mutate(basin = case_when(site_no == "02307498" ~ "LTARPON",
#                            TRUE ~ site_no),
#          yr = year(date),
#          mo = month(date)) %>%
#   select(basin, date, yr, mo, flow_cfs)
#
# check_plots <- ltoc_flow_corrected %>%
#   ggplot(aes(x = date, y = flow_cfs)) +
#   geom_line() +
#   facet_wrap(~ basin, scales = "free")
#
# check_plots
#
# ltoc_flow_monthly_means <- ltoc_flow_corrected %>%
#   group_by(basin, yr, mo) %>%
#   summarise(flow_cfs = mean(flow_cfs))
#
# # Pinellas County data obtained directly from FDEP WIN (Station 06-06).Alternatively, data can be downloaded from USF Water Atlas.
# wq_pin <- read.table(file = "./data-raw/PIN_CO/FDEP_WIN_WAVES_06-06_WQData_1985-2023.txt", skip = 6, header = T, sep = "|") %>%
#   filter(DEP.Analyte.Name %in% c("Nitrate-Nitrite (N)", "Nitrogen- Total Kjeldahl", "Phosphorus- Total", "Residues- Nonfilterable (TSS)")) %>%
#   select(Monitoring.Location.ID, Activity.Start.Date.Time, DEP.Analyte.Name, DEP.Result.Value.Number) %>%
#   group_by(Monitoring.Location.ID, Activity.Start.Date.Time) %>%
#   spread(key = DEP.Analyte.Name, value = DEP.Result.Value.Number) %>%
#   rename(station = Monitoring.Location.ID,
#          nox_mgl = "Nitrate-Nitrite (N)",
#          tkn_mgl = "Nitrogen- Total Kjeldahl",
#          tp_mgl = "Phosphorus- Total",
#          tss_mgl = "Residues- Nonfilterable (TSS)") %>%
#   ungroup() %>%
#   mutate(date = date(lubridate::mdy_hms(Activity.Start.Date.Time)),
#          tn_mgl = tkn_mgl + nox_mgl) %>%
#   select(-Activity.Start.Date.Time) %>%
#   arrange(station, date)
# # End Pinellas County WQ data input
#
# wq_pin <- read_xlsx("./data-raw/USF_WATERATLAS/PC_Lake_Tarpon_DataDownload_1991-2024-02.xlsx") %>%
#           dplyr::filter()
#
#
# ltoc_wq_fldata <- wq_pin %>%
#              mutate(basin = case_when(station == "06-06" ~ "LTARPON",
#                                       TRUE ~ NA),
#                     yr = year(date),
#                     mo = month(date)) %>%
#              full_join(ltoc_flow_monthly_means, by = c("basin", "yr", "mo")) %>%
#              arrange(basin, yr, mo) %>%
#              filter(basin %in% c("LTARPON")) %>%
#              filter(yr >= 2018) %>%
#              mutate(tn_mgl = case_when(yr == 2018 & mo == 1 ~ 0.65,
#                             TRUE ~ tn_mgl),
#                     tp_mgl = case_when(yr == 2018 & mo == 1 ~ 0.05,
#                                        TRUE ~ tp_mgl))
#
# ltoc_wq_fldata_corrected <- ltoc_wq_fldata %>%
#     mutate(tn_mgl = zoo::na.approx(tn_mgl)) %>%    # Linear interpolate missing monthly WQ concentration values
#     mutate(tp_mgl = zoo::na.approx(tp_mgl)) %>%
#     filter(yr<=2023) %>%
#     mutate(flow = flow_cfs * 60 * 60 * 24 * (365/12) * 28.32,
#          h2oload = flow * 0.001,
#          tnload = tn_mgl * flow * 0.001 * 0.001,
#          tpload = tp_mgl * flow * 0.001 * 0.001) %>%
#         # tssload = tss_mgl * flow * 0.001 * 0.001,
#         # bodload = bod_mgl * flow * 0.001 * 0.001)
#     select(basin, yr, mo, station, tp_mgl, tn_mgl, flow_cfs, flow, h2oload, tnload, tpload)
#
#
# old_ltoc_1992_94 <- read_sas("./data-raw/JEI_PRIOR/cnps_1992-94.sas7bdat") %>%
#                     mutate(basin = BASIN,
#                            year = YEAR,
#                            month = MONTH,
#                            tssload = TSSLOAD,
#                            h2oload = H2OLOAD)
# old_ltoc_1995_98 <- read_sas("./data-raw/JEI_PRIOR/npsmod04_1995_1998.sas7bdat") %>%
#                     mutate(basin = BASIN,
#                     year = YEAR,
#                     month = MONTH,
#                     tnload = TNLOAD,
#                     tpload = TPLOAD,
#                     tssload = TSSLOAD,
#                     bodload = BODLOAD,
#                     h2oload = H2OLOAD)
# old_ltoc_1999_03 <- read_sas("./data-raw/JEI_PRIOR/npsmod04_1999-2003_18apr09.sas7bdat")
# old_ltoc_2004_07 <- read_sas("./data-raw/JEI_PRIOR/npsmod04_2004-07_19apr09.sas7bdat") %>%
#                     mutate(BAY_SEG = bay_seg)
# old_ltoc_2008_11 <- read_sas("./data-raw/JEI_PRIOR/npsmod04_2008-11_01dec12.sas7bdat")
# old_ltoc_2012_14 <- read_sas("./data-raw/JEI_PRIOR/npsmod04_2012-14_10mar16.sas7bdat")
# old_ltoc_2015 <- read_sas("./data-raw/JEI_PRIOR/npsmod04_2015_170224.sas7bdat")
# old_ltoc_2016 <- read_sas("./data-raw/JEI_PRIOR/npsmod04_2016_170224.sas7bdat")
# old_ltoc_2017_18 <- read_sas("./data-raw/JEI_PRIOR/npsmod04_2017-18_03mar20.sas7bdat")
# old_ltoc_2019 <- read_sas("./data-raw/JEI_PRIOR/npsmod04_2019_24sep20.sas7bdat")
# old_ltoc_2020 <- read_sas("./data-raw/JEI_PRIOR/npsmod04_2020_09sep21.sas7bdat")
# old_ltoc_2021 <- read_sas("./data-raw/JEI_PRIOR/npsmod04_2021_26oct22.sas7bdat")
#
# old_ltoc <- dplyr::bind_rows(old_ltoc_1992_94, old_ltoc_1995_98, old_ltoc_1999_03, old_ltoc_2004_07, old_ltoc_2008_11, old_ltoc_2012_14,
#                              old_ltoc_2015, old_ltoc_2016, old_ltoc_2017_18, old_ltoc_2019, old_ltoc_2020, old_ltoc_2021) %>%
#             dplyr::filter(basin == "LTARPON") %>%
#             mutate(yr = year, mo = month, jei_h2oload = h2oload, jei_tnload = tnload, jei_tpload = tpload, jei_bodload = BODLOAD, jei_tssload = tssload) %>%
#             select(basin, yr, mo, jei_h2oload, jei_tnload, jei_tpload, jei_bodload, jei_tssload)
#
# ltoc_data <- full_join(old_ltoc, ltoc_wq_fldata_corrected, by = c("basin", "yr", "mo")) #%>%
#              save(ltoc_data, file = "./data/ltoc_loads_1992-2023.Rdata")
#
