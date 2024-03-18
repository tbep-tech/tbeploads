#' Check units for DPS reuse and end of pipe from raw entity data
#'
#' Check units for DPS reuse and end of pipe from raw entity data
#'
#' @param dat data frame from raw entity data as \code{data.frame}
#'
#' @details
#' Input data should include flow as million gallons per day, and concentration as mg/L.
#'
#' @return Input data frame from \code{pth} with relevant data and columns renamed, otherwise an error is returned if units are not correct.  Only year, month, outfall, flow, TN, TP, TSS, and BOD are returned.
#'
#' @export
#'
#' @examples
#' pth <- system.file('extdata/ps_dom_hillsco_falkenburg_2019.txt', package = 'tbeploads')
#' dat <- read.table(pth, skip = 0, sep = '\t', header = TRUE)
#' util_dps_checkuni(dat)
util_dps_checkuni <- function(dat){

  # check flow units
  if(!'Average.Daily.Flow..ADF...mgd.' %in% names(dat)){
    stop('Flow not as mgd')
  }

  dat <- dat |>
    dplyr::select(
      Year,
      Month,
      outfall = Outfall.ID,
      flow_mgd = dplyr::matches('^Average.Daily.Flow'),
      tn_mgl = dplyr::matches('^Total.N'),
      tp_mgl = dplyr::matches('^Total.P'),
      tss_mgl = dplyr::matches('^TSS'),
      bod_mgl = dplyr::matches('^BOD')
    )

  # check mgl
  chk_mgl <- dat |>
    dplyr::select(dplyr::matches('2$')) |>
    unlist() |>
    unique() |>
    na.omit() |>
    tolower()

  if(any(!chk_mgl %in% c('', 'mg/l'))){
    stop('Concentration not as mg/l')
  }

  out <- dat |>
    dplyr::select(-dplyr::matches('2$')) |>
    dplyr::rename_at(dplyr::vars(dplyr::matches('1$')), ~ gsub('1$', '', .x))

  return(out)

}
