test_that("Check util_nps_landsoilrc returns correct format", {

  result <- util_nps_landsoilrc(tbbase)
  expect_s3_class(result, "data.frame")

  nms <- c("bay_seg", "basin", "drnfeat", "clucsid", "hydgrp", "area", "dry_rc", "wet_rc", "mo",
           "rc", "rca", "tot_rca", "yr")
  expect_true(all(nms %in% names(result)))

})
