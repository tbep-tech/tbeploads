noaa_key <- Sys.getenv("NOAA_KEY")

test_that("util_ad_getrain returns a data frame", {

  result <- util_ad_getrain(2021, 228, noaa_key)
  expect_s3_class(result, "data.frame")

})
