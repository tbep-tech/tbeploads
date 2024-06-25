
test_that("Check load calculations", {

  result <- ml |>
    filter(Year == 2021 & Month == 1 & facility == 'Riverview') |>
    mutate_if(is.numeric, round, 3)

  expect_equal(result$tn_load[[1]], 0.082)
  expect_equal(result$tp_load[[1]], NA)
  expect_equal(result$tss_load[[1]], NA)
  expect_equal(result$bod_load[[1]], NA)
  expect_equal(result$hy_load[[1]], NA)

})

test_that("Verify output class", {

  expect_s3_class(ips, "data.frame")

})
