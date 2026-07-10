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
    ),
    facname = if_else(
      facname == "Rockport  (fka Eastern Terminals)",
      "CSX - Rockport Newport", 
      facname
    ),
    # New Wales Stack Closure (retired, no facilities/ips_data entry) is
    # mis-recorded in the source CSV with the active New Wales Chemical
    # Plant's permit (FL0036421); correct it to its own permit so anlz_aa's
    # permit join doesn't duplicate the active plant's real IPS load onto
    # the closed stack's row
    permit = if_else(
      facname == "Point Source - New Wales Stack Closure",
      "FL0178527", permit
    ),
    # Busch Gardens (FL0185833) is recorded in the source CSV with a 0 ton/yr
    # allocation, predating its official 1 ton/yr allocation set in the 2022
    # RA Update
    alloc_tons = if_else(permit == "FL0185833", 1, alloc_tons),
    # RP's draft TN-loading tables mark these permits (mostly Mosaic mining
    # facilities plus a handful of others) with a "Hydrologically Affected"
    # row label in the Point Sources section; all other IPS facilities (and
    # any facility with no match here) are left unnormalized in anlz_aa()
    hydro_affected = permit %in% c(
      "FL0001589", # Mosaic - Bartow
      "FL0000523", # Mosaic - Bonnie
      "FL0036412", # Mosaic - Four Corners
      "FL0033332", # Mosaic - Ft. Lonesome
      "FL0000752", # Mosaic - Green Bay
      "FL0033294", # Mosaic - Hookers Prairie
      "FL0334944", # Mosaic - Mulberry Phospho Stack
      "FL0000671", # Mosaic - Mulberry Plant
      "FL0036421", # Mosaic - New Wales Chemical Plant
      "FL0030139", # Mosaic - Nichols Mine
      "FL0000078", # Mosaic - Plant City
      "FL0000761", # Mosaic - Riverview
      "FL0177130", # Mosaic - Riverview Stack Closure
      "FL0000370", # Mosaic - South Pierce
      "FL0187313", # Mosaic - Tampa Ammonia Terminal
      "FL0166057", # Mosaic - Tampa Marine Terminal
      "FL0000809", # TECO - Bayside (fka Gannon)
      "FL0000647", # Trademark Nitrogen Corporation
      "FL0029653", # Alpha/Owens Corning
      "FL0132381", # Brewster Phosphogypsum
      "FL0034657", # Coronet Industries
      "FL0160083", # Estech Agricola
      "FL0002666", # Point Source - Exxon Mobil
      "FL0032590", # Point Source - Hopewell
      "FL0000256", # Point Source - Kingsford
      "FL0000299", # Point Source - Nichols Prep Plant (Agrifos)
      "FL0178527", # Point Source - New Wales Stack Closure
      "FL0038652"  # Mosaic - Black Point (fka Yara)
      # Busch Gardens (FL0185833) also carries the "Hydrologically Affected"
      # row label but is intentionally excluded here: per direct confirmation
      # from RP, its 1 ton/yr allocation is a fixed value assessed
      # against the raw (unnormalized) load. A normalized value exists
      # elsewhere as a carryover from an outdated calculation step, but it is
      # not what's actually used for the pass/fail comparison.
    )
  ) |>
  select(entity, facname, permit, alloc_pct, alloc_tons, hydro_affected)

usethis::use_data(ps_allocations, overwrite = TRUE)
