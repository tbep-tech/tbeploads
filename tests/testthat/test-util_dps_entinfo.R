test_that("Extract entity, facility, and segment", {
  pth <- system.file('extdata/ps_dom_hillsco_falkenburg_2019.txt', package = 'tbeploads')
  result <- util_dps_entinfo(pth)

  expect_equal(result, list(entity = "Hillsborough Co.", facname = "Falkenburg AWTP",
                           permit = "FL0040614", facid = "59", coastco = "381", coastid = "D_HC_3P"))
})

test_that("Extract entity, facility, and segment, as data frame", {
  pth <- system.file('extdata/ps_dom_hillsco_falkenburg_2019.txt', package = 'tbeploads')
  result <- util_dps_entinfo(pth, asdf = TRUE)

  expect_equal(result, structure(list(entity = "Hillsborough Co.", facname = "Falkenburg AWTP",
                                      permit = "FL0040614", facid = "59", coastco = "381", coastid = "D_HC_3P"),
                                      row.names = c(NA, -1L
                                      ), class = c("tbl_df", "tbl", "data.frame")))
})
