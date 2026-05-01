# Minimal empty-input helpers used across multiple tests
make_nps_empty <- function() {
  data.frame(
    Year = integer(), source = character(), segment = character(),
    basin = character(), tn_load = numeric(), hy_load = numeric()
  )
}

make_ips_empty <- function() {
  data.frame(
    Year = integer(), Month = integer(), entity = character(),
    facility = character(), coastco = character(), tn_load = numeric()
  )
}

# Single-basin NPS data for Old Tampa Bay, basin 206-1 (mean_h2o_9294 = 100.37)
# hy_load is set to mean_h2o_9294 so the normalization ratio equals 1 (eff_tn = tn_entity).
nps_206_1 <- function(tn = 50.0, yr = 2023L) {
  h2o <- hydro_baseline$mean_h2o_9294[
    hydro_baseline$bay_seg == 1 & hydro_baseline$basin == "206-1"
  ]
  data.frame(
    Year = yr, source = "NPS", segment = "Old Tampa Bay",
    basin = "206-1", tn_load = tn, hy_load = h2o
  )
}

# ---- Output structure --------------------------------------------------------

test_that("anlz_aa returns a data frame with expected columns", {
  result <- anlz_aa(2023L, make_nps_empty(), make_ips_empty(), tbbase, aa_corrections)

  expect_s3_class(result, "data.frame")
  expected_cols <- c(
    "bay_seg", "segment", "entity", "entity_full", "facname",
    "permit", "source", "alloc_pct", "alloc_tons", "eff_load_tons", "pass"
  )
  expect_true(all(expected_cols %in% names(result)))
})

test_that("bay_seg is integer and pass is logical", {
  result <- anlz_aa(2023L, make_nps_empty(), make_ips_empty(), tbbase, aa_corrections)

  expect_type(result$bay_seg, "integer")
  expect_type(result$pass, "logical")
})

# ---- Full join: all allocation rows retained ---------------------------------

test_that("every nps_allocations bay_seg+entity key appears in output with empty NPS input", {
  result <- anlz_aa(2023L, make_nps_empty(), make_ips_empty(), tbbase, aa_corrections)

  alloc_keys <- paste(nps_allocations$bay_seg, nps_allocations$entity)
  out_keys   <- paste(result$bay_seg, result$entity)
  expect_true(all(alloc_keys %in% out_keys))
})

test_that("every ps_allocations permit appears in output with empty IPS input", {
  result <- anlz_aa(2023L, make_nps_empty(), make_ips_empty(), tbbase, aa_corrections)

  expect_true(all(ps_allocations$permit %in% result$permit))
})

# ---- pass column logic -------------------------------------------------------

test_that("pass is NA for all rows when no load data is supplied", {
  result <- anlz_aa(2023L, make_nps_empty(), make_ips_empty(), tbbase, aa_corrections)

  expect_true(all(is.na(result$pass)))
})

test_that("pass equals eff_load_tons <= alloc_tons wherever both are non-NA", {
  result <- anlz_aa(2023L, nps_206_1(), make_ips_empty(), tbbase, aa_corrections)

  rows_both <- result[!is.na(result$alloc_tons) & !is.na(result$eff_load_tons), ]
  if (nrow(rows_both) > 0) {
    expect_equal(rows_both$pass, rows_both$eff_load_tons <= rows_both$alloc_tons)
  }
})

# ---- NPS normalization invariant ---------------------------------------------

test_that("entity eff_load_tons sums to tn_load when normalization ratio equals 1", {
  # When hy_load == mean_h2o_9294 the ratio cancels and eff_tn == tn_entity.
  # factor_tn and factor_rc both sum to 1, so summed entity loads equal basin tn_load.
  result <- anlz_aa(2023L, nps_206_1(tn = 50.0), make_ips_empty(), tbbase, aa_corrections)

  nps_seg1_loaded <- result[result$bay_seg == 1 & !is.na(result$eff_load_tons), ]
  expect_equal(sum(nps_seg1_loaded$eff_load_tons), 50.0, tolerance = 1e-6)
})

# ---- Corrections reduce effective load ---------------------------------------

test_that("ad_tons correction reduces CLEARWATER eff_load_tons", {
  base_result <- anlz_aa(2023L, nps_206_1(), make_ips_empty(), tbbase, aa_corrections)

  corr <- data.frame(
    bay_seg = 1L, entity = "CLEARWATER",
    ad_tons = 5.0, project_tons = 0.0
  )
  corr_result <- anlz_aa(2023L, nps_206_1(), make_ips_empty(), tbbase, corr)

  cw_base <- base_result$eff_load_tons[
    base_result$entity == "CLEARWATER" & base_result$bay_seg == 1
  ]
  cw_corr <- corr_result$eff_load_tons[
    corr_result$entity == "CLEARWATER" & corr_result$bay_seg == 1
  ]

  expect_false(is.na(cw_base))
  expect_false(is.na(cw_corr))
  expect_true(cw_corr < cw_base)
})

# ---- Year range filtering ----------------------------------------------------

test_that("loads outside yrrng do not contribute to the average eff_load_tons", {
  # Supply two years with different tn_load: 2022 = 50, 2023 = 100.
  # Filtering to 2022 only should yield a smaller eff_load_tons than averaging 2022:2023.
  nps_two <- rbind(nps_206_1(tn = 50.0, yr = 2022L),
                   nps_206_1(tn = 100.0, yr = 2023L))

  result_2022 <- anlz_aa(2022L, nps_two, make_ips_empty(), tbbase, aa_corrections)
  result_both <- anlz_aa(2022:2023, nps_two, make_ips_empty(), tbbase, aa_corrections)

  cw_2022 <- result_2022$eff_load_tons[
    result_2022$entity == "CLEARWATER" & result_2022$bay_seg == 1
  ]
  cw_both <- result_both$eff_load_tons[
    result_both$entity == "CLEARWATER" & result_both$bay_seg == 1
  ]

  expect_false(is.na(cw_2022))
  expect_false(is.na(cw_both))
  # Two-year avg (tn = 75) should be larger than single-year avg (tn = 50)
  expect_true(cw_2022 < cw_both)
})

# ---- IPS path ----------------------------------------------------------------

test_that("IPS rows all carry source equal to IPS", {
  result <- anlz_aa(2020L, make_nps_empty(), ips, tbbase, aa_corrections)

  ips_rows <- result[!is.na(result$source) & result$source == "IPS", ]
  expect_true(nrow(ips_rows) > 0)
  expect_true(all(ips_rows$source == "IPS"))
})

test_that("IPS eff_load_tons is finite and positive when NPS water data covers the matching basin", {
  # Busch Gardens (bay_seg=2, basin=02304500, permit=FL0185833) needs NPS water
  # for basin 02304500 in bay_seg=2 so nps_h2o is non-NA for its normalization.
  nps_hb <- data.frame(
    Year = 2020L, source = "NPS", segment = "Hillsborough Bay",
    basin = "02304500", tn_load = 100.0, hy_load = 200.0
  )

  result <- anlz_aa(2020L, nps_hb, ips, tbbase, aa_corrections)

  bg <- result[!is.na(result$facname) & result$facname == "Busch Gardens", ]
  expect_true(nrow(bg) >= 1)
  expect_true(is.finite(bg$eff_load_tons[1]))
  expect_true(bg$eff_load_tons[1] > 0)
})
