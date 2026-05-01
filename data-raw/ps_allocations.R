library(dplyr)
library(readr)
library(usethis)

ps_allocations <- read_csv(
  "data-raw/PS_Allocations_20160701.csv",
  show_col_types = FALSE
) |>
  rename(
    entity     = Entity,
    facname    = Source,
    permit     = permit_no,
    alloc_pct  = ALLOC_PCT,
    alloc_tons = aLLOC_TONS
  ) |>
  mutate(
    alloc_pct = as.numeric(gsub("%", "", alloc_pct)) / 100,
    # Yara permit was transferred to Mosaic (Black Point) in 2022
    entity  = if_else(entity == "Yara North America", "Mosaic", entity),
    facname = if_else(
      facname == "Point Source - Yara North America",
      "Point Source - Black Point", facname
    )
  ) |>
  select(entity, facname, permit, alloc_pct, alloc_tons)

usethis::use_data(ps_allocations, overwrite = TRUE)
