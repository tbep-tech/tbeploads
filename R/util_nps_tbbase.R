#' Create unioned base layer for non-point source (NPS) ungaged load estimation in the Tampa Bay watershed
#'
#' @param tbsubshed sf object \code{link{tbsubshed}} of major drainage basins in the Tampa Bay watershed
#' @param tbjuris sf object \code{link{tbjuris}} of TBNMC jurisdictions in the Tampa Bay watershed
#' @param tblu sf object of land use/land cover in the Tampa Bay watershed, currently either \code{link{tblu2020}} or \code{link{tblu2023}}
#' @param tbsoil sf object \code{link{tbsoil}} of soil data in the Tampa Bay watershed
#' @param gdal_path Character string specifying the path to GDAL binaries (e.g., "C:/OSGeo4W/bin"). If NULL (default), assumes GDAL is in system PATH.
#' @param chunk_size Integer. For large datasets, process in chunks of this many features. Set to NULL (default) to process all at once.  This applies only to the final union with the soils data.
#' @param cast Logical. If TRUE, will cast multipolygon geometries to polygons before processing. Default is FALSE, which keeps multipolygons as is (usually faster).
#'
#' @returns A summarized data frame containing the union of all inputs showing major bay segment, sub-basin (basin), drainage feature (drnfeat), jurisdiction (entity), land use/land cover (FLUCCSCODE), CLUCSID, IMPROVED, hydrologic group (hydgrp), and area in hectures.  These represent all relevant spatial combinations in the Tampa Bay watershed.
#'
#' Relies heavily on \code{\link{util_nps_union}} to perform the union operations efficiently using GDAL/OGR.
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
                            chunk_size = NULL, cast = FALSE) {

  str <- Sys.time()

  # Ensure all inputs are sf objects
  if (!inherits(tbsubshed, "sf") || !inherits(tbjuris, "sf") ||
      !inherits(tblu, "sf") || !inherits(tbsoil, "sf")) {
    stop("All inputs must be sf objects.")
  }

  tb_base1 <- util_nps_union(tbsubshed, tbjuris, gdal_path = gdal_path, cast = cast) |>
    dplyr::group_by(bay_seg, basin, drnfeat, entity) |>
    dplyr::summarise()
  tb_base2 <- util_nps_union(tb_base1, tblu, gdal_path = gdal_path, cast = cast) |>
    dplyr::group_by(bay_seg, basin, drnfeat, entity, FLUCCSCODE) |>
    dplyr::summarise()
  tb_base3a <- util_nps_union(tb_base2, tbsoil, gdal_path = gdal_path, chunk_size = chunk_size, cast = cast) |>
    dplyr::group_by(bay_seg, basin, drnfeat, entity, FLUCCSCODE, hydgrp) |>
    dplyr::summarise()

  # Join with CLUCSID lookup table
  out <- dplyr::left_join(tbbase, clucsid, by = "FLUCCSCODE", relationship = 'one-to-many')

  dif <- capture.output(Sys.time() - str)
  cat(dif, '\n')

  return(out)

}
