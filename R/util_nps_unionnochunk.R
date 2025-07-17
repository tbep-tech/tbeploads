#' Helper function for union operation
#'
#' @param sf1 First sf object
#' @param sf2 Second sf object
#'
#' @details Used internally by \code{\link{util_nps_union}}. See the help file for more details.
#'
#' @export
#'
#' @return An sf object containing the spatial intersection of sf1 and sf2, with geometries unioned by unique combinations of all attributes from both input objects.
#'
#' @examples
#' \dontrun{
#' data(tbjuris)
#' data(tbsubshed)
#' result <- util_nps_unionnochunk(tbsubshed, tbjuris)
#' }
util_nps_unionnochunk <- function(sf1, sf2) {

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

  # Combine datasets into single file
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

  # Get layer names
  layer_info <- sf::st_layers(temp_combined)
  layer_names <- layer_info$name

  # Build SQL query dynamically
  sf1_cols <- setdiff(names(sf1), attr(sf1, "sf_column"))
  sf2_cols <- setdiff(names(sf2), attr(sf2, "sf_column"))

  sf1_select <- paste0("a.", sf1_cols, collapse = ", ")
  sf2_select <- paste0("b.", sf2_cols, collapse = ", ")
  all_select <- paste(c(sf1_select, sf2_select), collapse = ", ")

  sf1_group <- paste0("a.", sf1_cols, collapse = ", ")
  sf2_group <- paste0("b.", sf2_cols, collapse = ", ")
  all_group <- paste(c(sf1_group, sf2_group), collapse = ", ")

  first_sf1_col <- sf1_cols[1]
  first_sf2_col <- sf2_cols[1]

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

  result_code <- system(sprintf('ogr2ogr -f "GPKG" -nlt PROMOTE_TO_MULTI "%s" "%s" -dialect SQLite -sql "%s"',
                                temp_result, temp_combined, sql_query))

  if (result_code != 0) {
    stop("ogr2ogr operation failed. Try using chunk_size or simplify_tolerance parameters for large datasets.")
  }

  # Read and return result
  sf::st_read(temp_result, quiet = TRUE)
}
