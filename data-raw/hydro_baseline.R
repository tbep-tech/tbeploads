library(dplyr)
library(readr)
library(usethis)

# Historic1.csv: 1992-1994 mean total water load (DPS+IPS+NPS) per bay_seg x basin.
# Units: million m3/yr (already divided by 1e6 in SAS step 6).
# mean9294 is repeated for every year row; take distinct non-NA values.

hydro_baseline <- read_csv(
  "data-raw/Historic1.csv",
  show_col_types = FALSE
) |>
  select(bay_seg = BAY_SEG, basin, mean_h2o_9294 = mean9294) |>
  filter(!is.na(mean_h2o_9294)) |>
  distinct() |>
  mutate(bay_seg = as.integer(bay_seg))

usethis::use_data(hydro_baseline, overwrite = TRUE)
