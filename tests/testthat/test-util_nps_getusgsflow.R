# Mock data for testing
create_mock_waterdata_daily <- function(monitoring_location_id, parameter_code, time, skipGeometry = TRUE) {
  site_no <- sub("USGS-", "", monitoring_location_id)
  dates <- seq(as.Date(time[1]), as.Date(time[2]), by = "day")
  
  data.frame(
    monitoring_location_id = monitoring_location_id,
    time = dates,
    value = runif(length(dates), 10, 1000),
    qualifier = "A",
    stringsAsFactors = FALSE
  )
}

# Test suite for util_nps_getusgsflow
test_that("util_nps_getusgsflow basic functionality", {
  
  # Mock the read_waterdata_daily function
  local_mocked_bindings(
    read_waterdata_daily = create_mock_waterdata_daily,
    .package = "dataRetrieval"
  )
  
  result <- util_nps_getusgsflow(verbose = TRUE)
  
  # Check that result is a data frame
  expect_s3_class(result, "data.frame")
  
  # Check required columns exist
  expect_true(all(c("site_no", "date", "flow_cfs") %in% names(result)))
  
  # Check that all 15 default sites are included
  expected_sites <- c("02299950", "02300042", "02300500", "02300700", "02301000",
                      "02301300", "02301500", "02301750", "02303000", "02303330",
                      "02304500", "02306647", "02307000", "02307359", "02307498")
  actual_sites <- unique(result$site_no)
  expect_equal(length(actual_sites), 15)
  expect_true(all(expected_sites %in% actual_sites))
  
  # Check date column is Date class
  expect_s3_class(result$date, "Date")
  
  # Check flow_cfs is numeric
  expect_true(is.numeric(result$flow_cfs))
  
})

test_that("util_nps_getusgsflow works with custom site", {
  
  local_mocked_bindings(
    read_waterdata_daily = create_mock_waterdata_daily,
    .package = "dataRetrieval"
  )
  
  result <- util_nps_getusgsflow(site = c("02299950"), verbose = FALSE)
  
  expect_s3_class(result, "data.frame")
  expect_equal(unique(result$site_no), "02299950")
  
})

test_that("util_nps_getusgsflow works with custom date range", {
  
  local_mocked_bindings(
    read_waterdata_daily = create_mock_waterdata_daily,
    .package = "dataRetrieval"
  )
  
  result <- util_nps_getusgsflow(yrrng = c('2020-01-01', '2020-06-30'), verbose = FALSE)
  
  expect_s3_class(result, "data.frame")
  expect_true(min(result$date) >= as.Date("2020-01-01"))
  expect_true(max(result$date) <= as.Date("2020-06-30"))
  
})
