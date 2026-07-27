
vernafl <- system.file("extdata/verna-raw.csv", package = "tbeploads")
verna <- read.csv(vernafl, header = TRUE, stringsAsFactors = FALSE) |> 
  dplyr::arrange(yr, seas)

test_that("util_prepverna returns a data frame", {
  result <- util_prepverna(vernafl, typ = 'AD', fillmis = TRUE)
  expect_s3_class(result, "data.frame")
})

test_that("util_prepverna fills missing values when fillmis is TRUE", {
  result <- util_prepverna(vernafl, typ = 'AD', fillmis = TRUE)
  result <- result[result$Year >= 2017, ] # Focus on years where filling would occur
  expect_false(any(is.na(result$TNConc)))
  expect_false(any(is.na(result$TPConc)))
})

test_that("util_prepverna does not fill missing values when fillmis is FALSE", {
  result <- util_prepverna(vernafl, typ = 'AD', fillmis = FALSE)
  expect_true(any(is.na(result$TNConc)))
  expect_true(any(is.na(result$TPConc)))
})

test_that("util_prepverna calculates TNConc and TPConc correctly, typ = 'AD'", {
  result <- util_prepverna(vernafl, typ = 'AD', fillmis = TRUE)
  
  # find row where data exists
  tst <- which(verna$NH4 != -9 & verna$NO3 != -9)
  tstmo <- verna[max(tst), 'seas'] # get month of last valid data
  tstyr <- verna[max(tst), 'yr'] # get year of last valid data

  vernatst <- verna[verna$yr == tstyr & verna$seas == tstmo, ]
  resulttst <- result[result$Year == tstyr & result$Month == tstmo, ]

  # Manually calculate the expected values for the first row
  expected_TNConc <- (vernatst$NH4 * 0.78) + (vernatst$NO3 * 0.23)
  expected_TPConc <- 0.01262 * expected_TNConc + 0.00110

  expect_equal(resulttst$TNConc, expected_TNConc, tolerance = 1e-6)
  expect_equal(resulttst$TPConc, expected_TPConc, tolerance = 1e-6)
})

test_that("util_prepverna calculates TNConc and TPConc correctly, typ = 'NPS'", {
  result <- util_prepverna(vernafl, typ = 'NPS', fillmis = TRUE)

  # find row where data exists
  tst <- which(verna$NH4 != -9 & verna$NO3 != -9)
  tstmo <- verna[max(tst), 'seas'] # get month of last valid data
  tstyr <- verna[max(tst), 'yr'] # get year of last valid data

  vernatst <- verna[verna$yr == tstyr & verna$seas == tstmo, ]
  resulttst <- result[result$Year == tstyr & result$Month == tstmo, ]

  # Manually calculate the expected values for the first row
  expected_TNConc <- (vernatst$NH4 * 0.78) + (vernatst$NO3 * 0.23)
  expected_TPConc <- 0.195

  expect_equal(resulttst$TNConc, expected_TNConc, tolerance = 1e-6)
  expect_equal(resulttst$TPConc, expected_TPConc, tolerance = 1e-6)
})

test_that("util_prepverna treats a reported but low-completeness month as missing and fills it", {

  # June 1998 has a reported (non -9) value but Criteria1 = 50, below the
  # default mincrit = 75
  low <- verna[verna$yr == 1998 & verna$seas == 6, ]
  expect_true(low$NH4 != -9 & (low$Criteria1 < 75 | low$Criteria3 < 75))

  raw_TNConc <- (low$NH4 * 0.78) + (low$NO3 * 0.23)

  filtered <- util_prepverna(vernafl, typ = 'AD', fillmis = TRUE)
  filtered_val <- filtered$TNConc[filtered$Year == 1998 & filtered$Month == 6]

  unfiltered <- util_prepverna(vernafl, typ = 'AD', fillmis = TRUE, mincrit = 0)
  unfiltered_val <- unfiltered$TNConc[unfiltered$Year == 1998 & unfiltered$Month == 6]

  # default mincrit = 75 replaces the low-completeness reported value with a
  # filled estimate, so it no longer matches the raw calculation
  expect_false(isTRUE(all.equal(filtered_val, raw_TNConc)))

  # mincrit = 0 disables the completeness screen, reproducing the original
  # (pre-fix) behavior of using any reported, non -9 value as-is
  expect_equal(unfiltered_val, raw_TNConc, tolerance = 1e-6)
})

test_that("util_prepverna skips the completeness screen when Criteria1/Criteria3 are absent", {

  no_criteria <- tempfile(fileext = ".csv")
  write.csv(verna[, c("yr", "seas", "NH4", "NO3")], no_criteria, row.names = FALSE)

  result <- util_prepverna(no_criteria, typ = 'AD', fillmis = TRUE)

  low <- verna[verna$yr == 1998 & verna$seas == 6, ]
  raw_TNConc <- (low$NH4 * 0.78) + (low$NO3 * 0.23)
  result_val <- result$TNConc[result$Year == 1998 & result$Month == 6]

  expect_equal(result_val, raw_TNConc, tolerance = 1e-6)
})
