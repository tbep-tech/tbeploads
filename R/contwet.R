#' Upper Floridan Aquifer potentiometric surface contour lines, wet season 2022
#'
#' @format A \code{\link[sf]{sf}} object
#'
#' @details Contour lines representing the potentiometric surface of the Upper
#'   Floridan Aquifer for the wet season (September 2022), clipped to the Tampa
#'   Bay watershed (\code{\link{tbfullshed}}). Retrieved from the FDEP / Florida
#'   Geological Survey ArcGIS REST service. The data includes the following
#'   columns.
#'
#' \itemize{
#'   \item \code{CONTOUR}: Integer, potentiometric surface elevation in feet
#'     above mean sea level (range 10-110 ft for the Tampa Bay area)
#'   \item \code{MONTH_YEAR}: Character, survey date (\code{"September 2022"})
#'   \item \code{geometry}: The geometry column (LINESTRING)
#' }
#'
#' Wet season is represented by September observations. Dry season equivalent
#' is \code{\link{contdry}}.
#'
#' Projection is NAD83(2011) / Florida West (ftUS), CRS 6443.
#'
#' @examples
#' \dontrun{
#' contwet <- util_gw_getcontour("wet", 2022)
#' save(contwet, file = "data/contwet.RData", compress = "xz")
#' }
#' contwet
"contwet"
