# Mock ungaged loads output
mock_ungaged <- data.frame(
  bay_seg = c(1, 1),
  basin = c("Basin1", "Basin1"),
  yr = c(2021, 2021),
  mo = c(1, 2),
  clucsid = c(1, 2),
  h2oload = c(1000, 1500),
  tnload = c(10, 15),
  tpload = c(2, 3),
  tssload = c(50, 75),
  stnload = c(8, 12),
  stpload = c(1.5, 2.5),
  stssload = c(40, 60),
  bodload = c(20, 30),
  area = c(100, 200),
  bas_area = c(300, 300)
)

# Mock gaged loads output
mock_gaged <- data.frame(
  basin = c("Basin2", "Basin2"),
  yr = c(2021, 2021),
  mo = c(1, 2),
  h2oload = c(2000, 2500),
  tnload = c(20, 25),
  tpload = c(4, 5),
  tssload = c(100, 125),
  bodload = c(40, 50)
)

# Use system file paths
mancopth <- system.file('extdata/nps_wq_manco.txt', package = 'tbeploads')
pincopth <- system.file('extdata/nps_wq_pinco.txt', package = 'tbeploads')
lakemanpth <- system.file('extdata/nps_extflow_lakemanatee.xlsx', package = 'tbeploads')
tampabypth <- system.file('extdata/nps_extflow_tampabypass.xlsx', package = 'tbeploads')
bellshlpth <- system.file('extdata/nps_extflow_bellshoals.xls', package = 'tbeploads')
vernafl <- system.file('extdata/verna-raw.csv', package = 'tbeploads')

test_that("anlz_nps returns expected output format", {

  # Mock the analysis functions
  local_mocked_bindings(
    anlz_nps_ungaged = function(...) mock_ungaged,
    anlz_nps_gaged = function(...) mock_gaged
  )

  result <- anlz_nps(
    yrrng = c('2021-01-01', '2021-12-31'),
    tbbase, rain, mancopth, pincopth, lakemanpth, tampabypth, bellshlpth, vernafl,
    verbose = FALSE
  )

  # Test output format
  expect_s3_class(result, "data.frame")

  # Check expected columns are present
  expected_cols <- c("yr", "mo", "bay_seg", "basin", "h2oload", "tnload", "tpload",
                     "tssload", "bodload", "bas_area", "segment", "majbasin", "source")
  expect_true(all(expected_cols %in% names(result)))

  # Check data types
  expect_type(result$yr, "double")
  expect_type(result$mo, "double")
  expect_type(result$bay_seg, "double")
  expect_type(result$h2oload, "double")
  expect_type(result$tnload, "double")
  expect_type(result$tpload, "double")
  expect_type(result$tssload, "double")
  expect_type(result$bodload, "double")
  expect_type(result$bas_area, "double")
  expect_type(result$source, "character")

  # Check that source column contains expected value
  expect_true(all(result$source == "NPS"))
})

test_that("anlz_nps handles verbose output correctly", {


  # Mock the analysis functions
  local_mocked_bindings(
    anlz_nps_ungaged = function(...) mock_ungaged,
    anlz_nps_gaged = function(...) mock_gaged
  )

  # Test verbose output
  expect_output(
    anlz_nps(
      yrrng = c('2021-01-01', '2021-12-31'),
      tbbase, rain, mancopth, pincopth, lakemanpth, tampabypth, bellshlpth, vernafl,
      verbose = TRUE
    ),
    "Estimating ungaged NPS loads"
  )

  expect_output(
    anlz_nps(
      yrrng = c('2021-01-01', '2021-12-31'),
      tbbase, rain, mancopth, pincopth, lakemanpth, tampabypth, bellshlpth, vernafl,
      verbose = TRUE
    ),
    "Estimating gaged NPS loads"
  )

  expect_output(
    anlz_nps(
      yrrng = c('2021-01-01', '2021-12-31'),
      tbbase, rain, mancopth, pincopth, lakemanpth, tampabypth, bellshlpth, vernafl,
      verbose = TRUE
    ),
    "Combining ungaged and gaged NPS loads"
  )

  # Test silent operation
  expect_silent(
    anlz_nps(
      yrrng = c('2021-01-01', '2021-12-31'),
      tbbase, rain, mancopth, pincopth, lakemanpth, tampabypth, bellshlpth, vernafl,
      verbose = FALSE
    )
  )
})
