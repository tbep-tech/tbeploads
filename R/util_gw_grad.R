#' Compute hydraulic gradient per bay segment from UFA potentiometric surface contours
#'
#' @param contours \code{\link[sf]{sf}} object of Upper Floridan Aquifer contour
#'   lines produced by \code{\link{util_gw_getcontour}}.
#' @param segs \code{\link[sf]{sf}} object of sub-watershed polygons. Defaults
#'   to \code{\link{tbsubshed}}.
#' @param shoreline \code{\link[sf]{sf}} object of bay segment polygons used to
#'   measure distance from the watershed high point to the bay. Defaults to
#'   \code{\link{tbsegdetail}}.
#' @param north_segs named numeric vector mapping bay segment IDs to northward
#'   extension distances (in CRS units, US Survey Feet for EPSG 6443). Segments
#'   listed here have a rectangular extension appended to the north side of
#'   their sub-watershed polygon before the contour clipping step, allowing the
#'   high-point search to reach potentiometric highs that lie north of the
#'   standard subwatershed boundary.  Use this for segments such as Old Tampa
#'   Bay (segment 1) where the high point is north of the subwatershed. Names
#'   must be coercible to the integer bay segment IDs in \code{segs}.  The
#'   \code{contours} passed to this function must already cover the extended
#'   area — pass the same distance (or larger) as \code{north_dist} in
#'   \code{\link{util_gw_getcontour}}.  Default \code{NULL} (no extension).
#'
#' @details
#' Computes the Floridan aquifer hydraulic gradient \eqn{I} (ft/mile) for each
#' bay segment using Darcy's Law as applied in the Tampa Bay loading model
#' (Zarbock et al., 1994):
#'
#' \deqn{I = \frac{\text{elevation (ft)}}{\text{distance to shoreline (miles)}}}
#'
#' where elevation is the maximum UFA potentiometric surface contour value
#' within the (optionally extended) segment watershed, and distance is the
#' straight-line distance from that contour's representative point to the
#' nearest bay shoreline.
#'
#' The season (dry or wet) is inferred from the \code{MONTH_YEAR} field in
#' \code{contours} (\code{"May"} = dry, \code{"September"} = wet). Segments
#' with no reliably computable Floridan aquifer gradient receive a value of 0:
#' \itemize{
#'   \item Dry season: segments 4, 5, 6, 7, 55
#'   \item Wet season: segments 4, 5, 6, 7, 55 — Lower Tampa Bay, Terra Ceia
#'     Bay, and Manatee River are included here because the subwatershed
#'     geometry does not reliably capture the correct potentiometric high point
#'     for those segments, and the analyst-specified wet-season gradients
#'     (50/32, 50/34, and 50/40 ft/mile for the 2022-2024 analysis) were read
#'     manually from the 2021 FDEP map rather than computed algorithmically.
#' }
#'
#' \strong{Hillsborough Bay (segment 2):}
#' Segment 2 uses a weighted average of three sub-zone gradients following the
#' original flow net analysis. Sub-zones are constructed by unioning
#' \code{\link{tbdbasin}} drainage basins:
#' \itemize{
#'   \item Polk County drainage (weight 0.4): basins 02301000, 02301500
#'   \item Pasco County / Hillsborough River drainage (weight 0.3): basins
#'     02300700, 02301300, 02301750, TBYPASS
#'   \item Alafia River drainage (weight 0.3): basins 02301695, 02303000,
#'     02303330, 02304500, 204-2, 205-2, 206-2
#' }
#'
#' @return A data frame with columns:
#' \itemize{
#'   \item \code{bay_seg}: integer, bay segment number
#'   \item \code{grad}: numeric, hydraulic gradient (ft/mile); 0 for segments
#'     with no reliably computable Floridan aquifer gradient
#' }
#'
#' @export
#'
#' @examples
#' util_gw_grad(contdry)
#' util_gw_grad(contwet)
util_gw_grad <- function(contours, segs = tbsubshed, shoreline = tbsegdetail,
                         north_segs = NULL) {

  # Infer season from MONTH_YEAR
  month_year <- unique(contours$MONTH_YEAR)
  if (length(month_year) != 1)
    stop("contours must contain a single MONTH_YEAR value; found: ",
         paste(month_year, collapse = ", "))
  season <- if (grepl("May", month_year)) "dry" else "wet"

  # Segments with no reliably computable gradient (set to zero).
  # LTB (4), TCB (6), and MR (7) are zero in wet season because subwatershed
  # geometry does not reliably locate the correct potentiometric high point;
  # the 2022-2024 SAS values for those segments (50/32, 50/34, 50/40 ft/mile)
  # were read manually from the 2021 FDEP map rather than computed from contours.
  zero_segs   <- if (season == "dry") c(4L, 5L, 6L, 7L, 55L) else c(4L, 5L, 6L, 7L, 55L)
  active_segs <- setdiff(sort(unique(segs$bay_seg)), zero_segs)

  # Basin-to-sub-zone lookup for Hillsborough Bay (segment 2)
  hb_zone_lookup <- data.frame(
    basin  = c("02301000", "02301500",
               "02300700", "02301300", "02301750", "TBYPASS",
               "02301695", "02303000", "02303330", "02304500",
               "204-2", "205-2", "206-2"),
    zone   = c(rep("polk",   2L),
               rep("pasco",  4L),
               rep("alafia", 7L)),
    weight = c(rep(0.4, 2L), rep(0.3, 4L), rep(0.3, 7L)),
    stringsAsFactors = FALSE
  )

  # Gradient for a single clipped contour set toward a bay segment polygon
  grad_one <- function(cont_clip, shore_poly) {
    if (nrow(cont_clip) == 0L) return(0)
    max_elev <- max(cont_clip$CONTOUR, na.rm = TRUE)
    max_cont <- dplyr::filter(cont_clip, .data$CONTOUR == max_elev)
    high_pt  <- sf::st_point_on_surface(sf::st_union(sf::st_geometry(max_cont)))
    dist_ft  <- min(as.numeric(sf::st_distance(high_pt, shore_poly)))
    max_elev / (dist_ft / 5280)
  }

  results <- lapply(active_segs, function(seg) {

    watershed <- dplyr::filter(segs, .data$bay_seg == seg)
    seg_key   <- as.character(seg)

    if (!is.null(north_segs) && seg_key %in% names(north_segs)) {
      ws_geom <- sf::st_union(watershed)
      bb      <- sf::st_bbox(ws_geom)
      xmin    <- as.numeric(bb["xmin"]); xmax <- as.numeric(bb["xmax"])
      ymax    <- as.numeric(bb["ymax"])
      dist    <- north_segs[[seg_key]]
      north_rect <- sf::st_sfc(
        sf::st_polygon(list(matrix(c(
          xmin, ymax, xmax, ymax, xmax, ymax + dist,
          xmin, ymax + dist, xmin, ymax
        ), ncol = 2, byrow = TRUE))),
        crs = sf::st_crs(watershed)
      )
      watershed <- sf::st_union(ws_geom, north_rect)
    }

    shore     <- dplyr::filter(shoreline, .data$bay_seg == seg)
    cont_clip <- suppressWarnings(sf::st_intersection(contours, watershed))

    if (seg == 2L) {

      # Union tbdbasin basins into three geographic sub-zones, clip to HB watershed
      zone_unioned <- tbdbasin |>
        dplyr::filter(.data$basin %in% hb_zone_lookup$basin) |>
        dplyr::group_by(.data$basin) |>
        dplyr::summarise(geometry = sf::st_union(geometry), .groups = "drop") |>
        dplyr::inner_join(hb_zone_lookup, by = "basin") |>
        dplyr::group_by(.data$zone, .data$weight) |>
        dplyr::summarise(geometry = sf::st_union(geometry), .groups = "drop")

      zone_sf <- suppressWarnings(sf::st_intersection(zone_unioned, watershed))

      zone_grads <- vapply(seq_len(nrow(zone_sf)), function(i) {
        zc <- suppressWarnings(sf::st_intersection(cont_clip, zone_sf[i, ]))
        grad_one(zc, shore)
      }, numeric(1L))

      grad <- sum(zone_sf$weight * zone_grads) / sum(zone_sf$weight)

    } else {
      grad <- grad_one(cont_clip, shore)
    }

    data.frame(bay_seg = as.integer(seg), grad = grad)
  })

  dplyr::bind_rows(
    results,
    data.frame(bay_seg = as.integer(zero_segs), grad = 0)
  ) |>
    dplyr::arrange(.data$bay_seg)

}
