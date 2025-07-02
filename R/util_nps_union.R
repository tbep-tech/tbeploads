#' Fast Spatial Intersection Union Using GDAL
#'
#' Performs a spatial intersection and union of two sf objects using GDAL's optimized spatial operations. This function is significantly faster than native sf operations for large datasets.
#'
#' @param sf1 An sf object containing polygons. All non-geometry columns will be preserved in the output
#' @param sf2 An sf object containing polygons. All non-geometry columns will be preserved in the output
#' @param gdal_path Character string specifying the path to GDAL binaries (e.g., "C:/OSGeo4W/bin"). If NULL (default), assumes GDAL is in system PATH or uses sf's internal GDAL installation
#'
#' @return An sf object containing the spatial intersection of sf1 and sf2, with geometries unioned by unique combinations of all attributes from both input objects
#'
#' @details
#' This function uses GDAL's ogr2ogr utility to perform spatial intersection operations, which can be much faster than sf's native functions for large datasets. The process:
#' \enumerate{
#'   \item Exports both sf objects to temporary GeoPackage files
#'   \item Combines them into a single file
#'   \item Dynamically builds SQL query based on actual column names
#'   \item Uses SQL with spatial functions to find intersections
#'   \item Groups and unions results by all attribute combinations
#' }
#'
#' The function automatically detects all non-geometry columns from both input objects and includes them in the intersection operation.
#'
#' @note
#' Requires GDAL/OGR to be installed and accessible. On Windows, this is typically provided by OSGeo4W or QGIS installations, downloadable at <https://trac.osgeo.org/osgeo4w/>
#'
#' @export
#'
#' @examples
#' \dontrun{
#'
#' data(tbsubshed)
#' data(tbjuris)
#'
#' result <- util_nps_union(
#'   sf1 = tbsubshed,
#'   sf2 = tbjuris,
#'   "C:/OSGeo4W/bin"
#' )
#' }
util_nps_union <- function(sf1, sf2, gdal_path = NULL) {

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

  # Create temporary files
  temp_sf1 <- tempfile(fileext = ".gpkg")
  temp_sf2 <- tempfile(fileext = ".gpkg")
  temp_combined <- tempfile(fileext = ".gpkg")
  temp_result <- tempfile(fileext = ".gpkg")

  # Ensure temp files are cleaned up
  on.exit(unlink(c(temp_sf1, temp_sf2, temp_combined, temp_result)), add = TRUE)

  # Export data to temp files
  sf::st_write(sf1, temp_sf1, delete_dsn = TRUE, quiet = TRUE)
  sf::st_write(sf2, temp_sf2, delete_dsn = TRUE, quiet = TRUE)

  # Step 1: Combine datasets into single file
  sf::gdal_utils(
    util = "vectortranslate",
    source = temp_sf1,
    destination = temp_combined,
    options = c("-f", "GPKG")
  )

  sf::gdal_utils(
    util = "vectortranslate",
    source = temp_sf2,
    destination = temp_combined,
    options = c("-f", "GPKG", "-update", "-append")
  )

  # Step 2: Get layer names
  layer_info <- sf::st_layers(temp_combined)
  layer_names <- layer_info$name

  # Step 3: Build SQL query dynamically based on actual column names
  # Get column names (excluding geometry column)
  sf1_cols <- setdiff(names(sf1), attr(sf1, "sf_column"))
  sf2_cols <- setdiff(names(sf2), attr(sf2, "sf_column"))

  # Build SELECT clause for attributes (with proper spacing)
  sf1_select <- paste0("a.", sf1_cols, collapse = ", ")
  sf2_select <- paste0("b.", sf2_cols, collapse = ", ")
  all_select <- paste(c(sf1_select, sf2_select), collapse = ", ")

  # Build GROUP BY clause (all attributes from both tables)
  sf1_group <- paste0("a.", sf1_cols, collapse = ", ")
  sf2_group <- paste0("b.", sf2_cols, collapse = ", ")
  all_group <- paste(c(sf1_group, sf2_group), collapse = ", ")

  # Build minimal WHERE clause (only check first column from each table to match your pattern)
  # This follows your working pattern of only checking key columns for NULL
  first_sf1_col <- sf1_cols[1]
  first_sf2_col <- sf2_cols[1]

  # Create the complete SQL query matching your working format exactly
  sql_query <- sprintf("
  SELECT ST_Union(ST_Intersection(a.geom, b.geom)) as geom,
         %s
  FROM %s a, %s b
  WHERE ST_Intersects(a.geom, b.geom)
    AND a.%s IS NOT NULL
    AND b.%s IS NOT NULL
  GROUP BY %s",
                       all_select, layer_names[1], layer_names[2],
                       first_sf1_col, first_sf2_col, all_group)

  result_code <- system(sprintf('ogr2ogr -f "GPKG" "%s" "%s" -dialect SQLite -sql "%s"',
                                temp_result, temp_combined, sql_query))

  if (result_code != 0) {
    stop("ogr2ogr operation failed. Check input data and GDAL installation.")
  }

  # Step 4: Read and return result
  out <- sf::st_read(temp_result, quiet = TRUE)

  return(out)

}
