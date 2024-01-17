#' Add column names for DPS reuse and end of pipe from raw entity data
#'
#' Add column names for DPS reuse and end of pipe from raw entity data
#'
#' @param dat data frame from raw entity data as \code{data.frame}
#'
#' @details The function checks for TN, TP, TSS, and BOD.  If any of these are missing, the columns are added with empty values including a column for units.  If BOD is missing but CBOD is present, the CBOD column is renamed to BOD.
#'
#' @return Input data frame from \code{pth} as is if column names are correct, otherwise additional columns are added as needed.
#' @export
#'
#' @examples
#' pth <- system.file('extdata/ps_dom_hillsco_falkenburg_2019.txt', package = 'tbeploads')
#' dat <- read.table(pth, skip = 0, sep = '\t', header = TRUE)
#' util_dps_addcol(dat)
util_dps_addcol <- function(dat){

  # check tn
  chktn <- grepl('^Total.N', names(dat))
  if(!any(chktn))
    dat <- dat %>%
      mutate(
        Total.N = NA_real_,
        Total.N.Unit = 'mg/l'
        )

  # check tp
  chktp <- grepl('^Total.P', names(dat))
  if(!any(chktp))
    dat <- dat %>%
      mutate(
        Total.P = NA_real_,
        Total.P.Unit = 'mg/l'
        )

  # check tss
  chktss <- grepl('^TSS', names(dat))
  if(!any(chktss))
    dat <- dat %>%
      mutate(
        TSS = NA_real_,
        TSS.Unit = 'mg/l'
        )

  # check bod, use cbod if bod not present and cbod is present
  chkbod <- grepl('^BOD', names(dat))
  if(!any(chkbod)){
    chkbod <- grepl('^CBOD$', names(dat))
    if(any(chkbod)){
      dat <- dat %>%
        rename(
          BOD = matches('^CBOD$'),
          BOD.Unit = matches('^CBOD.*Unit')
          )
    } else {
      dat <- dat %>%
        mutate(
          BOD = NA_real_,
          BOD.Unit = 'mg/l'
          )
    }
  }

  return(dat)

}
