#' Data frame of historical daily rainfall datas
#'
#' @format A \code{data.frame}
#'
#' @details Historical daily rain fall data for 388 stations through 2021. Columns are:
#'
#' \itemize{
#'    \item \code{COOPID}: Character string for the station id
#'    \item \code{date}: Date for the observation
#'    \item \code{Prcp}: Numeric value for the amount of rainfall in inches
#'}
#'
#' @examples
#' \dontrun{
#' pth1 <- 'T:/03_BOARDS_COMMITTEES/05_TBNMC/2022_RA_Update/01_FUNDING_OUT/DELIVERABLES/TO-9/'
#' pth2 <- 'datastick_deliverables/LoadingCodes&Datasets/2021/AtmosphericDeposition2021/'
#' fl <- 'fl_rain_por_220223v93.sas7bdat'
#' pth <- file.path(pth1, pth2, fl)
#' rain_historic <- haven::read_sas(pth)
#'
#' save(rain_historic, file = 'data/rain_historic.RData', compress = 'xz')
#' }
"rain_historic"
