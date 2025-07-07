#' Lookup table for CLUCSID runoff coefficients
#'
#' @format A data frame
#'
#' @details Used to create the land use runoff coefficient data used in \code{\link{util_nps_landsoilrc}}.
#'
#' \itemize{
#'  \item \code{clucsid}: Numeric value for CLUCSID
#'  \item \code{hsg}: Numeric value for the hydrologic soil group
#'  \item \code{dry_rc}: Numeric value for dry weather runoff coefficient
#'  \item \code{wet_rc}: Numeric value for wet weather runoff coefficient
#'}
#'
#' @examples
#' \dontrun{
#' rcclucsid <- read.csv('data-raw/rc_clucsid.csv', stringsAsFactors = F, header = T)
#'
#' save(rcclucsid, file = 'data/rcclucsid.RData', compress = 'xz')
#' }
#' rcclucsid
"rcclucsid"
