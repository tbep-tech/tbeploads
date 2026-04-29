#' Download and rasterize FDEP Upper Floridan Aquifer potentiometric surface
#'
#' @param season character, \code{"dry"} or \code{"wet"}.
#' @param yr integer, year for which to retrieve data. Biannual (May/September)
#'   observations are available from approximately 2010 onward.
#' @param max_records integer, maximum records per paginated API request.
#'   Default 1000.
#' @param verbose logical, print download and interpolation progress.
#'   Default \code{TRUE}.
#'
#' @details
#' Downloads Upper Floridan Aquifer potentiometric surface contour lines from
#' the FDEP / Florida Geological Survey ArcGIS REST service
#' (\url{https://ca.dep.state.fl.us/arcgis/rest/services/OpenData/FGS_PUBLIC/MapServer/8})
#' and interpolates them to a 1-mile \code{SpatRaster} using inverse distance
#' weighting (IDW).
#'
#' \strong{Spatial extent:} The API query covers the Tampa Bay watershed
#' (\code{\link{tbfullshed}}) buffered outward by 40 miles (211,200 US Survey
#' Feet), converted to WGS84. This wider extent captures the Polk County
#' potentiometric highlands that drive groundwater flow to Hillsborough Bay and
#' surrounding segments.
#'
#' \strong{Interpolation:} Contour line vertices are used as elevation
#' observations and interpolated to a 1-mile grid via IDW (5-mile radius,
#' power = 2). Cells more than 5 miles from any contour vertex are left
#' \code{NA} to avoid extrapolation into data-sparse regions. Five passes of a
#' 3x3 focal mean then fill small gaps. The 5-mile radius was chosen to bridge
#' typical contour spacing in the Tampa Bay region without extrapolating into
#' the panhandle or coastal areas.
#'
#' \strong{Season mapping:}
#' \itemize{
#'   \item \code{"dry"} maps to May of \code{yr}
#'   \item \code{"wet"} maps to September of \code{yr}
#' }
#'
#' @return A \code{\link[terra]{SpatRaster}} of potentiometric head (ft above
#'   MSL) at 1-mile resolution in the CRS of \code{\link{tbfullshed}} (EPSG
#'   6443). Returns \code{NULL} with a warning if no features are found for the
#'   requested season/year.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' pot_dry <- util_gw_getcontour("dry", 2022)
#' pot_wet <- util_gw_getcontour("wet", 2022)
#' }
util_gw_getcontour <- function(season = c("dry", "wet"), yr,
                               max_records = 1000, verbose = TRUE) {

  season     <- match.arg(season)
  month_year <- switch(season, dry = paste("May", yr), wet = paste("September", yr))

  url <- paste0("https://ca.dep.state.fl.us/arcgis/rest/services/",
                "OpenData/FGS_PUBLIC/MapServer/8/query")

  buf_ft  <- 40 * 5280
  tbep_bb <- tbfullshed |>
    sf::st_union() |>
    sf::st_buffer(buf_ft) |>
    sf::st_transform(4326) |>
    sf::st_bbox()

  params <- list(
    f              = "geojson",
    where          = paste0("MONTH_YEAR = '", month_year, "'"),
    geometryType   = "esriGeometryEnvelope",
    geometry       = paste0(
      '{"xmin":', tbep_bb["xmin"], ',"ymin":', tbep_bb["ymin"],
      ',"xmax":', tbep_bb["xmax"], ',"ymax":', tbep_bb["ymax"], '}'
    ),
    inSR           = 4326,
    spatialRel     = "esriSpatialRelIntersects",
    outFields      = "CONTOUR,MONTH_YEAR",
    returnGeometry = TRUE
  )

  all_features <- list()
  offset <- 0

  repeat {
    p <- params
    p$resultOffset      <- offset
    p$resultRecordCount <- max_records
    response <- httr::GET(url, query = p)
    if (httr::status_code(response) != 200) {
      warning("Request failed at offset ", offset,
              " (HTTP ", httr::status_code(response), ")")
      break
    }
    features <- sf::st_read(
      httr::content(response, as = "text", encoding = "UTF-8"), quiet = TRUE
    )
    if (nrow(features) == 0) break
    all_features[[length(all_features) + 1]] <- features
    offset <- offset + max_records
    if (verbose) cat("Retrieved", nrow(features), "features, offset:", offset, "\n")
    if (nrow(features) < max_records) break
  }

  if (length(all_features) == 0) {
    warning("No features returned for season '", season, "', year ", yr,
            " (MONTH_YEAR = '", month_year, "')")
    return(NULL)
  }

  contours <- do.call(rbind, all_features) |>
    sf::st_transform(crs = sf::st_crs(tbfullshed)) |>
    dplyr::select(CONTOUR, MONTH_YEAR)

  if (verbose) cat("Interpolating to 1-mile raster...\n")
  contours_to_raster(contours, verbose = verbose)

}
