
test_that("Check load calculations", {

  result <- ips |>
    filter(Year == 2020 & Month == 1 & facility == 'Busch Gardens' & source == 'D-002') |>
    mutate_if(is.numeric, round, 3)

  expect_equal(result$tn_load[[1]], 0.086)
  expect_equal(result$tp_load[[1]], 0.005)
  expect_equal(result$tss_load[[1]], 0.595)
  expect_equal(result$bod_load[[1]], 1.14)
  expect_equal(result$hy_load[[1]], 0.108)

})

test_that("Check outfall not found", {

  tmp <- read.table(psindpth, skip = 0, sep = '\t', header = T)
  tmp$Outfall.ID[tmp$Outfall.ID == 'D002'] <- 'R-007'
  tmpfl <- file.path(tempdir(), basename(psindpth))
  write.table(tmp, tmpfl, sep = '\t', row.names = F, quote = F)

  expect_error(anlz_ips_facility(tmpfl), "outfall id not in data: ps_ind_busch_busch_2020.txt, R-007")

  file.remove(tmpfl)

})

test_that("Verify output class", {

  expect_s3_class(ips, "data.frame")

})
