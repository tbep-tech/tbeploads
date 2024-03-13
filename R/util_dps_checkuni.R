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
#' @importFrom dplyr matches rename_at select vars |>
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
    select(
      Year,
      Month,
      outfall = Outfall.ID,
      flow_mgd = matches('^Average.Daily.Flow'),
      tn_mgl = matches('^Total.N'),
      tp_mgl = matches('^Total.P'),
      tss_mgl = matches('^TSS'),
      bod_mgl = matches('^BOD')
    )

  # check mgl
  chk_mgl <- dat |>
    select(matches('2$')) |>
    unlist() |>
    unique() |>
    na.omit() |>
    tolower()

  if(any(!chk_mgl %in% c('', 'mg/l'))){
    stop('Concentration not as mg/l')
  }

  out <- dat |>
    select(-matches('2$')) |>
    rename_at(vars(matches('1$')), ~ gsub('1$', '', .x))

  return(out)

}
