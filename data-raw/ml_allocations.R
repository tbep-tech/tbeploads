library(dplyr)
library(usethis)

load("data-raw/entity_facility_alloc.RData")

bayseg_int <- c(OTB = 1L, HB = 2L, MTB = 3L, LTB = 4L, RALTB = 55L)

# Non-shared crosswalk: one allocation row → one output row.
# Entity names in the allocation file differ from the facilities table naming;
# the crosswalk normalises both entity and facname to the facilities convention.
crosswalk_ns <- tibble::tribble(
  ~entity_alloc,                ~facility_alloc,                                         ~entity,           ~facname,
  "CSX",                        "Point Source - Rockport Material Losses",                "CSX",             "Rockport",
  "CSX",                        "Point Source - Newport Material Losses (kfa Eastern)",   "CSX",             "Newport",
  "Kinder Morgan Port Manatee", "Point Source - Material Losses",                        "Kinder Morgan",   "Kinder Morgan Port Manatee"
)

ml_ns <- entity_facility_alloc |>
  dplyr::filter(.data$source == "ML", !.data$ishared,
                !.data$facility %in% c("Point Source - Port Sutton Material Losses",
                                       "Point Source - Tampaplex Material Losses")) |>
  dplyr::rename(
    entity_alloc   = "entity",
    facility_alloc = "facility",
    alloc_tons     = "allocation"
  ) |>
  dplyr::mutate(bay_seg = bayseg_int[.data$bayseg]) |>
  dplyr::left_join(crosswalk_ns, by = c("entity_alloc", "facility_alloc")) |>
  dplyr::mutate(ishared = FALSE) |>
  dplyr::select("entity", "facname", "bay_seg", "alloc_tons", "ishared")

# Shared (Mosaic): three facilities share a single combined allocation.
# Deduplicated to one row because the allocation value is identical for all
# three; during the assessment their loads are summed before comparison.
ml_shared_mosaic <- entity_facility_alloc |>
  dplyr::filter(.data$source == "ML", .data$ishared) |>
  dplyr::distinct(.data$entity, .data$bayseg, .data$allocation) |>
  dplyr::mutate(
    entity     = "Mosaic",
    facname    = NA_character_,
    bay_seg    = bayseg_int[.data$bayseg],
    alloc_tons = .data$allocation,
    ishared    = TRUE
  ) |>
  dplyr::select("entity", "facname", "bay_seg", "alloc_tons", "ishared")

# Shared (Kinder Morgan): Port Sutton and Tampaplex are assessed jointly
# against the sum of their two individual allocations, unlike Kinder Morgan
# Port Manatee (a separate facility assessed on its own).
ml_shared_km <- entity_facility_alloc |>
  dplyr::filter(.data$source == "ML",
                .data$facility %in% c("Point Source - Port Sutton Material Losses",
                                      "Point Source - Tampaplex Material Losses")) |>
  dplyr::summarise(
    entity     = "Kinder Morgan",
    facname    = NA_character_,
    bay_seg    = bayseg_int[unique(.data$bayseg)],
    alloc_tons = sum(.data$allocation),
    ishared    = TRUE
  )

ml_allocations <- dplyr::bind_rows(ml_ns, ml_shared_mosaic, ml_shared_km)

usethis::use_data(ml_allocations, overwrite = TRUE)
