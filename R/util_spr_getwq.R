#' Retrieve spring water quality data from APIs
#'
#' @param yrrng integer vector of length 2, start and end year, e.g. \code{c(2022, 2024)}.
#' @param verbose logical, if \code{TRUE} progress messages are printed.
#'
#' @details
#' Fetches annual mean TN, TP, and TSS concentrations (mg/L) for Lithia,
#' Buckhorn, and Sulphur springs from two external sources.
#'
#' \strong{Lithia and Buckhorn springs} are retrieved from the
#' \href{https://dev.api.wateratlas.org}{Water Atlas API}
#' (\code{GET /api/samplingdata/stream}), using Southwest Florida Water
#' Management District (SWFWMD) monitoring stations 17805 (Lithia Main Spring)
#' and 18276 (Buckhorn Main Spring) from the \code{WIN_21FLSWFD} data source.
#' This is the same underlying dataset as FDEP's Impaired Waters Rule file but
#' accessed directly via API. TSS is not routinely measured at these
#' stations and will typically be \code{NA}, in which case \code{\link{anlz_spr}}
#' substitutes fixed historical values.
#'
#' \strong{Sulphur Spring} data are retrieved via
#' \href{https://tbep-tech.github.io/tbeptools/reference/read_importepc.html}{\code{read_importepc}}, which downloads the Environmental
#' Protection Commission of Hillsborough County (EPC) monitoring spreadsheet.
#' Station 174 corresponds to the Sulphur Spring sampling location and provides
#' monthly TN, TP, and TSS observations.
#'
#' Annual means are computed across all observations within each calendar year.
#' TSS values that are \code{NaN} (i.e., no valid observations in a year) are
#' converted to \code{NA} so that \code{\link{anlz_spr}} can apply the fixed
#' fallback concentrations.
#'
#' @return A data frame with columns \code{spring}, \code{yr}, \code{tn_mgl},
#'   \code{tp_mgl}, and \code{tss_mgl} (one row per spring per year).
#'
#' @export
#'
#' @importFrom httr GET status_code content
#' @importFrom jsonlite fromJSON
#' @importFrom tbeptools read_importepc
#'
#' @seealso \code{\link{anlz_spr}}
#'
#' @examples
#' \dontrun{
#' wqdat <- util_spr_getwq(c(2022, 2024))
#' }
util_spr_getwq <- function(yrrng, verbose = TRUE) {

  start_date <- paste0(yrrng[1], "-01-01")
  end_date   <- paste0(yrrng[2], "-12-31")
  base_url   <- "https://dev.api.wateratlas.org/api/samplingdata/stream"

  # SWFWMD station IDs for the spring-head monitoring locations
  api_stations  <- c(Lithia = "17805", Buckhorn = "18276")
  target_params <- c("TN_mgl", "TP_mgl", "TSS_mgl")

  # ---------------------------------------------------------------------------
  # 1. Lithia and Buckhorn via Water Atlas API
  # ---------------------------------------------------------------------------
  if (verbose)
    cat("Retrieving Lithia and Buckhorn spring water quality from Water Atlas API...\n")

  api_dat <- lapply(names(api_stations), function(spring_name) {

    sid  <- api_stations[[spring_name]]
    resp <- httr::GET(base_url, query = list(
      stationIds = sid,
      startDate  = start_date,
      endDate    = end_date
    ))

    if (httr::status_code(resp) != 200)
      stop("Water Atlas API request failed for station ", sid,
           " (HTTP ", httr::status_code(resp), ")")

    txt   <- httr::content(resp, as = "text", encoding = "UTF-8")
    lines <- strsplit(txt, "\n")[[1]]
    lines <- trimws(lines)
    lines <- lines[nzchar(lines)]

    if (length(lines) == 0)
      return(NULL)

    recs <- lapply(lines, jsonlite::fromJSON)
    recs <- Filter(function(r) isTRUE(r$parameter %in% target_params), recs)

    if (length(recs) == 0)
      return(NULL)

    dat <- dplyr::bind_rows(lapply(recs, function(r) {
      data.frame(
        spring    = spring_name,
        yr        = lubridate::year(as.Date(substr(r$activityStartDate, 1, 10))),
        parameter = r$parameter,
        value     = r$resultValue,
        stringsAsFactors = FALSE
      )
    }))

    dat |>
      dplyr::group_by(spring, yr, parameter) |>
      dplyr::summarise(value = mean(value, na.rm = TRUE), .groups = "drop") |>
      tidyr::pivot_wider(names_from = parameter, values_from = value) |>
      dplyr::rename_with(tolower, dplyr::any_of(c("TN_mgl", "TP_mgl", "TSS_mgl")))
  })

  api_out <- dplyr::bind_rows(api_dat)

  # Ensure all expected columns are present even if a parameter had no records
  for (col in c("tn_mgl", "tp_mgl", "tss_mgl")) {
    if (!col %in% names(api_out))
      api_out[[col]] <- NA_real_
  }

  # ---------------------------------------------------------------------------
  # 2. Sulphur Spring via tbeptools::read_importepc (EPC station 174)
  # ---------------------------------------------------------------------------
  if (verbose)
    cat("Retrieving Sulphur Spring water quality from EPC via tbeptools...\n")

  tmpfl <- tempfile(fileext = ".xlsx")
  on.exit(unlink(tmpfl), add = TRUE)

  epc_raw <- suppressMessages(
    tbeptools::read_importepc(tmpfl, download_latest = TRUE)
  )

  sulphur_out <- epc_raw |>
    dplyr::filter(as.character(StationNumber) == "174") |>
    dplyr::mutate(
      spring  = "Sulphur",
      yr      = lubridate::year(SampleTime),
      tn_mgl  = suppressWarnings(as.numeric(Total_Nitrogen)),
      tp_mgl  = suppressWarnings(as.numeric(Total_Phosphorus)),
      tss_mgl = suppressWarnings(as.numeric(Total_Suspended_Solids))
    ) |>
    dplyr::filter(yr >= yrrng[1], yr <= yrrng[2]) |>
    dplyr::group_by(spring, yr) |>
    dplyr::summarise(
      tn_mgl  = mean(tn_mgl,  na.rm = TRUE),
      tp_mgl  = mean(tp_mgl,  na.rm = TRUE),
      tss_mgl = mean(tss_mgl, na.rm = TRUE),
      .groups = "drop"
    ) |>
    # mean() of all-NA returns NaN; convert to NA so coalesce works downstream
    dplyr::mutate(
      tn_mgl  = ifelse(is.nan(tn_mgl),  NA_real_, tn_mgl),
      tp_mgl  = ifelse(is.nan(tp_mgl),  NA_real_, tp_mgl),
      tss_mgl = ifelse(is.nan(tss_mgl), NA_real_, tss_mgl)
    )

  # ---------------------------------------------------------------------------
  # 3. Combine
  # ---------------------------------------------------------------------------
  out <- dplyr::bind_rows(api_out, sulphur_out) |>
    dplyr::arrange(spring, yr)

  return(out)

}
