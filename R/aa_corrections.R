#' Allocation assessment TN load corrections by bay segment and entity
#'
#' @format A \code{data.frame}
#'
#' @details TN load offsets applied before hydrologic normalization in
#' \code{\link{anlz_aa}}. Two correction types are combined per entity: AD
#' (atmospheric deposition) load estimates from \code{\link{anlz_ad}}, and
#' permitted project load credits. The current object is a zero-row placeholder;
#' it should be replaced with actual values when available.
#'
#' \itemize{
#'   \item \code{bay_seg}: Integer bay segment identifier
#'   \item \code{entity}: MS4 jurisdiction or entity name
#'   \item \code{ad_tons}: Atmospheric deposition TN offset (tons/yr)
#'   \item \code{project_tons}: Permitted project TN offset (tons/yr)
#' }
#'
#' See "data-raw/aa_corrections.R" for creation.
#'
#' @examples
#' aa_corrections
"aa_corrections"
