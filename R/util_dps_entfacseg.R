#' Get DPS entity, facility, and bay segment from file name
#'
#' Get DPS entity, facility, and bay segment from file name
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
#' @return A list with entity, facility, and bay segment
#'
#' @examples
#' pth <- system.file('extdata/ps_dom_hillsco_falkenburg_2019.txt', package = 'tbeploads')
#' util_dps_entfacseg(pth)
util_dps_entfacseg <- function(pth, asdf = FALSE){

  # get entity and facility from path
  flentfac <- basename(pth) %>%
    gsub('\\.txt$', '', .) %>%
    strsplit('_') %>%
    .[[1]] %>%
    .[c(3, 4)]

  entfac <- facilities %>%
    filter(entityshr == flentfac[1] & facnameshr == flentfac[2]) %>%
    select(-source) %>%
    unique()

  ent <- entfac %>%
    pull(entity)

  fac <- entfac %>%
    pull(facname)

  seg <- entfac %>%
    pull(bayseg)

  out <- list(entity = ent, facname = fac, bayseg = seg)

  if(asdf)
    out <- as.data.frame(out)

  return(out)

}
