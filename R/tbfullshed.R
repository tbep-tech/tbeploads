#' Simple features polygon for the Tampa Bay Estuary Program boundary
#'
#' @format A \code{\link[sf]{sf}} object
#'
#' @details Used for estimating ungaged non-point source (NPS) loads. The data includes the following columns.
#'
#' \itemize{
#'  \item \code{Name}: Character for the layer name
#'  \item \code{Hectares}: Numeric value for area of the polygon
#'  \item \code{geometry}: The geometry column
#'}
#'
#' Projection is NAD83(2011) / Florida West (ftUS), CRS 6443.
#'
#' @examples
#' \dontrun{
#' prj <- 6443
#'
#' tbfullshed <- sf::st_read("./data-raw/gis/TBEP_Watershed_Correct_Projection.shp") |>
#'   st_transform(prj) |>
#'   st_union(by_feature = T) |>
#'   st_buffer(dist = 0) |>
#'   dplyr::select(Name, Hectares)
#'
#' save(tbfullshed, file = 'data/tbfullshed.RData', compress = 'xz')
#' }
#' tbfullshed
"tbfullshed"
