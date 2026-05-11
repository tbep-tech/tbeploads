#' Allocation assessment TN load corrections by bay segment and entity
#'
#' @format A \code{data.frame} with 43 rows and 4 columns:
#' \describe{
#'   \item{bay_seg}{Integer bay segment identifier}
#'   \item{entity}{MS4 jurisdiction or entity name}
#'   \item{ad_tons}{Atmospheric deposition TN offset (tons/yr)}
#'   \item{project_tons}{Net permitted project TN offset (tons/yr); negative
#'     values indicate a load credit}
#' }
#'
#' @details TN load offsets applied before hydrologic normalization in
#' \code{\link{anlz_aa}} for the 2022-2024 TBNMC assessment period. Values are
#' sourced from the SAS script \code{7_Basin_assessment2224.sas} and cover two
#' correction types: atmospheric deposition (AD) loads apportioned to each
#' entity jurisdiction, and net permitted project (AP) load credits. FDACS
#' agriculture entries (\code{entity = "All"}) carry irrigation AP reductions
#' only (\code{ad_tons = 0}). Negative \code{project_tons} values reflect
#' project credits that increase the allowable load.
#'
#' See \code{data-raw/aa_corrections.R} for construction.
#'
#' @examples
#' aa_corrections
"aa_corrections"
