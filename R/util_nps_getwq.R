#' Get water quality data for NPS gaged flows
#'
#' @param yrrng A vector of two dates in 'YYYY-MM-DD' format, specifying the date range to retrieve flow data. Default is from '2021-01-01' to '2023-12-31'.
#' @param verbose logical indicating whether to print verbose output
#'
#' @importFrom tbeptools read_importepc
#'
#' @returns A data frame of water quality data for Manatee, Pinellas, and Hillsborough County
#'
#' @details Manatee and Pinellas County data is retrieved from the FDEP WIN database using \code{\link[tbeptools]{read_importwqwin}}.  Hillsborough County data is retrieved using \code{\link[tbeptools]{read_importwq}}.
#' @export
#'
#' @examples
#' \dontrun{
#' wqdat <- util_nps_getwq(c('2021-01-01', '2023-12-31'))
#' }
util_nps_getwq <- function(yrrng = c('2021-01-01', '2023-12-31'), verbose = TRUE){

  if(verbose)
    cat('Retrieving Manatee County data...\n')

  # manatee
  mancoraw <- tbeptools::read_importwqwin(yrrng[1], yrrng[2], '21FLMANA', verbose = verbose)

  if(verbose)
    cat('Retreiving Pinellas County data...\n')

  # pinellas
  pincoraw <- tbeptools::read_importwqwin(yrrng[1], yrrng[2], '21FLPDEM', verbose = verbose)

  # combine manatee and pinellas
  codat <- dplyr::bind_rows(mancoraw, pincoraw) |>
    dplyr::filter(depAnalytePrimaryName %in% c("Nitrate-Nitrite (N)", "Nitrogen- Total Kjeldahl", "Phosphorus- Total", "Residues- Nonfilterable (TSS)")) |>
    dplyr::filter(monitoringLocId %in% c('ER2', 'UM2', '06-06'))

  # make sure units are mg/L
  stopifnot(unique(codat$depResultUnit) == "mg/L")

  # process remaining manco, pinco
  codat <- codat |>
    dplyr::select(station = monitoringLocId, activityStartDate, depAnalytePrimaryName, depResultValue) |>
    tidyr::pivot_wider(names_from = depAnalytePrimaryName, values_from = depResultValue, values_fn = function(x) mean(x, na.rm = T)) |>
    dplyr::rename(
      nox_mgl = "Nitrate-Nitrite (N)",
      tkn_mgl = "Nitrogen- Total Kjeldahl",
      tp_mgl = "Phosphorus- Total",
      tss_mgl = "Residues- Nonfilterable (TSS)"
    ) |>
    dplyr::mutate(
      date = as.Date(lubridate::mdy_hms(activityStartDate)),
      tn_mgl = tkn_mgl + nox_mgl
    ) |>
    dplyr::select(station, date, tn_mgl, tp_mgl, tss_mgl) |>
    dplyr::arrange(station, date)

  if(verbose)
    cat('Retrieving Hillsborough County data...\n')

  tmpfl <- tempfile(fileext = '.xlsx')
  hilcoraw <- suppressMessages(tbeptools::read_importepc(tmpfl, download_latest = TRUE))
  unlink(tmpfl)

  hilco <- hilcoraw |>
    dplyr::mutate(
      station = as.character(StationNumber),
      tn_mgl = suppressWarnings(as.numeric(`Total_Nitrogen`)),
      tp_mgl = suppressWarnings(as.numeric(`Total_Phosphorus`)),
      tss_mgl = suppressWarnings(as.numeric(`Total_Suspended_Solids`)),
      bod_mgl = suppressWarnings(as.numeric(`BOD`)),
      date = lubridate::date(SampleTime),
      yr = lubridate::year(SampleTime),
      mo = lubridate::month(SampleTime)
    ) |>
    dplyr::filter(as.Date(SampleTime) >= as.Date(yrrng[1]) &
                  as.Date(SampleTime) <= as.Date(yrrng[2])) |>
    dplyr::filter(station %in% c('105', '113', '114', '132', '141', '138', '142', '147')) %>%
    dplyr::select(station, date, tn_mgl, tp_mgl, tss_mgl, bod_mgl)

  # combine all wq
  out <- dplyr::bind_rows(hilco, codat) %>%
    dplyr::mutate(
      basin = dplyr::case_when(
        station == "06-06" ~ "LTARPON",
        station == "105" ~ "02304500",
        station == "113" ~ "02300500",
        station == "114" ~ "02301500",
        station == "132" ~ "02300700",
        station == "141" ~ "02307000",
        station == "138" ~ "02301750",
        station == "142" ~ "02306647",
        station == "147" ~ "TBYPASS",
        station == "ER2" ~ "EVERSRES",
        station == "UM2" ~ "LMANATEE",
        TRUE ~ NA_character_
      ),
      yr = lubridate::year(date),
      mo = lubridate::month(date)
    ) |>
    dplyr::select(basin, yr, mo, tn_mgl, tp_mgl, tss_mgl, bod_mgl)

  return(out)

}
