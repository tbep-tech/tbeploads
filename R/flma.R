#' Simple features polygons of FNAI Florida Conservation Lands clipped to the Tampa Bay watershed
#'
#' @format A \code{\link[sf]{sf}} object
#'
#' @details Used to identify conservation lands for the non-point source (NPS)
#' load allocation assessment. When passed as the \code{tbconserv} argument to
#' \code{\link{util_nps_tbbase}}, conservation areas receive a \code{conservation = TRUE}
#' flag in the output \code{\link{tbbase}} dataset, which routes their load to
#' the aggregate \code{"Conserv"} entity in \code{\link{anlz_aa}}.
#'
#' Source: Florida Natural Areas Inventory (FNAI) Florida Managed Areas
#' (FLMA) / Florida Conservation Lands database. Downloaded via
#' \code{\link{util_nps_getflma}} and clipped to \code{\link{tbfullshed}}.
#'
#' Projection is NAD83(2011) / Florida West (ftUS), CRS 6443.
#'
#' @examples
#' \dontrun{
#' url <- "https://www.fnai.org/shapefiles/flma_202503.zip"
#'
#' flma <- util_nps_getflma(url = url)
#'
#' save(flma, file = "data/flma.RData", compress = "xz")
#' }
"flma"
