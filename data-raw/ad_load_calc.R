
library(tidyverse)

# Placeholder section to improve future AD calculations by utilizing any active
# rainfall stations within TB region over the time period of interest, you would then:
# 1) pass these stations to the NCDC function to get daily data (to sum to monthly totals)
# 2) still need to identify and assign UTM coordinates to these "new" stations
# 3) find the invdist2 value to each segment grid point in the targetxy dataframe using the loop starting on line 98

data(ad_rain)
data(ad_distance)

tb_mo_rain <- ad_rain |>
              group_by(station, Year, Month) |>
              summarise(tpcp_in = sum(rainfall), n=n())

tb_mo_rain_2022 <- tb_mo_rain |>
                     filter(Year == 2022)

# Merge distance and precipitation datasets
all_data <- merge(ad_distance, tb_mo_rain, by.x = "matchsit", by.y = "station")

# Sort the data frame by specified columns
all <- all_data[order(all_data$target, all_data$targ_x, all_data$targ_y, all_data$Year, all_data$Month), ]

# Calculate weighted mean of 'tpcp_in' using 'invdist2' as weight
db <- all |>
  group_by(target, targ_x, targ_y, Year, Month) |>
  summarise(tpcp = weighted.mean(tpcp_in, w = invdist2, na.rm = T), .groups = "drop")

# Compute average rainfall at all grid points
db2 <- db |>
  group_by(target, Year, Month) |>
  summarise(tpcp = mean(tpcp), .groups = "drop") |>
  filter(Year >= 2021) |>
  rename(segment = target)

trdb <- db2 |>
  pivot_wider(names_from = c(Year,Month), values_from = tpcp, names_sort = TRUE) |>
  rowwise() |>
  mutate(annual_2021 = sum(across("2021_1":"2021_12"), na.rm = T),
         annual_2022 = sum(across("2022_1":"2022_12"), na.rm = T),
         annual_2023 = sum(across("2023_1":"2023_12"), na.rm = T),)

rain <- db2 |>
          mutate(area = case_when(segment == 1 ~ 23407.05,
                                  segment == 2 ~ 10778.41,
                                  segment == 3 ~ 29159.64,
                                  segment == 4 ~ 24836.54,
                                  segment == 5 ~ 9121.87,
                                  segment == 6 ~ 1619.89,
                                  segment == 7 ~ 4153.22,
                                  TRUE ~ NA)) |>
          mutate(h2oload = (tpcp*10000*area/39.37),
                 source = "Atmospheric Deposition")

#Acquire and read-in Verna NTN atmospheric deposition concentration data over the period of interest from: https://nadp.slh.wisc.edu/sites/ntn-FL41/
vernafl <- list.files(system.file('extdata/', package = 'tbeploads'),
  pattern = 'verna-raw', full.names = TRUE)
verna <- util_ad_prepverna(vernafl)

load <- left_join(rain, verna, by = c("Year", "Month")) |>
          mutate(tnwet = TNConc*h2oload/1000,
                 tpwet = TPConc*h2oload/1000) |>
          mutate(tndry = case_when(Month<=6 ~ tnwet*1.05,
                                   Month>=11 ~ tnwet*1.05,
                                   Month >= 7 & Month <= 10 ~ tnwet*0.66,
                                   TRUE ~ NA),
                 tpdry = case_when(Month<=6 ~ tpwet*1.05,
                                   Month>=11 ~ tpwet*1.05,
                                   Month >= 7 & Month <= 10 ~ tpwet*0.66,
                                   TRUE ~ NA)) |>
          mutate(tntot = tnwet+tndry,
                 tptot = tpwet+tpdry)

annual_load <- load |>
               group_by(segment, Year) |>
               summarise(tntot = sum(tntot, na.rm = T),
                         tptot = sum(tptot, na.rm = T),
                         sum_h2oload = sum(h2oload)) |>
               mutate(tntons = tntot*0.0011023113,
                      tptons = tptot*0.0011023113,
                      source = "Atmospheric Deposition")
