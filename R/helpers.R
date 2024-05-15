summ_params <- function(x){

  out <- list(
    summ = 'chr string indicating how the returned data are summarized, see details',
    summtime = 'chr string indicating how the returned data are summarized temporally (month or year), see details',
    descrip = "The data are summarized differently based on the `summ` and `summtime` arguments.  All loading data are summed based on these arguments, e.g., by bay segment (`summ = 'segment'`) and year (`summtime = 'year'`)."
  )

  out <- out[[x]]

  return(out)

}
