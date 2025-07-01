#' Simple feature polygons major drainage basins in the Tampa Bay Estuary Program boundary
#'
#' @format A \code{\link[sf]{sf}} object
#'
#' @details Used for estimating ungaged non-point source (NPS) loads. The data includes the following columns.
#'
#' \itemize{
#'  \item \code{bay_seg}: Numeric value for the bay segment
#'  \item \code{basin}: Numeric value for the basin
#'  \item \code{drnfeat}: Numeric for the drainage feature
#'  \item \code{geometry}: The geometry column
#'}
#'
#' Segment numbers are 1-7 for Old Tampa Bay, Hillsborough Bay, Middle Tampa Bay, Lower Tampa Bay, Boca Ciega Bay, Terra Ceia Bay, and Manatee River.
#'
#' Projection is NAD83(2011) / Florida West (ftUS), CRS 6443.
#'
#' @examples
#' \dontrun{
#' prj <- 6443
#'
#' tbshed <- sf::st_read("./data-raw/TBEP/gis/TBEP_dBasins_Correct_Projection.shp") |>
#'   sf::st_transform(prj) |>
#'   sf::st_buffer(dist = 0) |>
#'   dplyr::group_by(BAY_SEGMEN, NEWGAGE, DRNFEATURE) |>
#'   dplyr::summarise() |>
#'   dplyr::ungroup() |>
#'   dplyr::rename(
#'     bay_seg = BAY_SEGMEN,
#'     basin = NEWGAGE,
#'     drnfeat = DRNFEATURE
#'   ) |>
#'   dplyr::arrange(bay_seg, basin, drnfeat)
#'
#' save(tbshed, file = 'data/tbshed.RData', compress = 'xz')
#' }
#' tbshed
"tbshed"
