#' Historic 1992-1994 mean total water load baseline by bay segment and basin
#'
#' @format A \code{data.frame}
#'
#' @details Mean total water load for the 1992-1994
#' baseline period, used for hydrologic normalization in the allocation assessment.
#' Values are in million cubic meters per year.
#'
#' \itemize{
#'   \item \code{bay_seg}: Integer bay segment identifier
#'   \item \code{basin}: Drainage basin identifier
#'   \item \code{mean_h2o_9294}: Mean 1992-1994 total water load (million m3/yr)
#' }
#'
#' See "data-raw/hydro_baseline.R" for creation.
#'
#' @examples
#' hydro_baseline
"hydro_baseline"
