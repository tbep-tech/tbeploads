library(dplyr)
library(readr)
library(usethis)

nps_allocations <- read_csv(
  "data-raw/Alloc_Loads.csv",
  show_col_types = FALSE
) |>
  rename(
    entity_full = entity1,
    alloc_tons  = alloc_tn_tons
  ) |>
  mutate(
    alloc_pct = as.numeric(gsub("%", "", alloc_pct)) / 100,
    bay_seg   = as.integer(bay_seg)
  ) |>
  select(bay_seg, entity, entity_full, type, alloc_pct, alloc_tons)

usethis::use_data(nps_allocations, overwrite = TRUE)
