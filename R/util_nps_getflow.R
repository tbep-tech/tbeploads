#' Get flow data from for NPS calculations at gaged sites
#'
#' @param pth1 character, path to the file containing the Lake Manatee flow data
#' @param pth2 character, path to the file containing the Tampa Bypass flow data
#' @param pth3 character, path to the file containing the Bell shoals data
#' @param yrrng vector of two integers, the year range for which to retrieve flow data. Default is c(2021, 2023).
#'
#' @returns A data frame of monthly mean flow
#' @export
#'
#' @examples
#' pth1 <- system.file('extdata/nps_extflow_lakemanatee.xlsx', package = 'tbeploads')
#' pth2 <- system.file('extdata/nps_extflow_tampabypass.xlsx', package = 'tbeploads')
#' pth3 <- system.file('extdata/nps_extflow_bellshoals.xls', package = 'tbeploads')
#' allflo <- util_nps_getflow(pth1, pth2, pth3)
util_nps_getflow <- function(pth1, pth2, pth3, yrrng = c(2021, 2023)){

  # external files
  lman <- util_nps_getextflow(pth1, 'LMANATEE', yrrng = yrrng)
  s160 <- util_nps_getextflow(pth2, 'TBYPASS', yrrng = yrrng)
  blsh <- util_nps_getextflow(pth3, '02301500', yrrng = yrrng)

  # usgs api flow data
  yrrng <- as.Date(paste0(yrrng, '-01-01'))
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

  # check_plots <- new_flow_corrected |>
  #   ggplot(aes(x = date, y = flow_cfs)) +
  #   geom_line() +
  #   facet_wrap(~ basin, scales = "free")
  # check_plots

  # get monthly means
  out <- new_flow_corrected |>
    summarise(
      flow_cfs = mean(flow_cfs),
      .by = c(basin, yr, mo)
    )

  return(out)

}
