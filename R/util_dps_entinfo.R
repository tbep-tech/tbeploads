#' Get DPS entity information from file name
#'
#' Get DPS entity information from file name
#'
#' @param pth path to raw entity data
#' @param asdf logical, if \code{TRUE} return as \code{data.frame}
#'
#' @export
#'
#' @details Bay segment is an integer with values of 1, 2, 3, 4, 5, 6, 7, and 55 for Old Tampa Bay, Hillsborough Bay, Middle Tampa Bay, Lower Tampa Bay, Boca Ciega Bay, Terra Ceia Bay, Manatee River, and Boca Ciega Bay South, respectively.
#'
#'
#' @importFrom dplyr filter pull select
#'
#' @return A list or \code{data.frame} (if \code{asdf = TRUE}) with entity, facility, permit, and facility id
#'
#' @examples
#' pth <- system.file('extdata/ps_dom_hillsco_falkenburg_2019.txt', package = 'tbeploads')
#' util_dps_entinfo(pth)
util_dps_entinfo <- function(pth, asdf = FALSE){

  # get entity and facility from path
  flentfac <- gsub('\\.txt$', '', basename(pth)) |>
    strsplit('_')
  flentfac <- flentfac[[1]][c(3, 4)]

  facinfo <- facilities |>
    filter(entityshr == flentfac[1] & facnameshr == flentfac[2]) |>
    select(-bayseg, -source, -basin) |>
    unique()

  out <- facinfo |>
    select(entity, facname, permit, facid)

  if(!asdf)
    out <- as.list(out)

  return(out)

}
