#' Calculate AD loads and summarize
#'
#' Calculate AD loads and summarize
#'
#' @param ad_rain data frame of daily rainfall data from NOAA NCDC, obtained using \code{\link{util_ad_getrain}}
#' @param vernafl character vector of file path to Verna Wellfield atmospheric concentration data
#' @param summ `r summ_params('summ')`
#' @param summtime `r summ_params('summtime')`
#'
#' @details
#' Loading from atmospheric deposition (AD) for bay segments in the Tampa Bay watershed are calculated using rainfall data and atmospheric concentration data from the Verna Wellfield site.  Rainfall data must be obtained using the \code{\link{util_ad_getrain}} function before calculating loads.  For convenience, daily rainfall data from 2017 to 2023 at sites in the watershed are included with the package in the \code{\link{ad_rain}} object.  The Verna Wellfield data must also be obtained from <https://nadp.slh.wisc.edu/sites/ntn-FL41/> as monthly observations. This file is also included with the package and can be found using \code{\link{system.file}} as in the examples below. Internally, the Verna data are converted to total nitrogen and total phosphorus from ammonium and nitrate concentration data (see \code{\link{util_ad_prepverna}} for additional information).
#'
#' The function first estimates the total hydrologic load for each bay segment using daily estimates of rainfall at NWIS NCDC sites in the watershed.  This is done as a weighted mean of rainfall at the measured sites relative to grid locations in each sub-watershed for the bay segments.  The weights are based on distance of the grid cells from the closest site as inverse distance squared. Total hydrologic load for a bay segment is then estimated by converting inches/month  to m3/month using the segment area. The distance data and bay segment areas are contained in the \code{\link{ad_distance}} file included with the package.
#'
#' The total nitrogen and phosphorus loads are then estimated for each bay segment by multiplying the total hydrologic load by the total nitrogen and phosphorus concentrations in the Verna data.  The loading calculations also include a wet/dry deposition conversion factor to account for differences in loading during the rainy and dry seasons.
#'
#' @return A data frame with nitrogen and phosphorus loads in tons/month, hydrologic load in million m3/month, and segment, year, and month as columns if \code{summ = 'segment'} and \code{summtime = 'month'}. Total load to all segments can be returned if \code{summ = 'all'} and annual summaries can be returned if \code{summtime = 'year'}.  In the latter case, loads are the sum of monthly estimates such that output is tons/yr for TN and TP and as million m3/yr for hydrologic load.
#'
#' @export
#'
#' @seealso \code{\link{util_ad_getrain}}, \code{\link{util_ad_prepverna}}
#'
#' @examples
#' vernafl <- system.file('extdata/verna-raw.csv', package = 'tbeploads')
#' data(ad_rain)
#' anlz_ad(ad_rain, vernafl)
anlz_ad <- function(ad_rain, vernafl, summ = c('segment', 'all'), summtime = c('month', 'year')){

  summ <- match.arg(summ)
  summtime <- match.arg(summtime)

  # prep verna
  verna <- util_ad_prepverna(vernafl)

  # total monthly precip in
  # combine with distance data
  # get weighted mean of tpcp_in using invdist
  # get mean by segment, year, month
  # calc hydro load
  loadrain <- ad_rain |>
    dplyr::summarise(
      tpcp_in = sum(rainfall),
      n = dplyr::n(),
      .by = c('station', 'Year', 'Month')
    ) |>
    dplyr::inner_join(ad_distance, by = c('station' = 'matchsit'), relationship = 'many-to-many') |>
    dplyr::arrange(segment, seg_x, seg_y, Year, Month) |>
    dplyr::summarise(
      tpcp_in = weighted.mean(tpcp_in, w = invdist2, na.rm = T),
      .by = c('segment', 'area', 'seg_x', 'seg_y', 'Year', 'Month')
    ) |>
    dplyr::summarise(
      tpcp_in = mean(tpcp_in, na.rm = T),
      .by = c('segment', 'area', 'Year', 'Month')
    ) |>
    dplyr::mutate(
      h2oload = (tpcp_in * 10000 * area / 39.37), # in/mo to m3/mo
      source = "AD"
    ) |>
    dplyr::select(source, segment, Year, Month, tpcp_in, h2oload)

  # get load by atmospheric conc as sum of wet/dry season
  # converts from mg/L to kg/mo, then tons/mo
  # hydro load as million m3/mo
  lddat <- dplyr::left_join(loadrain, verna, by = c("Year", "Month")) |>
    dplyr::mutate(
      tnwet = TNConc * h2oload / 1000,
      tpwet = TPConc * h2oload / 1000
    ) |>
    dplyr::mutate(
      tndry = dplyr::case_when(
        Month <= 6 ~ tnwet * 1.05,
        Month >= 11 ~ tnwet * 1.05,
        Month >= 7 & Month <= 10 ~ tnwet * 0.66,
        TRUE ~ NA
      ),
      tpdry = dplyr::case_when(
        Month <= 6 ~ tpwet * 1.05,
        Month >= 11 ~ tpwet * 1.05,
        Month >= 7 & Month <= 10 ~ tpwet * 0.66,
        TRUE ~ NA
      ),
      tn_load = (tnwet + tndry) * 0.0011023113,
      tp_load = (tpwet + tpdry) * 0.0011023113,
      hy_load = h2oload / 1000000
    )

  # add bay segment names
  lddat <- lddat |>
    dplyr::mutate(
      bayseg = dplyr::case_when(
        segment == 1 ~ "Old Tampa Bay",
        segment == 2 ~ "Hillsborough Bay",
        segment == 3 ~ "Middle Tampa Bay",
        segment == 4 ~ "Lower Tampa Bay",
        segment == 5 ~ "Boca Ciega Bay",
        segment == 6 ~ "Terra Ceia Bay",
        segment == 7 ~ "Manatee River"
      )
    ) |>
    dplyr::select(Year, Month, source, bayseg, tn_load, tp_load, hy_load)

  # create bcb south
  bcbld <- lddat |>
    dplyr::filter(bayseg == "Boca Ciega Bay") |>
    dplyr::mutate(
      bayseg = "Boca Ciega Bay South",
      tn_load = tn_load * 0.7,
      tp_load = tp_load * 0.7,
      hy_load = hy_load * 0.7
      )

  # add bcbs to lddat
  lddat <- rbind(lddat, bcbld) |>
    dplyr::arrange(bayseg, Year, Month)

  ##
  # output based on summ and summtime

  if(summ == 'segment' & summtime == 'month')
    out <- lddat

  if(summ == 'segment' & summtime == 'year')
    out <- lddat |>
      dplyr::summarise(
        tn_load = sum(tn_load),
        tp_load = sum(tp_load),
        hy_load = sum(hy_load),
        .by = c(Year, source, bayseg)
      )

  if(summ == 'all' & summtime == 'month')
    out <- lddat |>
      dplyr::filter(bayseg != "Boca Ciega Bay") |>
      dplyr::summarise(
        tn_load = sum(tn_load),
        tp_load = sum(tp_load),
        hy_load = sum(hy_load),
        .by = c(Year, Month, source)
      )

  if(summ == 'all' & summtime == 'year')
    out <- lddat |>
      dplyr::filter(bayseg != "Boca Ciega Bay") |>
      dplyr::summarise(
        tn_load = sum(tn_load),
        tp_load = sum(tp_load),
        hy_load = sum(hy_load),
        .by = c(Year, source)
      )

  return(out)

}
