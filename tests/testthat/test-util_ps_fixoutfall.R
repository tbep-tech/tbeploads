test_that("Check correct out fall format", {

  chk <- data.frame(Outfall.ID = c("OutfallD001", " OutfallD-003 ", "D002", " D-002", "EFI1011  ", "D02R", "EMD"))
  expected <- data.frame(Outfall.ID = c('D-001', 'D-003', 'D-002', 'D-002', 'EFI-1011', "D-02R", "EMD"))
  result <- util_ps_fixoutfall(chk)
  expect_equal(result, expected)

})

