pth <- system.file('extdata/ps_dom_hillsco_falkenburg_2019.txt', package = 'tbeploads')

# Test case 1: Check if the function calculates loads correctly
test_that("Check load calculations", {

  result <- anlz_dps_entity(pth) %>%
    mutate_if(is.numeric, round, 3)

  expect_equal(result$tn_load[[1]], 1.13)
  expect_equal(result$tp_load[[1]], 0.134)
  expect_equal(result$tss_load[[1]], 0.307)
  expect_equal(result$bod_load[[1]], 0.709)
  expect_equal(result$hy_load[[1]], 0.435)

})

test_test("Verify output class", {

  result <- anlz_dps_entity(pth)

  expect_s3_class(result, "data.frame")

})
