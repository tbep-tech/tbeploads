dat <- read.table(pth, skip = 0, sep = '\t', header = TRUE)

test_that("util_dps_addcol function add TN", {

  datchk <- subset(dat, select = -c(Total.N, Total.N.Unit))
  result <- util_dps_addcol(datchk)
  expect_true("Total.N" %in% names(result))
  expect_true("Total.N.Unit" %in% names(result))

})

test_that("util_dps_addcol function add TP", {

  datchk <- subset(dat, select = -c(Total.P, Total.P.Unit))
  result <- util_dps_addcol(datchk)
  expect_true("Total.P" %in% names(result))
  expect_true("Total.P.Unit" %in% names(result))

})

test_that("util_dps_addcol function adds TSS", {

  datchk <- subset(dat, select = -c(TSS, TSS.Unit))
  result <- util_dps_addcol(datchk)
  expect_true("TSS" %in% names(result))
  expect_true("TSS.Unit" %in% names(result))

})

test_that("util_dps_addcol function add BOD", {

  datchk <- subset(dat, select = -c(BOD, BOD..Unit))
  result <- util_dps_addcol(datchk)
  expect_true("BOD" %in% names(result))
  expect_true("BOD.Unit" %in% names(result))

})

test_that("util_dps_addcol function uses CBOD for BOD if present", {

  datchk <- dat
  names(datchk) <- gsub('^BOD', 'CBOD', names(datchk))
  result <- util_dps_addcol(datchk)
  expect_true("BOD" %in% names(result))
  expect_true("BOD.Unit" %in% names(result))

})
