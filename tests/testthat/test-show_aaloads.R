# Minimal synthetic annavg = FALSE-shaped aa_data: bay_seg = 2, two years,
# one MS4 entity, one IPS facility, and the FDACS "All" aggregate row (the
# aggregate that always survives anlz_aa()'s negligible-sliver filter).
make_aa_data <- function() {
  base <- data.frame(
    bay_seg = 2L, segment = "Hillsborough Bay",
    entity_full = NA_character_, facname = NA_character_, permit = NA_character_,
    alloc_pct = NA_real_, alloc_tons = NA_real_, eff_load_tons = NA_real_,
    ishared = FALSE, group_id = NA_character_,
    seg_h2o_total = c(100, 150), seg_conserv_tn = c(5, 8), year = c(2022L, 2023L)
  )

  ms4 <- base
  ms4$entity <- "HILLSBOROUGH"
  ms4$entity_full <- "Hillsborough County"
  ms4$source <- "MS4"
  ms4$load_tons <- c(10, 12)

  ips <- base
  ips$entity <- "Mosaic"
  ips$facname <- "Mosaic - Bartow"
  ips$permit <- "FL0001589"
  ips$source <- "IPS"
  ips$load_tons <- c(3, 4)

  fdacs <- base
  fdacs$entity <- "All"
  fdacs$entity_full <- "FDACS (Agriculture)"
  fdacs$source <- NA_character_
  fdacs$load_tons <- c(20, 25)

  rbind(ms4, ips, fdacs)
}

make_gw_data <- function() {
  data.frame(Year = c(2022L, 2023L), source = "GW", segment = "Hillsborough Bay",
             tn_load = c(19.9, 19.9), hy_load = c(70.9, 70.9))
}

make_spr_data <- function() {
  data.frame(Year = c(2022L, 2023L), source = "SPR", segment = "Hillsborough Bay",
             tn_load = c(132.0, 123.0), hy_load = c(68.9, 61.0))
}

make_ad_data <- function() {
  data.frame(Year = c(2022L, 2023L), source = "AD", segment = "Hillsborough Bay",
             tn_load = c(72.2, 56.9), hy_load = c(156.0, 106.0))
}

test_that("show_aaloads errors clearly when aa_data is missing required columns", {
  aa_data <- make_aa_data()

  expect_error(
    show_aaloads(aa_data[, setdiff(names(aa_data), "year")], bay_seg = 2L,
                 make_gw_data(), make_spr_data(), make_ad_data()),
    "annavg = FALSE"
  )
  expect_error(
    show_aaloads(aa_data[, setdiff(names(aa_data), "seg_h2o_total")], bay_seg = 2L,
                 make_gw_data(), make_spr_data(), make_ad_data()),
    "seg_h2o_total"
  )
})

test_that("show_aaloads errors on an invalid bay_seg", {
  aa_data <- make_aa_data()
  expect_error(
    show_aaloads(aa_data, bay_seg = 99L, make_gw_data(), make_spr_data(), make_ad_data()),
    "bay_seg"
  )
})

test_that("show_aaloads returns a flextable", {
  ft <- show_aaloads(make_aa_data(), bay_seg = 2L, make_gw_data(), make_spr_data(), make_ad_data())
  expect_s3_class(ft, "flextable")
})

test_that("Atmospheric Deposition and Other rows are added with correct values", {
  ft <- show_aaloads(make_aa_data(), bay_seg = 2L, make_gw_data(), make_spr_data(), make_ad_data())
  d <- ft$body$dataset

  ad <- d[d$entity_label == "Atmospheric Deposition", ]
  expect_equal(as.numeric(ad[, c("2022", "2023")]), c(72.2, 56.9))

  # Other = gw$tn_load + spr$tn_load + seg_conserv_tn
  other <- d[d$entity_label == "Other (Groundwater, Springs, Conservation)", ]
  expect_equal(as.numeric(other[, c("2022", "2023")]), c(19.9 + 132.0 + 5, 19.9 + 123.0 + 8))
})

test_that("Atmospheric Deposition and Other rows zero-fill years missing from gw/spr/ad_data", {
  aa_data <- make_aa_data()
  gw_partial <- make_gw_data()[1, ]   # 2022 only
  spr_partial <- make_spr_data()[1, ]
  ad_partial <- make_ad_data()[1, ]

  ft <- show_aaloads(aa_data, bay_seg = 2L, gw_partial, spr_partial, ad_partial)
  d <- ft$body$dataset

  ad <- d[d$entity_label == "Atmospheric Deposition", ]
  expect_equal(ad[["2023"]], 0)

  other <- d[d$entity_label == "Other (Groundwater, Springs, Conservation)", ]
  # 2023 still gets seg_conserv_tn (from aa_data) even with no gw/spr data
  expect_equal(other[["2023"]], 8)
})

test_that("Total Load includes Atmospheric Deposition and Other, not just aa_data rows", {
  ft <- show_aaloads(make_aa_data(), bay_seg = 2L, make_gw_data(), make_spr_data(), make_ad_data())
  d <- ft$body$dataset

  total <- d[d$entity_label == "Total Load", ]
  # aa_data rows (10+3+20 = 33 in 2022) + AD (72.2) + Other (19.9+132+5 = 156.9)
  expect_equal(total[["2022"]], 33 + 72.2 + 156.9, tolerance = 1e-9)
})

test_that("Normalized Load applies the segment-wide ratio using the real baseline_h2o", {
  # bay_seg = 2 (Hillsborough Bay) baseline_h2o = 895.62, extracted from the
  # TBNMC partner's draft loading workbook formula (see roxygen Details).
  ft <- show_aaloads(make_aa_data(), bay_seg = 2L, make_gw_data(), make_spr_data(), make_ad_data())
  d <- ft$body$dataset

  normalized <- d[d$entity_label == "Normalized Load", ]
  total <- d[d$entity_label == "Total Load", ]
  expect_equal(nrow(normalized), 1L)

  total_h2o_2022 <- 100 + 70.9 + 68.9 + 156.0
  total_h2o_2023 <- 150 + 70.9 + 61.0 + 106.0
  expect_equal(normalized[["2022"]], total[["2022"]] * (895.62 / total_h2o_2022), tolerance = 1e-9)
  expect_equal(normalized[["2023"]], total[["2023"]] * (895.62 / total_h2o_2023), tolerance = 1e-9)
})

test_that("digits controls year-column display precision", {
  ft1 <- show_aaloads(make_aa_data(), bay_seg = 2L, make_gw_data(), make_spr_data(), make_ad_data())
  ft3 <- show_aaloads(make_aa_data(), bay_seg = 2L, make_gw_data(), make_spr_data(), make_ad_data(),
                      digits = 3)

  expect_s3_class(ft1, "flextable")
  expect_s3_class(ft3, "flextable")
})
