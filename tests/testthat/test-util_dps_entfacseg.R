test_that("Extract entity, facility, and segment", {
  pth <- system.file('extdata/ps_dom_hillsco_falkenburg_2019.txt', package = 'tbeploads')
  result <- util_dps_entfacseg(pth)

  expect_equal(result$ent, "Hillsborough Co.")
  expect_equal(result$fac, "Falkenburg AWTP")
  expect_equal(result$seg, 2)
})
