#' Get water quality data for NPS gaged flows
#'
#' @param yrrng A vector of two dates in 'YYYY-MM-DD' format, specifying the date range to retrieve flow data. Default is from '2021-01-01' to '2023-12-31'.
#' @param mancopth character, path to the Manatee County water quality data file, see details
#' @param pincopth character, path to the Pinellas County water quality data file, see details
#' @param verbose logical indicating whether to print verbose output
#'
#' @importFrom tbeptools read_importepc
#'
#' @returns A data frame of water quality data for Manatee, Pinellas, and Hillsborough County
#'
#' @details If \code{mancopth} or \code{pincopth} are \code{NULL}, Manatee and Pinellas County data are retrieved from the FDEP WIN database using \code{\link[tbeptools]{read_importwqwin}}.  Hillsborough County data is retrieved using \code{\link[tbeptools]{read_importwq}}. If \code{mancopth} or \code{pincopth} are not \code{NULL}, then data are imported from disk using the path specified. Data from the Environmental Protection Commission (EPC) of Hillsborough County are imported using \code{read_importepc} from the tbeptools R package.
#'
#' Local data files can be downloaded from the FDEP WIN database at <https://prodenv.dep.state.fl.us/DearWin/public/wavesSearchFilter?calledBy=menu>, using filters for 21FLMANA and 21FLPDEM for Manatee and Pinellas County, respectively. Activity start and end dates are bounded by the values in \code{yrrng}.  Chosen analytes are Nitrate-Nitrite (N), Nitrogen- Total Kjeldahl, Phosphorus- Total, and Residues- Nonfilterable (TSS). Chosen stations are ER2 and UM2 for Manatee County and station 06-06 for Pinellas County.  EPC stations retained are 105, 113, 114, 132, 141, 138, 142, and 147.
#'
#' The data are filtered to include only the following analytes: "Nitrate-Nitrite (N)", "Nitrogen- Total Kjeldahl", "Phosphorus- Total", and "Residues- Nonfilterable (TSS)". The units for all analytes are assumed to be mg/L.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # import from WIN
#' wqdat <- util_nps_getwq(c('2021-01-01', '2023-12-31'))
#'
#' # use system files
#' mancopth <- system.file('extdata/nps_wq_manco.txt', package = 'tbeploads')
#' pincopth <- system.file('extdata/nps_wq_pinco.txt', package = 'tbeploads')
#' wqdat <- util_nps_getwq(c('2021-01-01', '2023-12-31'), mancopth = mancopth, pincopth = pincopth)
#' }
util_nps_getwq <- function(yrrng = c('2021-01-01', '2023-12-31'), mancopth = NULL, pincopth = NULL, verbose = TRUE){

  if(verbose)
    cat('Retrieving Manatee County data...\n')

  # manatee
  if(is.null(mancopth)){
    mancoraw <- tbeptools::read_importwqwin(yrrng[1], yrrng[2], '21FLMANA', verbose = verbose)
  } else {
    mancoraw <- read.table(mancopth, sep = '|', header = TRUE, stringsAsFactors = FALSE, skip = 8) |>
      dplyr::rename(
        monitoringLocId = Monitoring.Location.ID,
        activityStartDate = Activity.Start.Date.Time,
        depAnalytePrimaryName = DEP.Analyte.Name,
        depResultValue = DEP.Result.Value.Number,
        depResultUnit = DEP.Result.Unit
        )
  }

  if(verbose)
    cat('Retreiving Pinellas County data...\n')

  # pinellas
  if(is.null(pincopth)){
    pincoraw <- tbeptools::read_importwqwin(yrrng[1], yrrng[2], '21FLPDEM', verbose = verbose)
  } else {
    pincoraw <- read.table(pincopth, sep = '|', header = TRUE, stringsAsFactors = FALSE, skip = 8) |>
      dplyr::rename(
        monitoringLocId = Monitoring.Location.ID,
        activityStartDate = Activity.Start.Date.Time,
        depAnalytePrimaryName = DEP.Analyte.Name,
        depResultValue = DEP.Result.Value.Number,
        depResultUnit = DEP.Result.Unit
      )
  }

  # combine manatee and pinellas
  codat <- dplyr::bind_rows(mancoraw, pincoraw) |>
    dplyr::filter(depAnalytePrimaryName %in% c("Nitrate-Nitrite (N)", "Nitrogen- Total Kjeldahl", "Phosphorus- Total", "Residues- Nonfilterable (TSS)")) |>
    dplyr::filter(monitoringLocId %in% c('ER2', 'UM2', '06-06'))

  # make sure units are mg/L
  stopifnot(any(codat$depResultUnit %in% c("", "mg/L")))

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
    dplyr::filter(date >= as.Date(paste0(yrrng[1], '-01-01')) &
                    date <= as.Date(paste0(yrrng[2] , '-12-31'))) |>
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
