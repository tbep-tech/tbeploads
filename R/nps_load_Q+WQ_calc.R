library(haven)
library(readxl)
library(tidyverse)
library(rnoaa)
library(tbeptools)
library(zoo)

noaa_key <- Sys.getenv('NOAA_KEY')


## This section begins import of daily discharge data for select tributary sites

lman <- read_xlsx("./data-raw/MAN_CO/Daily Discharge 2021-2023.xlsx") %>%
                rename(date = 1, flow_cfs = 2) %>%
                mutate(site_no = "LMANATEE") %>%
                select(site_no, date, flow_cfs)

s160 <- read_xlsx("./data-raw/TBW/TBW Device ID 957 Data (2021-2023).xlsx") %>%
                rename(date = MeasureDateTime) %>%
                mutate(site_no = "TBYPASS",
                       flow_cfs = round(Value*1.53723, digits = 4)) %>%
                select(site_no, date, flow_cfs)

TBW_BellSHWD <- read_xls("./data-raw/SWFWMD_REG/Withdrawal_Pumpage_Report_TBW-AR-BS.xls", sheet = "Pumpage") %>%  #SWFWMD WMIS Pumpage Reports for Permit 11794 OR Optional: You can substitute TBW reported withdrawals for Site 4626 here instead (Cathleen Jonas, cjonas@tampabaywater.org)
                  filter(`DID#` == 1) %>%
                  rename(date = `RECORDED DATE`) %>%
                  mutate(site_no = "02301500",
                         wd_cfs = round(`DAILY AVG`/1000000*1.54723, digits = 4)) %>%
                select(site_no, date, wd_cfs) %>%
                filter(year(date) >= 2021 & year(date) <= 2023)

fl_results <- list()  # list as storage variable for the loop results
i <- 1              # indexing variable

usgsid <-       c("02299950", "02300042", "02300500", "02300700", "02301000",
                  "02301300", "02301500", "02301750", "02303000", "02303330",
                  "02304500", "02306647", "02307000", "02307359", "02307498")
usgs <- data.frame(usgsid)

for(sid in unique(usgs$usgsid)) {         # Each station in your usgsid dataframe
    data <- dataRetrieval::readNWISdv(sid, "00060", "2021-01-01", "2023-12-31") %>%
      dataRetrieval::renameNWISColumns()

    fl_results[[i]] <- data # store it
    i <- i + 1 # rinse and repeat
}

new_flow <- do.call(rbind, fl_results) %>%
              dplyr::mutate(date = date(Date), flow_cfs = Flow) %>%
              dplyr::select(site_no, date, flow_cfs) %>%
              rbind(s160) %>%                                         #Add in S160 (TBW) & Lake Manatee (Man. Co.) flows here
              rbind(lman) %>%
              dplyr::full_join(TBW_BellSHWD, by = c("site_no", "date"))  #Add in TBW AR-Bell Shoals withdrawals here

new_flow_corrected <- new_flow %>%
                       mutate(flow_cfs = case_when(site_no == "02301500" ~ flow_cfs-wd_cfs, # Subtract TBW AR-Bell Shoals withdrawals from site 02301500 flows
                                                 TRUE ~ flow_cfs)) %>%
                       select(site_no, date, flow_cfs) %>%
                       complete(date, nesting(site_no), fill = list(flow_cfs = NA)) %>%     # Fill in missing dates, if any
                       arrange(site_no, date) %>%
                       mutate(flow_cfs = zoo::na.approx(flow_cfs), .by = site_no) %>%       # Linear interpolate missing daily values
                       mutate(basin = case_when(site_no == "02307498" ~ "LTARPON",
                                                site_no == "02300042" ~ "EVERSRES",
                                                TRUE ~ site_no),
                              yr = year(date),
                              mo = month(date)) %>%
                       select(basin, date, yr, mo, flow_cfs)

check_plots <- new_flow_corrected %>%
              ggplot(aes(x = date, y = flow_cfs)) +
                geom_line() +
                facet_wrap(~ basin, scales = "free")
check_plots

flow_monthly_means <- new_flow_corrected %>%
                       group_by(basin, yr, mo) %>%
                       summarise(flow_cfs = mean(flow_cfs))

## End assemble all flow location data


## Begin assembling all County Water Quality monitoring station data

# Manatee County data obtained directly from FDEP WIN (Stations UM2 & ER2). Alternatively, data can be downloaded from USF Water Atlas.

wq_man <- read.table(file = "./data-raw/MAN_CO/FDEP_WIN_WAVES_ER2-UM2_WQData_2021-2023.txt", skip = 6, header = T, sep = "|") %>%
              filter(DEP.Analyte.Name %in% c("Nitrate-Nitrite (N)", "Nitrogen- Total Kjeldahl", "Phosphorus- Total", "Residues- Nonfilterable (TSS)")) %>%
              select(Monitoring.Location.ID, Activity.Start.Date.Time, DEP.Analyte.Name, DEP.Result.Value.Number) %>%
              group_by(Monitoring.Location.ID, Activity.Start.Date.Time) %>%
              spread(key = DEP.Analyte.Name, value = DEP.Result.Value.Number) %>%
              rename(station = Monitoring.Location.ID,
                     nox_mgl = "Nitrate-Nitrite (N)",
                     tkn_mgl = "Nitrogen- Total Kjeldahl",
                     tp_mgl = "Phosphorus- Total",
                     tss_mgl = "Residues- Nonfilterable (TSS)") %>%
              ungroup() %>%
              mutate(date = date(lubridate::mdy_hms(Activity.Start.Date.Time)),
                     tn_mgl = tkn_mgl + nox_mgl) %>%
              select(-Activity.Start.Date.Time, -tkn_mgl, -nox_mgl) %>%
              arrange(station, date)

# End Manatee County WQ data input

# Pinellas County data obtained directly from FDEP WIN (Station 06-06).Alternatively, data can be downloaded from USF Water Atlas.
wq_pin <- read.table(file = "./data-raw/PIN_CO/FDEP_WIN_WAVES_06-06_WQData_2021-2023.txt", skip = 7, header = T, sep = "|") %>%
  filter(DEP.Analyte.Name %in% c("Nitrate-Nitrite (N)", "Nitrogen- Total Kjeldahl", "Phosphorus- Total", "Residues- Nonfilterable (TSS)")) %>%
  select(Monitoring.Location.ID, Activity.Start.Date.Time, DEP.Analyte.Name, DEP.Result.Value.Number) %>%
  group_by(Monitoring.Location.ID, Activity.Start.Date.Time) %>%
  spread(key = DEP.Analyte.Name, value = DEP.Result.Value.Number) %>%
  rename(station = Monitoring.Location.ID,
         nox_mgl = "Nitrate-Nitrite (N)",
         tkn_mgl = "Nitrogen- Total Kjeldahl",
         tp_mgl = "Phosphorus- Total",
         tss_mgl = "Residues- Nonfilterable (TSS)") %>%
  ungroup() %>%
  mutate(date = date(lubridate::mdy_hms(Activity.Start.Date.Time)),
         tn_mgl = tkn_mgl + nox_mgl) %>%
  select(-Activity.Start.Date.Time, -tkn_mgl, -nox_mgl) %>%
  arrange(station, date)

# End Pinellas County WQ data input

# Get EPCHC data through tbeptools

xlsx <- './data-raw/EPCHC/epchc-current.xlsx'
epchc <- read_importepc(xlsx, download_latest = TRUE)

wq_epc <- epchc %>%
           dplyr::mutate(station = as.character(StationNumber),
                        tn_mgl = suppressWarnings(as.numeric(`Total_Nitrogen`)),
                        tp_mgl = suppressWarnings(as.numeric(`Total_Phosphorus`)),
                        tss_mgl = suppressWarnings(as.numeric(`Total_Suspended_Solids`)),
                        bod_mgl = suppressWarnings(as.numeric(`BOD`)),
                        date = lubridate::date(SampleTime),
                        yr = lubridate::year(SampleTime),
                        mo = lubridate::month(SampleTime)
                        ) %>%
            filter(station %in% c(105, 113, 114, 132, 141, 138, 142, 147) & between(yr, 2021, 2023)) %>%
            select(station, date, tn_mgl, tp_mgl, tss_mgl, bod_mgl)

# End EPCHC wq data import

# Put the wq & flow datasets together to calculate the gaged loads where WQ and discharge data coexist
wq_fldata <- bind_rows(wq_epc, wq_pin, wq_man) %>%
             mutate(basin = case_when(station == "06-06" ~ "LTARPON",
                                      station == "105" ~ "02304500",
                                      station == "113" ~ "02300500",
                                      station == "114" ~ "02301500",
                                      station == "132" ~ "02300700",
                                      station == "141" ~ "02307000",
                                      station == "138" ~ "02301750",
                                      station == "142" ~ "02306647",
                                      station == "147" ~ "TBYPASS",
                                      station == "ER2" ~ "EVERSRES",
                                      station == "UM2" ~ "LMANATEE",
                                      TRUE ~ NA),
                    yr = year(date),
                    mo = month(date)) %>%
             select(basin, yr, mo, tn_mgl, tp_mgl, tss_mgl, bod_mgl) %>%
             full_join(flow_monthly_means, by = c("basin", "yr", "mo")) %>%
             arrange(basin, yr, mo) %>%
             filter(basin %in% c("02300500", "02300700", "02301500", "02301750",
                                 "02304500", "02306647", "02307000", "EVERSRES",
                                 "LMANATEE", "LTARPON", "TBYPASS"))

# Create a corrected dataset to interpolate missing WQ values & calculate loads from measured Q and WQ data for 11 gaged basins
wq_fldata_corrected <- wq_fldata %>%
                         mutate(tn_mgl = case_when((basin == "LTARPON" & yr == 2023 & mo == 12) ~ mean(c(0.62, 0.83, 0.9, 0.87, 0.9)),   # Fill in missing end date monthly values with prior 5 year averages
                                                   (basin == "LTARPON" & yr == 2021 & mo == 1) ~ mean(c(0.65, 0.59, 0.84, 0.9, 0.87)),
                                                   (basin == "LMANATEE" & yr == 2023 & mo == 12) ~ mean(c(0.962, 1.216, 1.099, 1.253)),
                                                   (basin == "EVERSRES" & yr == 2023 & mo == 12) ~ mean(c(0.666, 0.778, 0.812, 0.871)),
                                                   TRUE ~ tn_mgl),
                                tp_mgl = case_when((basin == "LTARPON" & yr == 2023 & mo == 12) ~ mean(c(0.04, 0.05, 0.04, 0.05, 0.03)),
                                                   (basin == "LTARPON" & yr == 2021 & mo == 1) ~ mean(c(0.05, 0.03, 0.04, 0.05, 0.04)),
                                                   (basin == "LMANATEE" & yr == 2023 & mo == 12) ~ mean(c(0.472, 0.322, 0.3, 0.48)),
                                                   (basin == "EVERSRES" & yr == 2023 & mo == 12) ~ mean(c(0.432, 0.097, 0.039, 0.072)),
                                                   TRUE ~ tp_mgl),
                                tss_mgl = case_when((basin == "LTARPON" & yr == 2023 & mo == 12) ~ mean(c(2, 2, 2, 3, 3)),
                                                    (basin == "LTARPON" & yr == 2021 & mo == 1) ~ mean(c(3, 2, 3, 3, 3)),
                                                    (basin == "LMANATEE" & yr == 2023 & mo == 12) ~ mean(c(1.8, 1.4, 1.3, 4)),
                                                  (basin == "EVERSRES" & yr == 2023 & mo == 12) ~ mean(c(4, 3.4, 2.8, 4.1)),
                                                  TRUE ~ tss_mgl),
                                bod_mgl = case_when((basin == "LTARPON" & yr == 2023 & mo == 12) ~ mean(c(1, 2.6, 2.9, 3.2, 2.3)),
                                                    TRUE ~ bod_mgl)) %>%
                         mutate(tn_mgl = zoo::na.approx(tn_mgl), .by = basin) %>%    # Linear interpolate missing monthly WQ concentration values
                         mutate(tp_mgl = zoo::na.approx(tp_mgl), .by = basin) %>%
                         mutate(flow = flow_cfs * 60 * 60 * 24 * (365/12) * 28.32,
                                h2oload = flow * 0.001,
                                tnload = tn_mgl * flow * 0.001 * 0.001,
                                tpload = tp_mgl * flow * 0.001 * 0.001,
                                tssload = tss_mgl * flow * 0.001 * 0.001,
                                bodload = bod_mgl * flow * 0.001 * 0.001)

nps_gaged_load <- wq_fldata_corrected #%>%
  save(nps_gaged_load, file = "./data/nps_gaged_loads_2021-2023.Rdata")
