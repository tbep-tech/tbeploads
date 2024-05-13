pth <- system.file('extdata/ps_dom_hillsco_falkenburg_2019.txt', package = 'tbeploads')
dat <- read.table(pth, skip = 0, sep = '\t', header = T)

# Test 1: Check if the function throws an error when flow units are not in mgd
test_that("Flow units are checked correctly", {
  datchk <- dat
  names(datchk)[names(datchk) == "Average.Daily.Flow..ADF...mgd."] <- "Average.Daily.Flow..ADF...mgm."
  expect_error(util_ps_checkuni(datchk), "Flow not as mgd")
})

# Test 2: Check if the function throws an error when concentration units are not in mg/l
test_that("Concentration units are checked correctly", {
  datchk <- dat
  datchk$Total.N.Unit <- 'mg/kg'
  expect_error(util_ps_checkuni(datchk), "Concentration not as mg/l")
})

# Test 3: Check if the function returns the expected output
test_that("Function returns the expected output", {
  res <- util_ps_checkuni(dat)
  expect_s3_class(res, "data.frame")
})
