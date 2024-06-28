#' Data frame of distances of target locations to National Weather Service (NWS) sites
#'
#' Data frame of distances of target locations to National Weather Service (NWS) sites
#'
#' @format A \code{data.frame}
#'
#' @details Used for estimating atmospheric deposition. The data frame contains the following columns:
#'
#' \itemize{
#'  \item \code{target}: Numeric identifier for the target location
#'  \item \code{targ_x}: Numeric value for the x-coordinate of the target location (UTM)
#'  \item \code{targ_y}: Numeric value for the y-coordinate of the target location (UTM)
#'  \item \code{matchsit}: Character string for the NWS site that matches the target location
#'  \item \code{distance}: Numeric value for the distance (m) between the target and NWS site
#'  \item \code{invdist2}: Numeric value for the inverse distance squared (1/m^2) between the target and NWS site
#'}
#'
#' @examples
#' ad_distance
"ad_distance"
