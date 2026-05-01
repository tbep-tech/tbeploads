library(tibble)
library(usethis)

# Placeholder corrections for anlz_aa().
# Two correction types subtracted from entity NPS loads before normalization:
#   ad_tons:      atmospheric deposition falling on entity jurisdiction
#                 (to avoid double-counting loads already captured in anlz_ad())
#   project_tons: permitted project corrections (site-specific, externally supplied)
#
# Both are zero for all entities until populated from their respective sources.
# Populate ad_tons by apportioning anlz_ad() segment loads by entity area fraction.
# Populate project_tons from external permit-specific data files.

aa_corrections <- tibble(
  bay_seg      = integer(0),
  entity       = character(0),
  ad_tons      = numeric(0),
  project_tons = numeric(0)
)

usethis::use_data(aa_corrections, overwrite = TRUE)
