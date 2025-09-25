
create_mock_flow_data <- function() {
  tidyr::crossing(
    basin = c("LMANATEE", "TBYPASS", "02301500"),
    yr = c(2021:2023),
    mo = c(1:12)
    ) |>
    dplyr::mutate(
      flow_cfs = runif(108, 0, 100)  # Random flow values
  )
}

create_mock_wq_data <- function() {
  data.frame(
    basin = rep(c("LTARPON", "02304500", "02300500", "02301500", "02300700",
                  "02307000", "02301750", "02306647", "TBYPASS", "EVERSRES", "LMANATEE"), each = 36),
    yr = rep(2021:2023, times = 11 * 12),
    mo = rep(1:12, times = 11 * 3),
    tn_mgl = runif(396, 0, 10),
    tp_mgl = runif(396, 0, 5),
    tss_mgl = runif(396, 0, 20),
    bod_mgl = runif(396, 0, 15)
  )
}

mock_util_nps_getflow <- function(lakemanpth, tampabypth, bellshlpth, yrrng, usgsflow, verbose = TRUE) {
  return(create_mock_flow_data())
}

mock_util_nps_getwq <- function(yrrng, mancopth = NULL, pincopth = NULL, verbose = TRUE) {
  return(create_mock_wq_data())
}

mancopth <- system.file('extdata/nps_wq_manco.txt', package = 'tbeploads')
pincopth <- system.file('extdata/nps_wq_pinco.txt', package = 'tbeploads')
lakemanpth <- system.file('extdata/nps_extflow_lakemanatee.xlsx', package = 'tbeploads')
tampabypth <- system.file('extdata/nps_extflow_tampabypass.xlsx', package = 'tbeploads')
bellshlpth <- system.file('extdata/nps_extflow_bellshoals.xls', package = 'tbeploads')

test_that("anlz_nps_gaged works with default parameters and mocked data", {

  local_mocked_bindings(
    util_nps_getflow = mock_util_nps_getflow,
    util_nps_getwq = mock_util_nps_getwq,
    .package = "tbeploads"
  )

  result <- anlz_nps_gaged(mancopth = mancopth, pincopth = pincopth, lakemanpth = lakemanpth,
                           tampabypth = tampabypth, bellshlpth = bellshlpth, verbose = FALSE)

  # Check that result is a data frame
  expect_type(result, "list")

  # Check required columns are present
  expected_cols <- c("basin", "yr", "mo", "tn_mgl", "tp_mgl", "tss_mgl", "bod_mgl", "flow", "h2oload", "tnload", "tpload", "tssload", "bodload")
  expect_true(all(expected_cols %in% names(result)))

  # Check that basins are mapped correctly
  expected_basins <- c("LTARPON", "02304500", "02300500", "02301500", "02300700",
                       "02307000", "02301750", "02306647", "TBYPASS", "EVERSRES", "LMANATEE")
  expect_true(all(result$basin %in% expected_basins))

  # Check that data filtering worked (years should be within range)
  expect_true(all(result$yr >= 2021 & result$yr <= 2023))

})

test_that("util_nps_getwq handles verbose output correctly", {

  local_mocked_bindings(
    util_nps_getflow = mock_util_nps_getflow,
    util_nps_getwq = mock_util_nps_getwq,
    .package = "tbeploads"
  )

  expect_output(
    anlz_nps_gaged(mancopth = mancopth, pincopth = pincopth, lakemanpth = lakemanpth,
                   tampabypth = tampabypth, bellshlpth = bellshlpth),
    "Retrieving flow data...\\nRetrieving water quality data..."
  )

})
