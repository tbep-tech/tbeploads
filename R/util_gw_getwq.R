#' Get groundwater quality concentrations for Floridan aquifer segments
#'
#' @param sta_ids character vector of SWFWMD station IDs to query. When
#'   \code{NULL} (default), uses stations 18340 (CR 581 North Fldn) and 18965
#'   (SR 52 and CR 581 Deep), the two Pasco County Floridan aquifer monitoring
#'   wells used in the 2022-2024 Tampa Bay groundwater loading analysis.
#' @param yrrng integer vector of length 2 specifying the start and end year
#'   for computing concentration means, e.g. \code{c(2020, 2024)}. When
#'   \code{NULL} (default), all available observations are used.
#' @param verbose logical, if \code{TRUE} (default) a progress message is
#'   printed.
#'
#' @details
#' Retrieves TN and TP concentrations (mg/L) from the
#' \href{https://dev.api.wateratlas.org}{Water Atlas API}
#' (\code{GET /api/samplingdata/stream}) for Upper Floridan Aquifer monitoring
#' stations and computes grand-mean concentrations per station. Station means
#' are then mapped to bay segments:
#'
#' \itemize{
#'   \item \strong{OTB (segment 1):} mean of \code{sta_ids[1]} only (default:
#'     CR 581 North Fldn, station 18340).
#'   \item \strong{HB (segment 2):} arithmetic mean of the per-station means
#'     across all \code{sta_ids} (default: mean of stations 18340 and 18965,
#'     SR 52 and CR 581 Deep).
#'   \item \strong{Segments 3-7:} fixed constants carried forward from
#'     \code{gwupdate95-98_final.xls} (the original 1995-1998 SWFWMD monitoring
#'     analysis). These values were used unchanged in every loading script from
#'     2012 through 2021 and are not updated from the API.
#' }
#'
#' \strong{History:} Through the 2021 loading cycle, all seven segments used
#' hardcoded Floridan concentrations sourced from the 1995-1998 spreadsheet
#' (TN: 0.010-0.025 mg/L, TP: 0.097-0.137 mg/L). For the 2022-2024 update,
#' new SWFWMD well data showed substantially higher TN in the Pasco County
#' Floridan aquifer, so segments 1 and 2 were revised using stations 18340 and
#' 18965. Segments 3-7 retained the original values.
#'
#' TN is taken from the \code{TN_mgl} parameter and TP from \code{TP_mgl} in
#' the Water Atlas API response.
#'
#' @return A data frame with one row per bay segment (1-7) and columns:
#' \itemize{
#'   \item \code{bay_seg}: integer, bay segment number
#'   \item \code{tn_mgl}: numeric, mean total nitrogen concentration (mg/L)
#'   \item \code{tp_mgl}: numeric, mean total phosphorus concentration (mg/L)
#' }
#'
#' @export
#'
#' @importFrom httr GET status_code content
#' @importFrom jsonlite fromJSON
#'
#' @examples
#' \dontrun{
#' # default stations, all available data
#' conc <- util_gw_getwq()
#'
#' # restrict to a specific period
#' conc <- util_gw_getwq(yrrng = c(2020, 2024))
#' }
util_gw_getwq <- function(sta_ids = NULL, yrrng = NULL, verbose = TRUE) {

  if (is.null(sta_ids))
    sta_ids <- c("18340", "18965")

  base_url <- "https://dev.api.wateratlas.org/api/samplingdata/stream"

  if (verbose)
    cat("Retrieving groundwater quality from Water Atlas API (stations:",
        paste(sta_ids, collapse = ", "), ")...\n")

  # Fixed historical Floridan concentrations for segments 3-7 (mg/L).
  # Source: SWFWMD monitoring data from 1999-2003 used in the original
  # Tampa Bay groundwater loading model. Not updated from the API.
  fixed <- data.frame(
    bay_seg = 3L:7L,
    tn_mgl  = c(0.025, 0.025, 0.022, 0.025, 0.025),
    tp_mgl  = c(0.137, 0.137, 0.118, 0.125, 0.114)
  )

  # Query API once per station and compute per-station grand means
  sta_means <- lapply(sta_ids, function(sid) {

    query <- list(stationIds = sid)
    if (!is.null(yrrng)) {
      query$startDate <- paste0(yrrng[1], "-01-01")
      query$endDate   <- paste0(yrrng[2], "-12-31")
    }

    resp <- httr::GET(base_url, query = query)

    if (httr::status_code(resp) != 200)
      stop("Water Atlas API request failed for station ", sid,
           " (HTTP ", httr::status_code(resp), ")")

    txt   <- httr::content(resp, as = "text", encoding = "UTF-8")
    lines <- strsplit(txt, "\n")[[1]]
    lines <- trimws(lines[nzchar(trimws(lines))])

    if (length(lines) == 0)
      stop("No data returned from Water Atlas API for station ", sid)

    recs <- lapply(lines, jsonlite::fromJSON)
    recs <- Filter(function(r) isTRUE(r$parameter %in% c("TN_mgl", "TP_mgl")), recs)

    if (length(recs) == 0)
      stop("No TN or TP data found for station ", sid)

    dat <- do.call(rbind, lapply(recs, function(r) {
      data.frame(parameter = r$parameter, value = as.numeric(r$resultValue),
                 stringsAsFactors = FALSE)
    }))

    agg <- aggregate(value ~ parameter, data = dat,
                     FUN = function(x) mean(x, na.rm = TRUE))

    data.frame(
      sid    = sid,
      tn_mgl = agg$value[agg$parameter == "TN_mgl"],
      tp_mgl = agg$value[agg$parameter == "TP_mgl"]
    )
  })

  sta_means <- do.call(rbind, sta_means)

  # Seg 1 (OTB): first station only
  # Seg 2 (HB):  arithmetic mean across all stations
  active <- data.frame(
    bay_seg = 1L:2L,
    tn_mgl  = c(sta_means$tn_mgl[1],       mean(sta_means$tn_mgl)),
    tp_mgl  = c(sta_means$tp_mgl[1],       mean(sta_means$tp_mgl))
  )

  out <- rbind(active, fixed)
  out[order(out$bay_seg), ]

}
