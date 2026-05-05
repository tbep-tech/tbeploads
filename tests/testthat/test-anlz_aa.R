# Minimal empty-input helpers used across multiple tests
make_dps_empty <- function() {
  data.frame(
    Year = integer(), Month = integer(), entity = character(),
    facility = character(), coastco = character(), source = character(),
    tn_load = numeric()
  )
}

make_ips_empty <- function() {
  data.frame(
    Year = integer(), Month = integer(), entity = character(),
    facility = character(), coastco = character(), tn_load = numeric()
  )
}

make_ml_empty <- function() {
  data.frame(
    Year = integer(), Month = integer(), entity = character(),
    facility = character(), tn_load = numeric()
  )
}

# Single ML facility: Kinder Morgan Tampaplex (bay_seg = 2, HB, ishared = FALSE)
ml_tampaplex <- function(tn_tonsyr = 5.0, yr = 2023L) {
  data.frame(
    Year = yr, Month = 1:12, entity = "Kinder Morgan",
    facility = "Kinder Morgan Tampaplex",
    tn_load = tn_tonsyr / 12
  )
}

make_nps_empty <- function() {
  data.frame(
    Year = integer(), source = character(), segment = character(),
    basin = character(), tn_load = numeric(), hy_load = numeric()
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

# Single-facility DPS data for Bradenton SW (coastco = "736", bay_seg = 3, MTB)
dps_bradenton_sw <- function(tn = 20.0, yr = 2023L) {
  coastco <- facilities$coastco[
    facilities$entity == "Bradenton" & grepl("SW", facilities$source)
  ]
  data.frame(
    Year = yr, Month = 1L, entity = "Bradenton",
    facility = "City of Bradenton WRF",
    coastco = coastco[1],
    source = "D-001",
    tn_load = tn
  )
}

# ---- Output structure --------------------------------------------------------

test_that("anlz_aa returns a data frame with expected columns", {
  result <- anlz_aa(2023L, make_dps_empty(), make_ips_empty(), make_ml_empty(), make_nps_empty(), tbbase, aa_corrections)

  expect_s3_class(result, "data.frame")
  expected_cols <- c(
    "bay_seg", "segment", "entity", "entity_full", "facname",
    "permit", "source", "alloc_pct", "alloc_tons", "eff_load_tons", "pass"
  )
  expect_true(all(expected_cols %in% names(result)))
})

test_that("bay_seg is integer and pass is logical", {
  result <- anlz_aa(2023L, make_dps_empty(), make_ips_empty(),  make_ml_empty(), make_nps_empty(), tbbase, aa_corrections)

  expect_type(result$bay_seg, "integer")
  expect_type(result$pass, "logical")
})

# ---- Full join: all allocation rows retained ---------------------------------

test_that("every nps_allocations bay_seg+entity key appears in output with empty NPS input", {
  result <- anlz_aa(2023L, make_dps_empty(), make_ips_empty(), make_ml_empty(), make_nps_empty(), tbbase, aa_corrections)

  alloc_keys <- paste(nps_allocations$bay_seg, nps_allocations$entity)
  out_keys   <- paste(result$bay_seg, result$entity)
  expect_true(all(alloc_keys %in% out_keys))
})

test_that("every ps_allocations permit appears in output with empty IPS input", {
  result <- anlz_aa(2023L, make_dps_empty(), make_ips_empty(), make_ml_empty(), make_nps_empty(), tbbase, aa_corrections)

  expect_true(all(ps_allocations$permit %in% result$permit))
})

test_that("every dps_allocations row appears in output with empty DPS input", {
  result <- anlz_aa(2023L, make_dps_empty(), make_ips_empty(), make_ml_empty(), make_nps_empty(), tbbase, aa_corrections)

  alloc_keys <- paste(dps_allocations$bay_seg, dps_allocations$entity,
                      dps_allocations$facname, dps_allocations$source)
  out_keys   <- paste(result$bay_seg, result$entity, result$facname, result$source)
  expect_true(all(alloc_keys %in% out_keys))
})

# ---- pass column logic -------------------------------------------------------

test_that("pass is NA for all rows when no load data is supplied", {
  result <- anlz_aa(2023L, make_dps_empty(), make_ips_empty(), make_ml_empty(), make_nps_empty(), tbbase, aa_corrections)

  expect_true(all(is.na(result$pass)))
})

test_that("pass equals eff_load_tons <= alloc_tons wherever both are non-NA", {
  result <- anlz_aa(2023L, make_dps_empty(), make_ips_empty(), make_ml_empty(), nps_206_1(), tbbase, aa_corrections)

  rows_both <- result[!is.na(result$alloc_tons) & !is.na(result$eff_load_tons), ]
  if (nrow(rows_both) > 0) {
    expect_equal(rows_both$pass, rows_both$eff_load_tons <= rows_both$alloc_tons)
  }
})

# ---- NPS normalization invariant ---------------------------------------------

test_that("entity eff_load_tons sums to tn_load when normalization ratio equals 1", {
  # When hy_load == mean_h2o_9294 the ratio cancels and eff_tn == tn_entity.
  # factor_tn and factor_rc both sum to 1, so summed entity loads equal basin tn_load.
  result <- anlz_aa(2023L, make_dps_empty(), make_ips_empty(), make_ml_empty(), nps_206_1(tn = 50.0), tbbase, aa_corrections)

  nps_seg1_loaded <- result[result$bay_seg == 1 & !is.na(result$eff_load_tons), ]
  expect_equal(sum(nps_seg1_loaded$eff_load_tons), 50.0, tolerance = 1e-6)
})

# ---- Corrections reduce effective load ---------------------------------------

test_that("ad_tons correction reduces CLEARWATER eff_load_tons", {
  base_result <- anlz_aa(2023L, make_dps_empty(), make_ips_empty(), make_ml_empty(), nps_206_1(), tbbase, aa_corrections)

  corr <- data.frame(
    bay_seg = 1L, entity = "CLEARWATER",
    ad_tons = 5.0, project_tons = 0.0
  )
  corr_result <- anlz_aa(2023L, make_dps_empty(), make_ips_empty(), make_ml_empty(), nps_206_1(), tbbase, corr)

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

  result_2022 <- anlz_aa(2022L, make_dps_empty(), make_ips_empty(), make_ml_empty(), nps_two, tbbase, aa_corrections)
  result_both <- anlz_aa(2022:2023, make_dps_empty(), make_ips_empty(), make_ml_empty(), nps_two, tbbase, aa_corrections)

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
  result <- anlz_aa(2020L, make_dps_empty(), ips, make_ml_empty(), make_nps_empty(), tbbase, aa_corrections)

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

  result <- anlz_aa(2020L, make_dps_empty(), ips, make_ml_empty(), nps_hb, tbbase, aa_corrections)

  bg <- result[!is.na(result$facname) & result$facname == "Busch Gardens", ]
  expect_true(nrow(bg) >= 1)
  expect_true(is.finite(bg$eff_load_tons[1]))
  expect_true(bg$eff_load_tons[1] > 0)
})

# ---- DPS path ----------------------------------------------------------------

test_that("DPS rows carry source of DPS - end of pipe or DPS - reuse", {
  result <- anlz_aa(2023L, make_dps_empty(), make_ips_empty(), make_ml_empty(), make_nps_empty(), tbbase, aa_corrections)

  dps_rows <- result[!is.na(result$source) & grepl("^DPS", result$source), ]
  expect_true(nrow(dps_rows) > 0)
  expect_true(all(dps_rows$source %in% c("DPS - end of pipe", "DPS - reuse")))
})

test_that("DPS eff_load_tons is finite and positive when dps_data covers the facility", {
  result <- anlz_aa(2023L, dps_bradenton_sw(tn = 20.0), make_ips_empty(), make_ml_empty(), make_nps_empty(), 
                    tbbase, aa_corrections)

  brd <- result[
    !is.na(result$facname) & result$facname == "City of Bradenton WRF" &
      !is.na(result$source) & result$source == "DPS - end of pipe",
  ]
  expect_true(nrow(brd) >= 1)
  expect_true(is.finite(brd$eff_load_tons[1]))
  expect_true(brd$eff_load_tons[1] > 0)
})

test_that("DPS pass is FALSE when eff_load_tons exceeds alloc_tons", {
  # Use a very large tn_load to force a fail
  result <- anlz_aa(2023L, dps_bradenton_sw(tn = 1e6), make_ips_empty(), make_ml_empty(), make_nps_empty(), 
                    tbbase, aa_corrections)

  brd <- result[
    !is.na(result$facname) & result$facname == "City of Bradenton WRF" &
      !is.na(result$source) & result$source == "DPS - end of pipe",
  ]
  expect_true(nrow(brd) >= 1)
  expect_false(isTRUE(brd$pass[1]))
})

test_that("DPS year range filtering averages only over yrrng years", {
  dps_two <- rbind(
    dps_bradenton_sw(tn = 10.0, yr = 2022L),
    dps_bradenton_sw(tn = 90.0, yr = 2023L)
  )

  result_2022 <- anlz_aa(2022L,  dps_two, make_ips_empty(), make_ml_empty(), make_nps_empty(), tbbase, aa_corrections)
  result_both <- anlz_aa(2022:2023,  dps_two, make_ips_empty(), make_ml_empty(), make_nps_empty(), tbbase, aa_corrections)

  brd_2022 <- result_2022$eff_load_tons[
    !is.na(result_2022$facname) & result_2022$facname == "City of Bradenton WRF" &
      !is.na(result_2022$source) & result_2022$source == "DPS - end of pipe"
  ]
  brd_both <- result_both$eff_load_tons[
    !is.na(result_both$facname) & result_both$facname == "City of Bradenton WRF" &
      !is.na(result_both$source) & result_both$source == "DPS - end of pipe"
  ]

  expect_false(is.na(brd_2022))
  expect_false(is.na(brd_both))
  # 2022-only avg = 10; two-year avg = 50 (mean of 10 and 90)
  expect_true(brd_2022 < brd_both)
})

# ---- ML path ----------------------------------------------------------------

test_that("every ml_allocations non-shared row appears in output with empty ML input", {
  result <- anlz_aa(2023L, make_dps_empty(), make_ips_empty(), make_ml_empty(),make_nps_empty(),
                    tbbase, aa_corrections)

  ns_keys <- paste(
    ml_allocations$bay_seg[!ml_allocations$ishared],
    ml_allocations$entity[!ml_allocations$ishared],
    ml_allocations$facname[!ml_allocations$ishared]
  )
  out_keys <- paste(result$bay_seg, result$entity, result$facname)
  expect_true(all(ns_keys %in% out_keys))
})

test_that("shared ML allocation row appears in output with empty ML input", {
  result <- anlz_aa(2023L, make_dps_empty(), make_ips_empty(), make_ml_empty(), make_nps_empty(),
                    tbbase, aa_corrections)

  shared_row <- result[
    !is.na(result$source) & result$source == "ML" &
      result$entity == "Mosaic" & result$bay_seg == 2 & is.na(result$facname),
  ]
  expect_equal(nrow(shared_row), 1L)
  expect_equal(shared_row$alloc_tons, 3.3, tolerance = 1e-9)
})

test_that("ML rows carry source equal to ML", {
  result <- anlz_aa(2023L, make_dps_empty(), make_ips_empty(), make_ml_empty(), make_nps_empty(),
                    tbbase, aa_corrections)

  ml_rows <- result[!is.na(result$source) & result$source == "ML", ]
  expect_true(nrow(ml_rows) > 0)
  expect_true(all(ml_rows$source == "ML"))
})

test_that("ML eff_load_tons is finite and positive for non-shared facility", {
  result <- anlz_aa(2023L, make_dps_empty(), make_ips_empty(), ml_tampaplex(tn_tonsyr = 5.0), make_nps_empty(),
                    tbbase, aa_corrections)

  km_tp <- result[
    !is.na(result$facname) & result$facname == "Kinder Morgan Tampaplex" &
      !is.na(result$source) & result$source == "ML",
  ]
  expect_true(nrow(km_tp) >= 1)
  expect_equal(km_tp$eff_load_tons[1], 5.0, tolerance = 1e-9)
})

test_that("ML shared eff_load_tons equals sum of individual Mosaic facility loads", {
  # Supply one Mosaic ML facility (Riverview) and verify the shared row reflects it
  ml_riverview <- data.frame(
    Year = 2023L, Month = 1:12, entity = "Mosaic",
    facility = "Riverview", tn_load = 1.0 / 12
  )
  result <- anlz_aa(2023L, make_dps_empty(), make_ips_empty(), ml_riverview, make_nps_empty(),
                    tbbase, aa_corrections)

  shared_row <- result[
    !is.na(result$source) & result$source == "ML" &
      result$entity == "Mosaic" & is.na(result$facname),
  ]
  expect_true(nrow(shared_row) == 1L)
  expect_equal(shared_row$eff_load_tons, 1.0, tolerance = 1e-9)
})

test_that("ML year range filtering averages only over yrrng years", {
  ml_two <- rbind(
    ml_tampaplex(tn_tonsyr = 10.0, yr = 2022L),
    ml_tampaplex(tn_tonsyr = 90.0, yr = 2023L)
  )

  result_2022 <- anlz_aa(2022L, make_dps_empty(), make_ips_empty(), ml_two, make_nps_empty(),
                          tbbase, aa_corrections)
  result_both <- anlz_aa(2022:2023, make_dps_empty(), make_ips_empty(), ml_two, make_nps_empty(),
                          tbbase, aa_corrections)

  km_2022 <- result_2022$eff_load_tons[
    !is.na(result_2022$facname) & result_2022$facname == "Kinder Morgan Tampaplex" &
      !is.na(result_2022$source) & result_2022$source == "ML"
  ]
  km_both <- result_both$eff_load_tons[
    !is.na(result_both$facname) & result_both$facname == "Kinder Morgan Tampaplex" &
      !is.na(result_both$source) & result_both$source == "ML"
  ]

  expect_false(is.na(km_2022))
  expect_false(is.na(km_both))
  # 2022-only = 10; two-year avg = 50 (mean of 10 and 90)
  expect_true(km_2022 < km_both)
})
