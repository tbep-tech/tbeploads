#' Calculate non-point source (NPS) loads for gaged basins
#'
#' @inheritParams util_nps_getwq
#' @param lakemanpth character, path to the file containing the Lake Manatee flow data
#' @param tampabypth character, path to the file containing the Tampa Bypass flow data
#' @param bellshlpth character, path to the file containing the Bell shoals data
#' @param allflo data frame of flow data, if already available from \code{\link{util_nps_getflow}}, otherwise NULL and the function will retrieve the data
#' @param allwq data frame of water quality data, if already available from \code{\link{util_nps_getwq}}, otherwise NULL and the function will retrieve the data.
#' @param usgsflow data frame of USGS flow data, if already available from \code{\link{util_nps_getusgsflow}}, otherwise NULL and the function will retrieve the data. Default is NULL. Does not apply if \code{allflo} is provided.
#'
#' @export
#'
#' @details The function uses \code{\link{util_nps_getflow}} to retrieve flow data and \code{\link{util_nps_getwq}} to retrieve water quality data. It then combines these datasets and calculates loads for TN, TP, TSS, BOD, and hydrologic load.  See the help files for each function for more details.
#'
#' Required external data inputs are Lake Manatee, Tampa Bypass, and Alafia River Bell Shoals flow data.  These are not available from the USGS API and must be obtained from the contacts listed in \code{\link{util_nps_getextflow}}.  USGS flow data are for stations 02299950, 02300042, 02300500, 02300700, 02301000, 02301300, 02301500, 02301750, 02303000, 02303330, 02304500, 02306647, 02307000, 02307359, and 02307498.  The USGS flow data are from the NWIS database as returned by \code{\link[dataRetrieval]{read_waterdata_daily}} using \code{\link{util_nps_getusgsflow}}. A preprocessed USGS flow data frame can be provided using the `usgsflow` argument to avoid re-downloading the data.  All inputs for flow can be superseded by providing a complete flow data frame using the `allflo` argument.
#'
#' Water Quality data are obtained from the FDEP WIN database API, tbeptools, or local files as described in \code{\link{util_nps_getwq}}. Chosen stations are ER2 and UM2 for Manatee County and station 06-06 for Pinellas County. Environmental Protection Commission (EPC) of Hillsborough County stations retained are 105, 113, 114, 132, 141, 138, 142, and 147. Manatee or Pinellas County data can be imported from local files using the \code{mancopth} and \code{pincopth} arguments, respectively.  If these are not provided, the function will attempt to retrieve data from the FDEP WIN database using \code{read_importwqwin} from tbeptools.  The EPC data are retrieved using \code{read_importepc} from tbeptools.  All inputs for water quality can be superseded by providing a complete water quality data frame using the `allwq` argument.
#'
#' The function assumes that the water quality data are in mg/L and flow data are in cfs.  Missing water quality data are filled with previous five year averages for the end months, then linearly interpolated using \code{\link{util_nps_fillmiswq}}.
#'
#' @return A data frame with columns for basin, year, month, TN in mg/L, TP in mg/L, TSS in mg/L, BOD in mg/L, flow in liters/month, hydrologic load in m3/month, TN load in kg/month, TP load in kg/month, TSS load in kg/month, and BOD load in kg/month.
#'
#' @examples
#' data(allwq)
#' data(allflo)
#'
#' nps_gaged <- anlz_nps_gaged(
#'   yrrng = c('2021-01-01', '2023-12-31'), 
#'   allflo = allflo,
#'   allwq = allwq
#' )
#'
#' head(nps_gaged)
anlz_nps_gaged <- function(yrrng = c('2021-01-01', '2023-12-31'), mancopth = NULL, pincopth = NULL, 
  lakemanpth = NULL, tampabypth = NULL, bellshlpth = NULL, allflo = NULL, allwq = NULL, usgsflow = NULL, verbose = TRUE){

  # get flow data
  if(is.null(allflo)){
    if(verbose)
      cat('Retrieving flow data...\n')
    floyrrng <- lubridate::year(as.Date(yrrng))
    allflo <- util_nps_getflow(lakemanpth, tampabypth, bellshlpth, yrrng = floyrrng, 
      usgsflow = usgsflow, verbose = verbose)
  }

  # get wq data
  if(is.null(allwq)){
    if(verbose)
      cat('Retrieving water quality data...\n')
    allwq <- util_nps_getwq(yrrng = yrrng, mancopth = mancopth, pincopth = pincopth, verbose = FALSE)
  }

  # fill missing, combine with flow, fill miss
  alldat <- util_nps_fillmiswq(allwq, yrrng = yrrng) |>
    dplyr::full_join(allflo, by = c("basin", "yr", "mo")) |>
    dplyr::filter(basin %in% c("02300500", "02300700", "02301500",
                               "02304500", "02307000",
                               "LMANATEE")) # several were removed here following review by RP 2/18/26 to get our estimates to match

  if(verbose)
    cat('Estimating gaged NPS loads...\n')
  
  # get gaged loads
  out <- alldat |>
    dplyr::mutate(
      flow = flow_cfs * 60 * 60 * 24 * (365 / 12) * 28.32,
      h2oload = flow * 0.001,
      tnload = tn_mgl * flow * 0.001 * 0.001,
      tpload = tp_mgl * flow * 0.001 * 0.001,
      tssload = tss_mgl * flow * 0.001 * 0.001,
      bodload = bod_mgl * flow * 0.001 * 0.001
    ) |>
    dplyr::select(-flow_cfs)

  return(out)

}
