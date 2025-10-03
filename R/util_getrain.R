#' Get rainfall data at NOAA NCDC sites for atmospheric deposition and non-point source ungaged calculations
#'
#' Get rainfall data at NOAA NCDC sites for atmospheric deposition and non-point source ungaged calculations
#'
#' @param yrs numeric vector for the years of data to retrieve
#' @param station numeric vector of station numbers to retrieve, see details
#' @param noaa_key character for the NOAA API key
#' @param ntry numeric for the number of times to try to download the data
#' @param quiet logical to print progress in the console
#'
#' @details This function is used to retrieve a long-term record of rainfall for estimating AD and NPS ungaged loads.  It is used to create an input data file for load calculations and it is not used directly by any other functions due to download time.  A NOAA API key is required to use the function.
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
#' @seealso \code{\link{rain}}
#'
#' @examples
#' \dontrun{
#' noaa_key <- Sys.getenv('NOAA_KEY')
#' util_getrain(2021, 228, noaa_key)
#' }
util_getrain <- function(yrs, station = NULL, noaa_key, ntry = 5, quiet = FALSE){

  if(is.null(station))
    station <- c(228, 478, 520, 940, 945,
                 1046, 1163, 1632, 1641, 2806,
                 3153, 3986, 4707, 5973, 6065,
                 6880, 7205, 7851, 7886, 8788,
                 8824, 9176, 9401)
  
  stationid <- dplyr::case_when(
    station == 2806 ~ 'GHCND:USW00092806',
    station == 8788 ~ 'GHCND:USW00012842',
    TRUE ~ paste0('GHCND:USC0008', sprintf('%04d', station))
  )

  # empty data frame
  empt <- data.frame(
          station = character(0),
          date = character(0),
          Year = numeric(0),
          Month = numeric(0),
          Day = numeric(0),
          rainfall = numeric(0)
        )
  
  stayr <- tidyr::crossing(yrs, stationid) |>
    dplyr::mutate(data = NA)
  
  for(i in 1:nrow(stayr)){

    sta <- stayr$stationid[i]
    yr <- stayr$yrs[i]

    if(!quiet)
      cat(yr, sta, i, 'of', nrow(stayr), '\n')

    startdate <- paste0(yr, '-01-01')
    enddate <- paste0(yr, '-12-31')
    
    # Build the API request URL
    base_url <- "https://www.ncei.noaa.gov/cdo-web/api/v2/data"
    query_params <- list(
      datasetid = 'GHCND',
      stationid = sta,
      datatypeid = 'PRCP',
      startdate = startdate,
      enddate = enddate,
      limit = 1000,  # Increased from 400 to get more data per request
      units = 'metric'
    )
    
    # Make the API request
    dat <- try({
      response <- httr::GET(
        url = base_url,
        query = query_params,
        httr::add_headers(token = noaa_key)
      )
      
      # Check if request was successful
      if(httr::status_code(response) != 200) {
        stop("API request failed with status code: ", httr::status_code(response))
      }
      
      # Parse the JSON response
      content <- httr::content(response, as = "text", encoding = "UTF-8")
      parsed_data <- jsonlite::fromJSON(content)
      
      # Return the results data frame
      if(!length(parsed_data$results) == 0) {
        parsed_data$results
      } else {
        empt
      }
      
    }, silent = TRUE)

    tryi <- 0
    while(inherits(dat, 'try-error') & tryi < ntry) {

      if(!quiet)
        cat('Retrying...\n')

      dat <- try({
        response <- httr::GET(
          url = base_url,
          query = query_params,
          httr::add_headers(token = noaa_key)
        )
        
        if(httr::status_code(response) != 200) {
          stop("API request failed with status code: ", httr::status_code(response))
        }
        
        content <- httr::content(response, as = "text", encoding = "UTF-8")
        parsed_data <- jsonlite::fromJSON(content)

        if(!length(parsed_data$results) == 0) {
          parsed_data$results
        } else {
          empt
        }
        
      }, silent = TRUE)
      
      tryi <- tryi + 1
    }

    if(tryi == ntry){
      if(!quiet) cat('Failed...\n')
      next()
    }
    
    stayr$data[[i]] <- list(dat)
  }

  out <- stayr |>
    tidyr::unnest('data')

  # Return empty data frame with expected structure if no data
  if(all(unlist(lapply(out$data, nrow)) == 0))
    return(empt)

  # station and stationid crosswalk
  stations <- tibble::tibble(
    station = station,
    stationid = stationid
  )

  out <- out |>
    tidyr::unnest('data') |>
    dplyr::select(-station) |>
    dplyr::mutate(
      date = lubridate::date(date),
      Year = yrs,
      Month = lubridate::month(date),
      Day = lubridate::day(date),
      rainfall = round(value / 25.4, 2)  # Convert from mm to inches
    ) |>
    dplyr::left_join(stations, by = 'stationid') |>
    dplyr::select(station, date, Year, Month, Day, rainfall) |>
    dplyr::arrange(station, date)

  return(out)
}