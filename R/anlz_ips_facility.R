#' Calculate IPS from raw facility data
#'
#' Calculate IPS from raw facility data
#'
#' @param fls vector of file paths to raw facility data, one to many
#'
#' @details
#' Input data should include flow as million gallons per day, and conc as mg/L.  Steps include:
#'
#' 1. Multiply flow by day in month to get million gallons per month
#' 1. Multiply flow by 3785.412 to get cubic meters per month
#' 1. Multiply conc by flow and divide by 1000 to get kg var per month
#' 1. Multiply m3 by 1000 to get L, then divide by 1e6 to convert mg to kg, same as dividing by 1000
#'
#' @return data frame with loading data for TP, TN, TSS, and BOD as tons per month and hydro load as million cubic meters per month.  Information for each entity, facility, and outfall is retained.
#'
#' @seealso \code{\link{anlz_dps}}
#'
#' @export
#'
#' @examples
#' fls <- list.files(system.file('extdata/', package = 'tbeploads'),
#'   pattern = 'ps_ind', full.names = TRUE)
#' anlz_ips_facility(fls)
anlz_ips_facility <- function(fls){

  ##
  # import and prep all data

  ipsprep <- tibble::tibble(
    fls = fls
  ) |>
    dplyr::group_by(fls) |>
    tidyr::nest(.key = 'dat') |>
    dplyr::mutate(
      dat = purrr::map(fls, read.table, skip = 0, sep = '\t', header = T, na.strings = c('NA', 'NOD', 'IFS', '.')),
      dat = purrr::map(dat, util_ps_addcol),
      dat = purrr::map(dat, util_ps_fixoutfall),
      dat = purrr::map(dat, util_ps_checkuni),
      dat = purrr::map(dat, util_ps_fillmis),
      entinfo = purrr::map(fls, util_ps_facinfo, asdf = T)
    ) |>
    dplyr::ungroup() |>
    tidyr::unnest('entinfo') |>
    tidyr::unnest('dat')

  ##
  # calc loads

  # convert flow as mgd to mgm
  ips <- ipsprep |>
    dplyr::rename(flow_mgm = flow_mgd) |>
    dplyr::mutate(
      dys = lubridate::days_in_month(lubridate::ymd(paste(Year, Month, '01', sep = '-'))),
      flow_mgm = flow_mgm * dys
    ) |>
    dplyr::select(-dys)

  outfall <- c("D-001", "D-002", "D-004", "D-008", "D-010", "D-003", "D-02R",
                 "EMD", "FLW-3", "D-005", "D-006", "D-007A", "D-04A", "D-009",
                 "D-001F", "D-005A", "D-005B", "D-021", "D-022", "D-025", "D-023",
                 "D-024", "SW-1", "SW-3", "I-038", "I-130", "EFF-001", "I-002"
  )

  chk <- !ips$outfall %in% outfall
  if(any(chk)){

    msg <- ips[which(chk),] |>
      dplyr::select(fls, outfall) |>
      unique() |>
      dplyr::mutate(fls = basename(fls)) |>
      tidyr::unite('msg', fls, outfall, sep = ', ') |>
      dplyr::pull(msg) |>
      paste(collapse = '; ')

    stop("outfall id not in data: ", msg)

  }

  # remove fls
  ips <- dplyr::select(ips, -fls)

  # actual load calc
  ips <- ips |>
    tidyr::pivot_longer(c('tn_mgl', 'tp_mgl', 'tss_mgl', 'bod_mgl'), names_to = 'var', values_to = 'conc_mgl') |>
    dplyr::rename(flow_m3m = flow_mgm) |>
    dplyr::mutate(
      flow_m3m = flow_m3m * 3785.412, # mgm to m3m,
      load_kg = conc_mgl * flow_m3m / 1000 # kg var per month,
    )

  # flow as mill m3 per month
  # load as tons per month
  ips <- ips |>
    dplyr::arrange(entity, facname, outfall, Year, Month) |>
    dplyr::select(-conc_mgl) |>
    dplyr::rename(
      hy_load = flow_m3m,
      load = load_kg
    ) |>
    dplyr::mutate(
      load = load / 907.1847, # kg to tons,
      hy_load = hy_load / 1e6,
      var = gsub('mgl$', 'load', var)
    ) |>
    tidyr::pivot_wider(names_from = var, values_from = load) |>
    dplyr::select(
      Year,
      Month,
      entity,
      facility = facname,
      coastco,
      source = outfall,
      tn_load,
      tp_load,
      tss_load,
      bod_load,
      hy_load
    )

  out <- ips

  return(out)

}
