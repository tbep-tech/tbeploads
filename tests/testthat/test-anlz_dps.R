test_that("anlz_dps returns correct results for facility, month", {

  # summarize by facility and year
  result <- anlz_dps(psdomfls, summ = 'facility', summtime = 'month')
  result <- names(result)
  expected <- c("Year", "Month", "source", "entity", "facility", "segment", "tn_load",
                "tp_load", "tss_load", "bod_load", "hy_load")
  expect_identical(result, expected)

})

test_that("anlz_dps returns basin and segment columns for summ = 'basin'", {

  result <- anlz_dps(psdomfls, summ = 'basin', summtime = 'month')
  expect_true("basin" %in% names(result))
  expect_true("segment" %in% names(result))

})
