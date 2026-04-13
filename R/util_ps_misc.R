#' Fill missing concentration data for miscellaneous industrial point source facilities
#'
#' Fill total phosphorus, total suspended solids, and biological oxygen demand
#' for miscellaneous industrial point source records where one or more of these
#' parameters are unmeasured and must be estimated from historical averages.
#'
#' @param dat data frame for a single facility with columns matching the
#'   standard clean IPS format: \code{Permit.Number}, \code{Facility.Name},
#'   \code{Outfall.ID}, \code{Year}, \code{Month},
#'   \code{Average.Daily.Flow..ADF...mgd.}, \code{Total.N}, \code{Total.N.Unit},
#'   \code{Total.P}, \code{Total.P.Unit}, \code{TSS}, \code{TSS.Unit},
#'   \code{BOD}, \code{BOD.Unit}
#'
#' @details
#' Unlike Mosaic facilities (see \code{\link{util_ps_mosaic}}), the facilities
#' handled here already report some concentration parameters from DMR data.
#' This function fills only those parameters that are chronically unmeasured,
#' using historical averages or standard assumptions.  Measured values are
#' preserved unless the fill rule explicitly overrides them (e.g., Trademark
#' Nitrogen TP and BOD are always set to historical means regardless of any
#' reported value).
#'
#' The general fill rule is: when flow is zero or missing, all concentrations
#' are set to \code{NA}; when flow is positive, fill values are applied to
#' unmeasured parameters and measured values are retained for everything else.
#' Unit strings are standardised to \code{"mg/L"} when a value is present and
#' \code{""} otherwise.
#'
#' As for the \code{\link{util_ps_mosaic}} function, #' Note that this function 
#' may need to be updated if new data become available or if there are changes 
#' in the fill rules. The current fill values and rules are based on 
#' historical permit compliance data and may not reflect future conditions.
#' 
#' @section Fill values (mg/L):
#' \describe{
#'   \item{Alpha/ Owens Corning (D-001)}{TP = 1, TSS = 2, BOD = 6;
#'     last recorded BOD and TSS from Dec 2017 minimal discharge; TP from
#'     Grizzle-Figg limits}
#'   \item{Big Bend Station (I-130)}{TP = 1.73, TSS = 12.11, BOD = 9.6;
#'     TP and TSS from 95-98 averages; BOD from Harper 1994}
#'   \item{Brewster Phosphogypsum Stack System (D-001)}{BOD = 9.6 (Harper 1994);
#'     TP and TSS from actual DMR measurements}
#'   \item{Busch Gardens (D-002)}{TSS = 5, BOD = 9.6 (Harper 1994);
#'     TP from actual DMR measurements}
#'   \item{Coronet Industries (D-002, D-004, D-005)}{BOD = 9.6 (Harper 1994);
#'     TP and TSS from actual DMR measurements}
#'   \item{CSX - ROCKPORT NEWPORT (D-001, D-002, D-008, D-010)}{TP = 0, TSS = 0,
#'     BOD = 9.6; no TP or TSS info; BOD same as Winston Yard previously}
#'   \item{CSX Winston Yard (D-002)}{TP = 0, TSS = 0, BOD = 9.6 (Harper 1994);
#'     no TP or TSS info}
#'   \item{Duke Energy-Bartow Plant (I-002)}{TP = 0, BOD = 9.6 (Harper 1994);
#'     TSS from actual DMR measurements; no TP measurements}
#'   \item{DRS Piney Point (D-001, D-002, D-003)}{BOD = 9.6 (Harper 1994);
#'     TP and TSS from actual DMR measurements}
#'   \item{Estech Agricola (D-001)}{BOD = 9.6 (Harper 1994);
#'     TP and TSS from actual DMR measurements}
#'   \item{H.L. Culbreath Bayside Power Station (I-038)}{TP = 1, TSS = 12.96,
#'     BOD = 9.6; TP from Grizzle-Figg limits; TSS avg 2012-2014; BOD Harper 1994}
#'   \item{Lowry Park Zoo (D-001)}{TSS = 5, BOD = 9.6 (Harper 1994);
#'     TP from actual DMR measurements; TN and TP for September 2023 filled
#'     with adjacent-month means (TN = 0.967, TP = 0.17)}
#'   \item{Trademark Nitrogen Corporation (D-001)}{TP = 0.13333, BOD = 1.09833;
#'     both filled with means from 1995-1998 loadings regardless of measured
#'     values; TSS from actual DMR measurements}
#' }
#'
#' @return The input data frame with \code{Total.P}, \code{TSS}, \code{BOD},
#'   and their unit columns updated.  All other columns are returned unchanged
#'   except that unit strings are standardised and concentrations are set to
#'   \code{NA} for zero- or missing-flow months.
#'
#' @seealso \code{\link{util_ps_mosaic}} for filling missing data for Mosaic facilities
#' 
#' @export
#'
#' @examples
#' dat <- data.frame(
#'   Permit.Number                  = rep('FL0185833', 3),
#'   Facility.Name                  = rep('Busch Gardens', 3),
#'   Outfall.ID                     = rep('D-002', 3),
#'   Year                           = rep(2022L, 3),
#'   Month                          = 1:3,
#'   Average.Daily.Flow..ADF...mgd. = c(0.78, 0.50, 0),
#'   Total.N                        = c(0.45, 0.06, NA),
#'   Total.N.Unit                   = c('mg/L', 'mg/L', ''),
#'   Total.P                        = c(0.08, 0.08, NA),
#'   Total.P.Unit                   = c('mg/L', 'mg/L', ''),
#'   TSS                            = c(NA, NA, NA),
#'   TSS.Unit                       = c('', '', ''),
#'   BOD                            = c(NA, NA, NA),
#'   BOD.Unit                       = c('', '', '')
#' )
#' util_ps_misc(dat)
util_ps_misc <- function(dat) {

  fac_nm <- unique(dat$Facility.Name)
  stopifnot("dat must contain data from exactly one facility" = length(fac_nm) == 1)

  # Fill values sourced from 1_IPS_2224_20251017.sas.
  # tp/tss/bod: a number means always use that fill value (overwriting any measured
  # data); NA_real_ means preserve whatever measured value is already in the column.
  # All facilities zero out all concentrations when flow is 0 or missing.
  fill_vals <- data.frame(
    Facility.Name = c(
      'Alpha/ Owens Corning',
      'Big Bend Station',
      'Brewster Phosphogypsum Stack System',
      'Busch Gardens',
      'Coronet Industries',
      'CSX - ROCKPORT NEWPORT',
      'CSX Winston Yard',
      'Duke Energy-Bartow Plant',
      'DRS Piney Point',
      'Estech Agricola',
      'H.L. Culbreath Bayside Power Station',
      'Lowry Park Zoo',
      'Trademark Nitrogen Corporation'
    ),
    tp = c(
      1,           # Alpha/Owens: Grizzle-Figg limit; not measured
      1.73,        # Big Bend: avg 95-98
      NA_real_,    # Brewster: use actual DMR data
      NA_real_,    # Busch: use actual DMR data
      NA_real_,    # Coronet: use actual DMR data
      0,           # CSX Rockport: no TP info
      0,           # CSX Winston: no TP info
      0,           # Duke: not measured
      NA_real_,    # Piney Point: use actual DMR data
      NA_real_,    # Estech: use actual DMR data
      1.00,        # TECO Bayside: Grizzle-Figg limit
      NA_real_,    # Lowry Park: use actual DMR data
      0.13333      # Trademark: mean from 95-98 loadings
    ),
    tss = c(
      2,           # Alpha/Owens: last recorded Dec 2017
      12.11,       # Big Bend: from last time (12-14)
      NA_real_,    # Brewster: use actual DMR data
      5,           # Busch: not measured
      NA_real_,    # Coronet: use actual DMR data
      0,           # CSX Rockport: no TSS info
      0,           # CSX Winston: no TSS info
      NA_real_,    # Duke: use actual DMR data
      NA_real_,    # Piney Point: use actual DMR data
      NA_real_,    # Estech: use actual DMR data
      12.96,       # TECO Bayside: avg 2012-2014
      5,           # Lowry Park: not measured
      NA_real_     # Trademark: use actual DMR data
    ),
    bod = c(
      6,           # Alpha/Owens: last recorded Dec 2017
      9.6,         # Big Bend: Harper 1994
      9.6,         # Brewster: Harper 1994
      9.6,         # Busch: Harper 1994
      9.6,         # Coronet: Harper 1994
      9.6,         # CSX Rockport: same as Winston Yard previously
      9.6,         # CSX Winston: Harper 1994
      9.6,         # Duke: Harper 1994
      9.6,         # Piney Point: Harper 1994
      9.6,         # Estech: Harper 1994
      9.6,         # TECO Bayside: Harper 1994
      9.6,         # Lowry Park: Harper 1994
      1.09833      # Trademark: mean from 95-98 loadings
    ),
    stringsAsFactors = FALSE
  )

  fills <- fill_vals[fill_vals$Facility.Name == fac_nm, ]

  if (nrow(fills) == 0)
    stop(sprintf("No fill rules defined for facility '%s'", fac_nm), call. = FALSE)

  tp_fill  <- fills$tp
  tss_fill <- fills$tss
  bod_fill <- fills$bod

  out <- dat |>
    dplyr::mutate(
      zero_flow = is.na(`Average.Daily.Flow..ADF...mgd.`) | `Average.Daily.Flow..ADF...mgd.` == 0,
      # Zero out TN when flow is absent
      Total.N = dplyr::if_else(zero_flow, NA_real_, Total.N),
      # TP: NA on zero flow; fill if a fill value is defined, else keep actual
      Total.P = dplyr::case_when(
        zero_flow         ~ NA_real_,
        !is.na(tp_fill)   ~ tp_fill,
        TRUE              ~ Total.P
      ),
      # TSS
      TSS = dplyr::case_when(
        zero_flow          ~ NA_real_,
        !is.na(tss_fill)   ~ tss_fill,
        TRUE               ~ TSS
      ),
      # BOD: bod_fill is always non-NA for these facilities
      BOD = dplyr::case_when(
        zero_flow          ~ NA_real_,
        !is.na(bod_fill)   ~ bod_fill,
        TRUE               ~ BOD
      ),
      # Standardise unit strings
      Total.N.Unit = dplyr::if_else(!is.na(Total.N), 'mg/L', ''),
      Total.P.Unit = dplyr::if_else(!is.na(Total.P), 'mg/L', ''),
      TSS.Unit     = dplyr::if_else(!is.na(TSS),     'mg/L', ''),
      BOD.Unit     = dplyr::if_else(!is.na(BOD),     'mg/L', '')
    ) |>
    dplyr::select(-zero_flow)

  # Lowry Park Zoo: September 2023 TN and TP filled with adjacent-month means
  # due to missing DMR measurement (per RP communication)
  if (fac_nm == 'Lowry Park Zoo') {
    out <- out |>
      dplyr::mutate(
        Total.N      = dplyr::if_else(Year == 2023L & Month == 9L, 0.967, Total.N),
        Total.P      = dplyr::if_else(Year == 2023L & Month == 9L, 0.17,  Total.P),
        Total.N.Unit = dplyr::if_else(!is.na(Total.N), 'mg/L', ''),
        Total.P.Unit = dplyr::if_else(!is.na(Total.P), 'mg/L', '')
      )
  }

  return(out)

}
