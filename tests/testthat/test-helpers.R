test_that("summ_params returns expected output", {

  expect_equal(summ_params('summ'), 'chr string indicating how the returned data are summarized, see details')
  expect_equal(summ_params('summtime'), 'chr string indicating how the returned data are summarized temporally (month or year), see details')
  expect_equal(summ_params('descrip'), "The data are summarized differently based on the `summ` and `summtime` arguments.  All loading data are summed based on these arguments, e.g., by bay segment (`summ = 'segment'`) and year (`summtime = 'year'`).")

})
