
test_that("Check end of pipe load calculations", {

  result <- dps |>
    filter(Year == 2021 & Month == 1 & facility == 'City of Clearwater Northeast AWWTF' & source == 'D-001') |>
    mutate_if(is.numeric, round, 3)

  expect_equal(result$tn_load[[1]], 0.862)
  expect_equal(result$tp_load[[1]], 6.037)
  expect_equal(result$tss_load[[1]], 0.452)
  expect_equal(result$bod_load[[1]], 1.144)
  expect_equal(result$hy_load[[1]], 0.663)

})

test_that("Check outfall not found", {

  tmp <- read.table(psdompth, skip = 0, sep = '\t', header = T)
  tmp$Outfall.ID[tmp$Outfall.ID == 'R-001'] <- 'R-007'
  tmpfl <- file.path(tempdir(), basename(psdompth))
  write.table(tmp, tmpfl, sep = '\t', row.names = F, quote = F)

  expect_error(anlz_dps_facility(tmpfl), "outfall id not in data: ps_dom_hillsco_falkenburg_2019.txt, R-007")

  file.remove(tmpfl)

})

test_that("Verify output class", {

  expect_s3_class(dps, "data.frame")

})
