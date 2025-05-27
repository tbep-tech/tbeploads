
# Helper function to create mock USGS flow data (based on util_nps_getusgsflow structure)
create_mock_usgs_flow <- function(start_date, end_date) {
  # Create 15 USGS sites as per the original function
  sites <- c("02299950", "02300042", "02300500", "02300700", "02301000",
             "02301300", "02301500", "02301750", "02303000", "02303330",
             "02304500", "02306647", "02307000", "02307359", "02307498")

  dates <- seq(as.Date(start_date), as.Date(end_date), by = "day")

  # Create mock data for all sites
  mock_data <- purrr::map_dfr(sites, function(site) {
    tibble::tibble(
      site_no = site,
      date = dates,
      flow_cfs = runif(length(dates), 50, 500)
    )
  })

  return(mock_data)
}

pth1 <- system.file('extdata/nps_extflow_lakemanatee.xlsx', package = 'tbeploads')
pth2 <- system.file('extdata/nps_extflow_tampabypass.xlsx', package = 'tbeploads')
pth3 <- system.file('extdata/nps_extflow_bellshoals.xls', package = 'tbeploads')

# Test suite for util_nps_getflow
test_that("util_nps_getflow basic functionality", {

  # Create mock functions that return the expected data structures
  mock_usgs_flow_func <- function(yrrng) {
    create_mock_usgs_flow(yrrng[1], yrrng[2])
  }

  # Use local_mocked_bindings to mock both functions
  local_mocked_bindings(
    util_nps_getusgsflow = mock_usgs_flow_func,
    .package = "tbeploads"
  )

  # Test with default parameters
  result <- util_nps_getflow(pth1, pth2, pth3)

  # Check that result is a data frame
  expect_s3_class(result, "data.frame")

  # Check required columns exist
  expect_true(all(c("basin", "yr", "mo", "flow_cfs") %in% names(result)))

  # Check that data is aggregated to monthly means
  expect_true(all(result$yr %in% c(2021, 2022, 2023)))
  expect_true(all(result$mo %in% 1:12))

  # Check that flow_cfs is numeric
  expect_true(is.numeric(result$flow_cfs))

  # Check that special basin names are applied
  unique_basins <- unique(result$basin)
  expect_true("LTARPON" %in% unique_basins)  # Should replace 02307498
  expect_true("EVERSRES" %in% unique_basins) # Should replace 02300042
  expect_true("LMANATEE" %in% unique_basins)
  expect_true("TBYPASS" %in% unique_basins)
})
