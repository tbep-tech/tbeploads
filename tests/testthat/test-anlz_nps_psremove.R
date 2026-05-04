# Helper to build a minimal basin/month load data frame
make_load_df <- function(segment, basin, source, tn = 10, tp = 2, tss = 5,
                         bod = 3, hy = 1e6, year = 2022L, months = 1:12) {
  n <- length(months)
  data.frame(
    Year     = rep(year, n),
    Month    = months,
    source   = rep(source, n),
    segment  = rep(segment, n),
    basin    = rep(basin, n),
    tn_load  = rep(tn,  n),
    tp_load  = rep(tp,  n),
    tss_load = rep(tss, n),
    bod_load = rep(bod, n),
    hy_load  = rep(hy,  n)
  )
}

# --- Fixtures ----------------------------------------------------------------

# NPS: gaged basin (HB) + ungaged basin (OTB)
nps_hb  <- make_load_df("Hillsborough Bay", "02301500", "NPS", tn = 10)
nps_otb <- make_load_df("Old Tampa Bay",    "206-1",    "NPS", tn = 5)
nps_all <- rbind(nps_hb, nps_otb)

# IPS in gaged basin (HB) and ungaged basin (OTB)
ips_hb_gaged   <- make_load_df("Hillsborough Bay", "02301500", "IPS", tn = 2)
ips_otb_ungaged <- make_load_df("Old Tampa Bay",   "206-1",    "IPS", tn = 1)
ips_all <- rbind(ips_hb_gaged, ips_otb_ungaged)

# DPS: zero loads — present but negligible, in gaged basin
dps_empty <- make_load_df("Hillsborough Bay", "02301500", "DPS - end of pipe",
                          tn = 0, tp = 0, tss = 0, bod = 0, hy = 0)

res_month <- anlz_nps_psremove(nps_all, ips_all, dps_empty,
                                ad_ap = FALSE, summtime = 'month')
res_month_adap <- anlz_nps_psremove(nps_all, ips_all, dps_empty,
                                    ad_ap = TRUE, summtime = 'month')
res_year  <- anlz_nps_psremove(nps_all, ips_all, dps_empty,
                                ad_ap = FALSE, summtime = 'year')
res_month_basin <- anlz_nps_psremove(nps_all, ips_all, dps_empty,
                                     ad_ap = FALSE, summ = 'basin',
                                     summtime = 'month'
                                     )
res_year_basin  <- anlz_nps_psremove(nps_all, ips_all, dps_empty,
                                     ad_ap = FALSE, summ = 'basin',
                                     summtime = 'year'
                                     )

# --- Output structure --------------------------------------------------------

test_that("Monthly output has expected columns in correct order (segment)", {
  expected <- c("Year", "Month", "source", "segment",
                "tn_load", "tp_load", "tss_load", "bod_load", "hy_load")
  expect_equal(names(res_month), expected)
})

test_that("Monthly basin output includes basin column after segment", {
  expected <- c("Year", "Month", "source", "segment", "basin",
                "tn_load", "tp_load", "tss_load", "bod_load", "hy_load")
  expect_equal(names(res_month_basin), expected)
})

test_that("source is always 'NPS'", {
  expect_true(all(res_month$source == "NPS"))
})

test_that("Annual segment output has Year, source, segment but no Month or basin", {
  expect_true(all(c("Year", "source", "segment", "tn_load") %in% names(res_year)))
  expect_false("Month" %in% names(res_year))
  expect_false("basin" %in% names(res_year))
})

test_that("Annual basin output includes basin column and no Month", {
  expect_true(all(c("Year", "source", "segment", "basin", "tn_load") %in% names(res_year_basin)))
  expect_false("Month" %in% names(res_year_basin))
})

test_that("One row per segment per month for monthly output", {
  expect_equal(nrow(res_month), length(unique(nps_all$segment)) * 12L)
})

# --- PS subtraction ----------------------------------------------------------

test_that("Gaged IPS loads are subtracted from NPS totals", {
  hb <- res_month[res_month$segment == "Hillsborough Bay", ]
  # nps=10, ips_gaged=2 → net = 8 (no ad_ap)
  expect_equal(unique(hb$tn_load), 8, tolerance = 1e-9)
})

test_that("Ungaged IPS loads are NOT subtracted", {
  otb <- res_month[res_month$segment == "Old Tampa Bay", ]
  # nps=5, ips in ungaged basin → net still 5 (no ad_ap)
  expect_equal(unique(otb$tn_load), 5, tolerance = 1e-9)
})

# --- AD/AP adjustment --------------------------------------------------------

test_that("AD/AP reduces TN by the correct monthly amount (Hillsborough Bay = 4.31)", {
  hb <- res_month_adap[res_month_adap$segment == "Hillsborough Bay", ]
  # net before adap = 8; after adap = 8 - 4.31 = 3.69
  expect_equal(unique(hb$tn_load), 8 - 4.31, tolerance = 1e-9)
})

test_that("AD/AP reduces TN for Old Tampa Bay (2.41 tons/month)", {
  otb <- res_month_adap[res_month_adap$segment == "Old Tampa Bay", ]
  expect_equal(unique(otb$tn_load), 5 - 2.41, tolerance = 1e-9)
})

test_that("AD/AP does not affect TP, TSS, BOD, or hy_load", {
  hb_no   <- res_month[res_month$segment == "Hillsborough Bay", ]
  hb_adap <- res_month_adap[res_month_adap$segment == "Hillsborough Bay", ]
  expect_equal(hb_adap$tp_load,  hb_no$tp_load)
  expect_equal(hb_adap$tss_load, hb_no$tss_load)
  expect_equal(hb_adap$bod_load, hb_no$bod_load)
  expect_equal(hb_adap$hy_load,  hb_no$hy_load)
})

test_that("Segments with no AD/AP rule are unaffected (tp, tss)", {
  # Create a segment with no defined AD/AP (e.g. Boca Ciega Bay)
  nps_bcb <- make_load_df("Boca Ciega Bay", "207-5", "NPS", tn = 7)
  dps_z   <- make_load_df("Boca Ciega Bay", "207-5", "DPS - end of pipe",
                          tn = 0, tp = 0, tss = 0, bod = 0, hy = 0)
  res_bcb <- anlz_nps_psremove(nps_bcb, dps_z, dps_z,
                                ad_ap = TRUE, summtime = 'month')
  # No IPS or DPS subtraction; no AD/AP defined → tn stays 7
  expect_equal(unique(res_bcb$tn_load), 7, tolerance = 1e-9)
})

# --- Annual summation --------------------------------------------------------

test_that("Annual TN is 12x monthly TN (no AD/AP, constant monthly loads)", {
  hb_yr <- res_year[res_year$segment == "Hillsborough Bay", ]
  # 12 months × 8 tons/month = 96 tons/year
  expect_equal(hb_yr$tn_load, 96, tolerance = 1e-9)
})

# --- summ = 'basin' -----------------------------------------------------------

test_that("summ basin retains basin column with correct values matching segment output", {
  # One basin per segment in fixtures: basin values should equal segment values
  hb_seg   <- res_month[res_month$segment == "Hillsborough Bay", ]
  hb_basin <- res_month_basin[res_month_basin$segment == "Hillsborough Bay", ]
  expect_equal(hb_basin$tn_load, hb_seg$tn_load)
  expect_equal(unique(hb_basin$basin), "02301500")
})

test_that("summ basin annual tn equals 12x monthly tn", {
  hb_yr <- res_year_basin[res_year_basin$segment == "Hillsborough Bay", ]
  expect_equal(hb_yr$tn_load, 96, tolerance = 1e-9)
  expect_equal(hb_yr$basin, "02301500")
})

# --- Nested basin reassignment -----------------------------------------------

test_that("Nested basin (02301000) IPS loads are subtracted after reassignment to 02301500", {
  # IPS in nested gaged basin 02301000 should be reassigned to 02301500
  # and subtracted from the HB segment NPS total
  ips_nested <- make_load_df("Hillsborough Bay", "02301000", "IPS", tn = 3)
  nps_base   <- make_load_df("Hillsborough Bay", "02301500", "NPS", tn = 10)
  dps_z      <- make_load_df("Hillsborough Bay", "02301500", "DPS - end of pipe",
                             tn = 0, tp = 0, tss = 0, bod = 0, hy = 0)
  res_nested <- anlz_nps_psremove(nps_base, ips_nested, dps_z,
                                   ad_ap = FALSE, summtime = 'month')
  hb <- res_nested[res_nested$segment == "Hillsborough Bay", ]
  # 10 - 3 = 7
  expect_equal(unique(hb$tn_load), 7, tolerance = 1e-9)
})
