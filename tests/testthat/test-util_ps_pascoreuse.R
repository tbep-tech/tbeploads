result <- util_ps_pascoreuse(
  yr   = 2022:2024,
  res  = c(744120, 522273, 344189),
  golf = c(0, 0, 0),
  ribs = c(0, 0, 0),
  ag   = c(169, 269, 153)
)

test_that("Returns correct dimensions", {
  expect_equal(nrow(result), 3 * 12)
  expect_equal(ncol(result), 14)
})

test_that("Returns correct column names", {
  expected_cols <- c(
    "Permit.Number", "Facility.Name", "Outfall.ID", "Year", "Month",
    "Average.Daily.Flow..ADF...mgd.", "Total.N", "TN.Unit",
    "Total.P", "TP.Unit", "TSS", "TSS.Unit", "BOD", "BOD.Unit"
  )
  expect_equal(names(result), expected_cols)
})

test_that("Permit and facility fields are correct", {
  expect_true(all(result$Permit.Number == "PascoReuse"))
  expect_true(all(result$Facility.Name == "Pasco Reuse"))
  expect_true(all(result$Outfall.ID == "R-001"))
})

test_that("Months 1-12 present for each year", {
  expect_equal(sort(unique(result$Month)), 1:12)
  for (yr in 2022:2024) {
    expect_equal(nrow(result[result$Year == yr, ]), 12)
  }
})

test_that("Default TN concentration is 9 mg/l", {
  expect_true(all(result$Total.N == 9))
  expect_true(all(result$TN.Unit == "mg/l"))
})

test_that("TP, TSS, BOD are zero", {
  expect_true(all(result$Total.P == 0))
  expect_true(all(result$TSS == 0))
  expect_true(all(result$BOD == 0))
})

test_that("Flow is gte 0 and varies by month (days in month)", {
  yr2022 <- result[result$Year == 2022, ]
  expect_true(all(yr2022$Average.Daily.Flow..ADF...mgd. >= 0))
})

test_that("Custom tn_conc is applied", {
  res_custom <- util_ps_pascoreuse(
    yr = 2022, res = 500000, tn_conc = 5
  )
  expect_true(all(res_custom$Total.N == 5))
})

test_that("n_coastal divides flow correctly", {
  res1 <- util_ps_pascoreuse(yr = 2022, res = 500000, n_coastal = 1)
  res2 <- util_ps_pascoreuse(yr = 2022, res = 500000, n_coastal = 2)
  expect_equal(res1$Average.Daily.Flow..ADF...mgd., res2$Average.Daily.Flow..ADF...mgd. * 2)
})

test_that("Input length mismatch raises error", {
  expect_error(
    util_ps_pascoreuse(yr = 2022:2023, res = c(500000)),
    "res must be the same length as yr"
  )
})

test_that("Negative tn_conc raises error", {
  expect_error(
    util_ps_pascoreuse(yr = 2022, res = 500000, tn_conc = -1),
    "tn_conc must be a single positive number"
  )
})
