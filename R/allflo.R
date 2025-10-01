#' Data frame of all flow data used in \code{\link{anlz_nps_gaged}} and \code{\link{anlz_nps_ungaged}}
#'
#' Data frame of all flow data used in \code{\link{anlz_nps_gaged}} and \code{\link{anlz_nps_ungaged}}
#'
#' @format A \code{data.frame} of monthly mean daily flow data for select basins
#'
#' @details Monthly flow data at select stations used for estimating non-point source gaged and ungaged loads.  Created using the \code{\link{util_nps_getflow}} function. Includes data from the USGS API using \code{\link{util_nps_getusgsflow}} and from external sources using \code{\link{util_nps_getextflow}}. The data frame contains the following columns:
#'
#' \itemize{
#'    \item \code{basin}: Character string for the basin or gauge location
#'    \item \code{yr}: Year of the observation
#'    \item \code{mo}: Month of the observation
#'    \item \code{flow_cfs}: Numeric value for the average daily flow in cubic feet per second (cfs)
#' }
#' @seealso \code{\link{util_nps_getusgsflow}}, \code{\link{util_nps_getextflow}}, \code{\link{util_nps_getflow}}
#'
#' @examples
#' allflo
"allflo"
