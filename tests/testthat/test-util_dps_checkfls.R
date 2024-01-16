dirpth <- dirname(pth)
chkfls <- util_dps_checkfls(dirpth)

test_that("Check output class", {

  expect_s3_class(chkfls, 'tbl_df')

})

test_that("Check chk entries", {

  expect_true(all(chkfls$chk %in% c('ok', 'read error', 'check columns')))

})
