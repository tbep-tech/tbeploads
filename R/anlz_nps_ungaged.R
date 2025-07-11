#' Estimated non-point source (NPS) ungaged loads
#'
#' @param tbbase data frame containing polygon areas for the combined data layer of bay segment, basin, jurisdiction, land use data, and soils, see details
#' @param rain data frame of rainfall data, see details
#' @param lakemanpth character, path to the file containing the Lake Manatee flow data, see details
#' @param tampabypth character, path to the file containing the Tampa Bypass flow data, see details
#' @param bellshlpth character, path to the file containing the Bell shoals data, see details
#'
#' @details
#' Requires the following inputs:
#'
#' \itemize{
#'  \item \code{tbbase}: A data frame containing polygon areas for the combined data layer of bay segment, basin, jurisdiction, land use data, and soils, Stored as \code{\link{tbbase}} or created (takes an hour or so) with \code{\link{util_nps_gettbbase}}.
#'  \item \code{rain}: A data frame of rainfall data see \code{\link{rain}}.
#'  \item \code{lakemanpth}: character, path to the file containing the Lake Manatee flow data. See \code{\link{util_nps_getextflow}}.
#'  \item \code{tampabypth}: character, path to the file containing the Tampa Bypass flow data. See \code{\link{util_nps_getextflow}}.
#'  \item \code{bellshlpth}: character, path to the file containing the Bell shoals data. See \code{\link{util_nps_getextflow}}.
#' }
#'
#' USGS gaged flows are also used as returned by \code{\link{util_nps_getusgsflow}}.
#'
#' @returns A data frame
#'
#' @export
#'
#' @examples
#' # external flow sources
#' lakemanpth <- system.file('extdata/nps_extflow_lakemanatee.xlsx', package = 'tbeploads')
#' tampabypth <- system.file('extdata/nps_extflow_tampabypass.xlsx', package = 'tbeploads')
#' bellshlpth <- system.file('extdata/nps_extflow_bellshoals.xls', package = 'tbeploads')
#'
#' anlz_nps_ungaged(tbbase, rain, lakemanpth, tampabypth, bellshlpth)
anlz_nps_ungaged <- function(tbbase, rain, lakemanpth, tampabypth, bellshlpth){

  # get data prepped for logistic regression
  tbnestland <- util_nps_preplog(tbbase)

  # get inverse weighted distance data from rainfall to sub-bains
  npsrain <- util_nps_preprain(rain)

  # flow_monthly_means
  allflo <- util_nps_getflow(lakemanpth, tampabypth, bellshlpth)

  # start assembling NPS model parameters

  rainflow <- dplyr::full_join(npsrain, allflo, by = c("basin", "yr", "mo"))

  rainflow <- rainflow |>
    dplyr::mutate(
      bay_seg = dplyr::case_when(
        basin %in% c("02306647", "02307000", "02307359", "LTARPON", "206-1") ~ 1,
        basin %in% c("02300700", "02301000", "02301300", "02301500", "02301695", "02301750",
                     "02303000", "02303330", "02304500", "TBYPASS", "204-2", "205-2", "206-2") ~ 2,
        basin %in% c("02300500", "02300530", "203-3", "206-3C", "206-3E", "206-3W") ~ 3,
        basin == "206-4" ~ 4,
        basin == "207-5" ~ 5,
        basin == "206-5" ~ 55,
        basin == "206-6" ~ 6,
        basin %in% c("02299950", "202-7", "EVERSRES", "LMANATEE") ~ 7,
        TRUE ~ NA_real_
        )
      )  # Retain existing bay_seg if no condition is met

  rainflowextra <- rainflow |>
    dplyr::filter(basin == "207-5") |>
    dplyr::mutate(bay_seg = 55)

  rainflow1 <- dplyr::bind_rows(rainflow, rainflowextra)

  npsmod1 <- dplyr::left_join(tbnestland, rainflow1, by = c("bay_seg", "basin"))

  tbshydro <- dplyr::full_join(dbasing, npsmod1, by = c("bayseg" = "bay_seg", "basin"), relationship = "many-to-many") |>
    dplyr::rename(
      bay_seg = bayseg
    )

  # Remove 'Non-connected' basins, saltwater features and wetland CLUCs from basins' total area calculation
  # CLUC-Soil category areas and the Total area calculated under this effort deviate from JEI's prior efforts
  # This needs to be researched/QC'd a bit more based on total available land area in each basin, for now proceeding with model calculations

  explan <- tbshydro |>
    dplyr::mutate(

      # Remove non-connected basins
      bas_area = tot_area - rowSums(dplyr::select(tbshydro, dplyr::starts_with("NC_C")), na.rm = TRUE),

      # Remove saltwater and wetlands
      bas_area = tot_area - rowSums(dplyr::select(tbshydro, dplyr::starts_with("C_C17"),
                                                  dplyr::starts_with("C_C21"), dplyr::starts_with("C_C22")), na.rm = TRUE),

      # Calculate CLUCs percentages
      lu01 = (rowSums(dplyr::select(tbshydro, dplyr::starts_with("C_C01")), na.rm = TRUE)) / bas_area,
      lu02 = (rowSums(dplyr::select(tbshydro, dplyr::starts_with("C_C02")), na.rm = TRUE)) / bas_area,
      lu03 = (rowSums(dplyr::select(tbshydro, dplyr::starts_with("C_C03")), na.rm = TRUE)) / bas_area,
      lu04 = (rowSums(dplyr::select(tbshydro, dplyr::starts_with("C_C04")), na.rm = TRUE)) / bas_area,
      lu05 = (rowSums(dplyr::select(tbshydro, dplyr::starts_with("C_C05")), na.rm = TRUE)) / bas_area,
      lu06 = (rowSums(dplyr::select(tbshydro, dplyr::starts_with("C_C06")), na.rm = TRUE)) / bas_area,
      lu07 = (rowSums(dplyr::select(tbshydro, dplyr::starts_with("C_C07")), na.rm = TRUE)) / bas_area,
      lu08 = (rowSums(dplyr::select(tbshydro, dplyr::starts_with("C_C08")), na.rm = TRUE)) / bas_area,
      lu09 = (rowSums(dplyr::select(tbshydro, dplyr::starts_with("C_C09")), na.rm = TRUE)) / bas_area,
      lu10 = (rowSums(dplyr::select(tbshydro, dplyr::starts_with("C_C10")), na.rm = TRUE)) / bas_area,
      lu11 = (rowSums(dplyr::select(tbshydro, dplyr::starts_with("C_C11")), na.rm = TRUE)) / bas_area,
      lu12 = (rowSums(dplyr::select(tbshydro, dplyr::starts_with("C_C12")), na.rm = TRUE)) / bas_area,
      lu13 = (rowSums(dplyr::select(tbshydro, dplyr::starts_with("C_C13")), na.rm = TRUE)) / bas_area,
      lu14 = (rowSums(dplyr::select(tbshydro, dplyr::starts_with("C_C14")), na.rm = TRUE)) / bas_area,
      lu15 = (rowSums(dplyr::select(tbshydro, dplyr::starts_with("C_C15")), na.rm = TRUE)) / bas_area,
      lu16 = (rowSums(dplyr::select(tbshydro, dplyr::starts_with("C_C16")), na.rm = TRUE)) / bas_area,
      lu17 = (rowSums(dplyr::select(tbshydro, dplyr::starts_with("C_C17")), na.rm = TRUE)) / bas_area, #Not used in model - seawater
      lu18 = (rowSums(dplyr::select(tbshydro, dplyr::starts_with("C_C18")), na.rm = TRUE)) / bas_area,
      lu19 = (rowSums(dplyr::select(tbshydro, dplyr::starts_with("C_C19")), na.rm = TRUE)) / bas_area,
      lu20 = (rowSums(dplyr::select(tbshydro, dplyr::starts_with("C_C20")), na.rm = TRUE)) / bas_area,
      lu21 = (rowSums(dplyr::select(tbshydro, dplyr::starts_with("C_C21")), na.rm = TRUE)) / bas_area, #Not used in model - tidal flats
      lu22 = (rowSums(dplyr::select(tbshydro, dplyr::starts_with("C_C22")), na.rm = TRUE)) / bas_area, #Not used NPDES areas

      #Calculate aggregated land use (%)
      urb = lu01 + lu02 + lu03 + lu04 + lu05 + lu07,
      ag = lu06 + lu11 + lu12 + lu13 + lu14,
      wet = lu16 + lu18 + lu19 + lu20,
      frs = lu08 + lu09 + lu10 + lu15,

      # Calculate forest land cover (%) by HSG, C_C10A + C_C10B excluded/missing -- need to QC CLUCs-FLUCCs crosswalk for 'Pasture Lands'
      for_ab = (rowSums(dplyr::select(tbshydro, c("C_C08A", "C_C08B", "C_C09A", "C_C09B", "C_C15A", "C_C15B")), na.rm = TRUE)) / bas_area,
      for_cd = (rowSums(dplyr::select(tbshydro, c("C_C08C", "C_C08D", "C_C09C", "C_C09D", "C_C15C", "C_C15D")), na.rm = TRUE)) / bas_area,  # C_C10C + C_C10D excluded/missing -- need to QC CLUCs-FLUCCs crosswalk for 'Pasture Lands'
      flow = ((flow_cfs * 0.0283) / (bas_area *10000)) * 60 * 60 * 24 * (365/12),  # Convert from cfs to meters per month
      rain = rain * 0.0254,  # Convert from inches to meters per month
      lag1rain = lag1rain * 0.0254,  # Convert from inches to meters per month
      lag2rain = lag2rain * 0.0254,  # Convert from inches to meters per month
      grp = dplyr::case_when(
        urb <= 0.19 ~ "A",
        urb > 0.19  ~ "B",
        TRUE ~ NA
      ),
      season = dplyr::case_when(
        mo %in% c(7, 8, 9, 10) ~ "wet",
        mo %in% c(1, 2, 3, 4, 5, 6, 11, 12) ~ "dry",
        TRUE ~ NA
      )
    ) |>
    dplyr::select(bay_seg, basin, gagetype, grp, season, mo, yr, flow, rain, lag1rain, lag2rain,
           bas_area, tot_area, urb, ag, wet, frs, for_ab, for_cd, dplyr::num_range("lu0", 1:9),
           dplyr::num_range("lu", 10:22))

  npsmod2 <- explan |>
    dplyr::mutate(
      lflowhat = dplyr::case_when(
        season == "dry" & grp == "A" ~
          rain * 4.59483000 + lag1rain * 6.26892755 + lag2rain * 4.29704324 +
          urb * -4.86110475 + ag * -2.97134608 + wet * -16.90735157 + frs * -3.04320707,
        season == "wet" & grp == "A" ~
          rain * 7.21891992 + lag1rain * 3.59249568 + lag2rain * 2.24675993 +
          urb * -5.62930983 + ag * -3.85343456 + wet * -11.76932936 + frs * -5.00397713,
        season == "dry" & grp == "B" ~
          rain * 5.93231559 + lag1rain * 6.16790364 + lag2rain * 3.58033336 +
          urb * -5.98227539 + ag * -5.48850473 + wet * -1.44922321 + frs * -10.14869568,
        season == "wet" & grp == "B" ~
          rain * 7.60247189 + lag1rain * 1.70865432 + lag2rain * 2.78577463 +
          urb * -4.66502277 + ag * -5.38936557 + wet * -2.79156203 + frs * -10.21741924,
        TRUE ~ NA_real_
      ),
      flowhat = exp(lflowhat),
      outlier = dplyr::if_else(rain > 38.1, 1, 0)
    )

  flowhat <- npsmod2 |>
    filter(! basin %in% c("02301000", "02301300", "02303000", "02303330", "02307359")) |>  #Remove 02307359 when LTARPON missing
    select(bay_seg, basin, bas_area, yr, mo, flow, flowhat)

  # apply runoff coefficients to tbbase
  landsoil <- util_nps_landsoilrc(tbbase)

  pflow1 <- flowhat |>
    dplyr::left_join(landsoil, by = c("yr", "mo", "bay_seg", "basin")) |>
    dplyr::mutate(flow = ifelse(is.na(flow), flowhat, flow)) |>
    dplyr::mutate(pflow = dplyr::case_when(basin %in% c("02299950", "02300500", "02300700", "02301500",
                                          "02301750", "02304500", "02306647", "02307000",
                                          "EVERSRES", "LMANATEE", "LTARPON", "TBYPASS",
                                          "02307359") ~ ((rca/tot_rca)*flow),
                             basin %in% c("02300530", "02301695", "202-7", "203-3", "204-2",
                                          "205-2", "206-1", "206-2", "206-3C", "206-3E", "206-3W",
                                          "206-4", "206-5", "206-6", "207-5") ~ ((rca/tot_rca)*flowhat),
                             TRUE ~ NA))

  pflow <- pflow1 |>
    dplyr::group_by(yr, mo, bay_seg, basin, clucsid, bas_area) |>
    dplyr::summarise(
      pflow = sum(pflow, na.rm = TRUE),
      area = sum(area, na.rm = TRUE)
    ) |>
    dplyr::select(yr, mo, bay_seg, basin, clucsid, pflow, area, bas_area)

  npspol <- emc |>
    dplyr::mutate(
      sm_tn = dplyr::case_when(
        clucsid %in% c(18, 20) ~ 0,
        TRUE ~ mean_tn
      ),
      sm_tp = dplyr::case_when(
        clucsid %in% c(18, 20) ~ 0,
        TRUE ~ mean_tp
      ),
      sm_tss = dplyr::case_when(
        clucsid %in% c(18, 20) ~ 0,
        TRUE ~ mean_tss)
      ) |>
    dplyr::select(clucsid, mean_tn, mean_tp, mean_tss, mean_bod, sm_tn, sm_tp, sm_tss)

  out <- pflow |>
    dplyr::left_join(npspol, by = "clucsid") |>
    dplyr::mutate(
      h2oload = pflow * bas_area * 10000,
      tnload = mean_tn * 1000 * h2oload * 0.001 * 0.001,
      tpload = mean_tp * 1000 * h2oload * 0.001 * 0.001,
      tssload = mean_tss * 1000 * h2oload * 0.001 * 0.001,
      bodload = mean_bod * 1000 * h2oload * 0.001 * 0.001,
      stnload = sm_tn * 1000 * h2oload * 0.001 * 0.001,
      stpload = sm_tp * 1000 * h2oload * 0.001 * 0.001,
      stssload = sm_tss * 1000 * h2oload * 0.001 * 0.001
    ) |>
    dplyr::group_by(bay_seg, basin, yr, mo, clucsid) |>
    dplyr::summarise(
      h2oload = sum(h2oload, na.rm=TRUE),
      tnload = sum(tnload, na.rm=TRUE),
      tpload = sum(tpload, na.rm=TRUE),
      tssload = sum(tssload, na.rm=TRUE),
      stnload = sum(stnload, na.rm=TRUE),
      stpload = sum(stpload, na.rm=TRUE),
      stssload = sum(stssload, na.rm=TRUE),
      bodload = sum(bodload, na.rm=TRUE),
      area = sum(area, na.rm=TRUE),
      bas_area = first(bas_area),
      .groups = 'drop'
    )

  return(out)

}
