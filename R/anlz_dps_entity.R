#' Calculate DPS reuse and end of pipe from raw entity data
#'
#' Calculate DPS reuse and end of pipe from raw entity data
#'
#' @param pth path to raw entity data
#' @param skip number of lines to skip in raw entity data
#' @param sep separator for raw entity data
#'
#' @details
#' Indput data should include flow as million gallons per day, and conc as mg/L.  Steps include:
#'
#' 1. Multiply flow by day in month to get million gallons per month
#' 1. Multiply flow by 3785.412 to get cubic meters per month
#' 1. Multiply N by flow and divide by 1000 to get kg N per month
#' 1. Multiply m3 by 1000 to get L, then divide by 1e6 to convert mg to kg, same as dividing by 1000
#' 1. TN DPS reuse is multiplied by 0.3 for land application attenuation factor (70%)
#' 1. TP, TSS, BOD  dps reuse is multiplied by 0.05 for land application attenuation factor (95%)
#' 1. Hydro load (m3 / mo) is also attenuated for the reuse, multiplied by 0.6 (40% attenutation)
#'
#' @return data frame with loading data for TP, TN, TSS, and BOD as tons per month and hydro load as million cubic meters per month
#' @export
#'
#' @importFrom dplyr case_when mutate_at mutate case_when select filter rename
#' @importFrom dplyr contains matches vars
#' @importFrom tidyr pivot_longer pivot_wider
#' @importFrom lubridate ymd days_in_month
#'
#' @examples
#' pth <- system.file('extdata/ps_dom_hillsco_falkenburg_2019.txt', package = 'tbeploads')
#' anlz_dps_entity(pth)
anlz_dps_entity <- function(pth, skip = 0, sep = '\t'){

  # read file
  dat <- read.table(pth, skip = skip, sep = sep, header = TRUE)

  # add wq columns
  dat <- util_dps_addcol(dat)

  # check units
  dat <- util_dps_checkuni(dat)

  # format columns
  dat <- dat |>
    rename(source = outfall) |>
    mutate_at(vars(contains('mgl')), as.numeric) |>
    # select(-outfallno, -outfall) |>
    pivot_longer(names_to = 'var', values_to = 'conc_mgl', matches('tn_mgl|tp_mgl|tss_mgl|bod_mgl'))

  # get entity, facility, and bay segment
  entfac <- util_dps_entinfo(pth)

  # get loads
  out <- dat |>
    mutate(
      dys = days_in_month(ymd(paste(Year, Month, '01', sep = '-'))),
      flow_mgm = flow_mgd * dys, # million gallons per month
      flow_m3m = flow_mgm * 3785.412, # cubic meters per month
      load_kg = conc_mgl * flow_m3m / 1000, # kg var per month,
      load_tons = load_kg / 907.1847, # kg to tons,
      load_tons = case_when(
        grepl('^R\\-', source) & var == 'Total N' ~ load_tons * 0.3,
        grepl('^R\\-', source) & var %in% c('Total P', 'TSS', 'BOD') ~ load_tons * 0.05,
        flow_m3m <= 0 ~ 0, # no flow, no load
        T ~ load_tons
      ),
      flow_m3m = case_when(
        grepl('^R\\-', source) ~ flow_m3m * 0.6,
        T ~ flow_m3m
      ),
      entity = entfac$entity,
      facility = entfac$facname,
      var = factor(var, levels = c('tn_mgl', 'tp_mgl', 'tss_mgl', 'bod_mgl'),
                   labels = c('tn_load', 'tp_load', 'tss_load', 'bod_load')
      ),
      hy_load = flow_m3m / 1e6 # flow as mill m3 /month
    ) |>
    select(-flow_mgm, -flow_mgd, -conc_mgl, -dys, -load_kg, -flow_m3m) |>
    pivot_wider(names_from = 'var', values_from = 'load_tons') |>
    select(Year, Month, entity, facility, source, tn_load, tp_load, tss_load, bod_load, hy_load)

  return(out)

}
