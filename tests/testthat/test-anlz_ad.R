test_that("anlz_ad returns correct columns for segment and month summary", {
  result <- anlz_ad(ad_rain, vernafl, summ = 'segment', summtime = 'month')

  expect_true(all(c("Year", "Month", "source", "segment", "tn_load", "tp_load", "hy_load") %in% colnames(result)))
})

test_that("anlz_ad returns correct columns for segment and year summary", {
  result <- anlz_ad(ad_rain, vernafl, summ = 'segment', summtime = 'year')

  expect_true(all(c("Year", "source", "segment", "tn_load", "tp_load", "hy_load") %in% colnames(result)))
})

test_that("anlz_ad returns correct columns for all and month summary", {
  result <- anlz_ad(ad_rain, vernafl, summ = 'all', summtime = 'month')

  expect_true(all(c("Year", "Month", "source", "tn_load", "tp_load", "hy_load") %in% colnames(result)))
})

test_that("anlz_ad returns correct columns for all and year summary", {
  result <- anlz_ad(ad_rain, vernafl, summ = 'all', summtime = 'year')

  expect_true(all(c("Year", "source", "tn_load", "tp_load", "hy_load") %in% colnames(result)))
})
