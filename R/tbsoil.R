#' Simple feature polygons of soil data in the Tampa Bay Estuary Program boundary
#'
#' @format A \code{\link[sf]{sf}} object
#'
#' @details Used for estimating ungaged non-point source (NPS) loads. The data includes the following columns.
#'
#' \itemize{
#'  \item \code{FLUCCSCODE}: Numeric value for the Florida Land Use, Cover and Forms Classification System (FLUCCS) code
#'  \item \code{FLUCCSDESC}: Character describing the FLUCCS description
#'  \item \code{geometry}: The geometry column
#'}
#'
#' Projection is NAD83(2011) / Florida West (ftUS), CRS 6443.
#'
#' @examples
#' \dontrun{
#' # use SWFWMD API
#' tbsoil <- util_nps_getswfwmd('soil')
#'
#' save(tbsoil, file = 'data/tbsoil.RData', compress = 'xz')
#' }
#' tbsoil
"tbsoil"
