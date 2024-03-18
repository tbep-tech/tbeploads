pth <- system.file('extdata/ps_dom_hillsco_falkenburg_2019.txt', package = 'tbeploads')
dat <- read.table(pth, skip = 0, sep = '\t', header = TRUE)
dat <- util_dps_checkuni(dat)

test_that("Check concentration and flow zero if flow is NA", {

  chkdat <- dat
  chkdat$flow_mgd[1] <- NA
  chkdat <- util_dps_fillmis(chkdat)
  result <- chkdat$tn_mgl[1]

  expect_identical(result, 0)

  result <- chkdat$flow[1]

  expect_identical(result, 0)

})

test_that("Check flow as zero if negative", {

  chkdat <- dat
  chkdat$flow_mgd[1] <- -5
  chkdat <- util_dps_fillmis(chkdat)
  result <- chkdat$flow[1]

  expect_identical(result, 0)

})

test_that("Check correct average for missing concentration", {

  chkdat <- dat
  chkdat$tn_mgl[2:3] <- NA
  chkdat <- util_dps_fillmis(chkdat)
  result <- unique(chkdat$tn_mgl[2:3])

  expected <- mean(dat$tn_mgl[c(1, 4:12)])

  expect_identical(result, expected)

})
