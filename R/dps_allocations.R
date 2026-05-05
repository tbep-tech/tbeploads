#' TBNMC TN load allocations for DPS domestic wastewater facilities
#'
#' @format A \code{data.frame}
#'
#' @details TN load allocations assigned to individual domestic point source
#' (DPS) facilities under the Tampa Bay Nitrogen Management Consortium (TBNMC)
#' framework.
#'
#' \itemize{
#'   \item \code{entity}: Short entity name matching the \code{\link{facilities}}
#'     table convention (e.g., \code{"Clearwater"}, \code{"Hillsborough Co."})
#'   \item \code{entity_full}: Full entity name as listed in the source
#'     allocation file (e.g., \code{"City of Clearwater"},
#'     \code{"Hillsborough County"})
#'   \item \code{facname}: Facility name matching the \code{\link{facilities}}
#'     table convention
#'   \item \code{bay_seg}: Integer bay segment identifier (1 = Old Tampa Bay,
#'     2 = Hillsborough Bay, 3 = Middle Tampa Bay, 4 = Lower Tampa Bay,
#'     55 = Remaining Lower Tampa Bay)
#'   \item \code{source}: DPS discharge type; one of \code{"DPS - end of pipe"}
#'     (direct surface water discharge) or \code{"DPS - reuse"} (reclaimed
#'     water reuse)
#'   \item \code{alloc_tons}: Allocation in tons TN per year
#' }
#'
#' TECO Big Bend and Tropicana are not included: TECO is an industrial reuse
#' customer rather than a direct discharger, and Tropicana is classified as an
#' industrial point source in the \code{\link{facilities}} table. Neither can
#' be matched to DPS load data from \code{\link{anlz_dps_facility}}.
#'
#' @examples
#' dps_allocations
"dps_allocations"
