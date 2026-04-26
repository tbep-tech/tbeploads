#' Upper Floridan Aquifer potentiometric surface contour lines, dry season 2022
#'
#' @format A \code{\link[sf]{sf}} object
#'
#' @details Contour lines representing the potentiometric surface of the Upper
#'   Floridan Aquifer for the dry season (May 2022), clipped to the Tampa Bay
#'   watershed (\code{\link{tbfullshed}}). Retrieved from the FDEP / Florida
#'   Geological Survey ArcGIS REST service. The data includes the following
#'   columns.
#'
#' \itemize{
#'   \item \code{CONTOUR}: Integer, potentiometric surface elevation in feet
#'     above mean sea level (range 10-100 ft for the Tampa Bay area)
#'   \item \code{MONTH_YEAR}: Character, survey date (\code{"May 2022"})
#'   \item \code{geometry}: The geometry column (LINESTRING)
#' }
#'
#' Dry season is represented by May observations. Wet season equivalent is
#' \code{\link{contwet}}.
#'
#' Projection is NAD83(2011) / Florida West (ftUS), CRS 6443.
#'
#' @examples
#' \dontrun{
#' contdry <- util_gw_getcontour("dry", 2022)
#' save(contdry, file = "data/contdry.RData", compress = "xz")
#' }
#' contdry
"contdry"
