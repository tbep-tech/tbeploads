# Sample data for testing
test_data <- data.frame(
  yr = c(2020, 2020, 2020, 2020, 2021, 2021, 2021, 2021),
  seas = c(1, 2, 3, 4, 1, 2, 3, 4),
  NH4 = c(1.1, -9, 2.3, 4.5, 1.2, 3.4, -9, 5.6),
  NO3 = c(0.3, 0.4, -9, 0.5, 0.6, 0.7, 0.8, -9)
)

# Create a temporary CSV file with the sample data
temp_csv <- tempfile(fileext = ".csv")
write.csv(test_data, temp_csv, row.names = FALSE)

test_that("util_prepverna returns a data frame", {
  result <- util_prepverna(vernafl, fillmis = TRUE)
  expect_s3_class(result, "data.frame")
})

test_that("util_prepverna fills missing values when fillmis is TRUE", {
  result <- util_prepverna(vernafl, fillmis = TRUE)
  expect_false(any(is.na(result$TNConc)))
  expect_false(any(is.na(result$TPConc)))
})

test_that("util_prepverna does not fill missing values when fillmis is FALSE", {
  result <- util_prepverna(vernafl, fillmis = FALSE)
  expect_true(any(is.na(result$TNConc)))
  expect_true(any(is.na(result$TPConc)))
})

test_that("util_prepverna calculates TNConc and TPConc correctly", {
  result <- util_prepverna(temp_csv, fillmis = TRUE)

  # Manually calculate the expected values for the first row
  expected_TNConc <- (test_data$NH4[1] * 0.78) + (test_data$NO3[1] * 0.23)
  expected_TPConc <- 0.01262 * expected_TNConc + 0.00110

  expect_equal(result$TNConc[1], expected_TNConc, tolerance = 1e-6)
  expect_equal(result$TPConc[1], expected_TPConc, tolerance = 1e-6)
})

unlink(temp_csv)
