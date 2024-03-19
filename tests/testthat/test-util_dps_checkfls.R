dirpth <- dirname(pth)
chkfls <- util_dps_checkfls(dirpth)

test_that("Check output class", {

  expect_s3_class(chkfls, 'tbl_df')

})

test_that("Check chk entries", {

  expect_true(all(chkfls$chk %in% 'ok'))

})

test_that("Check file incorrect columns", {

  tmpfl <- tempfile(fileext = '.txt')
  write.table(NA, tmpfl)
  chkfls <- util_dps_checkfls(dirname(tmpfl))

  expect_true(chkfls$chk == 'check columns')

  file.remove(tmpfl)

})

test_that("Check file read error", {

  tmpfl <- tempfile(fileext = '.txt')
  writeLines(c("header1\theader2\theader3", "1\t2\t3", "a\tb"), tmpfl)
  chkfls <- util_dps_checkfls(dirname(tmpfl))

  expect_true(chkfls$chk == 'read error')

  file.remove(tmpfl)

})
