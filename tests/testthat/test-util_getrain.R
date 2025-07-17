# Mocking the rnoaa::ncdc function
mock_ncdc <- function(datasetid = 'GHCND', stationid,
                      datatypeid = 'PRCP', startdate,
                      enddate, limit = 400, add_units = TRUE,
                      token) {
  list(
    data = data.frame(
      date = as.character(seq.Date(as.Date(startdate), as.Date(enddate), by = "month")),
      datatype = 'PRCP',
      station = stationid,
      value = runif(12, min = 0, max = 100),
      fl_m = "",
      fl_q = "",
      fl_so = "7",
      fl_t = "0800",
      units = "mm_tenths"
      )
  )
}

fail_once <- TRUE
mock_ncdc_retry <- function(datasetid = 'GHCND', stationid,
                            datatypeid = 'PRCP', startdate,
                            enddate, limit = 400, add_units = TRUE,
                            token) {
  if (fail_once) {
    fail_once <<- FALSE
    stop("API error")
  }
  list(
    data = data.frame(
      date = as.character(seq.Date(as.Date(startdate), as.Date(enddate), by = "month")),
      datatype = 'PRCP',
      station = stationid,
      value = runif(12, min = 0, max = 100),
      fl_m = "",
      fl_q = "",
      fl_so = "7",
      fl_t = "0800",
      units = "mm_tenths"
    )
  )
}

test_that("util_getrain returns correct structure and data", {
  # Mock rnoaa::ncdc function
  stub(util_getrain, "ncdc", mock_ncdc)

  # Test with a single year and station
  noaa_key <- "test_key"
  result <- util_getrain(2021, 228, noaa_key, ntry = 1)

  expect_s3_class(result, "data.frame")
  expect_true(all(c("station", "date", "Year", "Month", "Day", "rainfall") %in% colnames(result)))
  expect_equal(result$Year[1], 2021)
  expect_equal(result$station[1], 228)

  # Test with multiple years and default stations
  result <- util_getrain(c(2021, 2022), noaa_key = noaa_key, ntry = 1)

  expect_s3_class(result, "data.frame")
  expect_true(all(c("station", "date", "Year", "Month", "Day", "rainfall") %in% colnames(result)))

  # Check if data contains rows for both years
  expect_true(all(c(2021, 2022) %in% result$Year))

})

test_that("util_getrain retry mechanism works", {

  # Mock rnoaa::ncdc function with retry behavior
  stub(util_getrain, "ncdc", mock_ncdc_retry)

  noaa_key <- "test_key"
  result <- util_getrain(2021, 228, noaa_key, ntry = 2)

  expect_s3_class(result, "data.frame")
  expect_true(all(c("station", "date", "Year", "Month", "Day", "rainfall") %in% colnames(result)))
  expect_equal(result$Year[1], 2021)
  expect_equal(result$station[1], 228)

  result <- util_getrain(2021, c(1111, 9999), noaa_key, ntry = 0)
  expect_null(result)

})
