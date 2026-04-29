# Prototype v2: Hybrid raster/subwatershed approach for Floridan aquifer gradients
#
# Key changes from v1 (Voronoi approach):
#   - Bbox derived from tbfullshed + 40-mile buffer (avoids panhandle contours)
#   - IDW radius reduced to 5 miles; terra::focal fills remaining gaps
#   - Max head found within tbsubshed search areas, not Voronoi zones
#   - north_segs / buf_segs parameters mirror util_gw_grad logic
#   - HB three-zone weighted average preserved from util_gw_grad
#
# Run interactively — API download takes a few minutes.

library(sf)
library(terra)
library(httr)
library(dplyr)
library(ggplot2)
library(devtools)

devtools::load_all()

# ---- Reference gradients from SAS (2021 FDEP map, applied 2022-2024) --------
sas_dry <- c("1" = 100/27,
             "2" = (120/43)*0.4 + (100/25)*0.3 + (80/31)*0.3,
             "3" = 50/31,
             "4" = 0, "5" = 0, "6" = 0, "7" = 0)

sas_wet <- c("1" = 100/27,
             "2" = (120/44)*0.4 + (100/25)*0.3 + (70/26)*0.3,
             "3" = 60/32,
             "4" = 50/32,
             "5" = 0,
             "6" = 50/34,
             "7" = 50/40)

# ---- 1. Download FDEP contours over a moderate bbox -------------------------
# Bbox derived from tbfullshed + 40-mile buffer then transformed to WGS84.
# Smaller than v1's central-FL box; avoids bringing in panhandle data.

buf_40mi    <- 40 * 5280
ws_bb_wgs84 <- tbfullshed |>
  sf::st_union() |>
  sf::st_buffer(buf_40mi) |>
  sf::st_transform(4326) |>
  sf::st_bbox()
TB_BB_WGS84 <- setNames(as.numeric(ws_bb_wgs84), names(ws_bb_wgs84))
cat(sprintf("Bbox (WGS84): xmin=%.3f ymin=%.3f xmax=%.3f ymax=%.3f\n",
            TB_BB_WGS84["xmin"], TB_BB_WGS84["ymin"],
            TB_BB_WGS84["xmax"], TB_BB_WGS84["ymax"]))

fetch_fdep_contours <- function(season = c("dry", "wet"), yr,
                                bbox    = TB_BB_WGS84,
                                max_rec = 1000,
                                verbose = TRUE) {
  season     <- match.arg(season)
  month_year <- switch(season, dry = paste("May", yr), wet = paste("September", yr))
  url        <- paste0(
    "https://ca.dep.state.fl.us/arcgis/rest/services/",
    "OpenData/FGS_PUBLIC/MapServer/8/query"
  )
  params <- list(
    f              = "geojson",
    where          = paste0("MONTH_YEAR = '", month_year, "'"),
    geometryType   = "esriGeometryEnvelope",
    geometry       = sprintf('{"xmin":%s,"ymin":%s,"xmax":%s,"ymax":%s}',
                             bbox["xmin"], bbox["ymin"], bbox["xmax"], bbox["ymax"]),
    inSR           = 4326,
    spatialRel     = "esriSpatialRelIntersects",
    outFields      = "CONTOUR,MONTH_YEAR",
    returnGeometry = TRUE
  )
  all_features <- list()
  offset       <- 0
  repeat {
    p <- params
    p$resultOffset      <- offset
    p$resultRecordCount <- max_rec
    resp <- httr::GET(url, query = p)
    if (httr::status_code(resp) != 200) { warning("HTTP ", httr::status_code(resp)); break }
    feat <- sf::st_read(httr::content(resp, as = "text", encoding = "UTF-8"), quiet = TRUE)
    if (nrow(feat) == 0) break
    all_features[[length(all_features) + 1]] <- feat
    offset <- offset + max_rec
    if (verbose) cat("  retrieved", nrow(feat), "features (offset", offset, ")\n")
    if (nrow(feat) < max_rec) break
  }
  if (length(all_features) == 0) return(NULL)
  do.call(rbind, all_features) |>
    sf::st_transform(sf::st_crs(tbfullshed)) |>
    dplyr::select(CONTOUR, MONTH_YEAR)
}

cat("Downloading dry season (May 2022)...\n")
cont_dry <- fetch_fdep_contours("dry", 2022)
cat("Downloading wet season (September 2022)...\n")
cont_wet <- fetch_fdep_contours("wet", 2022)

cat("\nDry:", nrow(cont_dry), "lines, CONTOUR",
    paste(range(cont_dry$CONTOUR), collapse = "-"), "ft\n")
cat("Wet:", nrow(cont_wet), "lines, CONTOUR",
    paste(range(cont_wet$CONTOUR), collapse = "-"), "ft\n")

# ---- 2. Interpolate contour lines to 1-mile SpatRaster ----------------------
# IDW radius 5 mi (26400 ft) — cells far from any contour return NA rather than
# extrapolating wildly.  terra::focal then fills small gaps iteratively.

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
  if (verbose) cat("  template:", terra::ncol(template), "x",
                   terra::nrow(template), "=", terra::ncell(template), "cells\n")
  pts    <- lapply(seq_len(nrow(contours)), function(i) {
    coords <- sf::st_coordinates(contours[i, ])
    data.frame(x = coords[, "X"], y = coords[, "Y"], elev = contours$CONTOUR[i])
  })
  pts_df <- do.call(rbind, pts)
  pts_sv <- terra::vect(pts_df, geom = c("x", "y"), crs = crs_str)
  if (verbose) cat("  IDW from", nrow(pts_df), "points (radius",
                   idw_radius / 5280, "mi)...\n")
  r <- terra::interpIDW(template, pts_sv, field = "elev",
                         radius = idw_radius, power = 2)
  if (focal_iter > 0) {
    if (verbose) cat("  Focal gap-fill (", focal_iter, "passes)...\n")
    for (i in seq_len(focal_iter))
      r <- terra::focal(r, w = 3, fun = "mean", na.policy = "only", na.rm = TRUE)
  }
  r
}

cat("\nBuilding dry potentiometric raster...\n")
pot_dry <- contours_to_raster(cont_dry)
cat("Building wet potentiometric raster...\n")
pot_wet <- contours_to_raster(cont_wet)
# Snap wet raster to dry's grid so all layers share the same extent
pot_wet <- terra::resample(pot_wet, pot_dry, method = "bilinear")

# ---- 3. Bay water mask -------------------------------------------------------
bay_water <- terra::rasterize(terra::vect(tbsegdetail), pot_dry, field = 1)
land_mask <- terra::ifel(is.na(bay_water), 1, NA)

# ---- 4. Build subwatershed search areas --------------------------------------
# Mirrors the north_segs / buf_segs logic in util_gw_grad.

build_search_area <- function(seg, segs = tbsubshed, shoreline = tbsegdetail,
                               north_segs = NULL, buf_segs = NULL) {
  watershed <- dplyr::filter(segs, bay_seg == seg)
  seg_key   <- as.character(seg)
  all_bay   <- sf::st_union(sf::st_geometry(shoreline))

  if (!is.null(north_segs) && seg_key %in% names(north_segs)) {
    ws_geom <- sf::st_union(watershed)
    bb      <- sf::st_bbox(ws_geom)
    dist    <- north_segs[[seg_key]]
    north_rect <- sf::st_sfc(
      sf::st_polygon(list(matrix(c(
        bb["xmin"], bb["ymax"], bb["xmax"], bb["ymax"],
        bb["xmax"], bb["ymax"] + dist,
        bb["xmin"], bb["ymax"] + dist, bb["xmin"], bb["ymax"]
      ), ncol = 2, byrow = TRUE))),
      crs = sf::st_crs(watershed)
    )
    sf::st_union(ws_geom, north_rect)

  } else if (!is.null(buf_segs) && seg_key %in% names(buf_segs)) {
    ws_geom  <- sf::st_union(watershed)
    buffered <- sf::st_buffer(ws_geom, dist = buf_segs[[seg_key]])
    suppressWarnings(sf::st_difference(buffered, all_bay))

  } else {
    sf::st_union(watershed)
  }
}

# ---- 5. Gradient computation -------------------------------------------------
# grad_from_rast: finds the max-head cell in a masked raster and returns
# elevation, distance to segment shoreline, and gradient.

grad_from_rast <- function(masked, seg, shoreline) {
  if (all(is.na(terra::values(masked)))) return(NULL)
  max_val  <- terra::global(masked, "max", na.rm = TRUE)[[1]]
  max_pts  <- terra::as.points(terra::ifel(masked == max_val, 1, NA))
  max_sf   <- sf::st_as_sf(max_pts[1])

  shore_sf  <- dplyr::filter(shoreline, bay_seg == seg)
  shore_uni <- sf::st_union(sf::st_geometry(shore_sf))
  centroid  <- sf::st_centroid(shore_uni)

  # Line from bay centroid through the shoreline to the max head point.
  # The portion inside the bay is subtracted so the gradient distance is
  # measured from the shoreline crossing (not the nearest extreme point).
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
  list(elev = max_val, dist_mi = dist_ft / 5280, grad = max_val / (dist_ft / 5280))
}

compute_gradients <- function(pot_rast, land_mask,
                               north_segs = NULL, buf_segs = NULL,
                               segs = tbsubshed, shoreline = tbsegdetail) {
  # Segments not computed dynamically (gradient = 0 by default).
  # buf_segs removes segment IDs from this list.
  zero_segs <- c(4L, 5L, 6L, 7L, 55L)
  if (!is.null(buf_segs))
    zero_segs <- setdiff(zero_segs, as.integer(names(buf_segs)))

  active_segs <- setdiff(sort(unique(segs$bay_seg)), zero_segs)

  # HB (seg 2) three-zone basin lookup — matches util_gw_grad
  hb_zone_lookup <- data.frame(
    basin  = c("02301000", "02301500",
               "02300700", "02301300", "02301750", "TBYPASS",
               "02301695", "02303000", "02303330", "02304500",
               "204-2", "205-2", "206-2"),
    zone   = c(rep("polk", 2L), rep("pasco", 4L), rep("alafia", 7L)),
    weight = c(rep(0.4, 2L), rep(0.3, 4L), rep(0.3, 7L)),
    stringsAsFactors = FALSE
  )

  results <- lapply(active_segs, function(seg) {

    search_area <- build_search_area(seg, segs, shoreline, north_segs, buf_segs)
    search_v    <- terra::vect(sf::st_as_sf(search_area))
    zone_mask   <- terra::rasterize(search_v, pot_rast, field = 1)
    masked      <- pot_rast * zone_mask * land_mask

    if (seg == 2L) {
      zone_unioned <- tbdbasin |>
        dplyr::filter(basin %in% hb_zone_lookup$basin) |>
        dplyr::group_by(basin) |>
        dplyr::summarise(geometry = sf::st_union(geometry), .groups = "drop") |>
        dplyr::inner_join(hb_zone_lookup, by = "basin") |>
        dplyr::group_by(zone, weight) |>
        dplyr::summarise(geometry = sf::st_union(geometry), .groups = "drop")

      zone_sf <- suppressWarnings(
        sf::st_intersection(zone_unioned, sf::st_as_sf(search_area))
      )

      zone_rows <- lapply(seq_len(nrow(zone_sf)), function(i) {
        zm     <- terra::rasterize(terra::vect(zone_sf[i, ]), pot_rast, field = 1)
        z_mask <- pot_rast * zone_mask * zm * land_mask
        r      <- grad_from_rast(z_mask, seg = 2L, shoreline = shoreline)
        data.frame(zone   = zone_sf$zone[i],
                   weight = zone_sf$weight[i],
                   grad   = if (is.null(r)) NA_real_ else r$grad)
      })
      zone_df <- dplyr::bind_rows(zone_rows)
      valid   <- !is.na(zone_df$grad)
      grad    <- sum(zone_df$weight[valid] * zone_df$grad[valid]) /
                 sum(zone_df$weight[valid])

      return(data.frame(bay_seg = 2L, elev_ft = NA_real_,
                        dist_mi = NA_real_, grad = round(grad, 3)))
    }

    r <- grad_from_rast(masked, seg = seg, shoreline = shoreline)
    if (is.null(r))
      return(data.frame(bay_seg = as.integer(seg),
                        elev_ft = NA_real_, dist_mi = NA_real_, grad = NA_real_))
    data.frame(bay_seg = as.integer(seg),
               elev_ft = round(r$elev, 1),
               dist_mi = round(r$dist_mi, 1),
               grad    = round(r$grad, 3))
  })

  dplyr::bind_rows(
    results,
    data.frame(bay_seg = as.integer(zero_segs),
               elev_ft = NA_real_, dist_mi = NA_real_, grad = 0)
  ) |> dplyr::arrange(bay_seg)
}

# ---- Visualization -----------------------------------------------------------
# Shows the IDW-interpolated head surface clipped to the segment's search area,
# the bay polygon, the max-head point, and the dashed distance-to-shore line.

show_rast_grad <- function(pot_rast, land_mask, seg,
                            north_segs = NULL, buf_segs = NULL,
                            segs = tbsubshed, shoreline = tbsegdetail,
                            season_lab = "") {
  seg_names <- c(
    "1" = "Old Tampa Bay",    "2" = "Hillsborough Bay",
    "3" = "Middle Tampa Bay", "4" = "Lower Tampa Bay",
    "5" = "Boca Ciega Bay",   "6" = "Terra Ceia Bay",
    "7" = "Manatee River"
  )

  search_area <- build_search_area(seg, segs, shoreline, north_segs, buf_segs)
  search_v    <- terra::vect(sf::st_as_sf(search_area))
  zone_mask   <- terra::rasterize(search_v, pot_rast, field = 1)
  masked      <- pot_rast * zone_mask * land_mask

  if (all(is.na(terra::values(masked))))
    stop("No land cells in search area for segment ", seg)

  max_val  <- terra::global(masked, "max", na.rm = TRUE)[[1]]
  max_pts  <- terra::as.points(terra::ifel(masked == max_val, 1, NA))
  max_pt   <- max_pts[1]
  max_sf   <- sf::st_as_sf(max_pt)

  shore_sf  <- dplyr::filter(shoreline, bay_seg == seg)
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
  dist_ft     <- dist_total - dist_inside
  grad        <- max_val / (dist_ft / 5280)
  # Land portion of the centroid-to-head line (what the gradient measures)
  line_land <- suppressWarnings(sf::st_difference(line_sfc, shore_uni))

  search_ext <- terra::ext(search_v)
  buf_ft     <- 52800  # 10-mile context buffer around search area
  crop_ext   <- terra::ext(
    search_ext$xmin - buf_ft, search_ext$xmax + buf_ft,
    search_ext$ymin - buf_ft, search_ext$ymax + buf_ft
  )
  rast_df <- as.data.frame(terra::crop(masked, crop_ext), xy = TRUE)
  names(rast_df)[3] <- "elev"
  rast_df <- rast_df[!is.na(rast_df$elev), ]

  search_sf <- sf::st_sf(geometry = sf::st_sfc(search_area,
                                                crs = sf::st_crs(shoreline)))
  title_lab <- sprintf("Seg %d: %s", seg, seg_names[as.character(seg)])
  if (nchar(season_lab) > 0) title_lab <- paste(title_lab, "-", season_lab)

  ggplot2::ggplot() +
    ggplot2::geom_sf(data = search_sf, fill = "lightyellow", alpha = 0.6,
                     color = "grey50", linewidth = 0.4) +
    ggplot2::geom_raster(data = rast_df,
                         ggplot2::aes(x = x, y = y, fill = elev)) +
    ggplot2::scale_fill_viridis_c(name = "Head (ft)", option = "plasma",
                                   na.value = NA) +
    ggplot2::geom_sf(data = shoreline, fill = "grey80", alpha = 0.3,
                     color = "grey60", linewidth = 0.2) +
    ggplot2::geom_sf(data = shore_sf, fill = "steelblue", alpha = 0.6,
                     color = "steelblue4", linewidth = 0.5) +
    ggplot2::geom_sf(data = sf::st_sf(geometry = line_sfc),
                     color = "grey40", linewidth = 0.5, linetype = "dotted") +
    ggplot2::geom_sf(data = sf::st_sf(geometry = line_land),
                     color = "black", linewidth = 1.0, linetype = "dashed") +
    ggplot2::geom_sf(data = max_sf, color = "red", size = 3.5, shape = 16) +
    ggplot2::coord_sf(crs = sf::st_crs(shoreline),
                      xlim = c(search_ext$xmin - buf_ft, search_ext$xmax + buf_ft),
                      ylim = c(search_ext$ymin - buf_ft, search_ext$ymax + buf_ft)) +
    ggplot2::labs(
      title    = title_lab,
      subtitle = sprintf("Max head: %.1f ft | Distance: %.1f mi | Gradient: %.3f ft/mi",
                         max_val, dist_ft / 5280, grad),
      x = NULL, y = NULL
    ) +
    ggplot2::theme_bw() +
    ggplot2::theme(legend.position = "right")
}

# ---- 6. Run gradient computation --------------------------------------------
# Dry: segs 4,5,6,7,55 = 0 (matches SAS); no buf_segs needed.
# Wet: buf_segs unlocks 4, 6, 7 so they are computed dynamically.

cat("Computing dry season gradients...\n")
result_dry <- compute_gradients(
  pot_dry, land_mask,
  buf_segs = c("1" = 100000)
)

cat("Computing wet season gradients...\n")
result_wet <- compute_gradients(
  pot_wet, land_mask,
  buf_segs = c("1" = 100000, "4" = 100000, "6" = 100000, "7" = 100000)
)

# ---- 7. Comparison table ----------------------------------------------------
seg_names <- c("1" = "OTB", "2" = "HB", "3" = "MTB", "4" = "LTB",
                "5" = "BCB", "6" = "TCB", "7" = "MR")

compare <- result_dry |>
  dplyr::rename(elev_dry = elev_ft, dist_dry = dist_mi, grad_dry = grad) |>
  dplyr::left_join(
    result_wet |> dplyr::rename(elev_wet = elev_ft, dist_wet = dist_mi,
                                 grad_wet = grad),
    by = "bay_seg"
  ) |>
  dplyr::mutate(
    seg     = seg_names[as.character(bay_seg)],
    sas_dry = round(sas_dry[as.character(bay_seg)], 3),
    sas_wet = round(sas_wet[as.character(bay_seg)], 3),
    err_dry = ifelse(sas_dry == 0, NA,
                round((grad_dry - sas_dry) / sas_dry * 100, 1)),
    err_wet = ifelse(sas_wet == 0, NA,
                round((grad_wet - sas_wet) / sas_wet * 100, 1))
  ) |>
  dplyr::select(bay_seg, seg,
                elev_dry, dist_dry, grad_dry, sas_dry, err_dry,
                elev_wet, dist_wet, grad_wet, sas_wet, err_wet)

cat("\n--- Gradient comparison (hybrid raster/subwatershed vs. SAS manual) ---\n")
cat("err = % deviation from SAS; NA = SAS gradient is 0 (no comparison)\n\n")
print(compare, digits = 3)

# ---- 8. Visualization examples -----------------------------------------------
# Run individually to inspect each segment:

show_rast_grad(pot_dry, land_mask, seg = 1,
               buf_segs = c("1" = 100000), season_lab = "May 2022")
show_rast_grad(pot_dry, land_mask, seg = 2, season_lab = "May 2022")
show_rast_grad(pot_dry, land_mask, seg = 3, season_lab = "May 2022")
show_rast_grad(pot_wet, land_mask, seg = 4,
               buf_segs = c("4" = 100000), season_lab = "Sep 2022")
show_rast_grad(pot_wet, land_mask, seg = 6,
               buf_segs = c("6" = 100000), season_lab = "Sep 2022")
show_rast_grad(pot_wet, land_mask, seg = 7,
               buf_segs = c("7" = 100000), season_lab = "Sep 2022")

# ---- 9. Save rasters if results look good ------------------------------------
# contdry <- pot_dry
# contwet <- pot_wet
# save(contdry, file = "data/contdry.RData", compress = "xz")
# save(contwet, file = "data/contwet.RData", compress = "xz")
