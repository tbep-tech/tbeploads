test_that("util_nps_segment assigns correct segments for basic cases", {
  dat <- data.frame(
    basin = c("LTARPON", "TBYPASS", "02300500", "206-4", "EVERSRES"),
    bay_seg = c(1, 2, 3, 4, 7)
  )
  
  result <- util_nps_segment(dat)
  
  expect_equal(result$segment[1], 'Old Tampa Bay')  
  expect_equal(result$segment[2], 'Hillsborough Bay')
  expect_equal(result$segment[3], 'Middle Tampa Bay')
  expect_equal(result$segment[4], 'Lower Tampa Bay')  
  expect_equal(result$segment[5], 'Manatee River')

})

test_that("util_nps_segment handles special 207-5 cases correctly", {
  dat <- data.frame(
    basin = c("207-5", "207-5"),
    bay_seg = c(55, 5)
  )
  
  result <- util_nps_segment(dat)
  
  expect_equal(result$segment[1], 'Boca Ciega Bay South')
  expect_equal(result$segment[2], 'Boca Ciega Bay')
})
