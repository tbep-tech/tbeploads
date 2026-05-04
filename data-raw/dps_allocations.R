library(dplyr)
library(usethis)

load("data-raw/entity_facility_alloc.RData")

# Bay segment code → integer (bayseg 6 and 7 both become 55, matching the
# remapping applied throughout the allocation assessment).
bayseg_int <- c(OTB = 1L, HB = 2L, MTB = 3L, LTB = 4L, RALTB = 55L)

# Crosswalk maps each unique (entity_full, facility_desc) allocation key to the
# entity short name and facname conventions used in the facilities table.
# bay_seg is derived from the allocation bayseg code above, not stored here.
#
# City of St. Petersburg has three allocation rows sharing the same
# entity+facility description but different bayseg values (OTB, MTB, RALTB);
# a single crosswalk entry correctly expands to three output rows via the join.
#
# TECO Big Bend and Tropicana are excluded: TECO is an industrial reuse
# customer, and Tropicana is classified as industrial in the facilities table.
# Neither has matching rows in the DPS facilities dataset.

crosswalk <- tibble::tribble(
  ~entity_alloc,            ~facility_alloc,                                ~entity,              ~facname,
  "City of Bradenton",      "Point Source - Bradenton SW",                  "Bradenton",           "City of Bradenton WRF",
  "City of Bradenton",      "Point Source - Bradenton RE",                  "Bradenton",           "City of Bradenton WRF",
  "City of Clearwater",     "Point Source - Clearwater East SW",            "Clearwater",          "City of Clearwater East AWWTF",
  "City of Clearwater",     "Point Source - Clearwater Northeast SW",       "Clearwater",          "City of Clearwater Northeast AWWTF",
  "City of Clearwater",     "Point Source - Clearwater East RE",            "Clearwater",          "City of Clearwater East AWWTF",
  "City of Clearwater",     "Point Source - Clearwater Northeast RE",       "Clearwater",          "City of Clearwater Northeast AWWTF",
  "City of Lakeland",       "Point Source - Lakeland SW",                   "Lakeland",            "City of Lakeland",
  "City of Lakeland",       "Point Source - Lakeland RE",                   "Lakeland",            "City of Lakeland",
  "City of Largo",          "Point Source - Largo SW",                      "Largo",               "City of Largo",
  "City of Largo",          "Point Source - Largo RE",                      "Largo",               "City of Largo",
  "City of Mulberry",       "Point Source - Mulberry SW",                   "Mulberry",            "City of Mulberry",
  "City of Oldsmar",        "Point Source - Oldsmar SW",                    "Oldsmar",             "City of Oldsmar WRF",
  "City of Oldsmar",        "Point Source - Oldsmar  RE",                   "Oldsmar",             "City of Oldsmar WRF",
  "City of Palmetto",       "Point Source - Palmetto SW",                   "Palmetto",            "City of Palmetto WWTF",
  "City of Palmetto",       "Point Source - Palmetto RE",                   "Palmetto",            "City of Palmetto WWTF",
  "City of Plant City",     "Point Source - Plant City SW",                 "Plant City",          "Plant City WRF",
  "City of Plant City",     "Point Source - Plant City RE",                 "Plant City",          "Plant City WRF",
  "City of St. Petersburg", "Point Source - St. Pete Facilities RE",        "St. Petersburg",      "St Pete Facilities",
  "City of Tampa",          "Point Source - HF Curren SW",                  "Tampa",               "Howard F. Curren",
  "City of Tampa",          "Point Soruce - HF Curren RE",                  "Tampa",               "Howard F. Curren",
  "City of Zephyrhills",    "Point Source - Zephyrhills RE",                "Zephyrhills",         "City of Zephyrhills WWTF",
  "Hillsborough County",    "Point Source - Falkenburg SW",                 "Hillsborough Co.",    "Falkenburg AWTP",
  "Hillsborough County",    "Point Source - Pebble Creek SW",               "Hillsborough Co.",    "Pebble Creek AWTP",
  "Hillsborough County",    "Point Source - South County SW",               "Hillsborough Co.",    "South County Regional WWTP",
  "Hillsborough County",    "Point Source - Valrico SW",                    "Hillsborough Co.",    "Valrico AWTP",
  "Hillsborough County",    "Point Source - Falkenburg RE",                 "Hillsborough Co.",    "Falkenburg AWTP",
  "Hillsborough County",    "Point Source - Pebble Creek RE",               "Hillsborough Co.",    "Pebble Creek AWTP",
  "Hillsborough County",    "Point Source - Valrico RE",                    "Hillsborough Co.",    "Valrico AWTP",
  "Hillsborough County",    "Point Source - South County RE",               "Hillsborough Co.",    "South County Regional WWTP",
  "Hillsborough County",    "Point Source - Dale Mabry SW",                 "Hillsborough Co.",    "Dale Mabry AWTP",
  "Hillsborough County",    "Point Source - Northwest Regional SW",         "Hillsborough Co.",    "Northwest Regional WRF",
  "Hillsborough County",    "Point Source - River Oaks SW",                 "Hillsborough Co.",    "River Oaks AWWTP",
  "Hillsborough County",    "Point Source - Dale Mabry RE",                 "Hillsborough Co.",    "Dale Mabry AWTP",
  "Hillsborough County",    "Point Source - Northwest Regional RE",         "Hillsborough Co.",    "Northwest Regional WRF",
  "Hillsborough County",    "Point Source - River Oaks RE",                 "Hillsborough Co.",    "River Oaks AWWTP",
  "Hillsborough County",    "Point Source - Van Dyke RE",                   "Hillsborough Co.",    "Van Dyke WWTP",
  "MacDill Air Force Base", "Point Source - MacDill AFB RE",                "MacDill",             "MacDill AFB WWTP",
  "Manatee County",         "Point Source - Manatee County North SW",       "Manatee Co.",         "Manatee County North WRF",
  "Manatee County",         "Point Source - Manatee County North RE",       "Manatee Co.",         "Manatee County North WRF",
  "Manatee County",         "Point Source - Southeast RE",                  "Manatee Co.",         "Manatee County Southeast WRF",
  "On Top of the World",    "Point Source - OTOTW RE",                      "On Top Of The World", "On Top Of The World WWTP",
  "Pasco County",           "Point Source - Master Reuse System RE",        "Pasco Co.",           "Pasco Reuse",
  "Pinellas County",        "Point Source - Bridgeway Acres SW",            "Pinellas Co.",        "Bridgeway Acres",
  "Pinellas County",        "Point Source - W.E. Dunn RE",                  "Pinellas Co.",        "William E. Dunn WRF (Pinellas NW)",
  "Polk County",            "Point Source - Northwest Regional RE",         "Polk Co.",            "NW Regional WWTP",
  "Polk County",            "Point Source - Southwest Regional RE",         "Polk Co.",            "Southwest Regional WWTF"
)

dps_allocations <- entity_facility_alloc |>
  dplyr::filter(grepl("^DPS", .data$source)) |>
  dplyr::rename(
    entity_alloc   = "entity",
    facility_alloc = "facility",
    alloc_tons     = "allocation"
  ) |>
  dplyr::mutate(bay_seg = bayseg_int[.data$bayseg]) |>
  dplyr::left_join(crosswalk, by = c("entity_alloc", "facility_alloc")) |>
  dplyr::filter(!is.na(.data$entity)) |>
  dplyr::rename(entity_full = "entity_alloc") |>
  dplyr::select(
    "entity", "entity_full", "facname", "bay_seg", "source", "alloc_tons"
  )

usethis::use_data(dps_allocations, overwrite = TRUE)
