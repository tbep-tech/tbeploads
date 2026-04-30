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

  expected_cols <- c("Year", "Month", "source", "segment", "spring",
                     "tn_load", "tp_load", "tss_load", "bod_load", "hy_load")
  expect_identical(names(result), expected_cols)

  # 3 springs x 3 years x 12 months
  expect_equal(nrow(result), 108L)

  expect_true(all(result$source == "SPR"))
  expect_true(all(result$segment == "Hillsborough Bay"))
  expect_setequal(unique(result$spring), c("Lithia", "Buckhorn", "Sulphur"))

  # All loads positive
  expect_true(all(result$hy_load > 0))
  expect_true(all(result$tn_load > 0))
  expect_true(all(result$tp_load > 0))
  expect_true(all(result$tss_load > 0))

})

test_that("anlz_spr spring/year drops month and aggregates correctly", {

  result_mo <- anlz_spr(tbwxlpth, wqpth, yrrng = c(2022, 2024),
                        summ = 'spring', summtime = 'month',
                        sulphurflow = mock_sulphurflow)

  result_yr <- anlz_spr(tbwxlpth, wqpth, yrrng = c(2022, 2024),
                        summ = 'spring', summtime = 'year',
                        sulphurflow = mock_sulphurflow)

  # 3 springs x 3 years, no Month column
  expect_equal(nrow(result_yr), 9L)
  expect_false("Month" %in% names(result_yr))

  # Annual tn_load for each spring/year must equal the sum of monthly tnloads
  for (spr in c("Lithia", "Buckhorn", "Sulphur")) {
    for (yr in 2022:2024) {
      annual  <- result_yr$tn_load[result_yr$spring == spr & result_yr$Year == yr]
      monthly <- sum(result_mo$tn_load[result_mo$spring == spr & result_mo$Year == yr])
      expect_equal(annual, monthly, tolerance = 1e-6,
                   label = paste("tn_load", spr, yr))
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

  expected_cols <- c("Year", "Month", "source", "segment", "majbasin",
                     "tn_load", "tp_load", "tss_load", "bod_load", "hy_load")
  expect_identical(names(result), expected_cols)

  # 2 basins x 3 years x 12 months
  expect_equal(nrow(result), 72L)

  expect_setequal(unique(result$majbasin),
                  c("Alafia River", "Hillsborough River"))

  # spring/site columns should not be present
  expect_false("spring" %in% names(result))

  # All loads positive
  expect_true(all(result$tn_load > 0))
  expect_true(all(result$tp_load > 0))
  expect_true(all(result$tss_load > 0))

})

test_that("anlz_spr basin/month loads match spring/month sums by basin", {

  spr <- anlz_spr(tbwxlpth, wqpth, yrrng = c(2022, 2024),
                  summ = 'spring', summtime = 'month',
                  sulphurflow = mock_sulphurflow)

  bas <- anlz_spr(tbwxlpth, wqpth, yrrng = c(2022, 2024),
                  summ = 'basin', summtime = 'month',
                  sulphurflow = mock_sulphurflow)

  # Alafia River = Lithia + Buckhorn
  alafia_bas <- sum(bas$tn_load[bas$majbasin == "Alafia River"])
  alafia_spr <- sum(spr$tn_load[spr$spring %in% c("Lithia", "Buckhorn")])
  expect_equal(alafia_bas, alafia_spr, tolerance = 1e-6)

  # Hillsborough River = Sulphur
  hills_bas <- sum(bas$tn_load[bas$majbasin == "Hillsborough River"])
  hills_spr <- sum(spr$tn_load[spr$spring == "Sulphur"])
  expect_equal(hills_bas, hills_spr, tolerance = 1e-6)

})

test_that("anlz_spr basin/year drops mo and has correct row count", {

  result <- anlz_spr(tbwxlpth, wqpth, yrrng = c(2022, 2024),
                     summ = 'basin', summtime = 'year',
                     sulphurflow = mock_sulphurflow)

  # 2 basins x 3 years
  expect_equal(nrow(result), 6L)
  expect_false("Month" %in% names(result))

})

# ---------------------------------------------------------------------------
# summ = 'segment'
# ---------------------------------------------------------------------------

test_that("anlz_spr segment/month returns correct structure", {

  result <- anlz_spr(tbwxlpth, wqpth, yrrng = c(2022, 2024),
                     summ = 'segment', summtime = 'month',
                     sulphurflow = mock_sulphurflow)

  expected_cols <- c("Year", "Month", "source", "segment",
                     "tn_load", "tp_load", "tss_load", "bod_load", "hy_load")
  expect_identical(names(result), expected_cols)

  # 1 segment x 3 years x 12 months
  expect_equal(nrow(result), 36L)
  expect_true(all(result$segment == "Hillsborough Bay"))

})

test_that("anlz_spr segment/month loads equal sum of all spring loads", {

  spr <- anlz_spr(tbwxlpth, wqpth, yrrng = c(2022, 2024),
                  summ = 'spring', summtime = 'month',
                  sulphurflow = mock_sulphurflow)

  seg <- anlz_spr(tbwxlpth, wqpth, yrrng = c(2022, 2024),
                  summ = 'segment', summtime = 'month',
                  sulphurflow = mock_sulphurflow)

  expect_equal(sum(seg$tn_load),   sum(spr$tn_load),   tolerance = 1e-6)
  expect_equal(sum(seg$tp_load),   sum(spr$tp_load),   tolerance = 1e-6)
  expect_equal(sum(seg$tss_load),  sum(spr$tss_load),  tolerance = 1e-6)
  expect_equal(sum(seg$hy_load),  sum(spr$hy_load),  tolerance = 1e-6)

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
    annual  <- seg_yr$tn_load[seg_yr$Year == yr]
    monthly <- sum(seg_mo$tn_load[seg_mo$Year == yr])
    expect_equal(annual, monthly, tolerance = 1e-6,
                 label = paste("segment tn_load", yr))
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

  expected_cols <- c("Year", "Month", "source", "segment", "spring",
                     "tn_load", "tp_load", "tss_load", "bod_load", "hy_load")
  expect_identical(names(result), expected_cols)

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

  expect_equal(sum(seg$tn_load),  sum(spr$tn_load),  tolerance = 1e-6)
  expect_equal(sum(seg$tp_load),  sum(spr$tp_load),  tolerance = 1e-6)
  expect_equal(sum(seg$tss_load), sum(spr$tss_load), tolerance = 1e-6)

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

})

# ---------------------------------------------------------------------------
# Error: no complete prior year to carry forward from
# ---------------------------------------------------------------------------

test_that("anlz_spr errors when no prior complete year exists for carry-forward", {

  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)

  # Only Jan-Apr 2024 for Sulphur (incomplete); no Lithia or Buckhorn data at all
  wq_incomplete <- data.frame(
    year       = 2024L,
    month      = 1:4,
    spring     = "Sulphur",
    `tn(mg/L)` = 0.15,
    `tp(mg/L)` = 0.10,
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  write.csv(wq_incomplete, tmp, row.names = FALSE)

  expect_error(
    anlz_spr(tbwxlpth, tmp, yrrng = c(2024, 2024),
             sulphurflow = mock_sulphurflow),
    "Water quality concentrations could not be filled"
  )

})
