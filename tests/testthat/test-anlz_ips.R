test_that("anlz_ips returns correct results for facility, month", {

  # summarize by facility and year
  result <- anlz_ips(psindfls, summ = 'facility', summtime = 'month')
  result <- names(result)
  expected <- c("Year", "Month", "source", "entity", "facility", "segment", "tn_load",
                "tp_load", "tss_load", "bod_load", "hy_load")
  expect_identical(result, expected)

})
