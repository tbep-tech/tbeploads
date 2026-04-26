#' Get groundwater quality concentrations for Floridan aquifer segments
#'
#' @param path character string, path to a folder containing one or more water
#'   quality CSV files downloaded from the SWFMD District database (see
#'   Details).
#'
#' @details
#' Reads SWFMD District water quality CSV files for Upper Floridan Aquifer
#' monitoring stations and computes mean TN and TP concentrations (mg/L) per
#' station. Station means are then mapped to bay segments following the
#' methodology in Zarbock et al. (1994) as applied in the 2022-2024 Tampa Bay
#' groundwater loading analysis:
#'
#' \itemize{
#'   \item \strong{OTB (segment 1):} CR 581 North Fldn well (Pasco County,
#'     77 ft depth; SWFMD station 18340).
#'   \item \strong{HB (segment 2):} arithmetic mean of CR 581 North Fldn and
#'     SR 52 and CR 581 Deep (Pasco County, 83 ft depth) stations.
#'   \item \strong{Segments 3-7:} fixed historical concentrations from earlier
#'     monitoring periods (late 1990s to early 2000s). These values are
#'     returned as constants and are not updated from the CSV files.
#' }
#'
#' TN is taken from \code{"Nitrogen- Total (Total)"} and TP from
#' \code{"Phosphorus- Total (Total)"}. All qualifying flags are retained;
#' non-detect values (\code{qualifier = "U"}) are included at the reported
#' instrument value.
#'
#' CSV files must match the format produced by the SWFMD Water Management
#' Information System (WMIS) data download tool, with columns: SID, Station
#' Name, Parameter Name, Sample Date and Time, Timezone, Sample Result,
#' Measuring Unit, Remark, Method Name, Medium, Value Qualifier, Analysis Date
#' and Time, Measuring program Name, Activity Depth, Activity Depth Unit,
#' Sampling Agency.
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
#' @examples
#' \dontrun{
#' conc <- util_gw_getwq("path/to/GW_DistrictWQData")
#' }
util_gw_getwq <- function(path) {

  sta_segs <- list(
    "1"   = "CR 581 North Fldn",
    "2"   = c("CR 581 North Fldn", "SR 52 and CR 581 Deep")
  )

  # Fixed historical Floridan concentrations for segments 3-7 (mg/L).
  # Source: SWFMD monitoring data from 1999-2003 used in the original
  # Tampa Bay groundwater loading model. Not updated from the District files.
  fixed <- data.frame(
    bay_seg = 3L:7L,
    tn_mgl  = c(0.025, 0.025, 0.022, 0.025, 0.025),
    tp_mgl  = c(0.137, 0.137, 0.118, 0.125, 0.114)
  )

  # Read all CSV files in path
  files <- list.files(path, pattern = "\\.csv$", full.names = TRUE,
                      ignore.case = TRUE)
  if (length(files) == 0L)
    stop("No CSV files found in path: ", path)

  raw <- lapply(files, function(f) {
    read.csv(f, check.names = FALSE, stringsAsFactors = FALSE)
  })
  dat <- do.call(rbind, raw)

  col_map <- c("sid", "station", "param", "date", "tz", "result", "unit",
               "remark", "method", "medium", "qualifier", "analysis_date",
               "program", "depth", "depth_unit", "agency")
  if (ncol(dat) != length(col_map))
    stop("Unexpected number of columns in CSV files; expected ", length(col_map),
         ", found ", ncol(dat))
  names(dat) <- col_map

  dat$result <- suppressWarnings(as.numeric(dat$result))

  # Identify which stations are needed
  needed_sta <- unique(unlist(sta_segs, use.names = FALSE))
  wq <- dat[
    dat$param %in% c("Nitrogen- Total (Total)", "Phosphorus- Total (Total)") &
      dat$station %in% needed_sta, ,
    drop = FALSE
  ]

  missing_sta <- setdiff(needed_sta, unique(wq$station))
  if (length(missing_sta) > 0L)
    stop("Required station(s) not found in CSV files: ",
         paste(missing_sta, collapse = ", "))

  # Grand mean per station and parameter
  sta_means <- aggregate(result ~ station + param, data = wq,
                         FUN = function(x) mean(x, na.rm = TRUE))

  get_mean <- function(stations, param_name) {
    vals <- sta_means$result[
      sta_means$station %in% stations & sta_means$param == param_name
    ]
    mean(vals, na.rm = TRUE)
  }

  active <- data.frame(
    bay_seg = 1L:2L,
    tn_mgl  = vapply(sta_segs, get_mean, numeric(1L),
                     param_name = "Nitrogen- Total (Total)"),
    tp_mgl  = vapply(sta_segs, get_mean, numeric(1L),
                     param_name = "Phosphorus- Total (Total)"),
    row.names = NULL
  )

  out <- rbind(active, fixed)
  out[order(out$bay_seg), ]

}
