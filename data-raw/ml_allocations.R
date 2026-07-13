library(dplyr)
library(usethis)

load("data-raw/entity_facility_alloc.RData")

bayseg_int <- c(OTB = 1L, HB = 2L, MTB = 3L, LTB = 4L, RALTB = 55L)

# Crosswalk: one entity_facility_alloc row → one output row (always, whether
# shared or not). Entity names in the allocation file differ from the
# facilities table naming; the crosswalk normalises both entity and facname
# to the facilities convention.
#
# Riverview, Tampa Marine, and Big Bend Material Losses (all Mosaic, ishared
# = TRUE in entity_facility_alloc) are jointly assessed against one combined
# allocation; Port Sutton and Tampaplex Material Losses (Kinder Morgan,
# ishared = FALSE) are each assessed on their own distinct allocation,
# confirmed against RP's draft assessment table (prior_assess shows 1.80 and
# 3.38 respectively, not a shared total) despite the misleadingly identical
# facility names to the shared IPS Port Sutton/Tampaplex group.
crosswalk_ns <- tibble::tribble(
  ~entity_alloc,                ~facility_alloc,                                                ~entity,           ~facname,
  "CSX",                        "Point Source - Rockport Material Losses",                       "CSX",             "Rockport",
  "CSX",                        "Point Source - Newport Material Losses (kfa Eastern)",          "CSX",             "Newport",
  "Kinder Morgan Port Manatee", "Point Source - Material Losses",                                "Kinder Morgan",   "Kinder Morgan Port Manatee",
  "Kinder Morgan",              "Point Source - Port Sutton Material Losses",                    "Kinder Morgan",   "Kinder Morgan Port Sutton",
  "Kinder Morgan",              "Point Source - Tampaplex Material Losses",                      "Kinder Morgan",   "Kinder Morgan Tampaplex",
  "Mosaic",                     "Point Source - Riverview Material Losses",                      "Mosaic",          "Riverview",
  "Mosaic",                     "Point Source - Tampa Marine (fka CF) Material Losses",          "Mosaic",          "Tampa Marine",
  "Mosaic",                     "Point Source - Big Bend Material Losses",                       "Mosaic",          "Big Bend"
)

# Collective allocation per shared group (entity + bay_seg), summed from the
# individual per-facility shares in entity_facility_alloc. Confirmed against
# prior_assess: the Mosaic Riverview/Tampa Marine/Big Bend group totals 9.9
# tons/yr (3 x 3.3), not the 3.3 of a single member.
ml_shared_totals <- entity_facility_alloc |>
  dplyr::filter(.data$source == "ML", .data$ishared) |>
  dplyr::mutate(bay_seg = bayseg_int[.data$bayseg]) |>
  dplyr::group_by(.data$entity, .data$bay_seg) |>
  dplyr::summarise(alloc_tons_shared = sum(.data$allocation), .groups = "drop")

ml_allocations <- entity_facility_alloc |>
  dplyr::filter(.data$source == "ML") |>
  dplyr::rename(
    entity_alloc   = "entity",
    facility_alloc = "facility",
    alloc_tons     = "allocation"
  ) |>
  dplyr::mutate(bay_seg = bayseg_int[.data$bayseg]) |>
  dplyr::left_join(crosswalk_ns, by = c("entity_alloc", "facility_alloc")) |>
  dplyr::left_join(ml_shared_totals, by = c("entity", "bay_seg")) |>
  dplyr::mutate(
    alloc_tons = dplyr::if_else(.data$ishared, .data$alloc_tons_shared, .data$alloc_tons)
  ) |>
  dplyr::select("entity", "facname", "bay_seg", "alloc_tons", "ishared")

usethis::use_data(ml_allocations, overwrite = TRUE)
