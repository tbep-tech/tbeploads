#' Visualise the hydraulic gradient for a bay segment
#'
#' @param pot_rast \code{\link[terra]{SpatRaster}} (or \code{PackedSpatRaster})
#'   of Upper Floridan Aquifer potentiometric head (ft above MSL) as returned
#'   by \code{\link{util_gw_getcontour}}, or the package datasets
#'   \code{\link{contdry}} / \code{\link{contwet}}.
#' @param season character, \code{"dry"} or \code{"wet"}.
#' @param seg integer, bay segment number (1-7).
#' @param segs \code{\link[sf]{sf}} object of sub-watershed polygons. Defaults
#'   to \code{\link{tbsubshed}}.
#' @param shoreline \code{\link[sf]{sf}} object of bay segment polygons.
#'   Defaults to \code{\link{tbsegdetail}}.
#' @param buf_segs named numeric vector of buffer distances (US Survey Feet)
#'   in the same format accepted by \code{\link{util_gw_grad}}. When
#'   \code{NULL}, season-specific defaults are used (see
#'   \code{\link{util_gw_grad}} for details).
#'
#' @details
#' Returns a \code{ggplot2} map for the requested segment showing:
#' \itemize{
#'   \item The potentiometric surface (ft) within the search area, coloured by
#'     head value.
#'   \item The search area boundary (light yellow).
#'   \item All bay segments (grey background) and the target segment (blue).
#'   \item A dotted line from the bay centroid to the max-head land cell
#'     (showing the full transect used in the distance calculation).
#'   \item A dashed line for the land portion of that transect (the actual
#'     gradient distance).
#'   \item The max-head point (red dot).
#' }
#' The subtitle reports max head (ft), distance (miles), and gradient (ft/mi).
#' See \code{\link{util_gw_grad}} for the distance calculation methodology.
#'
#' @return A \code{\link[ggplot2]{ggplot}} object.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' contdry <- util_gw_getcontour("dry", 2022)
#' }
#' util_gw_showgrad(contdry, season = "dry", seg = 1)
#' util_gw_showgrad(contdry, season = "dry", seg = 3)
#'
#' \dontrun{
#' contwet <- util_gw_getcontour("wet", 2022)
#' }
#' util_gw_showgrad(contwet, season = "wet", seg = 4)
#' util_gw_showgrad(contwet, season = "wet", seg = 7)
util_gw_showgrad <- function(pot_rast, season = c("dry", "wet"), seg,
                              segs = tbsubshed, shoreline = tbsegdetail,
                              buf_segs = NULL) {

  season <- match.arg(season)

  if (inherits(pot_rast, "PackedSpatRaster"))
    pot_rast <- terra::unwrap(pot_rast)

  if (is.null(buf_segs))
    buf_segs <- if (season == "dry")
      c("1" = 100000)
    else
      c("1" = 100000, "4" = 100000, "6" = 100000, "7" = 100000)

  seg_names <- c(
    "1" = "Old Tampa Bay",    "2" = "Hillsborough Bay",
    "3" = "Middle Tampa Bay", "4" = "Lower Tampa Bay",
    "5" = "Boca Ciega Bay",   "6" = "Terra Ceia Bay",
    "7" = "Manatee River"
  )

  bay_water <- terra::rasterize(terra::vect(shoreline), pot_rast, field = 1)
  land_mask <- terra::ifel(is.na(bay_water), 1, NA)

  search_area <- build_search_area(seg, segs, shoreline, buf_segs)
  search_v    <- terra::vect(sf::st_as_sf(search_area))
  zone_mask   <- terra::rasterize(search_v, pot_rast, field = 1)
  masked      <- pot_rast * zone_mask * land_mask

  if (all(is.na(terra::values(masked))))
    stop("No land cells in search area for segment ", seg)

  r <- grad_from_rast(masked, seg, shoreline)
  if (is.null(r))
    stop("Could not compute gradient for segment ", seg)

  # Land portion of the centroid-to-head line (the gradient distance)
  line_land <- suppressWarnings(
    sf::st_difference(r$line_sfc, r$shore_uni)
  )

  search_ext <- terra::ext(search_v)
  buf_ft     <- 52800  # 10-mile context buffer
  crop_ext   <- terra::ext(
    search_ext$xmin - buf_ft, search_ext$xmax + buf_ft,
    search_ext$ymin - buf_ft, search_ext$ymax + buf_ft
  )
  rast_df <- as.data.frame(terra::crop(masked, crop_ext), xy = TRUE)
  names(rast_df)[3] <- "elev"
  rast_df <- rast_df[!is.na(rast_df$elev), ]

  search_sf  <- sf::st_sf(geometry = sf::st_sfc(search_area,
                                                 crs = sf::st_crs(shoreline)))
  shore_sf   <- dplyr::filter(shoreline, .data$bay_seg == seg)
  season_lab <- if (season == "dry") "Dry season" else "Wet season"

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
    ggplot2::geom_sf(data = sf::st_sf(geometry = r$line_sfc),
                     color = "grey40", linewidth = 0.5, linetype = "dotted") +
    ggplot2::geom_sf(data = sf::st_sf(geometry = line_land),
                     color = "black", linewidth = 1.0, linetype = "dashed") +
    ggplot2::geom_sf(data = r$max_sf, color = "red", size = 3.5, shape = 16) +
    ggplot2::coord_sf(crs = sf::st_crs(shoreline),
                      xlim = c(search_ext$xmin - buf_ft, search_ext$xmax + buf_ft),
                      ylim = c(search_ext$ymin - buf_ft, search_ext$ymax + buf_ft)) +
    ggplot2::labs(
      title    = sprintf("Seg %d: %s - %s", seg,
                         seg_names[as.character(seg)], season_lab),
      subtitle = sprintf("Max head: %.1f ft | Distance: %.1f mi | Gradient: %.3f ft/mi",
                         r$elev, r$dist_mi, r$grad),
      x = NULL, y = NULL
    ) +
    ggplot2::theme_bw() +
    ggplot2::theme(legend.position = "right")

}
