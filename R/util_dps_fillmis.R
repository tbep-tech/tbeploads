#' Fill missing DPS data with annual average
#'
#' Fill missing DPS data with annual average
#'
#' @param dat data frame from raw entity data as \code{data.frame}
#'
#' @details
#' Missing concentration data are replaced with the average for the outfall in a given year. All flow data are also floored at zero.  Rows with missing flow data are assigned 0 for all data.
#'
#' @return Input data frame as is if no missing values, otherwise missing data filled as described above.
#'
#' @export
#'
#' @examples
#' pth <- system.file('extdata/ps_dom_hillsco_falkenburg_2019.txt', package = 'tbeploads')
#' dat <- read.table(pth, skip = 0, sep = '\t', header = TRUE)
#' dat <- util_dps_checkuni(dat)
#' util_dps_fillmis(dat)
util_dps_fillmis <- function(dat){

  out <- dat |>
    dplyr::mutate(dplyr::across(dplyr::matches('tn|tp|tss|bod|load'), ~ ifelse(is.na(.x), mean(.x, na.rm = TRUE), .x)) ,
                  .by = c('Year', 'outfall')) |>
    dplyr::mutate(flow_mgd = pmax(0, flow_mgd)) |>
    dplyr::mutate(dplyr::across(dplyr::matches('tn|tp|tss|bod|load'), ~ ifelse(is.na(flow_mgd), 0, .x))) |>
    dplyr::mutate(flow_mgd = ifelse(is.na(flow_mgd), 0, flow_mgd))

  return(out)

}
