#' Get flow data from USGS for NPS calculations
#'
#' @param site A character vector of USGS site numbers. If NULL, defaults to a predefined set of sites. Default is NULL, see details.
#' @param yrrng A vector of two dates in 'YYYY-MM-DD' format, specifying the date range to retrieve flow data. Default is from '2021-01-01' to '2023-12-31'.
#'
#' @returns A data frame of daily flow values in cfs for fifteen stations
#' @export
#'
#' @details Stations are from the USGS NWIS database and include 02299950, 02300042, 02300500, 02300700, 02301000, 02301300, 02301500, 02301750, 02303000, 02303330, 02304500, 02306647, 02307000, 02307359, and 02307498.
#'
#' @examples
#' usgsflo <- util_nps_getusgsflow()
util_nps_getusgsflow <- function(site = NULL, yrrng = c('2021-01-01', '2023-12-31')){

  if(is.null(site))
    usgsid <- c("02299950", "02300042", "02300500", "02300700", "02301000",
                    "02301300", "02301500", "02301750", "02303000", "02303330",
                    "02304500", "02306647", "02307000", "02307359", "02307498")

  fl_results <- vector("list", length(usgsid))
  names(fl_results) <- usgsid

  for(sid in usgsid) {

    dat <- suppressMessages(dataRetrieval::readNWISdv(sid, "00060", yrrng[1], yrrng[2])) %>%
      dataRetrieval::renameNWISColumns()

    fl_results[[sid]] <- dat

  }

  out <- tibble::enframe(fl_results) |>
    tidyr::unnest('value') |>
    dplyr::mutate(date = as.Date(Date), flow_cfs = Flow)  |>
    dplyr::select(site_no, date, flow_cfs)

  return(out)

}
