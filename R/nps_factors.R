#' NPS disaggregation factors for allocation assessment
#'
#' @format A named \code{list} with two elements: \code{rc} and \code{tn}
#'
#' @details Pre-computed disaggregation factors used by \code{\link{anlz_aa}} to
#' allocate basin-level NPS TN loads to individual MS4 jurisdictions. Created by
#' \code{\link{util_aa_npsfactors}} from \code{\link{tbbase}}, \code{\link{rcclucsid}},
#' and \code{\link{emc}}. \code{\link{tbbase}} is tied to specific land use and soils
#' data and must be rebuilt whenever update are available.
#'
#' \code{rc}: Data frame of runoff coefficient factors
#' \itemize{
#'   \item \code{bay_seg}: Integer bay segment identifier
#'   \item \code{basin}: Drainage basin identifier
#'   \item \code{entity}: MS4 jurisdiction or entity name
#'   \item \code{category}: Allocation category (Agriculture, Other, or NA for urban MS4)
#'   \item \code{clucsid}: Land use class identifier
#'   \item \code{factor_rc}: Entity's fractional share of area x runoff coefficient
#'     within each basin x CLUCSID; sums to 1 across entities per basin x CLUCSID
#' }
#'
#' \code{tn}: Data frame of TN concentration factors
#' \itemize{
#'   \item \code{bay_seg}: Integer bay segment identifier
#'   \item \code{basin}: Drainage basin identifier
#'   \item \code{clucsid}: Land use class identifier
#'   \item \code{factor_tn}: CLUCSID's fractional share of basin TN load weighted
#'     by area x event mean TN concentration; sums to 1 across CLUCSIDs per basin
#' }
#'
#' See "data-raw/nps_factors.R" and \code{\link{util_aa_npsfactors}} for creation.
#'
#' @examples
#' nps_factors
"nps_factors"
