#' Create Pasco Reuse point source input data
#'
#' Create Pasco Reuse point source input data from external hydrologic volume inputs and a constant TN concentration
#'
#' @param yr integer vector of years
#' @param res numeric vector of residential reuse volumes (million gallons per year x 1000), one value per year
#' @param golf numeric vector of golf course reuse volumes (million gallons per year x 1000), one value per year
#' @param ribs numeric vector of rapid infiltration basin volumes (million gallons per year x 1000), one value per year
#' @param ag numeric vector of agricultural reuse volumes (million gallons per year x 1000), one value per year
#' @param tn_conc numeric, constant TN concentration in mg/L applied to all records (default \code{9})
#' @param n_coastal integer, number of coastal bay segment codes over which flow is divided equally (default \code{2})
#'
#' @details
#' Pasco County reuse hydrologic inputs are provided externally as annual volumes (in million gallons per year x 1000) broken into
#' land use categories: residential, golf courses, rapid infiltration basins (RIBs), and agriculture.
#' These are summed and converted to million gallons (MG) per year, then distributed evenly across
#' 12 months and divided equally across \code{n_coastal} coastal bay segment codes to produce average
#' daily flow in MGD.  A constant TN concentration of \code{tn_conc} mg/L is assumed.  TP, TSS, and
#' BOD are set to zero.
#'
#' The output format matches the standard point source input data frame used by \code{\link{anlz_dps_facility}}.
#'
#' @return A \code{data.frame} with one row per year-month combination and columns:
#' \describe{
#'   \item{Permit.Number}{character, \code{"PascoReuse"}}
#'   \item{Facility.Name}{character, \code{"Pasco Reuse"}}
#'   \item{Outfall.ID}{character, \code{"R-001"}}
#'   \item{Year}{integer}
#'   \item{Month}{integer, 1--12}
#'   \item{Average.Daily.Flow..ADF...mgd.}{numeric, average daily flow in MGD}
#'   \item{Total.N}{numeric, TN concentration in mg/L}
#'   \item{TN.Unit}{character, \code{"mg/l"}}
#'   \item{Total.P}{numeric, 0}
#'   \item{TP.Unit}{character, \code{"mg/l"}}
#'   \item{TSS}{numeric, 0}
#'   \item{TSS.Unit}{character, \code{"mg/l"}}
#'   \item{BOD}{numeric, 0}
#'   \item{BOD.Unit}{character, \code{"mg/l"}}
#' }
#'
#' @export
#'
#' @examples
#' util_ps_pascoreuse(
#'   yr   = 2022:2024,
#'   res  = c(744120, 522273, 344189),
#'   golf = c(0, 0, 0),
#'   ribs = c(0, 0, 0),
#'   ag   = c(169, 269, 153)
#' )
util_ps_pascoreuse <- function(yr, res, golf = rep(0, length(yr)), ribs = rep(0, length(yr)),
                               ag = rep(0, length(yr)), tn_conc = 9, n_coastal = 2) {

  # input checks
  n <- length(yr)
  stopifnot(
    "res must be the same length as yr"  = length(res)  == n,
    "golf must be the same length as yr" = length(golf) == n,
    "ribs must be the same length as yr" = length(ribs) == n,
    "ag must be the same length as yr"   = length(ag)   == n,
    "tn_conc must be a single positive number" = length(tn_conc) == 1 && tn_conc >= 0,
    "n_coastal must be a single positive integer" = length(n_coastal) == 1 && n_coastal > 0
  )

  out <- list(
      Year = yr,
      res  = res,
      golf = golf,
      ribs = ribs,
      ag   = ag
    ) |>
    data.frame() |>
    dplyr::mutate(
      MG = sum(res, golf, ribs, ag) / 1e3, # total MG per year
      .by = Year
    ) |>
    tidyr::crossing(Month = 1:12) |>
    dplyr::mutate(
      Permit.Number = 'PascoReuse',
      Facility.Name = 'Pasco Reuse',
      Outfall.ID    = 'R-001',
      Average.Daily.Flow..ADF...mgd. = MG / 12 / n_coastal /
        lubridate::days_in_month(lubridate::make_date(Year, Month, 1)),
      Total.N  = tn_conc,
      TN.Unit  = 'mg/l',
      Total.P  = 0,
      TP.Unit  = 'mg/l',
      TSS      = 0,
      TSS.Unit = 'mg/l',
      BOD      = 0,
      BOD.Unit = 'mg/l'
    ) |>
    dplyr::select(
      Permit.Number,
      Facility.Name,
      Outfall.ID,
      Year,
      Month,
      Average.Daily.Flow..ADF...mgd.,
      Total.N,
      TN.Unit,
      Total.P,
      TP.Unit,
      TSS,
      TSS.Unit,
      BOD,
      BOD.Unit
    )

  return(out)

}
