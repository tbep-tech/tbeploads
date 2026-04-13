#' Calculate IPS loads and summarize
#'
#' Calculate IPS loads and summarize
#'
#' @param fls vector of file paths to raw entity data, one to many
#' @param summ `r summ_params('summ')`
#' @param summtime `r summ_params('summtime')`
#'
#' @details
#' Input data files in \code{fls} are first processed by \code{\link{anlz_ips_facility}} to calculate IPS loads for each facility and outfall.  `r summ_params('descrip')`  Options for \code{summ} are \code{'entity'} to summarize by entity, \code{'facility'} to summarize by facility, \code{'basin'} to summarize by drainage basin (retains the \code{basin} column for use with \code{\link{anlz_nps_psremove}}), \code{'segment'} to summarize by bay segment, and \code{'all'} to summarize across all segments.
#'
#' @return data frame with loading data for TP, TN, TSS, and BOD as tons per month/year and hydro load as million cubic meters per month/year
#' @export
#'
#' @seealso \code{\link{anlz_ips_facility}}
#'
#' @examples
#' fls <- list.files(system.file('extdata/', package = 'tbeploads'),
#'   pattern = 'ps_ind_', full.names = TRUE)
#' anlz_ips(fls)
anlz_ips <- function(fls, summ = c('entity', 'facility', 'basin', 'segment', 'all'), summtime = c('month', 'year')){

  summ <- match.arg(summ)
  summtime <- match.arg(summtime)

  # get facility and outfall level data
  ipsbyfac <- anlz_ips_facility(fls)

  # add bay segment and source, there should only b loads to hills, middle, and lower tampa bay
  ipsld <- ipsbyfac  |>
    dplyr::arrange(coastco) |>
    dplyr::left_join(dbasing, by = "coastco") |>
    dplyr::mutate(
      segment = dplyr::case_when(
        bayseg == 1 ~ "Old Tampa Bay",
        bayseg == 2 ~ "Hillsborough Bay",
        bayseg == 3 ~ "Middle Tampa Bay",
        bayseg == 4 ~ "Lower Tampa Bay",
        TRUE ~ NA_character_
      ),
      source = 'IPS'
    ) |>
    dplyr::select(-hectare, -coastco, -name, -bayseg)

  if (summ != 'basin')
    ipsld <- dplyr::select(ipsld, -basin)

  ##
  # summarize by selection

  out <- util_summ(ipsld, summ = summ, summtime = summtime)

  return(out)

}
