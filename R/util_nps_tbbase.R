#' Create unioned base layer for non-point source (NPS) ungaged load estimation in the Tampa Bay watershed
#'
#' @param tblu sf object of land use/land cover in the Tampa Bay watershed, currently \code{link{tblu2023}}
#' @param tbsoil sf object \code{link{tbsoil}} of soil data in the Tampa Bay watershed
#' @param gdal_path Character string specifying the path to GDAL binaries (e.g., "C:/OSGeo4W/bin"). If NULL (default), assumes GDAL is in system PATH.
#' @param chunk_size Integer. For large datasets, process in chunks of this many features. Set to NULL (default) to process all at once.  This applies only to the final union with the soils data.
#' @param cast Logical. If TRUE, will cast multipolygon geometries to polygons before processing. Default is FALSE, which keeps multipolygons as is (usually faster).
#' @param verbose Logical. If TRUE, will print progress messages. Default is TRUE.
#'
#' @returns A summarized data frame containing the union of all inputs showing major bay segment, sub-basin (basin), drainage feature (drnfeat), jurisdiction (entity), land use/land cover (FLUCCSCODE), CLUCSID, IMPROVED, hydrologic group (hydgrp), and area in hectares. These represent all relevant spatial combinations in the Tampa Bay watershed. Land falling under an active NPDES discharge permit (see \code{\link{tbmines}}) is reclassified to \code{CLUCSID = 22}, overriding any FLUCCS-based category, so it can be excluded from NPS load estimation in \code{\link{util_aa_npsfactors}}. Areas with no soil classification in \code{\link{tbsoil}} (\code{hydgrp} is \code{NA}, typically open water) are assigned \code{hydgrp = "D"} and retained rather than dropped. Basin/jurisdiction area not covered by \code{tblu} (also typically open bay/estuarine water) is likewise retained, assigned FLUCCS code 5400 (\code{CLUCSID = 17}, Saltwater) rather than dropped.
#'
#' @details
#' Relies heavily on \code{\link{util_nps_union}} to perform the union operations efficiently using GDAL/OGR.  All input must have the CRS of NAD83(2011) / Florida West (ftUS), EPSG:6443.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Load required data
#' data(tblu2023)
#' data(tbsoil)
#' result <- util_nps_tbbase(tblu2023, tbsoil, gdal_path = "C:/OSGeo4W/bin", chunk_size = 1000)
#' }
util_nps_tbbase <- function(tblu, tbsoil, gdal_path = NULL,
                            chunk_size = NULL, cast = FALSE, verbose = TRUE) {

  str <- Sys.time()

  # Ensure all inputs are sf objects
  if (!all(inherits(tblu, "sf"),
           inherits(tbsoil, "sf"))) {
    stop("All inputs must be sf objects.")
  }

  # check all sf inputs have the right projection
  prj <- 6443 # NAD83(2011) / Florida West (ftUS)
  if (!all(sf::st_crs(tblu)$epsg == prj,
           sf::st_crs(tbsoil)$epsg == prj)) {
    stop("All inputs must have CRS of NAD83(2011) / Florida West (ftUS), EPSG:6443.")
  }

  # util_nps_union()'s SQL requires each input's first non-geometry attribute
  # to be non-missing, or that row is dropped from the join entirely. hydgrp
  # is tbsoil's only attribute and is legitimately NA for water bodies (no
  # SSURGO hydrologic group), so without this, those areas are silently
  # excluded from tbbase instead of retained with a default group - the
  # replace_na() below never gets a chance to run for them otherwise.
  tbsoil <- tbsoil |>
    dplyr::mutate(hydgrp = tidyr::replace_na(hydgrp, "D"))

  if(verbose)
    cat('Combining drainage basins with sub-watersheds...\n')

  tbbase1 <- util_nps_union(tbsubshed, tbdbasin, gdal_path = gdal_path, cast = cast) |>
    dplyr::group_by(bay_seg, basin, drnfeat) |>
    dplyr::summarise()

  if(verbose)
    cat('Combining results with TBNMC jurisdictions...\n')

  tbbase2 <- util_nps_union(tbbase1, tbjuris, gdal_path = gdal_path, cast = cast) |>
    dplyr::group_by(bay_seg, basin, drnfeat, entity) |>
    dplyr::summarise()

  if(verbose)
    cat('Combining results with land use...\n')

  tbbase3 <- util_nps_union(tbbase2, tblu, gdal_path = gdal_path, cast = cast) |>
    dplyr::group_by(bay_seg, basin, drnfeat, entity, FLUCCSCODE) |>
    dplyr::summarise()

  if(verbose)
    cat('Filling land use gaps...\n')

  # tblu does not fully cover the watershed - real basin/jurisdiction area can
  # include open bay/estuarine water not covered by a terrestrial land use
  # survey (e.g., basin 206-3C is ~77% open water), so util_nps_union()'s
  # inner intersection silently drops that area rather than retaining it.
  # Recover it and assign a default "Saltwater" FLUCCSCODE (5400, CLUCSID 17
  # per the clucsid lookup), rather than letting it artificially inflate
  # other land's share of the basin during NPS disaggregation (see
  # util_aa_npsfactors()).
  lu_union <- sf::st_union(sf::st_geometry(tblu))

  tbbase2 <- dplyr::ungroup(tbbase2)
  tbbase2_gap <- suppressWarnings(sf::st_difference(tbbase2, lu_union))
  # st_difference() leaves a row with empty geometry (rather than dropping it)
  # when a feature is fully covered by lu_union, i.e. no gap - drop those
  # instead of carrying forward zero-area placeholder rows.
  tbbase2_gap <- tbbase2_gap[!sf::st_is_empty(tbbase2_gap), ]
  tbbase2_gap <- tbbase2_gap |>
    dplyr::mutate(FLUCCSCODE = 5400) |>
    dplyr::group_by(bay_seg, basin, drnfeat, entity, FLUCCSCODE) |>
    dplyr::summarise(.groups = 'drop')

  tbbase3 <- dplyr::bind_rows(dplyr::ungroup(tbbase3), tbbase2_gap) |>
    dplyr::group_by(bay_seg, basin, drnfeat, entity, FLUCCSCODE) |>
    dplyr::summarise(.groups = 'drop')

  if(verbose)
    cat('Combining results with soils...\n')

  tbbase4 <- util_nps_union(tbbase3, tbsoil, gdal_path = gdal_path, chunk_size = chunk_size, cast = cast, verbose = verbose) |>
    dplyr::group_by(bay_seg, basin, drnfeat, entity, FLUCCSCODE, hydgrp) |>
    dplyr::summarise()

  if(verbose)
    cat('Flagging NPDES-permitted (mine) land...\n')

  # tbmines covers only a small fraction of the watershed, so util_nps_union()
  # (an inner intersection) would drop everything outside the mine boundaries
  # if used here - a direct intersection/difference preserves full coverage
  # while flagging which land falls under a permit boundary.
  mines_union <- sf::st_union(sf::st_geometry(tbmines))

  tbbase4 <- dplyr::ungroup(tbbase4)
  tbbase4_mine <- suppressWarnings(sf::st_intersection(tbbase4, mines_union)) |>
    dplyr::mutate(npdes = TRUE)
  tbbase4_nomine <- suppressWarnings(sf::st_difference(tbbase4, mines_union)) |>
    dplyr::mutate(npdes = FALSE)

  tbbase4 <- dplyr::bind_rows(tbbase4_mine, tbbase4_nomine) |>
    dplyr::group_by(bay_seg, basin, drnfeat, entity, FLUCCSCODE, hydgrp, npdes) |>
    dplyr::summarise(.groups = 'drop')

  if(verbose)
    cat('Summarizing...\n')

  # Join with CLUCSID lookup table
  tbbase <- dplyr::left_join(tbbase4, clucsid, by = "FLUCCSCODE", relationship = 'many-to-one') |>
    dplyr::select(-DESCRIPTION)

  out <- tbbase |>
    dplyr::mutate(
      FLUCCSCODE = tidyr::replace_na(FLUCCSCODE, 0),
      hydgrp = tidyr::replace_na(hydgrp, "D")
    ) |>
    sf::st_transform(prj) |>
    dplyr::group_by(bay_seg, basin, drnfeat, entity, FLUCCSCODE, CLUCSID, IMPROVED, hydgrp, npdes) |>
    dplyr::summarise(.groups = 'drop')

  out$area_ha <- as.numeric(sf::st_area(out) * 0.000009290304) # Convert from ft^2 to ha

  out <- out |>
    sf::st_drop_geometry() |>
    dplyr::mutate(
      CLUCSID = dplyr::case_when(
        FLUCCSCODE == 2100 ~ 10,
        TRUE ~ CLUCSID),
      # land under an active NPDES discharge permit always overrides the
      # FLUCCS-based category - applied last so a mined parcel's permit
      # status wins regardless of its underlying land use (see @returns)
      CLUCSID = dplyr::if_else(npdes, 22L, CLUCSID),
      drnfeat = ifelse(is.na(drnfeat), "CON", drnfeat)
    ) |>
    dplyr::select(-npdes)

  dif <- capture.output(Sys.time() - str)
  if(verbose)
    cat(dif, '\n')

  return(out)

}
