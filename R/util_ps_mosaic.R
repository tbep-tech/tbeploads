#' Fill missing concentration data for Mosaic industrial point source facilities
#'
#' Fill total phosphorus, total suspended solids, and biological oxygen demand
#' for Mosaic industrial point source records, which contain only flow and total nitrogen.
#'
#' @param dat data frame for a single Mosaic facility with columns
#'   \code{Facility.Name}, \code{Outfall.ID}, \code{Year}, \code{Month},
#'   \code{Average.Daily.Flow..ADF...mgd.}, and \code{Total.N}
#'
#' @details
#' Mosaic data contain only average daily flow (MGD) and total nitrogen
#' (TN, mg/L). Total phosphorus (TP), total suspended solids (TSS), and biological
#' oxygen demand (BOD) are not measured and are filled with historical averages derived
#' from earlier permit compliance data (2008-2011 averages unless otherwise noted).
#'
#' The general fill rule is: if average daily flow is zero or missing, TP, TSS, and
#' BOD are set to \code{NA}; if flow is positive they are assigned the per-facility
#' (or per-outfall) historical average. A few facilities always receive
#' the historical fill regardless of flow and these include Mosaic Bartow, Green Bay, New Wales, South
#' Pierce, and Bonnie outfall D-003. Missing flow values are replaced with zero.
#' A permit number is added for each facility from FDEP permit records.
#'
#' @section Fill values (mg/L):
#' \describe{
#'   \item{Mosaic Bartow (all outfalls)}{TP = 1.61, TSS = 8.38, BOD = 9.6, always filled}
#'   \item{Mosaic Black Point (fka Yara) I-002}{TP = 0.56, TSS = 8.2, BOD = 2.45}
#'   \item{Mosaic Bonnie D-005}{TP = 0.18, TSS = 3.40, BOD = 9.6}
#'   \item{Mosaic Bonnie D-006}{TP = 0.85, TSS = 1.63, BOD = 9.6}
#'   \item{Mosaic Bonnie D-04A}{TP = 0.50, TSS = 2.26, BOD = 9.6}
#'   \item{Mosaic Bonnie D-07A}{TP = 0.23, TSS = 1.70, BOD = 9.6}
#'   \item{Mosaic Bonnie I-001}{TP = 0.73, TSS = 26.46, BOD = 9.6}
#'   \item{Mosaic Bonnie I-003}{TP = 2.30, TSS = 6.58, BOD = 9.6, always filled}
#'   \item{Mosaic Four Corners D-001, D-003}{TP = 1.12, TSS = 12.7, BOD = 9.6}
#'   \item{Mosaic Green Bay (all outfalls)}{TP = 4.23, TSS = 7.90, BOD = 9.6, always filled}
#'   \item{Mosaic Hookers Point (Ammonia Terminal) (all outfalls)}{TP = 25.3, TSS = 9.35, BOD = 9.6}
#'   \item{Mosaic Lonesome (all outfalls)}{TP = 0.016, TSS = 2.4, BOD = 9.6}
#'   \item{Mosaic Mulberry D-002}{TP = 2.21, TSS = 5.07, BOD = 9.6}
#'   \item{Mosaic Mulberry Phospho Stack D-01F}{TP = 6.67, TSS = 6.78, BOD = 9.6}
#'   \item{Mosaic New Wales (all outfalls)}{TP = 0.27, TSS = 4.9, BOD = 9.6, always filled}
#'   \item{Mosaic Nichols (all outfalls)}{TP = 0.21, TSS = 1.95, BOD = 1.85}
#'   \item{Mosaic Plant City (all outfalls)}{TP = 0.65, TSS = 12.0, BOD = 9.6}
#'   \item{Mosaic Port Sutton (all outfalls)}{TP = 0.66, TSS = 14.4, BOD = 9.6}
#'   \item{Mosaic Riverview D-001, D-021, D-022, D-05A, D-05B}{TP = 10.65, TSS = 11.49, BOD = 1.8}
#'   \item{Mosaic Riverview D-025}{TP = 10.65, TSS = 8.70, BOD = 1.8}
#'   \item{Mosaic South Pierce (all outfalls)}{TP = 1.50, TSS = 3.58, BOD = 9.6, always filled}
#'   \item{Mosaic Tampa Marine Terminal D-SW1}{TP = 22.0, TSS = 49.6, BOD = 9.6}
#'   \item{Mosaic Tampa Marine Terminal D-SW3}{TP = 25.3, TSS = 9.33, BOD = 9.6}
#' }
#' Mosaic Hookers Prairie and Mosaic Riverview Stack Closure have no established
#' fill values; TP, TSS, and BOD will be \code{NA} for those facilities.
#'
#' Facilities with named outfall rules (Bonnie, Four Corners, Mulberry,
#' Mulberry Phospho Stack, Riverview, and Tampa Marine Terminal) require that
#' every outfall present in \code{dat} matches a known entry.  An error is returned
#' for unrecognised outfalls.
#'
#' Note that this function may need to be updated if new data become available or if 
#' there are changes in the fill rules. The current fill values and rules are based on 
#' historical permit compliance data and may not reflect future conditions.
#' 
#' @return A data frame with columns: \code{Permit.Number}, \code{Facility.Name},
#'   \code{Outfall.ID}, \code{Year}, \code{Month},
#'   \code{Average.Daily.Flow..ADF...mgd.}, \code{Total.N}, \code{Total.N.Unit},
#'   \code{Total.P}, \code{Total.P.Unit}, \code{TSS}, \code{TSS.Unit},
#'   \code{BOD}, \code{BOD.Unit}.
#'
#' @export
#'
#' @examples
#' dat <- data.frame(
#'   Facility.Name = rep('Mosaic Bartow', 3),
#'   Outfall.ID = rep('D-001', 3),
#'   Year = rep(2022L, 3),
#'   Month = 1:3,
#'   Average.Daily.Flow..ADF...mgd. = c(0.57, 0, 0.43),
#'   Total.N = c(3.94, NA, 2.11)
#' )
#' util_ps_mosaic(dat)
util_ps_mosaic <- function(dat) {

  fac_nm <- unique(dat$Facility.Name)
  stopifnot("dat must contain data from exactly one facility" = length(fac_nm) == 1)

  # Map raw facility names to facname values in the facilities package dataset.
  # Permit numbers are derived from facilities rather than hardcoded here.
  facname_map <- c(
    'Mosaic Bartow'                           = 'Mosaic - Bartow',
    'Mosaic Black Point (fka Yara)'           = 'Mosaic - Black Point',
    'Mosaic Bonnie'                           = 'Mosaic - Bonnie',
    'Mosaic Four Corners'                     = 'Mosaic - Four Corners',
    'Mosaic Green Bay'                        = 'Mosaic - Green Bay',
    'Mosaic Hookers Point (Ammonia Terminal)' = 'Mosaic - Tampa Ammonia Terminal',
    'Mosaic Hookers Prairie'                  = 'Mosaic - Hookers Prairie',
    'Mosaic Lonesome'                         = 'Mosaic - Ft. Lonesome',
    'Mosaic Mulberry Phospho Stack'           = 'Mosaic - Mulberry Phospho Stack',
    'Mosaic Mulberry'                         = 'Mosaic - Mulberry Plant',
    'Mosaic New Wales'                        = 'Mosaic - New Wales Chemical Plant',
    'Mosaic Nichols'                          = 'Mosaic - Nichols Mine',
    'Mosaic Plant City'                       = 'Mosaic - Plant City',
    'Mosaic Port Sutton'                      = 'Mosaic - Port Sutton',
    'Mosaic Riverview'                        = 'Mosaic - Riverview',
    'Mosaic Riverview Stack Closure'          = 'Mosaic - Riverview Stack Closure',
    'Mosaic South Pierce'                     = 'Mosaic - South Pierce',
    'Mosaic Tampa Marine Terminal'            = 'Mosaic - Tampa Marine Terminal'
  )

  permit <- unique(facilities$permit[facilities$facname == facname_map[fac_nm]])

  # Historical fill values sourced from 1_IPS_2021a_20221025.sas
  # Outfall.ID = NA means facility-wide (applied to all outfalls for that facility)
  # check_flow = FALSE: fill regardless of flow; TRUE: fill only when flow > 0
  fill_vals <- data.frame(
    Facility.Name = c(
      # Facility-wide fills — always applied regardless of flow
      'Mosaic Bartow',
      'Mosaic Green Bay',
      'Mosaic New Wales',
      'Mosaic South Pierce',
      # Facility-wide fills — applied only when flow > 0
      'Mosaic Hookers Point (Ammonia Terminal)',
      'Mosaic Nichols',
      'Mosaic Plant City',
      'Mosaic Port Sutton',
      'Mosaic Lonesome',
      # Per-outfall fills — Mosaic Bonnie
      'Mosaic Bonnie', 'Mosaic Bonnie', 'Mosaic Bonnie',
      'Mosaic Bonnie', 'Mosaic Bonnie', 'Mosaic Bonnie',
      # Per-outfall fills — other facilities
      'Mosaic Black Point (fka Yara)',
      'Mosaic Mulberry',
      'Mosaic Mulberry Phospho Stack',
      'Mosaic Riverview', 'Mosaic Riverview', 'Mosaic Riverview', 
      'Mosaic Riverview', 'Mosaic Riverview', 'Mosaic Riverview',
      'Mosaic Tampa Marine Terminal', 'Mosaic Tampa Marine Terminal',
      'Mosaic Four Corners', 'Mosaic Four Corners'
    ),
    Outfall.ID = c(
      NA, NA, NA, NA,                              # facility-wide
      NA, NA, NA, NA, NA,                          # facility-wide
      'D-005', 'D-006', 'D-04A',                   # Bonnie
      'D-07A', 'I-001', 'I-003',                   # Bonnie (D-003 always filled)
      'I-002',                                     # Black Point
      'D-002',                                     # Mulberry
      'D-01F',                                     # Mulberry Phospho Stack
      'D-001', 'D-021', 'D-022',                   # Riverview
      'D-025', 'D-05A', 'D-05B',                   # Riverview
      'D-SW1', 'D-SW3',                            # Tampa Marine Terminal
      'D-001', 'D-003'                             # Four Corners
    ),
    tp = c(
      1.61, 4.23, 0.27, 1.50,
      25.3, 0.21, 0.65, 0.66, 0.016,
      0.18, 0.85, 0.50, 0.23, 0.73, 2.30,
      0.56,
      2.21,
      6.67,
      10.65, 10.65, 10.65, 
      10.65, 10.65, 10.65,
      22.0, 25.3,
      1.12, 1.12
    ),
    tss = c(
      8.38, 7.90, 4.9, 3.58,
      9.35, 1.95, 12.0, 14.4, 2.4,
      3.40, 1.63, 2.26, 1.70, 26.46, 6.58,
      8.2,
      5.07,
      6.78,
      11.49, 11.49, 11.49, 
      8.70, 11.49, 11.49,
      49.6, 9.33,
      12.7, 12.7
    ),
    bod = c(
      9.6, 9.6, 9.6, 9.6,
      9.6, 1.85, 9.6, 9.6, 9.6,
      9.6, 9.6, 9.6, 9.6, 9.6, 9.6,
      2.45,
      9.6,
      9.6,
      1.8, 1.8, 1.8, 
      1.8, 1.8, 1.8,
      9.6, 9.6,
      9.6, 9.6
    ),
    check_flow = c(
      FALSE, FALSE, FALSE, FALSE,
      TRUE, TRUE, TRUE, TRUE, TRUE,
      TRUE, TRUE, TRUE, TRUE, TRUE, FALSE,
      TRUE,
      TRUE,
      TRUE,
      TRUE, TRUE, TRUE, 
      TRUE, TRUE, TRUE,
      TRUE, TRUE,
      TRUE, TRUE
    ),
    stringsAsFactors = FALSE
  )

  # Separate facility-wide and per-outfall tables; rename facility-wide columns
  # to avoid collision when joining both onto dat
  per_outfall <- fill_vals[!is.na(fill_vals$Outfall.ID), ]
  fac_wide <- fill_vals[is.na(fill_vals$Outfall.ID), ] |>
    dplyr::select(-Outfall.ID) |>
    dplyr::rename(tp_fw = tp, tss_fw = tss, bod_fw = bod, cf_fw = check_flow)

  # For facilities that rely on named outfall rules (no facility-wide fallback),
  # any outfall not listed in per_outfall is unhandled — error rather than silently returning NA.
  facs_with_named_outfalls <- setdiff(
    unique(per_outfall$Facility.Name),
    unique(fac_wide$Facility.Name)
  )
  if (fac_nm %in% facs_with_named_outfalls) {
    known_outfalls <- per_outfall$Outfall.ID[per_outfall$Facility.Name == fac_nm]
    unknown_outfalls <- setdiff(unique(dat$Outfall.ID), known_outfalls)
    if (length(unknown_outfalls) > 0) {
      stop(
        sprintf(
          "Facility '%s' has outfall(s) with no named fill rule: %s\n  Known outfalls: %s",
          fac_nm,
          paste(unknown_outfalls, collapse = ', '),
          paste(known_outfalls, collapse = ', ')
        ),
        call. = FALSE
      )
    }
  }

  out <- dat |>
    dplyr::left_join(per_outfall, by = c('Facility.Name', 'Outfall.ID')) |>
    dplyr::left_join(fac_wide, by = 'Facility.Name') |>
    dplyr::mutate(
      tp         = dplyr::coalesce(tp, tp_fw),
      tss        = dplyr::coalesce(tss, tss_fw),
      bod        = dplyr::coalesce(bod, bod_fw),
      check_flow = dplyr::coalesce(check_flow, cf_fw)
    ) |>
    dplyr::select(-tp_fw, -tss_fw, -bod_fw, -cf_fw)

  out <- out |>
    dplyr::mutate(
      flow = `Average.Daily.Flow..ADF...mgd.`,
      # Replace missing flow with zero (treated as no discharge)
      `Average.Daily.Flow..ADF...mgd.` = dplyr::coalesce(flow, 0),
      zero_flow = is.na(flow) | flow == 0,
      # Fill TP, TSS, BOD: use fill value when flow > 0, or always for check_flow = FALSE
      Total.P = dplyr::case_when(
        is.na(tp)                              ~ NA_real_,
        !is.na(check_flow) & !check_flow       ~ tp,
        !zero_flow                             ~ tp,
        TRUE                                   ~ NA_real_
      ),
      TSS = dplyr::case_when(
        is.na(tss)                             ~ NA_real_,
        !is.na(check_flow) & !check_flow       ~ tss,
        !zero_flow                             ~ tss,
        TRUE                                   ~ NA_real_
      ),
      BOD = dplyr::case_when(
        is.na(bod)                             ~ NA_real_,
        !is.na(check_flow) & !check_flow       ~ bod,
        !zero_flow                             ~ bod,
        TRUE                                   ~ NA_real_
      ),
      # Units: "mg/L" when a value is present, "" otherwise
      Total.N.Unit = dplyr::if_else(!is.na(Total.N), 'mg/L', ''),
      Total.P.Unit = dplyr::if_else(!is.na(Total.P), 'mg/L', ''),
      TSS.Unit     = dplyr::if_else(!is.na(TSS),     'mg/L', ''),
      BOD.Unit     = dplyr::if_else(!is.na(BOD),     'mg/L', ''),
      Permit.Number = permit
    ) |>
    dplyr::select(
      Permit.Number,
      Facility.Name,
      Outfall.ID,
      Year,
      Month,
      `Average.Daily.Flow..ADF...mgd.`,
      Total.N,
      Total.N.Unit,
      Total.P,
      Total.P.Unit,
      TSS,
      TSS.Unit,
      BOD,
      BOD.Unit
    )

  return(out)

}
