
vernafl <- system.file("extdata/verna-raw.csv", package = "tbeploads")
verna <- read.csv(vernafl, header = TRUE, stringsAsFactors = FALSE) |> 
  dplyr::arrange(yr, seas)

test_that("util_prepverna returns a data frame", {
  result <- util_prepverna(vernafl, fillmis = TRUE)
  expect_s3_class(result, "data.frame")
})

test_that("util_prepverna fills missing values when fillmis is TRUE", {
  result <- util_prepverna(vernafl, fillmis = TRUE)
  result <- result[result$Year >= 2017, ] # Focus on years where filling would occur
  expect_false(any(is.na(result$TNConc)))
  expect_false(any(is.na(result$TPConc)))
})

test_that("util_prepverna does not fill missing values when fillmis is FALSE", {
  result <- util_prepverna(vernafl, fillmis = FALSE)
  expect_true(any(is.na(result$TNConc)))
  expect_true(any(is.na(result$TPConc)))
})

test_that("util_prepverna calculates TNConc and TPConc correctly", {
  result <- util_prepverna(vernafl, fillmis = TRUE)
  
  # find row where data exists
  tst <- which(verna$NH4 != -9 & verna$NO3 != -9)
  tst <- max(tst)

  # Manually calculate the expected values for the first row
  expected_TNConc <- (verna$NH4[tst] * 0.78) + (verna$NO3[tst] * 0.23)
  expected_TPConc <- 0.01262 * expected_TNConc + 0.00110

  expect_equal(result$TNConc[tst], expected_TNConc, tolerance = 1e-6)
  expect_equal(result$TPConc[tst], expected_TPConc, tolerance = 1e-6)
})

