#' Get DPS entity, facility, and bay segment from file name
#'
#' Get DPS entity, facility, and bay segment from file name
#'
#' @param pth path to raw entity data
#'
#' @export
#'
#' @details Bay segment is an integer with values of 1, 2, 3, 4, 5, 6, 7, and 55 for Old Tampa Bay, Hillsborough Bay, Middle Tampa Bay, Lower Tampa Bay, Boca Ciega Bay, Terra Ceia Bay, Manatee River, and Boca Ciega Bay South, respectively.
#'
#'
#' @importFrom dplyr filter pull
#'
#' @return A list with entity, facility, and bay segment
#'
#' @examples
#' pth <- system.file('extdata/ps_dom_hillsco_falkenburg_2019.txt', package = 'tbeploads')
#' util_dps_entfacseg(pth)
util_dps_entfacseg <- function(pth){

  # get entity and facility from path
  entfac <- basename(pth) %>%
    gsub('\\.txt$', '', .) %>%
    strsplit('_') %>%
    .[[1]] %>%
    .[c(3, 4)]

  ent <- facilities %>%
    filter(entityshr == entfac[1]) %>%
    pull(entity) %>%
    unique()

  fac <- facilities %>%
    filter(facnameshr == entfac[2]) %>%
    pull(facname) %>%
    unique()

  seg <- facilities %>%
    filter(entity == ent & facname == fac) %>%
    pull(bayseg) %>%
    unique()

  out <- list(ent = ent, fac = fac, seg = seg)

  return(out)

}
