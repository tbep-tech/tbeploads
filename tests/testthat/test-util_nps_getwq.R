
# Test data setup
create_mock_manatee_data <- function() {
  data.frame(
    monitoringLocId = c("ER2", "UM2", "ER2", "UM2"),
    activityStartDate = c("01/15/2021 10:00:00", "01/20/2021 11:00:00",
                          "02/15/2021 09:30:00", "02/20/2021 14:00:00"),
    depAnalytePrimaryName = c("Nitrate-Nitrite (N)", "Nitrogen- Total Kjeldahl",
                              "Phosphorus- Total", "Residues- Nonfilterable (TSS)"),
    depResultValue = c(1.5, 2.0, 0.15, 25.0),
    depResultUnit = c("mg/L", "mg/L", "mg/L", "mg/L"),
    stringsAsFactors = FALSE
  )
}

create_mock_pinellas_data <- function() {
  data.frame(
    monitoringLocId = c("06-06", "06-06", "06-06", "06-06"),
    activityStartDate = c("01/10/2021 08:00:00", "01/25/2021 12:00:00",
                          "02/10/2021 10:30:00", "02/25/2021 15:00:00"),
    depAnalytePrimaryName = c("Nitrate-Nitrite (N)", "Nitrogen- Total Kjeldahl",
                              "Phosphorus- Total", "Residues- Nonfilterable (TSS)"),
    depResultValue = c(1.2, 1.8, 0.12, 20.0),
    depResultUnit = c("mg/L", "mg/L", "mg/L", "mg/L"),
    stringsAsFactors = FALSE
  )
}

create_mock_epc_data <- function() {
  data.frame(
    StationNumber = c(105, 113, 114, 132, 141, 138, 142, 147),
    SampleTime = as.POSIXct(c("2021-01-15 10:00:00", "2021-01-20 11:00:00",
                              "2021-02-15 09:30:00", "2021-02-20 14:00:00",
                              "2021-03-15 08:00:00", "2021-03-20 13:00:00",
                              "2021-04-15 11:30:00", "2021-04-20 16:00:00")),
    Total_Nitrogen = c("2.5", "3.0", "2.8", "3.2", "2.1", "2.9", "3.1", "2.6"),
    Total_Phosphorus = c("0.20", "0.25", "0.18", "0.22", "0.16", "0.24", "0.21", "0.19"),
    Total_Suspended_Solids = c("30", "35", "28", "32", "26", "34", "31", "29"),
    BOD = c("4.5", "5.0", "4.2", "4.8", "4.1", "4.9", "5.1", "4.6"),
    stringsAsFactors = FALSE
  )
}

mock_read_importwqwin <- function(start_date, end_date, org_id, verbose = TRUE) {
  if (org_id == "21FLMANA") {
    return(create_mock_manatee_data())
  } else if (org_id == "21FLPDEM") {
    return(create_mock_pinellas_data())
  }
}

mock_read_importepc <- function(tmpfl, download_latest = TRUE) {
  return(create_mock_epc_data())
}

test_that("util_nps_getwq works with default parameters and mocked data", {

  local_mocked_bindings(
    read_importwqwin = mock_read_importwqwin,
    read_importepc = mock_read_importepc,
    .package = "tbeptools"
  )

  result <- util_nps_getwq(verbose = FALSE)

  # Check that result is a data frame
  expect_type(result, "list")

  # Check required columns are present
  expected_cols <- c("basin", "yr", "mo", "tn_mgl", "tp_mgl", "tss_mgl", "bod_mgl")
  expect_true(all(expected_cols %in% names(result)))

  # Check that basins are mapped correctly
  expected_basins <- c("LTARPON", "02304500", "02300500", "02301500", "02300700",
                       "02307000", "02301750", "02306647", "TBYPASS", "EVERSRES", "LMANATEE")
  expect_true(all(result$basin %in% expected_basins))

  # Check that data filtering worked (years should be within range)
  expect_true(all(result$yr >= 2021 & result$yr <= 2023))
})

test_that("util_nps_getwq works with local file paths", {

  mancopth <- system.file("extdata", "nps_wq_manco.txt", package = "tbeploads")
  pincopth <- system.file("extdata", "nps_wq_pinco.txt", package = "tbeploads")

  mock_read_importepc <- mock(create_mock_epc_data())

  local_mocked_bindings(
    read_importepc = mock_read_importepc,
    .package = "tbeptools"
  )

  result <- util_nps_getwq(
    mancopth = mancopth,
    pincopth = pincopth,
    verbose = FALSE
  )

  expect_type(result, "list")
  expect_true(all(c("basin", "yr", "mo", "tn_mgl", "tp_mgl", "tss_mgl", "bod_mgl") %in% names(result)))

})

test_that("util_nps_getwq handles verbose output correctly", {

  local_mocked_bindings(
    read_importwqwin = mock_read_importwqwin,
    read_importepc = mock_read_importepc,
    .package = "tbeptools"
  )

  # Capture output when verbose = TRUE
  expect_output(
    util_nps_getwq(verbose = TRUE),
    "Retrieving Manatee County data"
  )
  expect_output(
    util_nps_getwq(verbose = TRUE),
    "Retreiving Pinellas County data"
  )
  expect_output(
    util_nps_getwq(verbose = TRUE),
    "Retrieving Hillsborough County data"
  )

})
