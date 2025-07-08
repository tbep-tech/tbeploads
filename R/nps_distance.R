#' Data frame of distances of drainage basin locations to National Weather Service (NWS) sites
#'
#' Data frame of distances of drainage basin locations to National Weather Service (NWS) sites
#'
#' @format A \code{data.frame}
#'
#' @details Used for estimating non-point source (NPS) ungaged loads. The data frame contains the following columns:
#'
#' \itemize{
#'  \item \code{target}: Numeric identifier for the drainage basin
#'  \item \code{targ_x}: Numeric value for the x-coordinate of the drainage basin location (WGS 84, UTM Zone 17N, CRS 32617)
#'  \item \code{targ_y}: Numeric value for the y-coordinate of the drainage basin location (WGS 84, UTM Zone 17N, CRS 32617)
#'  \item \code{matchsit}: Numeric for the NWS site that matches the drainage basin location
#'  \item \code{distance}: Numeric value for the distance (m) between the drainage basin coordinate and NWS site
#'  \item \code{invdist2}: Numeric value for the inverse distance squared (1/m^2) between the drainage basin coordinate and NWS site
#'}
#'
#' @examples
#' nps_distance
"nps_distance"
