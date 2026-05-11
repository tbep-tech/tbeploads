library(tibble)
library(usethis)

# TN load corrections applied before hydrologic normalization in anlz_aa().
# Values extracted from SAS script 7_Basin_assessment2224.sas, which applies
# two correction types per entity × bay_seg:
#   ad_tons:      atmospheric deposition falling on entity jurisdiction
#   project_tons: net permitted project corrections (negative = load credit)
#
# FDACS (entity "All") entries are irrigation AP reductions only (ad_tons = 0).
# MANATEE bay_seg=55: project_tons is net of 0.882 AP minus 4.03 project credit.
# All bay_seg=55:     project_tons is net of 3.824 AP minus 0.25 project credit.
# ST PETERSBURG bay_seg=55: project_tons sums two separate AP values (1.970 + 0.265).

aa_corrections <- tribble(
  ~bay_seg, ~entity,                         ~ad_tons, ~project_tons,
  # Old Tampa Bay
        1L, "CLEARWATER",                       1.360,         6.150,
        1L, "HILLSBOROUGH",                     8.800,         0.000,
        1L, "LARGO",                            0.510,         0.030,
        1L, "MacDill AFB",                      0.030,         0.000,
        1L, "OLDSMAR",                          0.500,         0.000,
        1L, "PINELLAS",                         5.340,         1.650,
        1L, "PINELLAS PARK",                    0.410,         0.000,
        1L, "SAFETY HARBOR",                    0.500,         0.880,
        1L, "ST PETERSBURG",                    0.450,         0.000,
        1L, "Tampa",                            1.960,         0.110,
        1L, "TARPON SPRINGS",                   0.140,         0.000,
        1L, "All",                              0.000,         0.090,
  # Hillsborough Bay
        2L, "HILLSBOROUGH",                    35.770,         5.380,
        2L, "MacDill AFB",                      0.100,         0.000,
        2L, "Tampa",                            8.120,         0.120,
        2L, "All",                              0.000,         2.170,
  # Middle Tampa Bay
        3L, "HILLSBOROUGH",                     6.130,         0.750,
        3L, "MANATEE",                          2.460,         0.000,
        3L, "MacDill AFB",                      0.900,         0.000,
        3L, "PINELLAS",                         0.630,         1.440,
        3L, "PINELLAS PARK",                    0.710,         0.140,
        3L, "ST PETERSBURG",                    7.170,         5.660,
        3L, "All",                              0.000,         1.510,
  # Lower Tampa Bay
        4L, "HILLSBOROUGH",                     0.010,         0.000,
        4L, "Lexington",                        0.020,         0.000,
        4L, "MANATEE",                          1.350,         0.000,
        4L, "All",                              0.000,         0.250,
  # Remaining Lower Tampa Bay
       55L, "Bradenton",                        1.896,         0.000,
       55L, "Greyhawk Landing",                 0.147,         0.000,
       55L, "HILLSBOROUGH",                     0.005,         0.000,
       55L, "Harbourage at Braden River",       0.004,         0.000,
       55L, "Heritage Harbour",                 0.145,         0.000,
       55L, "Heritage Harbour Marketplace",     0.020,         0.000,
       55L, "Lexington",                        0.036,         0.000,
       55L, "MANATEE",                         25.816,        -3.148,
       55L, "PINELLAS",                         0.276,         0.000,
       55L, "Palmetto",                         0.957,         0.000,
       55L, "ST PETE BEACH",                    0.266,         0.000,
       55L, "ST PETERSBURG",                    0.016,         2.235,
       55L, "GULFPORT",                         0.474,         0.130,
       55L, "Waterlefe",                        0.123,         0.000,
       55L, "All",                              0.000,         3.574
)

usethis::use_data(aa_corrections, overwrite = TRUE)
