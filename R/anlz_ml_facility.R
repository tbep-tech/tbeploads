#' Calculate material losses (ML) from raw facility data
#'
#' Calculate material losses (ML) from raw facility data
#'
#' @param fls vector of file paths to raw facility data, one to many
#'
#' @details
#' Input data should be one row per year per facility, where the row shows the total tons per year of total nitrogen loss.  Input files are often created by hand based on reported annual tons of nitrogen shipped at each facility.  The material losses as tons/yr are estimated from the tons shipped using an agreed upon loss rate.  Values reported in the example files represent the estimated loss as the total tons of N shipped each year multiplied by 0.0023 and divided by 2000. The total N shipped at a facility each year can be obtained using a simple back-calculation (multiply by 2000, divide by 0.0023).
#'
#' @return data frame that is nearly identical to the input data except results are shown as monthly load as the annual loss estimate divided by 12.  This is for consistency of reporting with other loading sources.
#'
#' @seealso \code{\link{anlz_ml}}
#'
#' @export
#'
#' @examples
#' fls <- list.files(system.file('extdata/', package = 'tbeploads'),
#'   pattern = 'ps_indml', full.names = TRUE)
#' anlz_ml_facility(fls)
anlz_ml_facility <- function(fls){

  ##
  # import and prep all data

  mlprep <- tibble::tibble(
      fls = fls
    ) |>
    dplyr::group_by(fls) |>
    tidyr::nest(.key = 'dat') |>
    dplyr::mutate(
      dat = purrr::map(fls, read.table, skip = 0, sep = '\t', header = T),
      entinfo = purrr::map(fls, util_ps_facinfo, asdf = T)
    ) |>
    dplyr::ungroup() |>
    tidyr::unnest('entinfo') |>
    tidyr::unnest('dat')

  ##
  # expand to monthly

  ml <- tidyr::crossing(
      unique(mlprep[, c('Year', 'entity', 'facname')]),
      Month = 1:12
    ) |>
    dplyr::full_join(mlprep, by = c('Year', 'entity', 'facname')) |>
    dplyr::mutate(
      tn_load = tn_tonsyr / 12,
      tp_load = NA,
      tss_load = NA,
      bod_load = NA,
      hy_load = NA,
      source = NA
    ) |>
    dplyr::select(
      Year,
      Month,
      entity,
      facility = facname,
      coastco,
      source,
      tn_load,
      tp_load,
      tss_load,
      bod_load,
      hy_load
    )

  out <- ml

  return(out)

}
