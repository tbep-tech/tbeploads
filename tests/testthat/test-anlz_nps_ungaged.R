test_that("anlz_nps_ungaged returns expected output format", {

  # Mock the flow data that util_nps_getflow would return
  mock_flow <- data.frame(
    basin = c("Basin1", "Basin1"),
    yr = c(2020, 2020),
    mo = c(1, 2),
    flow_cfs = c(100, 150)
  )

  # Use system file paths for external flow data
  lakemanpth <- system.file('extdata/nps_extflow_lakemanatee.xlsx', package = 'tbeploads')
  tampabypth <- system.file('extdata/nps_extflow_tampabypass.xlsx', package = 'tbeploads')
  bellshlpth <- system.file('extdata/nps_extflow_bellshoals.xls', package = 'tbeploads')

  # Mock util_nps_getflow using local_mocked_bindings
  local_mocked_bindings(
    util_nps_getflow = function(...) mock_flow
  )

  result <- anlz_nps_ungaged(tbbase, rain, lakemanpth, tampabypth, bellshlpth)

  # Test output format
  expect_s3_class(result, "data.frame")

  # Check expected columns are present
  expected_cols <- c("bay_seg", "basin", "yr", "mo", "clucsid", "h2oload",
                     "tnload", "tpload", "tssload", "stnload", "stpload",
                     "stssload", "bodload", "area", "bas_area")
  expect_true(all(expected_cols %in% names(result)))

})
