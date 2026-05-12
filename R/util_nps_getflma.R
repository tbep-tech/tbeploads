#' Download and clip an FNAI FLMA zipped GDB to the Tampa Bay watershed
#'
#' Downloads a zipped File Geodatabase from the FNAI website (or any
#' compatible URL), extracts it, reads the first layer, reprojects, fixes
#' geometries, and clips to the study area boundary. The downloaded zip is
#' deleted on function exit.
#'
#' @param url Character. Direct URL to the FNAI zip file.
#' @param clp An \code{sf} polygon used to clip the output. Defaults to the
#'   Tampa Bay watershed (\code{\link{tbfullshed}}).
#' @param crs Integer EPSG code for the output CRS. Default \code{6443L}.
#' @param verbose Logical. Print progress messages. Default \code{TRUE}.
#'
#' @returns An \code{sf} object clipped to \code{clp} in \code{crs}.
#'
#' @details
#' The zip archive may contain either a File Geodatabase (\code{.gdb}) or a
#' shapefile (\code{.shp}). A GDB is preferred; if none is found the first
#' shapefile in the archive is used. When a GDB is present,
#' \code{sf::gdal_utils("vectortranslate")} converts it to a temporary
#' GeoPackage before reading to avoid GDAL driver limitations with curved
#' geometries.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' flma <- util_nps_getflma(
#'   url = "https://www.fnai.org/shapefiles/flma_202503.zip"
#' )
#' }
util_nps_getflma <- function(
    url,
    clp = tbfullshed,
    crs = 6443L,
    verbose = TRUE
) {

  zip_path <- tempfile(fileext = ".zip")
  on.exit(unlink(zip_path, force = TRUE))

  if (verbose) cat(sprintf("  Downloading: %s\n", basename(url)))
  resp <- httr2::request(url) |>
    httr2::req_timeout(600) |>
    httr2::req_retry(max_tries = 3, backoff = ~30) |>
    httr2::req_perform()
  writeBin(httr2::resp_body_raw(resp), zip_path)
  if (verbose) cat(sprintf("  Saved (%.1f MB)\n", file.size(zip_path) / 1e6))

  tmp_dir <- tempfile()
  on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)
  utils::unzip(zip_path, exdir = tmp_dir)

  gdb <- list.files(
    tmp_dir,
    pattern   = "\\.gdb$",
    full.names  = TRUE,
    recursive   = TRUE,
    include.dirs = TRUE
  )

  if (length(gdb)) {
    tmp_gpkg <- tempfile(fileext = ".gpkg")
    on.exit(unlink(tmp_gpkg, force = TRUE), add = TRUE)
    sf::gdal_utils(
      util        = "vectortranslate",
      source      = gdb[1],
      destination = tmp_gpkg,
      options     = c(
        "-nlt", "CONVERT_TO_LINEAR",
        "-nlt", "PROMOTE_TO_MULTI",
        "-f",   "GPKG",
        "-lco", "SPATIAL_INDEX=NO"
      )
    )
    out <- sf::st_read(tmp_gpkg, quiet = !verbose)
  } else {
    shp <- list.files(
      tmp_dir,
      pattern   = "\\.shp$",
      full.names = TRUE,
      recursive  = TRUE
    )
    if (!length(shp))
      stop("No .gdb or .shp found in zip: ", basename(url))
    out <- sf::st_read(shp[1], quiet = !verbose)
  }

  out |>
    sf::st_zm(drop = TRUE) |>
    sf::st_transform(crs) |>
    sf::st_make_valid() |>
    sf::st_buffer(dist = 0) |>
    sf::st_intersection(sf::st_union(clp)) |>
    sf::st_make_valid()

}
