#' Visualise the hydraulic gradient line for a bay segment
#'
#' @param contours \code{\link[sf]{sf}} object of Upper Floridan Aquifer contour
#'   lines as returned by \code{\link{util_gw_getcontour}}.
#' @param seg integer, bay segment number (1-7).
#' @param segs \code{\link[sf]{sf}} object of sub-watershed polygons. Defaults
#'   to \code{\link{tbsubshed}}.
#' @param shoreline \code{\link[sf]{sf}} object of bay segment polygons used to
#'   measure distance from the watershed high point to the bay. Defaults to
#'   \code{\link{tbsegdetail}}.
#' @param north_segs named numeric vector of northward extension distances (in
#'   CRS units, US Survey Feet for EPSG 6443), in the same format accepted by
#'   \code{\link{util_gw_grad}}. Default \code{NULL} (no extension).
#'
#' @details
#' Returns a \code{ggplot2} map showing, for the requested segment: the
#' subwatershed search area (optionally extended northward), all clipped
#' contour lines coloured by elevation, the maximum-elevation contour
#' highlighted in red, the representative high point used in the gradient
#' computation, and a dashed line to the nearest bay shoreline point.  The
#' plot subtitle reports the elevation, straight-line distance (miles), and
#' computed gradient (ft/mile).
#'
#' For segment 2 (Hillsborough Bay) the visualisation shows the single
#' max-contour approach rather than the weighted three-zone calculation used
#' in \code{\link{util_gw_grad}}.
#'
#' @return A \code{\link[ggplot2]{ggplot}} object.
#'
#' @export
#'
#' @examples
#' util_gw_showgrad(contdry, seg = 1, north_segs = c("1" = 150000))
#' util_gw_showgrad(contwet, seg = 3)
util_gw_showgrad <- function(contours, seg, segs = tbsubshed, shoreline = tbsegdetail,
                             north_segs = NULL) {

  seg_names <- c(
    "1" = "Old Tampa Bay",    "2" = "Hillsborough Bay",
    "3" = "Middle Tampa Bay", "4" = "Lower Tampa Bay",
    "5" = "Boca Ciega Bay",   "6" = "Terra Ceia Bay",
    "7" = "Manatee River"
  )

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
    search_area <- sf::st_union(ws_geom, north_rect)
  } else {
    search_area <- sf::st_union(watershed)
  }

  shore     <- dplyr::filter(shoreline, .data$bay_seg == seg)
  cont_clip <- suppressWarnings(sf::st_intersection(contours, search_area))

  if (nrow(cont_clip) == 0L)
    stop("No contours found within search area for segment ", seg)

  max_elev <- max(cont_clip$CONTOUR, na.rm = TRUE)
  max_cont <- dplyr::filter(cont_clip, .data$CONTOUR == max_elev)

  high_pt      <- sf::st_point_on_surface(sf::st_union(sf::st_geometry(max_cont)))
  shore_union  <- sf::st_union(sf::st_geometry(shore))
  nearest_line <- sf::st_nearest_points(high_pt, shore_union)

  dist_ft <- as.numeric(sf::st_length(nearest_line))
  grad    <- max_elev / (dist_ft / 5280)

  search_sf <- sf::st_sf(geometry = search_area)
  high_sf   <- sf::st_sf(geometry = high_pt)
  line_sf   <- sf::st_sf(geometry = nearest_line)

  season_lab <- unique(contours$MONTH_YEAR)

  ggplot2::ggplot() +
    ggplot2::geom_sf(data = search_sf, fill = "lightyellow", alpha = 0.6,
                     color = "grey50", linewidth = 0.4) +
    ggplot2::geom_sf(data = cont_clip,
                     ggplot2::aes(color = .data$CONTOUR), linewidth = 0.6) +
    ggplot2::scale_color_viridis_c(name = "Elevation (ft)", option = "plasma") +
    ggplot2::geom_sf(data = shore, fill = "steelblue", alpha = 0.5, color = NA) +
    ggplot2::geom_sf(data = max_cont, color = "red", linewidth = 1.3) +
    ggplot2::geom_sf(data = line_sf, color = "black", linewidth = 1.0,
                     linetype = "dashed") +
    ggplot2::geom_sf(data = high_sf, color = "red", size = 3.5, shape = 16) +
    ggplot2::labs(
      title    = sprintf("Seg %d: %s — %s", seg, seg_names[seg_key], season_lab),
      subtitle = sprintf(
        "Max contour: %d ft | Distance: %.1f mi | Gradient: %.3f ft/mi",
        max_elev, dist_ft / 5280, grad
      )
    ) +
    ggplot2::theme_bw() +
    ggplot2::theme(legend.position = "right")

}
