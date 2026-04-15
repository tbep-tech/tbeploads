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
# summ = 'spring' (per-spring loads)
# ---------------------------------------------------------------------------

test_that("anlz_spr spring/month returns correct structure and values", {

  result <- anlz_spr(tbwxlpth, wqpth, yrrng = c(2022, 2024),
                     summ = 'spring', summtime = 'month',
                     sulphurflow = mock_sulphurflow)

  expect_s3_class(result, "data.frame")

  expected_cols <- c("source", "spring", "site", "segment", "yr", "mo",
                     "hy_load", "tn_load", "tp_load", "tss_load")
  expect_identical(names(result), expected_cols)

  # 3 springs x 3 years x 12 months
  expect_equal(nrow(result), 108L)

  expect_true(all(result$source == "SPRING"))
  expect_true(all(result$segment == 2L))
  expect_setequal(unique(result$spring), c("Lithia", "Buckhorn", "Sulphur"))

  # All loads positive
  expect_true(all(result$hy_load > 0))
  expect_true(all(result$tn_load  > 0))
  expect_true(all(result$tp_load  > 0))
  expect_true(all(result$tss_load > 0))

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

  # Annual tn_load for each spring/year must equal the sum of monthly tn_loads
  for (spr in c("Lithia", "Buckhorn", "Sulphur")) {
    for (yr in 2022:2024) {
      annual <- result_yr$tn_load[result_yr$spring == spr & result_yr$yr == yr]
      monthly <- sum(result_mo$tn_load[result_mo$spring == spr & result_mo$yr == yr])
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

  expected_cols <- c("source", "majbasin", "segment", "yr", "mo",
                     "hy_load", "tn_load", "tp_load", "tss_load")
  expect_identical(names(result), expected_cols)

  # 2 basins x 3 years x 12 months
  expect_equal(nrow(result), 72L)

  expect_setequal(unique(result$majbasin),
                  c("Alafia River", "Hillsborough River"))

  # spring/site columns should not be present
  expect_false("spring" %in% names(result))
  expect_false("site"   %in% names(result))

  # All loads positive
  expect_true(all(result$tn_load > 0))
  expect_true(all(result$tp_load > 0))

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
                     "hy_load", "tn_load", "tp_load", "tss_load")
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

  expect_equal(sum(seg$tn_load),  sum(spr$tn_load),  tolerance = 1e-6)
  expect_equal(sum(seg$tp_load),  sum(spr$tp_load),  tolerance = 1e-6)
  expect_equal(sum(seg$tss_load), sum(spr$tss_load), tolerance = 1e-6)
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
    annual <- seg_yr$tn_load[seg_yr$yr == yr]
    monthly <- sum(seg_mo$tn_load[seg_mo$yr == yr])
    expect_equal(annual, monthly, tolerance = 1e-6,
                 label = paste("segment tnload", yr))
  }

})
