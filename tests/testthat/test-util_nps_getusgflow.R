# Mock data for testing
create_mock_usgs_data <- function(site_no, start_date, end_date) {
  dates <- seq(as.Date(start_date), as.Date(end_date), by = "day")
  data.frame(
    agency_cd = "USGS",
    site_no = site_no,
    Date = dates,
    X_00060_00003 = runif(length(dates), 10, 1000), # Random flow values
    X_00060_00003_cd = "A",
    Flow = runif(length(dates), 10, 1000),
    Flow_cd = "A",
    stringsAsFactors = FALSE
  )
}

# Test suite for util_nps_getusgsflow
test_that("util_nps_getusgsflow basic functionality", {

  # Create mock functions that return actual data
  mock_readNWISdv_func <- function(site, param, start, end) {
    create_mock_usgs_data(site, start, end)
  }

  mock_renameNWISColumns_func <- function(data) {
    data$Flow <- data$X_00060_00003
    data$Flow_cd <- data$X_00060_00003_cd
    return(data)
  }

  # Test with default parameters using local mocking
  local_mocked_bindings(
    readNWISdv = mock_readNWISdv_func,
    renameNWISColumns = mock_renameNWISColumns_func,
    .package = "dataRetrieval"
  )

  result <- util_nps_getusgsflow()

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

  # Check date range (default 2021-01-01 to 2023-12-31)
  expect_true(min(result$date) >= as.Date("2021-01-01"))
  expect_true(max(result$date) <= as.Date("2023-12-31"))

})

