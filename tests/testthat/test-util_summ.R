fls <- list.files(system.file('extdata/', package = 'tbeploads'),
  pattern = 'ps_ind_', full.names = TRUE)

ipsbyfac <- anlz_ips_facility(fls)

# add bay segment and source, there should only be loads to hills, middle, and lower tampa bay
ipsld <- ipsbyfac  |>
  dplyr::arrange(coastco) |>
  dplyr::left_join(dbasing, by = "coastco") |>
  dplyr::mutate(
    segment = dplyr::case_when(
      bayseg == 1 ~ "Old Tampa Bay",
      bayseg == 2 ~ "Hillsborough Bay",
      bayseg == 3 ~ "Middle Tampa Bay",
      bayseg == 4 ~ "Lower Tampa Bay",
      TRUE ~ NA_character_
    ),
    source = 'IPS'
  ) |>
  dplyr::select(-basin, -hectare, -coastco, -name, -bayseg)

# Test cases
test_that("util_summ returns correct results for facility, month", {
  # summarize by facility and year
  result <- util_summ(ipsld, summ = 'facility', summtime = 'month')
  result <- names(result)
  expected <- c("Year", "Month", "source", "entity", "facility", "segment", "tn_load",
                "tp_load", "tss_load", "bod_load", "hy_load")
  expect_identical(result, expected)
})

test_that("util_summ returns correct results for entity, month", {
  # summarize by facility and year
  result <- util_summ(ipsld, summ = 'entity', summtime = 'month')
  result <- names(result)
  expected <- c("Year", "Month", "source", "entity", "segment", "tn_load",
                "tp_load", "tss_load", "bod_load", "hy_load")
  expect_identical(result, expected)
})

test_that("util_summ returns correct results for segment, month", {
  # summarize by facility and year
  result <- util_summ(ipsld, summ = 'segment', summtime = 'month')
  result <- names(result)
  expected <- c("Year", "Month", "source", "segment", "tn_load",
                "tp_load", "tss_load", "bod_load", "hy_load")
  expect_identical(result, expected)
})

test_that("util_summ returns correct results for all, month", {
  # summarize by facility and year
  result <- util_summ(ipsld, summ = 'all', summtime = 'month')
  result <- names(result)
  expected <- c("Year", "Month", "source", "tn_load",
                "tp_load", "tss_load", "bod_load", "hy_load")
  expect_identical(result, expected)
})

test_that("util_summ returns correct results for facility, year", {
  # summarize by facility and year
  result <- util_summ(ipsld, summ = 'facility', summtime = 'year')
  result <- names(result)
  expected <- c("Year", "source", "entity", "facility", "segment", "tn_load",
                "tp_load", "tss_load", "bod_load", "hy_load")
  expect_identical(result, expected)
})

test_that("util_summ returns correct results for entity, year", {
  # summarize by facility and year
  result <- util_summ(ipsld, summ = 'entity', summtime = 'year')
  result <- names(result)
  expected <- c("Year", "source", "entity", "segment", "tn_load",
                "tp_load", "tss_load", "bod_load", "hy_load")
  expect_identical(result, expected)
})

test_that("util_summ returns correct results for segment, year", {
  # summarize by facility and year
  result <- util_summ(ipsld, summ = 'segment', summtime = 'year')
  result <- names(result)
  expected <- c("Year", "source", "segment", "tn_load",
                "tp_load", "tss_load", "bod_load", "hy_load")
  expect_identical(result, expected)
})

test_that("util_summ returns correct results for all, year", {
  # summarize by facility and year
  result <- util_summ(ipsld, summ = 'all', summtime = 'year')
  result <- names(result)
  expected <- c("Year", "source", "tn_load",
                "tp_load", "tss_load", "bod_load", "hy_load")
  expect_identical(result, expected)
})
