#' Calculate non-point source (NPS) loads for Tampa Bay
#'
#' @param yrrng A vector of two dates in 'YYYY-MM-DD' format, specifying the date range to retrieve flow data. Default is from '2021-01-01' to '2023-12-31'.
#' @param tbbase data frame containing polygon areas for the combined data layer of bay segment, basin, jurisdiction, land use data, and soils, see details
#' @param rain data frame of rainfall data, see details
#' @param mancopth character, path to the Manatee County water quality data file, see details
#' @param pincopth character, path to the Pinellas County water quality data file, see details
#' @param lakemanpth character, path to the file containing the Lake Manatee flow data, see details
#' @param tampabypth character, path to the file containing the Tampa Bypass flow data, see details
#' @param bellshlpth character, path to the file containing the Bell shoals data, see details
#' @param vernafl character vector of file path to Verna Wellfield atmospheric concentration data
#' @param allflo data frame of flow data, if already available from \code{\link{util_nps_getflow}}, otherwise NULL and the function will retrieve the data
#' @param allwq data frame of water quality data, if already available from \code{\link{util_nps_getwq}}, otherwise NULL and the function will retrieve the data.
#' @param usgsflow data frame of USGS flow data, if already available from \code{\link{util_nps_getusgsflow}}, otherwise NULL and the function will retrieve the data. Default is NULL.
#' @param summ `r summ_params('summ')`
#' @param summtime `r summ_params('summtime')`
#' @param aslu logical indicating whether to summarize by land use type (ungaged loads only), default is FALSE
#' @param verbose logical indicating whether to print verbose output
#'
#' @returns A data frame of non-point source loads for Tampa Bay, including columns for year, month, bay segment, basin, and loads for total nitrogen (TN), total phosphorus (TP), total suspended solids (TSS), biochemical oxygen demand (BOD), and hydrology using default values for the \code{summ} and \code{summtime} arguments. TN, TP, TSS, and BOD Loads are tons per month or year depending on the \code{summtime} argument. Hydrologic loads are cubic meters per month or year depending on the \code{summtime} argument.
#'
#' @export
#'
#' @details
#' The function estimates non-point source (NPS) loads for Tampa Bay by combining ungaged and gaged NPS loads. Ungaged loads are estimated using rainfall, flow, event mean concentration, land use, and soils data, while gaged loads are estimated using water quality data and flow data. The function also incorporates atmospheric concentration data from the Verna Wellfield site.
#'
#' `r summ_params('descrip')` Options for \code{summ} are 'basin' to summarize across sub-basins within bay segments, 'segment' to summarize by bay segment, and 'all' to summarize total load. Loads can also be summarized by land use type with the `summ` and `summtime` argumets by setting `aslu = TRUE`.  Land use type summaries only apply to ungaged load estimates.  Options for \code{summtime} are 'month' to summarize by month and 'year' to summarize by year.  The default is to summarize by basin and month.
#' 
#' The following functions are used internally and are provided here for reference on the components used in the calculations:
#'
#' \itemize{
#'  \item \code{\link{anlz_nps_ungaged}}: Estimates ungaged NPS loads.
#'  \item \code{\link{anlz_nps_gaged}}: Estimates gaged NPS loads.
#'  \item \code{\link{util_nps_fillmiswq}}: Fills missing water quality data with linear interpolation.
#'  \item \code{\link{util_nps_getflow}}: Gets flow estimates for NPS gaged and ungaged calculations.
#'  \item \code{\link{util_nps_getusgsflow}}: Gets USGS flow data for NPS calculations, used in \code{\link{util_nps_getflow}}.
#'  \item \code{\link{util_nps_getextflow}}: Gets external flow data (Lake Manatee, Tampa Bypass, and Bell Shoals), used in \code{\link{util_nps_getflow}}.
#'  \item \code{\link{util_nps_getwq}}: Gets water quality data for NPS gaged calculations.
#'  \item \code{\link{util_nps_preprain}}: Prepares and formats rainfall data.
#'  \item \code{\link{util_nps_preplog}}: Prepares land use data for logistic regression modeling.
#'  \item \code{\link{util_nps_segment}}: Assigns basins to bay segments.
#'  \item \code{\link{util_prepverna}}: Prepares and fills missing data with five-year means for the Verna Wellfield site data.
#' }
#'
#' @examples
#' data(tbbase)
#' data(rain)
#' data(allwq)
#' data(allflo)
#' vernafl <- system.file('extdata/verna-raw.csv', package = 'tbeploads')
#'
#' nps <- anlz_nps(
#'   yrrng = c('2021-01-01', '2023-12-31'), 
#'   tbbase = tbbase, 
#'   rain = rain, 
#'   allwq = allwq,
#'   allflo = allflo,  
#'   vernafl = vernafl, 
#' )
#' 
#' head(nps)
anlz_nps <- function(yrrng = c('2021-01-01', '2023-12-31'), tbbase, rain, mancopth = NULL,
                     pincopth = NULL, lakemanpth = NULL, tampabypth = NULL, bellshlpth = NULL, 
                     vernafl, allflo = NULL, allwq = NULL, usgsflow = NULL, 
                     summ = c('basin', 'segment', 'all'), summtime = c('month', 'year'), 
                     aslu = FALSE, verbose = TRUE){

  summ <- match.arg(summ)
  summtime <- match.arg(summtime)

  if(is.null(allflo)){
  
    if(verbose)
      cat('Retrieving flow data...\n')
    allflo <- util_nps_getflow(lakemanpth, tampabypth, bellshlpth, 
      yrrng = lubridate::year(as.Date(yrrng)), usgsflow = usgsflow, verbose = verbose)
    
  }

  if(verbose)
    cat('Estimating ungaged NPS loads...\n')
  nps_ungaged <- anlz_nps_ungaged(yrrng = yrrng,
                                  tbbase, rain, lakemanpth, tampabypth, bellshlpth,
                                  allflo = allflo,
                                  verbose = FALSE)

  if(!aslu){

    if(verbose)
      cat('Estimating gaged NPS loads...\n')

    nps_gaged <- anlz_nps_gaged(yrrng, mancopth, pincopth, lakemanpth, tampabypth,
                                bellshlpth, allflo = allflo, allwq = allwq, 
                                verbose = FALSE) |>
      dplyr::select(
        basin,
        yr,
        mo,
        oh2oload = h2oload,
        otnload = tnload,
        otpload = tpload,
        otssload = tssload,
        obodload = bodload
      )
  }

  if(verbose)
    cat('Combining atmospheric data with ungaged NPS loads...\n')
  
  # get verna data, fill missing w/ five-year avg
  verna <- util_prepverna(vernafl, typ = 'NPS') |>
    dplyr::rename(
      yr = Year,
      mo = Month,
      tn_ppt = TNConc,
      tp_ppt = TPConc
    )

  nps2 <- nps_ungaged |>
    dplyr::left_join(verna, by = c("yr", "mo")) |>
    dplyr::mutate(
      tnload_a = tnload,
      tnload_b = tnload,
      tpload_a = tpload,
      tpload_b = tpload,
      h2oload2 = h2oload * 1000 # m3 to liters
    ) |>
    dplyr::mutate(
      tnload_a = dplyr::case_when(
        clucsid %in% c(18, 20) ~ 0,
        TRUE ~ tnload_a
      ),
      tnload_b = dplyr::case_when(
        clucsid %in% c(18, 20) ~ h2oload2 * tn_ppt * 3.04 * 0.001 * 0.001,
        TRUE ~ tnload_b
      ),
      tpload_a = dplyr::case_when(
        clucsid %in% c(18, 20) ~ 0,
        TRUE ~ tpload_a
      ),
      tpload_b = dplyr::case_when(
        clucsid %in% c(18, 20) ~ h2oload2 * tp_ppt * 3.04 * 0.001 * 0.001,
        TRUE ~ tpload_b
      )
    ) 
   
  # ungaged lu summary
  if(aslu){

    if(verbose)
      cat('Summarizing ungaged NPS loads by land use...\n')

    out <- util_nps_lusumm(nps2, summ = summ, summtime = summtime)

    return(out)

  }
      
  nps2 <- nps2 |>
    dplyr::group_by(yr, mo, bay_seg, basin) |>
    dplyr::summarise(
      h2oload = sum(h2oload, na.rm=TRUE),
      tnload = sum(tnload, na.rm=TRUE),
      tpload = sum(tpload, na.rm=TRUE),
      tssload = sum(tssload, na.rm=TRUE),
      bodload = sum(bodload, na.rm=TRUE),
      tnload_a = sum(tnload_a, na.rm = TRUE),
      tnload_b = sum(tnload_b, na.rm = TRUE),
      tpload_a = sum(tpload_a, na.rm = TRUE),
      tpload_b = sum(tpload_b, na.rm = TRUE),
      area = sum(area, na.rm=TRUE),
      bas_area = dplyr::first(bas_area),
      .groups = 'drop'
    )

  nps <- nps2 |>
    dplyr::filter(!basin %in% c("02303000", "02303330", "02301000", "02301300")) |> # Remove nested basins
    dplyr::mutate(basin = ifelse(basin == "02299950", "LMANATEE", basin)) |>  # Rename basin
    dplyr::group_by(yr, mo, bay_seg, basin) |>
    dplyr::summarise(
      h2oload = sum(h2oload, na.rm=TRUE),
      tnload = sum(tnload, na.rm=TRUE),
      tpload = sum(tpload, na.rm=TRUE),
      tssload = sum(tssload, na.rm=TRUE),
      bodload = sum(bodload, na.rm=TRUE),
      tnload_a = sum(tnload_a, na.rm = TRUE),
      tnload_b = sum(tnload_b, na.rm = TRUE),
      tpload_a = sum(tpload_a, na.rm = TRUE),
      tpload_b = sum(tpload_b, na.rm = TRUE),
      area = sum(area, na.rm=TRUE),
      bas_area = dplyr::first(bas_area),
      .groups = 'drop'
    )

  estloads <- nps |>
    dplyr::mutate(
      eh2oload = h2oload,
      etnload = tnload,
      etpload = tpload,
      etnloada = tnload_a,
      etploada = tpload_a,
      etnloadb = tnload_b,
      etploadb = tpload_b,
      etssload = tssload,
      ebodload = bodload
    ) |>
    dplyr::select(
      yr, mo, basin, bay_seg, bas_area,
      eh2oload, etnload, etpload, etssload, ebodload,
      etnloada, etploada, etnloadb, etploadb
    )
  
  if(verbose)
    cat('Combining ungaged and gaged NPS loads, estimating final...\n')

  npsfinal <- estloads |>
    dplyr::full_join(nps_gaged, by = c("yr", "mo", "basin")) |>
    dplyr::mutate(
      h2oload = ifelse(is.na(oh2oload), eh2oload, oh2oload),
      tnload = ifelse(is.na(otnload), etnload, otnload),
      tpload = ifelse(is.na(otpload), etpload, otpload),
      tssload = ifelse(is.na(otssload), etssload, otssload),
      bodload = ifelse(is.na(obodload), ebodload, obodload),
      tnload_a = ifelse(is.na(otnload), etnloada, otnload),
      tpload_a = ifelse(is.na(otpload), etploada, otpload),
      tnload_b = ifelse(is.na(otnload), etnloadb, otnload),
      tpload_b = ifelse(is.na(otpload), etploadb, otpload),
      source = "NPS"
    ) |>
    util_nps_segment() |> 
    dplyr::mutate(
      majbasin = dplyr::case_when(
        basin %in% c("LTARPON", "02306647", "02307000", "02307359", "206-1") ~ "Coastal Old Tampa Bay",
        basin %in% c("TBYPASS", "02301750", "206-2", "02300700") ~ "Coastal Hillsborough Bay",
        basin %in% c("02301000", "02301300", "02303000", "02303330") ~ "Error!!!",
        basin %in% c("02301500", "02301695", "204-2") ~ "Alafia River",
        basin %in% c("02304500", "205-2") ~ "Hillsborough River",
        basin %in% c("02300500", "02300530", "203-3") ~ "Little Manatee River",
        basin %in% c("206-3C", "206-3E", "206-3W") ~ "Coastal Middle Tampa Bay",
        basin == "206-4" ~ "Coastal Lower Tampa Bay",
        basin == "206-5" | basin == "207-5" & bay_seg == 55 ~ "Boca Ciega Bay South",
        basin == "207-5" & bay_seg == 5 ~ "Boca Ciega Bay North",
        basin == "206-6" ~ "Terra Ceia Bay",
        basin %in% c("EVERSRES", "LMANATEE", "202-7", "02299950") ~ "Manatee River",
        TRUE ~ NA
      )
    ) |>
    dplyr::select(
      yr, mo, segment, majbasin, bay_seg, basin, bas_area, source,
      h2oload, tnload, tpload, tssload, bodload,
      tnload_a, tpload_a, tnload_b, tpload_b
    )

  npsld <- npsfinal |>
    dplyr::group_by(yr, mo, bay_seg, basin) |>
    dplyr::summarise(
      tn_load = sum(tnload_b, na.rm=TRUE) / 907.2, # kg to tons per month, use b
      tp_load = sum(tpload_b, na.rm=TRUE) / 907.2, # kg to tons per month, use b
      tss_load = sum(tssload, na.rm=TRUE) / 907.2, # kg to tons per month
      bod_load = sum(bodload, na.rm=TRUE) / 907.2, # kg to tons per month
      hy_load = sum(h2oload, na.rm=TRUE), # m3 per month
      bas_area = sum(bas_area, na.rm=TRUE), # hectares
      segment = dplyr::first(segment),
      majbasin = dplyr::first(majbasin),
      source = dplyr::first(source),
      .groups = 'drop'
    ) |>
    dplyr::select(Year = yr, Month = mo, source, segment, basin, tn_load, tp_load, 
      tss_load, bod_load, hy_load) |>     
    dplyr::arrange(segment, basin, Year, Month)

  ##
  # output based on summ and summtime

  ##
  # summarize by selection

  out <- util_summ(npsld, summ = summ, summtime = summtime)

  return(out)

}
