#' Calculate IPS from raw facility data
#'
#' Calculate IPS from raw facility data
#'
#' @param fls vector of file paths to raw facility data, one to many
#'
#' @details
#' Input data should include flow as million gallons per day, and conc as mg/L.  Steps include:
#'
#' 1. Multiply flow by day in month to get million gallons per month
#' 1. Multiply flow by 3785.412 to get cubic meters per month
#' 1. Multiply conc by flow and divide by 1000 to get kg var per month
#' 1. Multiply m3 by 1000 to get L, then divide by 1e6 to convert mg to kg, same as dividing by 1000
#'
#' @return data frame with loading data for TP, TN, TSS, and BOD as tons per month and hydro load as million cubic meters per month.  Information for each entity, facility, and outfall is retained.
#'
#' @seealso \code{\link{anlz_dps}}
#'
#' @export
#'
#' @examples
#' fls <- list.files(system.file('extdata/', package = 'tbeploads'),
#'   pattern = 'ps_ind', full.names = TRUE)
#' anlz_ips_facility(fls)
anlz_ips_facility <- function(fls){

  ##
  # import and prep all data

  ipsprep <- tibble::tibble(
    fls = fls
  ) |>
    dplyr::group_by(fls) |>
    tidyr::nest(.key = 'dat') |>
    dplyr::mutate(
      dat = purrr::map(fls, read.table, skip = 0, sep = '\t', header = T),
      dat = purrr::map(dat, util_ps_addcol),
      dat = purrr::map(dat, util_ps_checkuni),
      dat = purrr::map(dat, util_ps_fillmis),
      entinfo = purrr::map(fls, util_ps_facinfo, asdf = T)
    ) |>
    dplyr::ungroup() |>
    tidyr::unnest('entinfo') |>
    tidyr::unnest('dat')

  out <- ipsprep

  return(out)

}
