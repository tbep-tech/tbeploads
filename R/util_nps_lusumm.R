#' Summarize non-point source (NPS) ungaged loads by land use
#' 
#' Summarize non-point source (NPS) ungaged loads by land use
#'
#' @param dat Input data frame as an intermediate result from \code{\link{anlz_nps}}
#' @param summ `r summ_params('summ')`
#' @param summtime `r summ_params('summtime')`
#'
#' @details `r summ_params('descrip')`
#'
#' @returns Data frame with summarized loading data based on user-supplied arguments
#'
#' @export
#' @examples
#' dat <- data.frame(
#'   bay_seg = rep(1:2, each = 6),
#'   basin = rep(c("02304500", "02306647"), each = 6),
#'   yr = rep(2021:2022, each = 3, times = 2),
#'   mo = rep(1:3, times = 4),
#'   clucsid = rep(1:3, times = 4),
#'   tnload = c(150, 250, 50, 180, 300, 40, 160, 270, 45, 170, 280, 35),
#'   tpload = c(15, 35, 8, 18, 42, 6, 16, 38, 7, 17, 40, 5),
#'   tssload = c(1200, 3500, 400, 1400, 4000, 350, 1300, 3800, 380, 1350, 3900, 320),
#'   bodload = c(800, 1500, 200, 900, 1800, 180, 850, 1600, 190, 870, 1650, 170),
#'   h2oload = c(50000, 80000, 25000, 55000, 85000, 22000, 52000, 82000, 23000, 53000, 83000, 21000)
#' )
#' 
#' util_nps_lusumm(dat, summ = 'basin', summtime = 'month')
util_nps_lusumm <- function(dat, summ = c('basin', 'segment', 'all'), summtime = c('month', 'year')){
  
  summ <- match.arg(summ)
  summtime <- match.arg(summtime)

  ludescrip <- clucsid |> 
      dplyr::select(clucsid = CLUCSID, lu = DESCRIPTION) |> 
      dplyr::distinct()

  datfrm <- dat |> 
    util_nps_segment() |> 
    dplyr::select(
      Year = yr, 
      Month = mo, 
      segment, 
      basin,
      clucsid,
      tn_load = tnload,
      tp_load = tpload,
      tss_load = tssload,
      bod_load = bodload,
      hy_load = h2oload
    ) |> 
    dplyr::mutate(
      source = "NPS"
    ) |> 
    dplyr::summarize(
      tn_load = sum(tn_load, na.rm=TRUE) / 907.2, # kg to tons per month
      tp_load = sum(tp_load, na.rm=TRUE) / 907.2, # kg to tons per month
      tss_load = sum(tss_load, na.rm=TRUE) / 907.2, # kg to tons per month
      bod_load = sum(bod_load, na.rm=TRUE) / 907.2, # kg to tons per month
      hy_load = sum(hy_load, na.rm=TRUE), # m3 per month
      .by = c(Year, Month, source, segment, basin, clucsid)
    ) |> 
    dplyr::left_join(ludescrip, by = "clucsid") |> 
    dplyr::select(-clucsid) |> 
    dplyr::select(Year, Month, source, segment, basin, lu, dplyr::everything()) |> 
    dplyr::filter(!is.na(lu)) |> 
    dplyr::arrange(segment, basin, lu, Year, Month, source)
  
  if(summtime == 'month'){

    if(summ == 'basin')
      
      out <- datfrm
  
    if(summ == 'segment')
      
      out <- datfrm |>
        dplyr::summarise(dplyr::across(dplyr::contains("load"), ~ sum(., na.rm = TRUE)),
                        .by = c(Year, Month, source, segment, lu)) |> 
        dplyr::arrange(segment, lu, Year, Month, source)

    if(summ == 'all')

      out <- datfrm |>
        dplyr::filter(segment != "Boca Ciega Bay") |>
        dplyr::summarise(dplyr::across(dplyr::contains("load"), ~ sum(., na.rm = TRUE)),
                        .by = c(Year, Month, source, lu)) |> 
        dplyr::arrange(lu, Year, Month, source)

  }

  if(summtime == 'year'){

    if(summ == 'basin')

      out <- datfrm |>
        dplyr::summarise(dplyr::across(dplyr::contains("load"), ~ sum(., na.rm = TRUE)),
                        .by = c(Year, source, segment, basin, lu)) |> 
        dplyr::arrange(segment, basin, lu, Year, source)

    if(summ == 'segment')

      out <- datfrm |>
        dplyr::summarise(dplyr::across(dplyr::contains("load"), ~ sum(., na.rm = TRUE)),
                        .by = c(Year, source, segment, lu)) |> 
        dplyr::arrange(segment, lu, Year, source)

    if(summ == 'all')

      out <- datfrm |>
        dplyr::filter(segment != "Boca Ciega Bay") |>
        dplyr::summarise(dplyr::across(dplyr::contains("load"), ~ sum(., na.rm = TRUE)),
                        .by = c(Year, source, lu)) |> 
        dplyr::arrange(lu, Year, source)

  }

  return(out)
  
}
  