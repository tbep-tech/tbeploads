test_that("Extract entity, facility, and segment", {
  result <- util_ps_facinfo(psdompth)

  expect_equal(result, list(entity = "Hillsborough Co.", facname = "Falkenburg AWTP",
                           permit = "FL0040614", facid = "59", coastco = "381", coastid = "D_HC_3P"))
})

test_that("Extract entity, facility, and segment, as data frame", {
  result <- util_ps_facinfo(psdompth, asdf = TRUE)

  expect_equal(result, structure(list(entity = "Hillsborough Co.", facname = "Falkenburg AWTP",
                                      permit = "FL0040614", facid = "59", coastco = "381", coastid = "D_HC_3P"),
                                      row.names = c(NA, -1L
                                      ), class = c("tbl_df", "tbl", "data.frame")))
})
