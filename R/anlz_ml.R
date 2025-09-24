#' Calculate material loss (ML) loads and summarize
#'
#' Calculate material loss (ML) loads and summarize
#'
#' @param fls vector of file paths to raw entity data, one to many
#' @param summ `r summ_params('summ')`
#' @param summtime `r summ_params('summtime')`
#'
#' @details
#' Input data files in \code{fls} are first processed by \code{\link{anlz_ml_facility}} to calculate ML loads for each facility.  `r summ_params('descrip')` Options for \code{summ} are 'entity' to summarize by entity only, 'facility' to summarize by facility only, 'segment' to summarize by bay segment, and 'all' to summarize total load.  Options for \code{summtime} are 'month' to summarize by month and 'year' to summarize by year.  The default is to summarize by entity and month.
#'
#' @return data frame with loading data for TN as tons per month/year.  Columns for TP, TSS, BOD, and hydrologic load are also returned with zero load for consistency with other point source load calculation functions.
#'
#' @export
#'
#' @seealso \code{\link{anlz_ml_facility}}
#'
#' @examples
#' fls <- list.files(system.file('extdata/', package = 'tbeploads'),
#'   pattern = 'ps_indml', full.names = TRUE)
#' anlz_ml(fls)
anlz_ml <- function(fls, summ = c('entity', 'facility', 'segment', 'all'), summtime = c('month', 'year')){

  # get facility and outfall level data
  mlbyfac <- anlz_ml_facility(fls)

  # add bay segment and source, must use facilities object since no coastco
  baysegs <- facilities |>
    dplyr::filter(grepl('Material Losses', source)) |>
    dplyr::select(bayseg, entity, facility = facname)
  mlld <- mlbyfac  |>
    dplyr::left_join(baysegs, by = c('entity', 'facility')) |>
    dplyr::mutate(
      segment = dplyr::case_when(
        bayseg == 1 ~ "Old Tampa Bay",
        bayseg == 2 ~ "Hillsborough Bay",
        bayseg == 3 ~ "Middle Tampa Bay",
        bayseg == 4 ~ "Lower Tampa Bay",
        TRUE ~ NA_character_
      ),
      source = 'ML'
    ) |>
    dplyr::select(-bayseg)

  ##
  # summarize by selection

  out <- util_summ(mlld, summ = summ, summtime = summtime)

  return(out)

}
