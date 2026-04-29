#' Compute hydraulic gradient per bay segment from potentiometric surface raster
#'
#' @param pot_rast \code{\link[terra]{SpatRaster}} (or \code{PackedSpatRaster})
#'   of Upper Floridan Aquifer potentiometric head (ft above MSL) as returned
#'   by \code{\link{util_gw_getcontour}}, or the package datasets
#'   \code{\link{contdry}} / \code{\link{contwet}}.
#' @param season character, \code{"dry"} or \code{"wet"}.
#' @param segs \code{\link[sf]{sf}} object of sub-watershed polygons. Defaults
#'   to \code{\link{tbsubshed}}.
#' @param shoreline \code{\link[sf]{sf}} object of bay segment polygons used
#'   to derive the bay water mask and measure distances. Defaults to
#'   \code{\link{tbsegdetail}}.
#' @param buf_segs named numeric vector mapping bay segment IDs (as character
#'   strings) to omnidirectional buffer distances in US Survey Feet (CRS 6443).
#'   The subwatershed for each listed segment is buffered outward by the given
#'   distance and bay water is removed before the potentiometric high-point
#'   search. Listing a segment here also removes it from the default
#'   zero-gradient set so it is computed dynamically. When \code{NULL},
#'   season-specific defaults are used (see Details).
#'
#' @details
#' Computes the Floridan Aquifer hydraulic gradient \eqn{I} (ft/mile) per bay
#' segment using the Darcy's Law framework of Zarbock et al. (1994):
#'
#' \deqn{I = \frac{\text{elevation (ft)}}{\text{distance to shoreline (miles)}}}
#'
#' The max potentiometric head within the search area is located in the
#' interpolated raster and the distance is measured from the nearest shoreline
#' crossing along the bay centroid-to-head transect (see below).
#'
#' \strong{Zero-gradient segments (hardcoded):}
#' The following segments always receive a gradient of 0 based on the original
#' SAS loading analysis (Zarbock et al., 1994; GWld2224_SASCode.txt):
#' \itemize{
#'   \item Boca Ciega Bay (segments 5 and 55), both seasons: the urbanized
#'     coastal watershed has no meaningful Floridan Aquifer recharge directed
#'     toward the bay.
#'   \item Lower Tampa Bay (4), Terra Ceia Bay (6), Manatee River (7), dry
#'     season only: the potentiometric gradient is negligible during the dry
#'     season. These segments are computed dynamically in the wet season via
#'     the default \code{buf_segs}.
#' }
#' Any segment listed in \code{buf_segs} is removed from the zero set and
#' computed dynamically.
#'
#' \strong{Default buf_segs (calibrated against 2021 SAS reference values):}
#' \itemize{
#'   \item Dry season: \code{c("1" = 100000)} -- Old Tampa Bay subwatershed
#'     buffered ~19 miles; captures the potentiometric high north/northeast of
#'     the standard watershed boundary.
#'   \item Wet season: \code{c("1" = 100000, "4" = 100000, "6" = 100000,
#'     "7" = 100000)} -- adds LTB, TCB, and MR (each ~19 miles) to unlock
#'     wet-season computation for those segments.
#' }
#' Buffer distances were tuned to produce gradients within ~15\% of the 2021
#' FDEP potentiometric surface values used in the SAS analysis.
#'
#' \strong{Distance calculation:}
#' Rather than measuring from the potentiometric high to the nearest shoreline
#' point (which can hit an extreme geographic corner), the function draws a
#' line from the bay segment centroid to the max-head cell. The portion of that
#' line inside the bay polygon is subtracted from the total length, giving the
#' distance from the shoreline crossing point to the high point along a
#' representative transect.
#'
#' \strong{Hillsborough Bay (segment 2):}
#' Uses a three-zone weighted gradient (Polk County 0.4, Pasco County 0.3,
#' Alafia River 0.3) following the original flow net analysis. Sub-zones are
#' constructed from \code{\link{tbdbasin}} drainage basins as in the original
#' SAS code.
#'
#' \strong{Benchmark warning:}
#' After computing gradients, each non-zero segment is compared against the
#' 2021 SAS reference values (GWld2224_SASCode.txt). A warning is issued for
#' any segment whose computed gradient deviates by more than 50\% from its
#' reference, indicating a potentially anomalous potentiometric surface or a
#' need to revisit the \code{buf_segs} configuration.
#'
#' @return A data frame with columns \code{bay_seg} (integer) and \code{grad}
#'   (numeric, ft/mile; 0 for zero-gradient segments).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' pot_dry <- util_gw_getcontour("dry", 2022)
#' util_gw_grad(pot_dry, season = "dry")
#'
#' pot_wet <- util_gw_getcontour("wet", 2022)
#' util_gw_grad(pot_wet, season = "wet")
#' }
util_gw_grad <- function(pot_rast, season = c("dry", "wet"),
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

  zero_segs <- c(4L, 5L, 6L, 7L, 55L)
  if (!is.null(buf_segs))
    zero_segs <- setdiff(zero_segs, as.integer(names(buf_segs)))

  active_segs <- setdiff(sort(unique(segs$bay_seg)), zero_segs)

  bay_water <- terra::rasterize(terra::vect(shoreline), pot_rast, field = 1)
  land_mask <- terra::ifel(is.na(bay_water), 1, NA)

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

    search_area <- build_search_area(seg, segs, shoreline, buf_segs)
    zone_mask   <- terra::rasterize(
      terra::vect(sf::st_as_sf(search_area)), pot_rast, field = 1
    )
    masked <- pot_rast * zone_mask * land_mask

    if (seg == 2L) {
      zone_unioned <- tbdbasin |>
        dplyr::filter(.data$basin %in% hb_zone_lookup$basin) |>
        dplyr::group_by(.data$basin) |>
        dplyr::summarise(geometry = sf::st_union(geometry), .groups = "drop") |>
        dplyr::inner_join(hb_zone_lookup, by = "basin") |>
        dplyr::group_by(.data$zone, .data$weight) |>
        dplyr::summarise(geometry = sf::st_union(geometry), .groups = "drop")
      zone_sf <- suppressWarnings(
        sf::st_intersection(zone_unioned, sf::st_as_sf(search_area))
      )
      zone_rows <- lapply(seq_len(nrow(zone_sf)), function(i) {
        zm <- terra::rasterize(terra::vect(zone_sf[i, ]), pot_rast, field = 1)
        r  <- grad_from_rast(pot_rast * zone_mask * zm * land_mask, 2L, shoreline)
        list(weight = zone_sf$weight[i], grad = if (is.null(r)) NA_real_ else r$grad)
      })
      weights <- vapply(zone_rows, `[[`, numeric(1), "weight")
      grads   <- vapply(zone_rows, `[[`, numeric(1), "grad")
      valid   <- !is.na(grads)
      grad    <- sum(weights[valid] * grads[valid]) / sum(weights[valid])
      return(data.frame(bay_seg = 2L, grad = grad))
    }

    r <- grad_from_rast(masked, seg, shoreline)
    data.frame(bay_seg = as.integer(seg),
               grad    = if (is.null(r)) NA_real_ else r$grad)
  })

  out <- dplyr::bind_rows(
    results,
    data.frame(bay_seg = as.integer(zero_segs), grad = 0)
  ) |> dplyr::arrange(.data$bay_seg)

  # 2021 SAS reference gradients (GWld2224_SASCode.txt) used as benchmarks.
  # Warn if any computed gradient deviates >50% from its reference value.
  bench <- if (season == "dry")
    c("1" = 100 / 27,
      "2" = (120 / 43) * 0.4 + (100 / 25) * 0.3 + (80 / 31) * 0.3,
      "3" = 50 / 31)
  else
    c("1" = 100 / 27,
      "2" = (120 / 44) * 0.4 + (100 / 25) * 0.3 + (70 / 26) * 0.3,
      "3" = 60 / 32,
      "4" = 50 / 32,
      "6" = 50 / 34,
      "7" = 50 / 40)

  for (nm in names(bench)) {
    computed <- out$grad[out$bay_seg == as.integer(nm)]
    ref      <- bench[[nm]]
    if (length(computed) == 1L && !is.na(computed) && ref > 0 &&
        (computed < 0.5 * ref || computed > 1.5 * ref)) {
      warning(
        sprintf(
          "Segment %s %s-season gradient (%.3f ft/mi) deviates >50%% from the 2021 SAS benchmark (%.3f ft/mi). Check the potentiometric surface or buf_segs.",
          nm, season, computed, ref
        ),
        call. = FALSE
      )
    }
  }

  out

}
