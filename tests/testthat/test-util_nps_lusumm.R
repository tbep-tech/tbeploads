# test dataset
npsld <- data.frame(
  bay_seg = rep(1:2, each = 6),
  basin = rep(c("02304500", "02306647"), each = 6),
  yr = rep(2021:2022, each = 3, times = 2),
  mo = rep(1:3, times = 4),
  clucsid = rep(1:3, times = 4),
  tnload = c(150, 250, 50, 180, 300, 40, 160, 270, 45, 170, 280, 35),
  tpload = c(15, 35, 8, 18, 42, 6, 16, 38, 7, 17, 40, 5),
  tssload = c(1200, 3500, 400, 1400, 4000, 350, 1300, 3800, 380, 1350, 3900, 320),
  bodload = c(800, 1500, 200, 900, 1800, 180, 850, 1600, 190, 870, 1650, 170),
  h2oload = c(50000, 80000, 25000, 55000, 85000, 22000, 52000, 82000, 23000, 53000, 83000, 21000)
)

# Test cases
test_that("util_nps_lusumm returns correct results for basin, month", {
  result <- util_nps_lusumm(npsld, summ = 'basin', summtime = 'month')
  result <- names(result)
  expected <- c("Year", "Month", "source", "segment", "basin", "lu", 
                "tn_load", "tp_load", "tss_load", "bod_load", "hy_load")
  expect_identical(result, expected)
})

test_that("util_nps_lusumm returns correct results for segment, month", {
  result <- util_nps_lusumm(npsld, summ = 'segment', summtime = 'month')
  result <- names(result)
  expected <- c("Year", "Month", "source", "segment", "lu", 
                "tn_load", "tp_load", "tss_load", "bod_load", "hy_load")
  expect_identical(result, expected)
})

test_that("util_nps_lusumm returns correct results for all, month", {
  result <- util_nps_lusumm(npsld, summ = 'all', summtime = 'month')
  result <- names(result)
  expected <- c("Year", "Month", "source", "lu", 
                "tn_load", "tp_load", "tss_load", "bod_load", "hy_load")
  expect_identical(result, expected)
})

test_that("util_nps_lusumm returns correct results for basin, year", {
  result <- util_nps_lusumm(npsld, summ = 'basin', summtime = 'year')
  result <- names(result)
  expected <- c("Year", "source", "segment", "basin", "lu", 
                "tn_load", "tp_load", "tss_load", "bod_load", "hy_load")
  expect_identical(result, expected)
})

test_that("util_nps_lusumm returns correct results for segment, year", {
  result <- util_nps_lusumm(npsld, summ = 'segment', summtime = 'year')
  result <- names(result)
  expected <- c("Year", "source", "segment", "lu", 
                "tn_load", "tp_load", "tss_load", "bod_load", "hy_load")
  expect_identical(result, expected)
})

test_that("util_nps_lusumm returns correct results for all, year", {
  result <- util_nps_lusumm(npsld, summ = 'all', summtime = 'year')
  result <- names(result)
  expected <- c("Year", "source", "lu", 
                "tn_load", "tp_load", "tss_load", "bod_load", "hy_load")
  expect_identical(result, expected)
})

test_that("util_nps_lusumm filters out Boca Ciega Bay for 'all' summary", {
  # Add Boca Ciega Bay data to test filtering
  test_data <- npsld |>
    dplyr::bind_rows(
      data.frame(
        bay_seg = 5, basin = "02308000", yr = 2021, mo = 1, clucsid = 1,
        tnload = 100, tpload = 10, tssload = 1000, bodload = 500, h2oload = 30000
      )
    )
  
  result_all <- util_nps_lusumm(test_data, summ = 'all', summtime = 'month')
  result_segment <- util_nps_lusumm(test_data, summ = 'segment', summtime = 'month')
  
  # 'all' should have fewer rows than 'segment' due to Boca Ciega Bay filtering
  expect_true(nrow(result_all) <= nrow(result_segment))
  expect_false("Boca Ciega Bay" %in% result_all$segment)
})

test_that("util_nps_lusumm handles missing land use descriptions", {
  # Test with clucsid not in lookup table
  test_data <- npsld |>
    dplyr::mutate(clucsid = ifelse(dplyr::row_number() == 1, 99, clucsid))
  
  result <- util_nps_lusumm(test_data, summ = 'basin', summtime = 'month')
  
  # Should filter out rows with missing land use descriptions
  expect_false(any(is.na(result$lu)))

})

test_that("util_nps_lusumm adds source column correctly", {
  result <- util_nps_lusumm(npsld, summ = 'basin', summtime = 'month')
  
  # All rows should have source = "NPS"
  expect_true(all(result$source == "NPS"))
  expect_true(length(unique(result$source)) == 1)
})