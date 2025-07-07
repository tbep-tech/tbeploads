test_that("Check util_nps_preplog returns correct format", {

  result <- util_nps_preplog(tbbase)
  expect_s3_class(result, "data.frame")

})
