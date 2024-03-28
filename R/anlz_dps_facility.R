#' Calculate DPS reuse and end of pipe from raw facility data
#'
#' Calculate DPS reuse and end of pipe from raw facility data
#'
#' @param fls vector of file paths to raw facility data, one to many
#'
#' @details
#' Input data should include flow as million gallons per day, and conc as mg/L.  Steps include:
#'
#' 1. Multiply flow by day in month to get million gallons per month
#' 1. Multiply flow by 3785.412 to get cubic meters per month
#' 1. Multiply N by flow and divide by 1000 to get kg N per month
#' 1. Multiply m3 by 1000 to get L, then divide by 1e6 to convert mg to kg, same as dividing by 1000
#' 1. TN, TP, TSS, BOD dps reuse is multiplied by attenuation factor for land application (varies by location)
#' 1. Hydro load (m3 / mo) is also attenuated for the reuse, multiplied by 0.6 (40% attenuation)
#'
#' @return data frame with loading data for TP, TN, TSS, and BOD as tons per month and hydro load as million cubic meters per month.  Information for each entity, facility, and outfall is retained.
#'
#' @seealso \code{\link{anlz_dps}}
#'
#' @export
#'
#' @examples
#' fls <- list.files(system.file('extdata/', package = 'tbeploads'),
#'   pattern = '\\.txt$', full.names = TRUE)
#' anlz_dps_facility(fls)
anlz_dps_facility <- function(fls){

  ##
  # import and prep all data

  dpsprep <- tibble::tibble(
      fls = fls
    ) |>
    dplyr::group_by(fls) |>
    tidyr::nest(.key = 'dat') |>
    dplyr::mutate(
      dat = purrr::map(fls, read.table, skip = 0, sep = '\t', header = T),
      dat = purrr::map(dat, util_dps_addcol),
      dat = purrr::map(dat, util_dps_checkuni),
      dat = purrr::map(dat, util_dps_fillmis),
      entinfo = purrr::map(fls, util_dps_facinfo, asdf = T)
    ) |>
    dplyr::ungroup() |>
    tidyr::unnest('entinfo') |>
    tidyr::unnest('dat')

  ##
  # remove south county regional wwtp la and sw duplicate permits

  dps <- dpsprep |>
    dplyr::filter(!(grepl('^D', outfall) & permit == 'FL0028061LA')) |>
    dplyr::filter(!(grepl('^R', outfall) & permit == 'FL0028061SW'))

  ##
  # calc loads

  # convert flow as mgd to mgm
  dps <- dps |>
    dplyr::rename(flow_mgm = flow_mgd) |>
    dplyr::mutate(
      dys = lubridate::days_in_month(lubridate::ymd(paste(Year, Month, '01', sep = '-'))),
      flow_mgm = flow_mgm * dys
    ) |>
    dplyr::select(-dys)

  # change coastco for Hillsborough co Northwest Regional WRF (old Dale Mabry) D-005 (outfallid not in facilities)
  dps <- dps |>
    dplyr::mutate(coastco = dplyr::case_when(
      outfall == "D-005" & coastid == 'D_HC_1P' ~ "292",
      T ~ coastco
      )
    )

  swoutfall <- c("D-001", "D-002", "D-003", "D-004", "D-005", "D-006", "D001")
  laoutfall <- c("R-001", "R-002", "R-003")

  chk <- !dps$outfall %in% c(swoutfall, laoutfall)
  if(any(chk)){

    msg <- dps[which(chk),] |>
      dplyr::select(fls, outfall) |>
      unique() |>
      dplyr::mutate(fls = basename(fls)) |>
      tidyr::unite('msg', fls, outfall, sep = ', ') |>
      dplyr::pull(msg) |>
      paste(collapse = '; ')

    stop("outfall id not in data: ", msg)

  }

  # remove fls
  dps <- dplyr::select(dps, -fls)

  # calculate loads for end of pipe and reuse, same calc for both but reuse attenuated below
  dps <- dps |>
    tidyr::pivot_longer(c('tn_mgl', 'tp_mgl', 'tss_mgl', 'bod_mgl'), names_to = 'var', values_to = 'conc_mgl') |>
    dplyr::rename(flow_m3m = flow_mgm) |>
    dplyr::mutate(
      flow_m3m = flow_m3m * 3785.412, # mgm to m3m,
      load_kg = conc_mgl * flow_m3m / 1000 # kg var per month,
    )

  ##
  # separate dps into reuse and end of pipe
  dpsendofpipe <- dps |>
    dplyr::filter(outfall %in% swoutfall)
  dpsreuse <- dps |>
    dplyr::filter(outfall %in% laoutfall)

  ##
  # no sw load for permit STPETE
  dpsendofpipe <- dpsendofpipe |>
    dplyr::mutate(
      load_kg = dplyr::case_when(
        permit == 'STPETE' ~ 0,
        T ~ load_kg
      )
    )

  ##
  # apply attenuation factors to reuse depending on location

  # st pete facilities coastal id
  # loads are assigned proportionally to each coastal subbasin code for the selected coast ids
  # then additonal attenuation factor applied
  spcoastid <- c("D_PC_10", "D_PC_11", "D_PC_12", "D_PC_13")

  dpsreusesp <- dpsreuse |>
    dplyr::filter(coastid %in% spcoastid) |>
    dplyr::select(-coastco) |>
    list() |>
    tibble::tibble(
      coastco = c('508', '544', '566', '573', '580', '586', '588', '594'), #, '594a'),
      spccpro = c(0.16, 0.233, 0.161, 0.06, 0.131, 0.07, 0.04, 0.145), #0.085, 0.06),
      data = _
    ) |>
    unnest(data) |>
    dplyr::mutate(
      flow_m3m = flow_m3m * spccpro,
      load_kg = load_kg * spccpro,
      permit = 'STPETE',
      facid = 'STPET',
      facname = 'St Pete Facilities',
      coastid = NA_character_
    ) |>
    dplyr::select(-spccpro) |>
    dplyr::summarise(
      conc_mgl  = mean(conc_mgl, na.rm = T),
      flow_m3m = sum(flow_m3m, na.rm = T),
      load_kg = sum(load_kg),
      .by = c(Year, Month, outfall, entity, facname, permit, facid, coastco, coastid, var)
    )

  # add dpsresusesp back to dpsreuse and remove original st pete data
  dpsreuse <- dpsreuse |>
    dplyr::filter(!coastid %in% spcoastid) |>
    dplyr::bind_rows(dpsreusesp)

  # for all, 95% reduction in TP, TSS, BOD
  dpsreuse <- dpsreuse |>
    dplyr::mutate(
      load_kg = dplyr::case_when(
        var != 'tn_mgl' ~ load_kg * 0.05, # 95% reduction for all
        T ~ load_kg
      )
    )

  # TN attenuation varies
  # 95% for st pete coastsid
  # 90% for those in thcoastid (Van Dyke, Polk SW, Polk NW, Zephyrhills, Pinellas WEDunn, SouthCross (outside of RA), MacDill, Manatee North Reg, Manatee SE Reg, Largo, HillsCoSouthCo_SW, HillsCoSouthCo_LA)
  # 70% all others
  thcoastid <- c("D_HC_002", "D_PK_001", "D_PK_002", "D_PA_001", "PINNW", "SCROSSB", "D_HC_12",
                 "D_MC_1", "D_MC_4", "D_PC_9", "D_HC18D1", "D_HC18D2")

  dpsreuse <- dpsreuse |>
    dplyr::mutate(
      load_kg = dplyr::case_when(
        permit %in% 'STPETE' & var == 'tn_mgl'~ load_kg * 0.05, # 95% reduction
        coastid %in% thcoastid & var == 'tn_mgl' ~ load_kg * 0.1, # 90% reduction
        (!coastid %in% thcoastid) & (!permit %in% 'STPETE') & var == 'tn_mgl' ~ load_kg * 0.3, # 70% reduction
        T ~ load_kg
      )
    )

  # last step is 40% attenuation for hydro load
  dpsreuse <- dpsreuse |>
    dplyr::mutate(
      flow_m3m = flow_m3m * 0.6
    )

  ##
  # recreate dps

  # flow as mill m3 per month
  # load as tons per month
  dps <- dplyr::bind_rows(dpsendofpipe, dpsreuse) |>
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

  out <- dps

  return(out)

}
