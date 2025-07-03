#' Create unioned base layer for non-point source (NPS) ungaged load estimation in the Tampa Bay watershed
#'
#' @param tbsubshed sf object \code{link{tbsubshed}} of major drainage basins in the Tampa Bay watershed
#' @param tbjuris sf object \code{link{tbjuris}} of TBNMC jurisdictions in the Tampa Bay watershed
#' @param tblu sf object of land use/land cover in the Tampa Bay watershed, currently either \code{link{tblu2020}} or \code{link{tblu2023}}
#' @param tbsoil sf object \code{link{tbsoil}} of soil data in the Tampa Bay watershed
#' @param gdal_path Character string specifying the path to GDAL binaries (e.g., "C:/OSGeo4W/bin"). If NULL (default), assumes GDAL is in system PATH.
#' @param chunk_size Integer. For large datasets, process in chunks of this many features. Set to NULL (default) to process all at once.  This applies only to the final union with the soils data.
#' @param cast Logical. If TRUE, will cast multipolygon geometries to polygons before processing. Default is FALSE, which keeps multipolygons as is (usually faster).
#' @param verbose Logical. If TRUE, will print progress messages. Default is TRUE.
#'
#' @returns A summarized data frame containing the union of all inputs showing major bay segment, sub-basin (basin), drainage feature (drnfeat), jurisdiction (entity), land use/land cover (FLUCCSCODE), CLUCSID, IMPROVED, hydrologic group (hydgrp), and area in hectures.  These represent all relevant spatial combinations in the Tampa Bay watershed.
#'
#' @details
#' Relies heavily on \code{\link{util_nps_union}} to perform the union operations efficiently using GDAL/OGR.  All input must have the CRS of NAD83(2011) / Florida West (ftUS), EPSG:6443.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Load required data
#' data(tbsubshed)
#' data(tbjuris)
#' data(tblu2020)
#' data(tbsoil)
#' result <- util_nps_tbbase(tbsubshed, tbjuris, tblu2020, tbsoil, gdal_path = "C:/OSGeo4W/bin", chunk_size = 1000)
#' }
util_nps_tbbase <- function(tbsubshed, tbjuris, tblu, tbsoil, gdal_path = NULL,
                            chunk_size = NULL, cast = FALSE, verbose = TRUE) {

  str <- Sys.time()

  # Ensure all inputs are sf objects
  if (!all(inherits(tbsubshed, "sf"),
           inherits(tbjuris, "sf"),
           inherits(tblu, "sf"),
           inherits(tbsoil, "sf"))) {
    stop("All inputs must be sf objects.")
  }

  # check all sf inputs have the right projection
  prj <- 6443 # NAD83(2011) / Florida West (ftUS)
  if (!all(sf::st_crs(tbsubshed)$epsg == prj,
           sf::st_crs(tbjuris)$epsg == prj,
           sf::st_crs(tblu)$epsg == prj,
           sf::st_crs(tbsoil)$epsg == prj)) {
    stop("All inputs must have CRS of NAD83(2011) / Florida West (ftUS), EPSG:6443.")
  }

  if(verbose)
    cat('Combining Tampa Bay basins with TBNMC jurisdictions...\n')
  tbbase1 <- util_nps_union(tbsubshed, tbjuris, gdal_path = gdal_path, cast = cast) |>
    dplyr::group_by(bay_seg, basin, drnfeat, entity) |>
    dplyr::summarise()

  if(verbose)
    cat('Combining results with land use...\n')
  tbbase2 <- util_nps_union(tbbase1, tblu, gdal_path = gdal_path, cast = cast) |>
    dplyr::group_by(bay_seg, basin, drnfeat, entity, FLUCCSCODE) |>
    dplyr::summarise()

  if(verbose)
    cat('Combining results with soils...\n')
  tbbase3 <- util_nps_union(tbbase2, tbsoil, gdal_path = gdal_path, chunk_size = chunk_size, cast = cast, verbose = verbose) |>
    dplyr::group_by(bay_seg, basin, drnfeat, entity, FLUCCSCODE, hydgrp) |>
    dplyr::summarise()

  if(verbose)
    cat('Summarizing...\n')

  # Join with CLUCSID lookup table
  tbbase <- dplyr::left_join(tbbase3, clucsid, by = "FLUCCSCODE", relationship = 'many-to-one')

  # summarize
  out <- tbbase |>
    dplyr::mutate(
      FLUCCSCODE = tidyr::replace_na(FLUCCSCODE, 0),
      hydgrp = tidyr::replace_na(hydgrp, "D")
      ) |>
    sf::st_transform(prj) |>
    dplyr::group_by(bay_seg, basin, drnfeat, entity, FLUCCSCODE, CLUCSID, IMPROVED, hydgrp) |>
    dplyr::summarise(.groups = 'drop')

  out$area_ha <- as.numeric(sf::st_area(out) * 0.000009290304) # Convert from ft^2 to ha

  out <- out |>
    sf::st_drop_geometry() |>
    dplyr::mutate(
      CLUCSID = dplyr::case_when(
        FLUCCSCODE == 2100 ~ 10,
        TRUE ~ CLUCSID),
      drnfeat = ifelse(is.na(drnfeat), "CON", drnfeat)
    )

  dif <- capture.output(Sys.time() - str)
  if(verbose)
    cat(dif, '\n')

  return(out)

}
