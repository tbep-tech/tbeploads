#' Data frame of daily rainfall data from NOAA NCDC National Weather Service (NWS) sites from 2017 to 2023
#'
#' Data frame of daily rainfall data from NOAA NCDC National Weather Service (NWS) sites from 2017 to 2023
#'
#' @format A \code{data.frame}
#'
#' @details Used for estimating atmospheric deposition and non-point source ungaged loads.  Created using the \code{\link{util_getrain}} function. The data frame contains the following columns:
#'
#' \itemize{
#'    \item \code{station}: Character string for the station id
#'    \item \code{date}: Date for the observation
#'    \item \code{Year}: Numeric value for the year of the observation
#'    \item \code{Month}: Numeric value for the month of the observation
#'    \item \code{Day}: Numeric value for the day of the observation
#'    \item \code{rainfall}: Numeric value for the amount of rainfall in inches
#'}
#'
#' @seealso \code{\link{util_getrain}}
#'
#' @examples
#' rain
"rain"
