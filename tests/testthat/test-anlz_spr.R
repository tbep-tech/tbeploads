# Bundled file paths
tbwxlpth <- system.file('extdata/sprflow2224.xlsx', package = 'tbeploads')
wqpth    <- system.file('extdata/sprwq2224.csv',    package = 'tbeploads')

# Mock Sulphur Spring flow (avoids USGS API calls during testing)
sulphur_dates <- seq.Date(as.Date("2022-01-01"), as.Date("2024-12-31"), by = "day")
mock_sulphurflow <- data.frame(
  site_no  = "02306000",
  date     = sulphur_dates,
  flow_cfs = 50.0
)

# ---------------------------------------------------------------------------
# summ = 'spring' (per-spring loads) — file path WQ
# ---------------------------------------------------------------------------

test_that("anlz_spr spring/month returns correct structure and values", {

  result <- anlz_spr(tbwxlpth, wqpth, yrrng = c(2022, 2024),
                     summ = 'spring', summtime = 'month',
                     sulphurflow = mock_sulphurflow)

  expect_s3_class(result, "data.frame")

  expected_cols <- c("source", "spring", "site", "segment", "yr", "mo",
                     "flow_cfs", "tn_mgl", "tp_mgl", "tss_mgl",
                     "h2oload", "tnload", "tpload", "tssload")
  expect_identical(names(result), expected_cols)

  # 3 springs x 3 years x 12 months
  expect_equal(nrow(result), 108L)

  expect_true(all(result$source == "SPRING"))
  expect_true(all(result$segment == 2L))
  expect_setequal(unique(result$spring), c("Lithia", "Buckhorn", "Sulphur"))

  # All loads positive
  expect_true(all(result$h2oload > 0))
  expect_true(all(result$tnload  > 0))
  expect_true(all(result$tpload  > 0))
  expect_true(all(result$tssload > 0))

})

test_that("anlz_spr spring/year drops mo and aggregates correctly", {

  result_mo <- anlz_spr(tbwxlpth, wqpth, yrrng = c(2022, 2024),
                        summ = 'spring', summtime = 'month',
                        sulphurflow = mock_sulphurflow)

  result_yr <- anlz_spr(tbwxlpth, wqpth, yrrng = c(2022, 2024),
                        summ = 'spring', summtime = 'year',
                        sulphurflow = mock_sulphurflow)

  # 3 springs x 3 years, no mo column
  expect_equal(nrow(result_yr), 9L)
  expect_false("mo" %in% names(result_yr))

  # Annual tnload for each spring/year must equal the sum of monthly tnloads
  for (spr in c("Lithia", "Buckhorn", "Sulphur")) {
    for (yr in 2022:2024) {
      annual  <- result_yr$tnload[result_yr$spring == spr & result_yr$yr == yr]
      monthly <- sum(result_mo$tnload[result_mo$spring == spr & result_mo$yr == yr])
      expect_equal(annual, monthly, tolerance = 1e-6,
                   label = paste("tnload", spr, yr))
    }
  }

})

# ---------------------------------------------------------------------------
# summ = 'basin'
# ---------------------------------------------------------------------------

test_that("anlz_spr basin/month returns correct structure", {

  result <- anlz_spr(tbwxlpth, wqpth, yrrng = c(2022, 2024),
                     summ = 'basin', summtime = 'month',
                     sulphurflow = mock_sulphurflow)

  expected_cols <- c("source", "majbasin", "segment", "yr", "mo",
                     "h2oload", "tnload", "tpload", "tssload")
  expect_identical(names(result), expected_cols)

  # 2 basins x 3 years x 12 months
  expect_equal(nrow(result), 72L)

  expect_setequal(unique(result$majbasin),
                  c("Alafia River", "Hillsborough River"))

  # spring/site columns should not be present
  expect_false("spring" %in% names(result))
  expect_false("site"   %in% names(result))

  # All loads positive
  expect_true(all(result$tnload > 0))
  expect_true(all(result$tpload > 0))

})

test_that("anlz_spr basin/month loads match spring/month sums by basin", {

  spr <- anlz_spr(tbwxlpth, wqpth, yrrng = c(2022, 2024),
                  summ = 'spring', summtime = 'month',
                  sulphurflow = mock_sulphurflow)

  bas <- anlz_spr(tbwxlpth, wqpth, yrrng = c(2022, 2024),
                  summ = 'basin', summtime = 'month',
                  sulphurflow = mock_sulphurflow)

  # Alafia River = Lithia + Buckhorn
  alafia_bas <- sum(bas$tnload[bas$majbasin == "Alafia River"])
  alafia_spr <- sum(spr$tnload[spr$spring %in% c("Lithia", "Buckhorn")])
  expect_equal(alafia_bas, alafia_spr, tolerance = 1e-6)

  # Hillsborough River = Sulphur
  hills_bas <- sum(bas$tnload[bas$majbasin == "Hillsborough River"])
  hills_spr <- sum(spr$tnload[spr$spring == "Sulphur"])
  expect_equal(hills_bas, hills_spr, tolerance = 1e-6)

})

test_that("anlz_spr basin/year drops mo and has correct row count", {

  result <- anlz_spr(tbwxlpth, wqpth, yrrng = c(2022, 2024),
                     summ = 'basin', summtime = 'year',
                     sulphurflow = mock_sulphurflow)

  # 2 basins x 3 years
  expect_equal(nrow(result), 6L)
  expect_false("mo" %in% names(result))

})

# ---------------------------------------------------------------------------
# summ = 'segment'
# ---------------------------------------------------------------------------

test_that("anlz_spr segment/month returns correct structure", {

  result <- anlz_spr(tbwxlpth, wqpth, yrrng = c(2022, 2024),
                     summ = 'segment', summtime = 'month',
                     sulphurflow = mock_sulphurflow)

  expected_cols <- c("source", "segment", "yr", "mo",
                     "h2oload", "tnload", "tpload", "tssload")
  expect_identical(names(result), expected_cols)

  # 1 segment x 3 years x 12 months
  expect_equal(nrow(result), 36L)
  expect_true(all(result$segment == 2L))

})

test_that("anlz_spr segment/month loads equal sum of all spring loads", {

  spr <- anlz_spr(tbwxlpth, wqpth, yrrng = c(2022, 2024),
                  summ = 'spring', summtime = 'month',
                  sulphurflow = mock_sulphurflow)

  seg <- anlz_spr(tbwxlpth, wqpth, yrrng = c(2022, 2024),
                  summ = 'segment', summtime = 'month',
                  sulphurflow = mock_sulphurflow)

  expect_equal(sum(seg$tnload),   sum(spr$tnload),   tolerance = 1e-6)
  expect_equal(sum(seg$tpload),   sum(spr$tpload),   tolerance = 1e-6)
  expect_equal(sum(seg$tssload),  sum(spr$tssload),  tolerance = 1e-6)
  expect_equal(sum(seg$h2oload),  sum(spr$h2oload),  tolerance = 1e-6)

})

test_that("anlz_spr segment/year drops mo and aggregates across months", {

  seg_mo <- anlz_spr(tbwxlpth, wqpth, yrrng = c(2022, 2024),
                     summ = 'segment', summtime = 'month',
                     sulphurflow = mock_sulphurflow)

  seg_yr <- anlz_spr(tbwxlpth, wqpth, yrrng = c(2022, 2024),
                     summ = 'segment', summtime = 'year',
                     sulphurflow = mock_sulphurflow)

  # 1 segment x 3 years
  expect_equal(nrow(seg_yr), 3L)
  expect_false("mo" %in% names(seg_yr))

  # Annual totals must equal sum of monthly totals for each year
  for (yr in 2022:2024) {
    annual  <- seg_yr$tnload[seg_yr$yr == yr]
    monthly <- sum(seg_mo$tnload[seg_mo$yr == yr])
    expect_equal(annual, monthly, tolerance = 1e-6,
                 label = paste("segment tnload", yr))
  }

})

# ---------------------------------------------------------------------------
# wqpth = NULL: API path (util_spr_getwq mocked)
# ---------------------------------------------------------------------------

# Mock WQ data returned by util_spr_getwq
make_mock_wq <- function(yrrng, verbose = TRUE) {
  expand.grid(
    spring = c("Lithia", "Buckhorn", "Sulphur"),
    yr     = yrrng[1]:yrrng[2],
    stringsAsFactors = FALSE
  ) |>
    dplyr::mutate(tn_mgl = 0.50, tp_mgl = 0.05, tss_mgl = NA_real_)
}

# Mock WQ data with observed TSS for two springs
make_mock_wq_with_tss <- function(yrrng, verbose = TRUE) {
  dat <- make_mock_wq(yrrng, verbose)
  dat$tss_mgl[dat$spring == "Sulphur"] <- 3.0
  dat
}

test_that("anlz_spr wqpth=NULL calls util_spr_getwq and returns correct structure", {

  local_mocked_bindings(
    util_spr_getwq = make_mock_wq,
    .package = "tbeploads"
  )

  result <- anlz_spr(tbwxlpth, wqpth = NULL, yrrng = c(2022, 2024),
                     summ = 'spring', summtime = 'month',
                     sulphurflow = mock_sulphurflow, verbose = FALSE)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 108L)
  expect_setequal(unique(result$spring), c("Lithia", "Buckhorn", "Sulphur"))

  expected_cols <- c("source", "spring", "site", "segment", "yr", "mo",
                     "flow_cfs", "tn_mgl", "tp_mgl", "tss_mgl",
                     "h2oload", "tnload", "tpload", "tssload")
  expect_identical(names(result), expected_cols)

  # Constant WQ means tn_mgl is 0.50 for all rows
  expect_true(all(result$tn_mgl == 0.50))
  expect_true(all(result$tp_mgl == 0.05))

})

test_that("anlz_spr wqpth=NULL falls back to fixed TSS when tss_mgl is NA", {

  local_mocked_bindings(
    util_spr_getwq = make_mock_wq,  # returns tss_mgl = NA for all springs
    .package = "tbeploads"
  )

  result <- anlz_spr(tbwxlpth, wqpth = NULL, yrrng = c(2022, 2024),
                     summ = 'spring', summtime = 'month',
                     sulphurflow = mock_sulphurflow, verbose = FALSE)

  # Fixed TSS lookup: Sulphur 4.4, Lithia/Buckhorn 4.0
  sulphur_tss  <- unique(result$tss_mgl[result$spring == "Sulphur"])
  lithia_tss   <- unique(result$tss_mgl[result$spring == "Lithia"])
  buckhorn_tss <- unique(result$tss_mgl[result$spring == "Buckhorn"])

  expect_equal(sulphur_tss,  4.4)
  expect_equal(lithia_tss,   4.0)
  expect_equal(buckhorn_tss, 4.0)

})

test_that("anlz_spr wqpth=NULL uses observed TSS when available", {

  local_mocked_bindings(
    util_spr_getwq = make_mock_wq_with_tss,  # Sulphur has tss_mgl = 3.0
    .package = "tbeploads"
  )

  result <- anlz_spr(tbwxlpth, wqpth = NULL, yrrng = c(2022, 2024),
                     summ = 'spring', summtime = 'month',
                     sulphurflow = mock_sulphurflow, verbose = FALSE)

  # Sulphur: observed TSS 3.0 takes precedence over fixed 4.4
  expect_equal(unique(result$tss_mgl[result$spring == "Sulphur"]),  3.0)
  # Lithia/Buckhorn still NA → fixed fallback
  expect_equal(unique(result$tss_mgl[result$spring == "Lithia"]),   4.0)
  expect_equal(unique(result$tss_mgl[result$spring == "Buckhorn"]), 4.0)

})

test_that("anlz_spr wqpth=NULL segment totals are consistent with spring sums", {

  local_mocked_bindings(
    util_spr_getwq = make_mock_wq,
    .package = "tbeploads"
  )

  spr <- anlz_spr(tbwxlpth, wqpth = NULL, yrrng = c(2022, 2024),
                  summ = 'spring', summtime = 'month',
                  sulphurflow = mock_sulphurflow, verbose = FALSE)

  seg <- anlz_spr(tbwxlpth, wqpth = NULL, yrrng = c(2022, 2024),
                  summ = 'segment', summtime = 'month',
                  sulphurflow = mock_sulphurflow, verbose = FALSE)

  expect_equal(sum(seg$tnload),  sum(spr$tnload),  tolerance = 1e-6)
  expect_equal(sum(seg$tpload),  sum(spr$tpload),  tolerance = 1e-6)
  expect_equal(sum(seg$tssload), sum(spr$tssload), tolerance = 1e-6)

})

test_that("anlz_spr wqpth=NULL and wqpth file produce similar TN/TP loads", {

  local_mocked_bindings(
    util_spr_getwq = make_mock_wq,
    .package = "tbeploads"
  )

  # API path with constant mock concentrations
  api_result <- anlz_spr(tbwxlpth, wqpth = NULL, yrrng = c(2022, 2024),
                         summ = 'spring', summtime = 'month',
                         sulphurflow = mock_sulphurflow, verbose = FALSE)

  # File path
  file_result <- anlz_spr(tbwxlpth, wqpth, yrrng = c(2022, 2024),
                           summ = 'spring', summtime = 'month',
                           sulphurflow = mock_sulphurflow)

  # Both paths produce the same structure
  expect_identical(names(api_result), names(file_result))
  expect_equal(nrow(api_result), nrow(file_result))

  # API result uses the mocked WQ concentrations
  expect_true(all(api_result$tn_mgl == 0.50))

})
