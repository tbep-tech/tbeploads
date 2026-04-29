#' Upper Floridan Aquifer potentiometric surface raster, dry season 2022
#'
#' @format A \code{PackedSpatRaster} (see \code{\link[terra]{wrap}})
#'   representing a 1-mile resolution grid of potentiometric head (ft above
#'   MSL) for the dry season. Unwrap with \code{terra::unwrap(contdry)} to
#'   obtain a \code{\link[terra]{SpatRaster}}.
#'
#' @details
#' Interpolated from Upper Floridan Aquifer potentiometric surface contour
#' lines (May 2022) downloaded from the FDEP / Florida Geological Survey
#' ArcGIS REST service using \code{\link{util_gw_getcontour}}. The spatial
#' extent covers the Tampa Bay watershed (\code{\link{tbfullshed}}) buffered
#' outward by 40 miles. Interpolation used inverse distance weighting (IDW,
#' 5-mile radius, power = 2) followed by five passes of a 3x3 focal mean gap
#' fill. Projection is NAD83(2011) / Florida GDL Albers (ftUS), CRS 6443.
#'
#' Wet season equivalent is \code{\link{contwet}}.
#'
#' @examples
#' \dontrun{
#' pot_dry <- util_gw_getcontour("dry", 2022)
#' contdry <- terra::wrap(pot_dry)
#' save(contdry, file = "data/contdry.RData", compress = "xz")
#' }
#' terra::unwrap(contdry)
"contdry"
