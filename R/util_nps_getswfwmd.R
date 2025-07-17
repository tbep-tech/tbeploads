#' Retrieve non-point source (NPS) supporting data from SWFWMD web services
#'
#' @param dat Character string indicating the type of data to retrieve. Options are 'soil', 'lulc2020', or 'lulc2023'.
#' @param max_records Integer specifying the maximum number of records to retrieve in each request. Default is 1000.
#' @param verbose Logical indicating whether to print verbose output. Default is TRUE.
#'
#' @returns A simple features object for the relevant data, clipped by the Tampa Bay watershed boundary (\code{\link{tbfullshed}}).
#'
#' @details This function retrieves data from the SWFWMD web services for soils and land use/land cover (LULC) for the years 2020 and 2023. Soils data from <https://www25.swfwmd.state.fl.us/arcgis12/rest/services/BaseVector> and land use data from <https://www25.swfwmd.state.fl.us/arcgis12/rest/services/OpenData>.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Retrieve soil data
#' soil_data <- util_nps_getswfwmd('soil')
#'
#' # Retrieve LULC data for 2020
#' lulc2020_data <- util_nps_getswfwmd('lulc2020')
#'
#' # Retrieve LULC data for 2023
#' lulc2023_data <- util_nps_getswfwmd('lulc2023')
#'
#' }
util_nps_getswfwmd <- function(dat, max_records = 1000, verbose = TRUE) {

  dat <- match.arg(dat, c('soil', 'lulc2020', 'lulc2023'))

  url <- switch(dat,
                soil = "https://www25.swfwmd.state.fl.us/arcgis12/rest/services/BaseVector/Soils/MapServer/0/query",
                lulc2020 = "https://www25.swfwmd.state.fl.us/arcgis12/rest/services/OpenData/LandUseLandCoverPost2014/MapServer/2/query",
                lulc2023 = "https://www25.swfwmd.state.fl.us/arcgis12/rest/services/OpenData/LandUseLandCoverPost2014/MapServer/3/query"
                )

  prj <- switch(dat,
                soil = 3857,
                lulc2020 = 2882,
                lulc2023 = 2882
                )

  prmsadd <- switch(dat,
                soil = list(outFields = "muid, hydgrp"),
                lulc2020 = list(outFields = "FLUCCSCODE, FLUCSDESC"),
                lulc2023 = list(outFields = "FLUCCSCODE, FLUCSDESC")
                )

  tbep_bb <- tbfullshed |>
    sf::st_transform(prj) |>
    sf::st_bbox()

  params <- list(
    f = "geojson",
    geometryType = "esriGeometryEnvelope",
    geometry = paste0('{"xmin":', tbep_bb[1], ',"ymin":', tbep_bb[2], ',"xmax":', tbep_bb[3], ',"ymax":', tbep_bb[4], '}'),
    spatialRel = "esriSpatialRelIntersects",
    returnGeometry = TRUE
  )
  params <- c(params, prmsadd)

  all_features <- list()
  offset <- 0

  repeat {
    # Add pagination parameters
    current_params <- params
    current_params$resultOffset <- offset
    current_params$resultRecordCount <- max_records

    response <- httr::GET(url, query = current_params)

    if (httr::status_code(response) != 200) {
      warning("Request failed at offset ", offset)
      break
    }

    content_text <- httr::content(response, as = "text", encoding = "UTF-8")
    features <- sf::st_read(content_text, quiet = TRUE)

    if (nrow(features) == 0) {
      break  # No more features
    }

    all_features[[length(all_features) + 1]] <- features
    offset <- offset + max_records

    if(verbose)
      cat(paste("Retrieved", nrow(features), "features, offset:", offset), "\n")

    # Break if we got fewer features than requested (last batch)
    if (nrow(features) < max_records) {
      break
    }
  }

  # Combine all features
  if (length(all_features) > 0) {
    out <- do.call(rbind, all_features)
  } else {
    return(NULL)
  }

  out <- out |>
    sf::st_transform(crs = sf::st_crs(tbfullshed)) |>
    sf::st_intersection(tbfullshed) |>
    sf::st_buffer(dist = 0)

  if(dat == 'soil')
    out <- out |>
      dplyr::rename(hydgrp = HYDGRP) |>
      dplyr::group_by(hydgrp)

  if(dat %in% c('lulc2020', 'lulc2023'))
    out <- out |>
      dplyr::group_by(FLUCCSCODE, FLUCSDESC)

  out <- out |>
    dplyr::summarise() |>
    dplyr::ungroup()

  return(out)

}
