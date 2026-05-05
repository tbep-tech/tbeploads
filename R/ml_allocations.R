#' TBNMC TN load allocations for industrial material loss (ML) facilities
#'
#' @format A \code{data.frame}
#'
#' @details TN load allocations assigned to industrial material loss facilities
#' under the Tampa Bay Nitrogen Management Consortium (TBNMC) framework.
#'
#' \itemize{
#'   \item \code{entity}: Entity name matching the \code{\link{facilities}}
#'     table convention
#'   \item \code{facname}: Facility name matching the \code{\link{facilities}}
#'     table convention; \code{NA} for shared-allocation groups (see below)
#'   \item \code{bay_seg}: Integer bay segment identifier (2 = Hillsborough Bay,
#'     4 = Lower Tampa Bay)
#'   \item \code{alloc_tons}: Allocation in tons TN per year
#'   \item \code{ishared}: Logical; \code{TRUE} when the allocation is shared
#'     across multiple facilities. When \code{TRUE}, the combined load from all
#'     facilities belonging to the same entity and bay segment is compared to
#'     the single \code{alloc_tons} value.
#' }
#'
#' The three Mosaic material loss facilities (Big Bend, Riverview, Tampa Marine)
#' share a single 3.30 ton/year allocation in Hillsborough Bay; they are
#' represented by one row (\code{ishared = TRUE}, \code{facname = NA}).
#' All other entries are non-shared (\code{ishared = FALSE}) with one row per
#' facility.
#'
#' @examples
#' ml_allocations
"ml_allocations"
