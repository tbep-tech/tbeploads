test_that("Check util_nps_landsoil returns correct format", {

  result <- util_nps_landsoil(tbbase)
  expect_s3_class(result, "data.frame")
  expect_true(all(c("bay_seg", "basin", "drnfeat", "clucsid", "hydgrp", "improved", "area") %in% names(result)))

})
