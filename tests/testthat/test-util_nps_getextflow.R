test_that("util_nps_getextflow for Lake Manatee", {

  pth <- system.file('extdata/nps_extflow_lakemanatee.xlsx', package = 'tbeploads')
  extflo <- util_nps_getextflow(pth, loc = "LMANATEE")

  expect_equal(unique(extflo$site_no), 'LMANATEE')

})

test_that("util_nps_getextflow for Tampa Bypass", {

  pth <- system.file('extdata/nps_extflow_tampabypass.xlsx', package = 'tbeploads')
  extflo <- util_nps_getextflow(pth, loc = "TBYPASS")

  expect_equal(unique(extflo$site_no), 'TBYPASS')

})

test_that("util_nps_getextflow for Bell Shoals", {

  pth <- system.file('extdata/nps_extflow_bellshoals.xls', package = 'tbeploads')
  extflo <- util_nps_getextflow(pth, loc = "02301500")

  expect_equal(unique(extflo$site_no), '02301500')

})
