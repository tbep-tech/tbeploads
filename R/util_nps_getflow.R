#' Get flow data from for NPS calculations at gaged sites
#'
#' @param lakemanpth character, path to the file containing the Lake Manatee flow data
#' @param tampabypth character, path to the file containing the Tampa Bypass flow data
#' @param bellshlpth character, path to the file containing the Bell shoals data
#' @param yrrng vector of two integers, the year range for which to retrieve flow data. Default is c(2021, 2023).
#'
#' @returns A data frame of monthly mean flow or fifteen USGS stations and three external flow sites
#' @export
#'
#' @details Missing flow values are linearly interpolated using \code{\link[zoo]{na.approx}}.  The function combines external and USGS API flow data using the `util_nps_getextflow` and `util_nps_getusgsflow` functions.
#'
#' @seealso \code{\link{util_nps_getextflow}}, \code{\link{util_nps_getusgsflow}}
#'
#' @examples
#' lakemanpth <- system.file('extdata/nps_extflow_lakemanatee.xlsx', package = 'tbeploads')
#' tampabypth <- system.file('extdata/nps_extflow_tampabypass.xlsx', package = 'tbeploads')
#' bellshlpth <- system.file('extdata/nps_extflow_bellshoals.xls', package = 'tbeploads')
#' allflo <- util_nps_getflow(lakemanpth, tampabypth, bellshlpth)
util_nps_getflow <- function(lakemanpth, tampabypth, bellshlpth, yrrng = c(2021, 2023)){

  # external files
  lman <- util_nps_getextflow(lakemanpth, 'LMANATEE', yrrng = yrrng)
  s160 <- util_nps_getextflow(tampabypth, 'TBYPASS', yrrng = yrrng)
  blsh <- util_nps_getextflow(bellshlpth, '02301500', yrrng = yrrng)

  # usgs api flow data
  yrrng <- as.Date(c(paste0(yrrng[1], '-01-01'), paste0(yrrng[2], '-12-31')))
  intflo <- util_nps_getusgsflow(yrrng = yrrng)

  # combine all
  new_flow <- intflo |>
    rbind(s160) |>
    rbind(lman) |>
    dplyr::full_join(blsh, by = c("site_no", "date"))  #Add in TBW AR-Bell Shoals withdrawals here

  new_flow_corrected <- new_flow |>
    tidyr::complete(date, tidyr::nesting(site_no), fill = list(flow_cfs = NA)) |> # Fill in missing dates, if any
    dplyr::mutate(flow_cfs = dplyr::case_when(
      site_no == "02301500" ~ flow_cfs-wd_cfs, # Subtract TBW AR-Bell Shoals withdrawals from site 02301500 flows
      TRUE ~ flow_cfs)
    ) |>
    dplyr::mutate(
      basin = dplyr::case_when(
        site_no == "02307498" ~ "LTARPON",
        site_no == "02300042" ~ "EVERSRES",
        TRUE ~ site_no),
      yr = lubridate::year(date),
      mo = lubridate::month(date)
    ) |>
    dplyr::arrange(site_no, date) |>
    dplyr::mutate(flow_cfs = zoo::na.approx(flow_cfs), .by = site_no) |>  # Linear interpolate missing daily values
    dplyr::select(basin, date, yr, mo, flow_cfs, wd_cfs)

  # get monthly means
  out <- new_flow_corrected |>
    dplyr::summarise(
      flow_cfs = mean(flow_cfs),
      .by = c(basin, yr, mo)
    )

  return(out)

}
