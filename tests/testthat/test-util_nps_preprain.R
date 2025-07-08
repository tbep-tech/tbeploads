test_that("Check util_nps_preprain returns correct format", {

  result <- util_nps_preprain(rain)
  expect_s3_class(result, "data.frame")

  nms <- c("basin", "yr", "mo", "rain", "lag1rain", "lag2rain")
  expect_true(all(nms %in% names(result)))

})

test_that("Check yrrng argument for util_nps_preprain", {

  result <- util_nps_preprain(rain, yrrng = c(2021))
  chk <- unique(result$yr)
  expect_equal(chk, 2021)

  result <- util_nps_preprain(rain, yrrng = c(2021, 2022))
  chk <- unique(result$yr)
  expect_true(all(chk %in% c(2021, 2022)))

  # incorrect year input
  expect_error(util_nps_preprain(rain, yrrng = c(2022, 2021)))

})
