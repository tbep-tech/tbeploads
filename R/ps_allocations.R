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
#'   \item \code{alloc_tons}: Allocation in tons TN per year. For
#'     \code{ishared} permits, this is the group's collective allocation (the
#'     same value repeated on every member row), not an individual permit
#'     allocation
#'   \item \code{hydro_affected}: Logical; \code{TRUE} for permits whose IPS
#'     load \code{\link{anlz_aa}} hydrologically normalizes
#'   \item \code{ishared}: Logical; \code{TRUE} when the permit is jointly
#'     assessed against a collective allocation shared with other permits
#'     (see \code{alloc_tons})
#'   \item \code{group_id}: Character identifier for the shared group a permit
#'     belongs to (\code{NA} when \code{ishared} is \code{FALSE}). Provided so
#'     shared-group membership can be recovered directly rather than inferred
#'     from matching \code{entity} + \code{alloc_tons}
#' }
#'
#' The 19 Mosaic facilities in Hillsborough Bay (Bartow, Bonnie, Ft. Lonesome,
#' Green Bay, Hookers Prairie, Mulberry Phosphogypsum Stack, Mulberry Plant,
#' New Wales Chemical Plant, Nichols Mine, Plant City, Riverview, Riverview
#' Stack Closure, South Pierce, Tampa Ammonia Terminal, Tampa Marine
#' Terminal, Hopewell, Kingsford, Port Sutton, Black Point) share a single
#' 124.1 ton/year allocation (\code{ishared = TRUE}, \code{group_id =
#' "ips_mosaic_hb"}). Kinder Morgan Tampaplex, Port Sutton, and Hartford
#' Terminal likewise share a single 25.0 ton/year allocation (\code{group_id =
#' "ips_kinder_morgan"}). All other permits are non-shared (\code{ishared =
#' FALSE}, \code{group_id = NA}).
#'
#' @examples
#' ps_allocations
"ps_allocations"
