library(dplyr)
library(haven)
library(usethis)

data(rcclucsid)

# Read RP SAS land cover file. The conservation column (0/1) identifies
# pixels within conservation land boundaries as determined by a spatial
# overlay applied during a prior assessment. Entity names retain
# the original MS4 jurisdiction, so entity-specific fractions can be derived.
# These fractions are unavailable from the tbeploads-built tbbase (updatable
# GIS sources lack that conservation layer), so they are stored here for use
# as a backend correction in anlz_aa().
raw <- haven::read_sas("data-raw/npsag_3_2224_25Sep25.sas7bdat")

rc_lookup <- rcclucsid |>
  rename(hydgrp = hsg) |>
  mutate(rc = (dry_rc * 8 + wet_rc * 4) / 12) |>
  select(clucsid, hydgrp, rc)

prepped <- raw |>
  select(
    bay_seg      = BAY_SEG,
    basin,
    drnfeat      = DRNFEAT,
    entity,
    clucsid      = CLUCSID,
    hydgrp       = hsg,
    area_ha      = area,
    conservation
  ) |>
  filter(drnfeat != "NONCON", !clucsid %in% c(17L, 21L, 22L)) |>
  mutate(
    hydgrp = case_when(
      hydgrp == "A/D" ~ "A",
      hydgrp == "B/D" ~ "B",
      hydgrp == "C/D" ~ "C",
      TRUE            ~ hydgrp
    ),
    basin = case_when(
      basin %in% c("02303000", "02303330") ~ "02304500",
      basin %in% c("02301000", "02301300") ~ "02301500",
      basin == "02299950"                  ~ "LMANATEE",
      TRUE                                 ~ basin
    ),
    bay_seg = if_else(basin == "206-5", 55L, as.integer(bay_seg))
  ) |>
  filter(!basin %in% "02307359") |>
  left_join(rc_lookup, by = c("clucsid", "hydgrp")) |>
  mutate(mult = area_ha * coalesce(rc, 0)) |>
  group_by(bay_seg, basin, entity, clucsid, conservation) |>
  summarise(mult = sum(mult, na.rm = TRUE), .groups = "drop")

# Conservation fraction per bay_seg / basin / entity / clucsid:
#   conserv_frac = conservation area x RC / total entity area x RC.
# Because the SAS file retains the MS4 jurisdiction entity for conservation
# pixels, the fraction is entity-specific (not a basin-level average).
conserv_correction <- prepped |>
  group_by(bay_seg, basin, entity, clucsid) |>
  summarise(
    conserv_mult = sum(mult[conservation == 1L], na.rm = TRUE),
    total_mult   = sum(mult, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(conserv_frac = if_else(total_mult > 0, conserv_mult / total_mult, 0)) |>
  filter(conserv_frac > 0) |>
  select(bay_seg, basin, entity, clucsid, conserv_frac)

usethis::use_data(conserv_correction, overwrite = TRUE)
