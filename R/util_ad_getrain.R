#' Get rainfall data for a given year at NOAA NCDC sites
#'
#' Get rainfall data for a given year at NOAA NCDC sites
#'
#' @param yr numeric vector for the years of data to retrieve
#' @param station numeric vector of station numbers to retrieve, see details
#' @param noaa_key character for the NOAA API key
#' @param ntry numeric for the number of times to try to download the data
#' @param quiet logical to print progress in the console
#'
#' @details This function is used to retrieve a long-term record of rainfall for estimating AD loads.  It is used to create an input data file for load calculations and it is not used directly by any other functions due to download time.  A NOAA API key is required to use the function.
#'
#' By default, rainfall data is retrieved for the following stations:
#'
#' \itemize{
#'    \item \code{228}: ARCADIA
#'    \item \code{478}: BARTOW
#'    \item \code{520}: BAY LAKE
#'    \item \code{940}: BRADENTON EXPERIMENT
#'    \item \code{945}: BRADENTON 5 ESE
#'    \item \code{1046}: BROOKSVILLE CHIN HIL
#'    \item \code{1163}: BUSHNELL 2 E
#'    \item \code{1632}: CLEARWATER
#'    \item \code{1641}: CLERMONT 7 S
#'    \item \code{2806}: ST PETERSBURG WHITTD
#'    \item \code{3153}: FORT GREEN 12 WSW
#'    \item \code{3986}: HILLSBOROUGH RVR SP
#'    \item \code{4707}: LAKE ALFRED EXP STN
#'    \item \code{5973}: MOUNTAIN LAKE
#'    \item \code{6065}: MYAKKA RIVER STATE P
#'    \item \code{6880}: PARRISH
#'    \item \code{7205}: PLANT CITY
#'    \item \code{7851}: ST LEO
#'    \item \code{7886}: ST PETERSBURG WHITTD
#'    \item \code{8788}: TAMPA INTL ARPT
#'    \item \code{8824}: TARPON SPNGS SWG PLT
#'    \item \code{9176}: VENICE
#'    \item \code{9401}: WAUCHULA 2 N
#' }
#'
#' @return a data frame with the following columns:
#'
#' \itemize{
#'  \item \code{station}: numeric, the station id
#'  \item \code{date}: Date, the date of the observation
#'  \item \code{Year}: numeric, the year of the observation
#'  \item \code{Month}: numeric, the month of the observation
#'  \item \code{Day}: numeric, the day of the observation
#'  \item \code{rainfall}: numeric, the amount of rainfall in inches
#'  }
#'
#' @export
#'
#' @seealso \code{\link{ad_rain}}
#'
#' @examples
#' noaa_key <- Sys.getenv('NOAA_KEY')
#' util_ad_getrain(2021, 228, noaa_key)
util_ad_getrain <- function(yrs, station = NULL, noaa_key, ntry = 5, quiet = FALSE){

  if(!requireNamespace('rnoaa', quietly = TRUE))
    stop("Package \"noaa\" needed for this function to work. Please install it.", call. = FALSE)

  if(is.null(station))
    station <- c(228, 478, 520, 940, 945,
                 1046, 1163, 1632, 1641, 2806,
                 3153, 3986, 4707, 5973, 6065,
                 6880, 7205, 7851, 7886, 8788,
                 8824, 9176, 9401)
  stationid <- paste0('GHCND:USC0008', sprintf('%04d', station))

  stayr <- tidyr::crossing(yrs, stationid) |>
    dplyr::mutate(data = NA)
  for(i in 1:nrow(stayr)){

    sta <- stayr$stationid[i]
    yr <- stayr$yrs[i]

    if(!quiet)
      cat(yr, sta, i, 'of', nrow(stayr), '\n')

    dat <- try(rnoaa::ncdc(datasetid = 'GHCND', stationid = sta,
                           datatypeid = 'PRCP', startdate = paste0(yr, '-01-01'),
                           enddate = paste0(yr, '-12-31'), limit = 400, add_units = TRUE,
                           token = noaa_key)$data, silent = TRUE)

    tryi <- 0
    while(inherits(dat, 'try-error') & tryi < ntry) {

      if(!quiet)
        cat('Retrying...\n')

      dat <- try(rnoaa::ncdc(datasetid = 'GHCND', stationid = sta,
                             datatypeid = 'PRCP', startdate = paste0(yr, '-01-01'),
                             enddate = paste0(yr, '-12-31'), limit = 400, add_units = TRUE,
                             token = noaa_key)$data, silent = TRUE)
      tryi <- tryi + 1

    }

    if(tryi == ntry){
      if(!quiet) cat('Failed...\t')
      next()
    }

    stayr$data[[i]] <- list(dat)

  }

  out <- stayr |>
    tidyr::unnest('data') |>
    tidyr::unnest('data') |>
    dplyr::mutate(
      station = as.numeric(gsub('GHCND:USC0008', '', stationid)),
      date = lubridate::date(date),
      Year = yrs,
      Month = lubridate::month(date),
      Day = lubridate::day(date),
      rainfall = round(value / 254, 2)
      ) %>%
    dplyr::select(station, date, Year, Month, Day, rainfall) |>
    dplyr::arrange(station, date)

  return(out)

}
