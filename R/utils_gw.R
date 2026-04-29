# Internal helpers for the groundwater loading workflow. Not exported.

# Interpolate UFA contour lines to a 1-mile SpatRaster via IDW.
# IDW radius of 5 miles (26400 US Survey Feet) prevents wild extrapolation into
# areas with no nearby contours. terra::focal iteratively fills any remaining
# small gaps with a 3x3 mean window.
contours_to_raster <- function(contours, res_ft = 5280, idw_radius = 26400,
                                focal_iter = 5, verbose = TRUE) {
  crs_str  <- terra::crs(terra::vect(contours[1, ]))
  bb       <- sf::st_bbox(contours)
  template <- terra::rast(
    xmin       = as.numeric(bb["xmin"]) - res_ft,
    xmax       = as.numeric(bb["xmax"]) + res_ft,
    ymin       = as.numeric(bb["ymin"]) - res_ft,
    ymax       = as.numeric(bb["ymax"]) + res_ft,
    resolution = res_ft,
    crs        = crs_str
  )
  pts <- lapply(seq_len(nrow(contours)), function(i) {
    coords <- sf::st_coordinates(contours[i, ])
    data.frame(x = coords[, "X"], y = coords[, "Y"],
               elev = contours$CONTOUR[i])
  })
  pts_df <- do.call(rbind, pts)
  pts_sv <- terra::vect(pts_df, geom = c("x", "y"), crs = crs_str)
  if (verbose) cat("  IDW from", nrow(pts_df), "points...\n")
  r <- terra::interpIDW(template, pts_sv, field = "elev",
                         radius = idw_radius, power = 2)
  if (focal_iter > 0) {
    if (verbose) cat("  Focal gap-fill (", focal_iter, "passes)...\n")
    for (i in seq_len(focal_iter))
      r <- terra::focal(r, w = 3, fun = "mean", na.policy = "only", na.rm = TRUE)
  }
  r
}

# Build the search area polygon for one bay segment using the buf_segs mechanism.
# If buf_segs names the segment, the subwatershed is buffered outward by the
# given distance and all bay water (tbsegdetail) is removed. Otherwise the plain
# subwatershed union is returned.
build_search_area <- function(seg, segs = tbsubshed, shoreline = tbsegdetail,
                               buf_segs = NULL) {
  watershed <- dplyr::filter(segs, .data$bay_seg == seg)
  seg_key   <- as.character(seg)

  if (!is.null(buf_segs) && seg_key %in% names(buf_segs)) {
    ws_geom  <- sf::st_union(watershed)
    buffered <- sf::st_buffer(ws_geom, dist = buf_segs[[seg_key]])
    all_bay  <- sf::st_union(sf::st_geometry(shoreline))
    suppressWarnings(sf::st_difference(buffered, all_bay))
  } else {
    sf::st_union(watershed)
  }
}

# Find the max potentiometric head cell in a masked raster and compute the
# hydraulic gradient using a centroid-based distance.
#
# Distance approach:
#   1. Draw a line from the bay segment centroid to the max-head land cell.
#   2. Clip that line to the bay polygon; the clipped portion is the in-bay distance.
#   3. Gradient distance = total length - in-bay length.
#
# This avoids measuring to an extreme shoreline corner (e.g. the NE tip of MTB),
# giving a more representative transect from open water to the potentiometric high.
grad_from_rast <- function(masked, seg, shoreline) {
  if (all(is.na(terra::values(masked)))) return(NULL)
  max_val <- terra::global(masked, "max", na.rm = TRUE)[[1]]
  max_sf  <- sf::st_as_sf(
    terra::as.points(terra::ifel(masked == max_val, 1, NA))[1]
  )

  shore_sf  <- dplyr::filter(shoreline, .data$bay_seg == seg)
  shore_uni <- sf::st_union(sf::st_geometry(shore_sf))
  centroid  <- sf::st_centroid(shore_uni)

  line_sfc <- sf::st_sfc(
    sf::st_linestring(rbind(sf::st_coordinates(centroid),
                            sf::st_coordinates(sf::st_geometry(max_sf)))),
    crs = sf::st_crs(shore_sf)
  )
  dist_total  <- as.numeric(sf::st_length(line_sfc))
  inside      <- suppressWarnings(sf::st_intersection(line_sfc, shore_uni))
  dist_inside <- if (length(inside) > 0 && !all(sf::st_is_empty(inside)))
    sum(as.numeric(sf::st_length(inside))) else 0

  dist_ft <- dist_total - dist_inside
  list(elev    = max_val,
       dist_mi = dist_ft / 5280,
       grad    = max_val / (dist_ft / 5280),
       line_sfc = line_sfc,
       max_sf   = max_sf,
       shore_uni = shore_uni)
}
