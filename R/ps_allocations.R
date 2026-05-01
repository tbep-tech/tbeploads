#' TBNMC TN load allocations for IPS point source facilities
#'
#' @format A \code{data.frame}
#'
#' @details TN load allocations assigned to individual industrial point source
#' facilities under the Tampa Bay Nitrogen Management Consortium (TBNMC) framework.
#'
#' \itemize{
#'   \item \code{entity}: Entity name (owner/operator)
#'   \item \code{facname}: Facility name as used in \code{\link{facilities}}
#'   \item \code{permit}: NPDES permit number
#'   \item \code{alloc_pct}: Fractional allocation share (0-1)
#'   \item \code{alloc_tons}: Allocation in tons TN per year
#' }
#'
#' See "data-raw/ps_allocations.R" for creation.
#'
#' @examples
#' ps_allocations
"ps_allocations"
