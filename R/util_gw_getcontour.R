#' Download FDEP Upper Floridan Aquifer potentiometric surface contour lines
#'
#' @param season character, \code{"dry"} or \code{"wet"}
#' @param yr integer, year for which to retrieve data. Biannual (May/September)
#'   observations are available from 2010 through 2022.
#' @param max_records integer, maximum number of records per paginated request.
#'   Default is 1000.
#' @param north_dist numeric, distance in CRS units (US Survey Feet for EPSG
#'   6443) to extend the spatial filter and clipping boundary northward beyond
#'   the Tampa Bay watershed (\code{\link{tbfullshed}}). Use a positive value
#'   when the potentiometric high point for one or more bay segments lies north
#'   of the watershed boundary (e.g., Old Tampa Bay). The same value (or larger)
#'   should be passed as \code{north_dist} in \code{\link{util_gw_grad}} so
#'   that the returned contours cover the extended search areas. Default 0 (no
#'   extension).
#' @param verbose logical, if \code{TRUE} (default) progress messages are
#'   printed during download.
#'
#' @details
#' Downloads contour lines representing the potentiometric surface of the Upper
#' Floridan Aquifer from the Florida Department of Environmental Protection /
#' Florida Geological Survey ArcGIS REST service
#' (\url{https://ca.dep.state.fl.us/arcgis/rest/services/OpenData/FGS_PUBLIC/MapServer/8}).
#'
#' Contours are available biannually: \code{"dry"} season maps to May of
#' \code{yr} and \code{"wet"} season maps to September of \code{yr}.
#' Results are spatially filtered to the Tampa Bay watershed
#' (\code{\link{tbfullshed}}), optionally extended northward by
#' \code{north_dist}, and clipped to that boundary before return.
#'
#' The \code{CONTOUR} field contains potentiometric surface elevations in feet
#' above mean sea level. These are used to compute the hydraulic
#' gradient driving Floridan Aquifer discharge to Tampa Bay segments (Darcy's
#' Law).
#'
#' @return An \code{\link[sf]{sf}} object of \code{LINESTRING} features with
#'   columns \code{CONTOUR} (integer, feet MSL) and \code{MONTH_YEAR}
#'   (character), in the same CRS as \code{\link{tbfullshed}} (EPSG 6443).
#'   Returns \code{NULL} if no features are found for the requested
#'   season/year.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' dry_contours <- util_gw_getcontour("dry", 2022)
#' wet_contours <- util_gw_getcontour("wet", 2022)
#'
#' # extend north by ~28 miles for OTB high-point search
#' dry_contours <- util_gw_getcontour("dry", 2022, north_dist = 150000)
#' }
util_gw_getcontour <- function(season = c("dry", "wet"), yr, max_records = 1000,
                               north_dist = 0, verbose = TRUE) {

  season <- match.arg(season)

  month_year <- switch(season,
    dry = paste("May", yr),
    wet = paste("September", yr)
  )

  url <- "https://ca.dep.state.fl.us/arcgis/rest/services/OpenData/FGS_PUBLIC/MapServer/8/query"

  if (north_dist > 0) {
    bb   <- sf::st_bbox(tbfullshed)
    xmin <- as.numeric(bb["xmin"]); xmax <- as.numeric(bb["xmax"])
    ymax <- as.numeric(bb["ymax"])
    north_rect <- sf::st_sfc(
      sf::st_polygon(list(matrix(c(
        xmin, ymax, xmax, ymax, xmax, ymax + north_dist,
        xmin, ymax + north_dist, xmin, ymax
      ), ncol = 2, byrow = TRUE))),
      crs = sf::st_crs(tbfullshed)
    )
    shed <- sf::st_union(sf::st_geometry(tbfullshed), north_rect)
  } else {
    shed <- sf::st_geometry(tbfullshed)
  }

  tbep_bb <- shed |>
    sf::st_transform(4326) |>
    sf::st_bbox()

  params <- list(
    f            = "geojson",
    where        = paste0("MONTH_YEAR = '", month_year, "'"),
    geometryType = "esriGeometryEnvelope",
    geometry     = paste0(
      '{"xmin":', tbep_bb["xmin"],
      ',"ymin":',  tbep_bb["ymin"],
      ',"xmax":',  tbep_bb["xmax"],
      ',"ymax":',  tbep_bb["ymax"], '}'
    ),
    inSR         = 4326,
    spatialRel   = "esriSpatialRelIntersects",
    outFields    = "CONTOUR,MONTH_YEAR",
    returnGeometry = TRUE
  )

  all_features <- list()
  offset <- 0

  repeat {

    current_params <- params
    current_params$resultOffset      <- offset
    current_params$resultRecordCount <- max_records

    response <- httr::GET(url, query = current_params)

    if (httr::status_code(response) != 200) {
      warning("Request failed at offset ", offset, " (HTTP ",
              httr::status_code(response), ")")
      break
    }

    content_text <- httr::content(response, as = "text", encoding = "UTF-8")
    features     <- sf::st_read(content_text, quiet = TRUE)

    if (nrow(features) == 0)
      break

    all_features[[length(all_features) + 1]] <- features
    offset <- offset + max_records

    if (verbose)
      cat("Retrieved", nrow(features), "features, offset:", offset, "\n")

    if (nrow(features) < max_records)
      break

  }

  if (length(all_features) == 0) {
    warning("No features returned for season '", season, "', year ", yr,
            " (MONTH_YEAR = '", month_year, "')")
    return(NULL)
  }

  out <- do.call(rbind, all_features) |>
    sf::st_transform(crs = sf::st_crs(tbfullshed)) |>
    sf::st_intersection(shed) |>
    dplyr::select(CONTOUR, MONTH_YEAR)

  return(out)

}
