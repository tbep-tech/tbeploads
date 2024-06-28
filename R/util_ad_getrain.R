#' Get rainfall data for a given year at NOAA NCDC sites
#'
#' Get rainfall data for a given year at NOAA NCDC sites
#'
#' @param yr numeric for the year of data to retrieve
#' @param station numeric vector of station numbers to retrieve, see details
#' @param noaa_key character for the NOAA API key
#' @param quiet logical to print progress in the console
#'
#' @details This function is used to retrieve a long-term record of rainfall for estimating AD loads.  It is used to create an input data file for load calculations and it is not used directly by any other functions due to download time.  A NOAA API key is required to use the function.
#'
#' By default, rainfall data is retrieved for the stations 228, 478, 520, 940, 945, 1046, 1163, 1632, 1641, 2806, 3153, 3986, 4707, 5973, 6065, 6880, 7205, 7851, 7886, 8788, 8824, 9176, and 9401.
#'
#' @return a data frame with the following columns:
#' \itemize{
#'
#'  \item{stationid}{character, the station id}
#'  \item{date}{Date, the date of the observation}
#'  \item{Year}{numeric, the year of the observation}
#'  \item{Month}{numeric, the month of the observation}
#'  \item{Day}{numeric, the day of the observation}
#'  \item{rainfall}{numeric, the amount of rainfall in inches}
#'
#'  }
#'
#' @export
#'
#' @examples
#' noaa_key <- Sys.getenv('NOAA_KEY')
#' util_ad_getrain(2021, 228, noaa_key)
util_ad_getrain <- function(yr, station = NULL, noaa_key, quiet = FALSE){

  if(is.null(station))
    station <- c(228, 478, 520, 940, 945,
                 1046, 1163, 1632, 1641, 2806,
                 3153, 3986, 4707, 5973, 6065,
                 6880, 7205, 7851, 7886, 8788,
                 8824, 9176, 9401)
  stationid <- paste0('GHCND:USC0008', sprintf('%04d', station))

  res <- vector("list", length(stationid))
  names(res) <- stationid
  for(i in stationid){

    if(!quiet)
      cat(i, which(i == stationid), 'of', length(stationid), '\n')

    dat <- rnoaa::ncdc(datasetid = 'GHCND', stationid = i,
                       datatypeid = 'PRCP', startdate=paste0(yr, '-01-01'),
                       enddate = paste0(yr, '-12-31'), limit = 400, add_units = TRUE,
                       token = noaa_key)

    res[[i]] <- dat$data

  }

  out <- tibble::enframe(res, name = 'stationid') |>
    tidyr::unnest('value') |>
    dplyr::mutate(
      date = lubridate::date(date),
      Year = lubridate::year(date),
      Month = lubridate::month(date),
      Day = lubridate::day(date),
      rainfall = round(value / 254, 2)
      ) %>%
    dplyr::select(stationid, date, Year, Month, Day, rainfall) |>
    dplyr::arrange(stationid, date)

  return(out)

}
