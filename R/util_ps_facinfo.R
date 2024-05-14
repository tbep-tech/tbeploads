#' Get point source entity information from file name
#'
#' Get point source entity information from file name
#'
#' @param pth path to raw entity data
#' @param asdf logical, if \code{TRUE} return as \code{data.frame}
#'
#' @export
#'
#' @details Bay segment is an integer with values of 1, 2, 3, 4, 5, 6, 7, and 55 for Old Tampa Bay, Hillsborough Bay, Middle Tampa Bay, Lower Tampa Bay, Boca Ciega Bay, Terra Ceia Bay, Manatee River, and Boca Ciega Bay South, respectively.
#'
#' @return A list or \code{data.frame} (if \code{asdf = TRUE}) with entity, facility, permit, facility id, coastal id, and coastal subbasin code
#'
#' @examples
#' pth <- system.file('extdata/ps_dom_hillsco_falkenburg_2019.txt', package = 'tbeploads')
#' util_ps_facinfo(pth)
util_ps_facinfo <- function(pth, asdf = FALSE){

  # get entity and facility from path
  flentfac <- gsub('\\.txt$', '', basename(pth)) |>
    strsplit('_')
  flentfac <- flentfac[[1]][c(3, 4)]

  facinfo <- facilities |>
    dplyr::filter(entityshr == flentfac[1] & facnameshr == flentfac[2]) |>
    dplyr::select(-bayseg, -source, -basin) |>
    unique()

  out <- facinfo |>
    dplyr::select(entity, facname, permit, facid, coastco, coastid)

  if(!asdf)
    out <- as.list(out)

  return(out)

}
