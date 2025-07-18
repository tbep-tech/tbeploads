#' Fast Spatial Intersection and Union Using GDAL
#'
#' Performs a spatial intersection and union of two sf objects using GDAL's optimized spatial operations. This function is significantly faster than native sf operations for large datasets.
#'
#' @param sf1 An sf object containing polygons. All non-geometry columns will be preserved in the output
#' @param sf2 An sf object containing polygons. All non-geometry columns will be preserved in the output
#' @param gdal_path Character string specifying the path to GDAL binaries (e.g., "C:/OSGeo4W/bin"). If NULL (default), assumes GDAL is in system PATH
#' @param chunk_size Integer. For large datasets, process in chunks of this many features from sf1. Set to NULL (default) to process all at once
#' @param cast Logical. If TRUE, will cast multipolygon geometries to polygons before processing. Default is FALSE, which keeps multipolygons as is (usually faster).
#' @param verbose Logical. If TRUE, will print progress messages. Default is TRUE.
#'
#' @return An sf object containing the spatial intersection of sf1 and sf2, with geometries unioned by unique combinations of all attributes from both input objects
#'
#' This function uses GDAL's ogr2ogr utility to perform spatial intersection operations, which can be much faster than sf's native functions for large datasets. The process:
#'
#' \enumerate{
#'   \item Exports both sf objects to temporary GeoPackage files
#'   \item Combines them into a single file
#'   \item Dynamically builds SQL query based on actual column names
#'   \item Uses SQL with spatial functions to find intersections
#'   \item Groups and unions results by all attribute combinations
#' }
#'
#'For very large datasets that cause memory issues, the function can process data in chunks.
#'
#' The function automatically detects all non-geometry columns from both input objects and includes them in the intersection operation.
#'
#' @note
#' Requires GDAL/OGR to be installed and accessible. On Windows, this is typically provided by OSGeo4W or QGIS installations, downloadable at <https://trac.osgeo.org/osgeo4w/>.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' data(tbsubshed)
#' data(tbjuris)
#' result <- util_nps_union(
#'   sf1 = tbsubshed,
#'   sf2 = tbjuris,
#'   "C:/OSGeo4W/bin"
#'   )
#' }
util_nps_union <- function(sf1, sf2, gdal_path = NULL, chunk_size = NULL, cast = FALSE, verbose = TRUE) {

  # Store original PATH to restore later
  original_path <- Sys.getenv("PATH")

  # Set GDAL path if provided, with proper cleanup
  if (!is.null(gdal_path)) {
    new_path <- paste(gdal_path, original_path, sep = .Platform$path.sep)
    Sys.setenv(PATH = new_path)

    # Ensure PATH is restored even if function errors
    on.exit(Sys.setenv(PATH = original_path), add = TRUE)

    # Test if ogr2ogr is now accessible
    ogr_test <- suppressWarnings(system("ogr2ogr --version",
                                        ignore.stdout = TRUE,
                                        ignore.stderr = TRUE))
    if (ogr_test != 0) {
      stop("ogr2ogr not found at specified path: ", gdal_path,
           "\nPlease check GDAL installation and path.")
    }
  } else {
    # Test if ogr2ogr is accessible without path modification
    ogr_test <- suppressWarnings(system("ogr2ogr --version",
                                        ignore.stdout = TRUE,
                                        ignore.stderr = TRUE))
    if (ogr_test != 0) {
      stop("ogr2ogr not found in system PATH. ",
           "Please provide gdal_path argument or ensure GDAL is installed.")
    }
  }

  if(cast) {
    # Cast multipolygon geometries to polygons
    if(any(sf::st_geometry_type(sf1) == "MULTIPOLYGON"))
      sf1 <- sf::st_cast(sf1, "POLYGON")
    if(any(sf::st_geometry_type(sf2) == "MULTIPOLYGON"))
      sf2 <- sf::st_cast(sf2, "POLYGON")
  }

  # Check if chunking is needed
  if (!is.null(chunk_size) && nrow(sf1) > chunk_size) {
    if(verbose)
      cat("Processing in chunks of", chunk_size, "features\n")
    return(util_nps_unionchunk(sf1, sf2, chunk_size, verbose))
  }

  # Process normally for smaller datasets
  util_nps_unionnochunk(sf1, sf2)
}
