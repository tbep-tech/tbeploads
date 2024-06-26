# Verna well field NADP NTN atmospheric deposition concentration data
# https://nadp.slh.wisc.edu/sites/ntn-FL41/
# 2017 to 2022

library(here)
library(dplyr)

verna <- read.csv(file = here("data-raw/NTN-fl41-i-mgl_2017-2022.csv")) %>%
  mutate(mo = seas + 0) %>%
  mutate(
    nh4 = case_when(
      yr == 2022 & mo == 12 ~ mean(c(0.046, 0.063, 0.09, 0.105, 0.173)), # Dec. NH4 mean from 2017-2021 to fill in missing data
      TRUE ~ NH4
    ),
    no3 = case_when(
      yr == 2022 & mo == 12 ~ mean(c(0.194, 0.257, 0.364, 0.327, 1.41)), # Dec. NO3 mean from 2017-2021 to fill in missing data
    TRUE ~ NO3
    ),
    nh4 = nh4 * 0.78, # NADP data are reported as mg NO3 and mg NH4, this corrects for % of ions that is N;
    no3 = no3 * 0.23,
    TNConc = nh4 + no3,
    TPConc = 0.01262 * TNConc + 0.00110 # from regression relationship between TBADS TN and TP, applied to Verna;
  ) %>%
  select(yr, mo, TNConc, TPConc)

usethis::use_data(verna, overwrite = TRUE)
