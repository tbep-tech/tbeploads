# Test cases
test_that("anlz_dps returns correct results for facility, month", {
  # summarize by facility and year
  result <- anlz_dps(fls, summ = 'facility', summtime = 'month')
  result <- names(result)
  expected <- c("Year", "Month", "source", "entity", "facility", "segment", "tn_load",
                "tp_load", "tss_load", "bod_load", "hy_load")
  expect_identical(result, expected)
})

test_that("anlz_dps returns correct results for entity, month", {
  # summarize by facility and year
  result <- anlz_dps(fls, summ = 'entity', summtime = 'month')
  result <- names(result)
  expected <- c("Year", "Month", "source", "entity", "segment", "tn_load",
                "tp_load", "tss_load", "bod_load", "hy_load")
  expect_identical(result, expected)
})

test_that("anlz_dps returns correct results for segment, month", {
  # summarize by facility and year
  result <- anlz_dps(fls, summ = 'segment', summtime = 'month')
  result <- names(result)
  expected <- c("Year", "Month", "source", "segment", "tn_load",
                "tp_load", "tss_load", "bod_load", "hy_load")
  expect_identical(result, expected)
})

test_that("anlz_dps returns correct results for all, month", {
  # summarize by facility and year
  result <- anlz_dps(fls, summ = 'all', summtime = 'month')
  result <- names(result)
  expected <- c("Year", "Month", "source", "tn_load",
                "tp_load", "tss_load", "bod_load", "hy_load")
  expect_identical(result, expected)
})

test_that("anlz_dps returns correct results for facility, year", {
  # summarize by facility and year
  result <- anlz_dps(fls, summ = 'facility', summtime = 'year')
  result <- names(result)
  expected <- c("Year", "source", "entity", "facility", "segment", "tn_load",
                "tp_load", "tss_load", "bod_load", "hy_load")
  expect_identical(result, expected)
})

test_that("anlz_dps returns correct results for entity, year", {
  # summarize by facility and year
  result <- anlz_dps(fls, summ = 'entity', summtime = 'year')
  result <- names(result)
  expected <- c("Year", "source", "entity", "segment", "tn_load",
                "tp_load", "tss_load", "bod_load", "hy_load")
  expect_identical(result, expected)
})

test_that("anlz_dps returns correct results for segment, year", {
  # summarize by facility and year
  result <- anlz_dps(fls, summ = 'segment', summtime = 'year')
  result <- names(result)
  expected <- c("Year", "source", "segment", "tn_load",
                "tp_load", "tss_load", "bod_load", "hy_load")
  expect_identical(result, expected)
})

test_that("anlz_dps returns correct results for all, year", {
  # summarize by facility and year
  result <- anlz_dps(fls, summ = 'all', summtime = 'year')
  result <- names(result)
  expected <- c("Year", "source", "tn_load",
                "tp_load", "tss_load", "bod_load", "hy_load")
  expect_identical(result, expected)
})
