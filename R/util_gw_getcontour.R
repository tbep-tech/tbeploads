#' Download FDEP Upper Floridan Aquifer potentiometric surface contour lines
#'
#' @param season character, \code{"dry"} or \code{"wet"}
#' @param yr integer, year for which to retrieve data. Biannual (May/September)
#'   observations are available from 2010 through 2022.
#' @param max_records integer, maximum number of records per paginated request.
#'   Default is 1000.
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
#' (\code{\link{tbfullshed}}) and clipped to that boundary before return.
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
#' }
util_gw_getcontour <- function(season = c("dry", "wet"), yr, max_records = 1000,
                            verbose = TRUE) {

  season <- match.arg(season)

  month_year <- switch(season,
    dry = paste("May", yr),
    wet = paste("September", yr)
  )

  url <- "https://ca.dep.state.fl.us/arcgis/rest/services/OpenData/FGS_PUBLIC/MapServer/8/query"

  tbep_bb <- tbfullshed |>
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
    sf::st_intersection(tbfullshed) |>
    dplyr::select(CONTOUR, MONTH_YEAR)

  return(out)

}
