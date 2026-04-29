#' Calculate groundwater loads to Tampa Bay segments
#'
#' @param pot_dry \code{\link[terra]{SpatRaster}} (or \code{PackedSpatRaster})
#'   of Upper Floridan Aquifer potentiometric head for the dry season, as
#'   returned by \code{\link{util_gw_getcontour}} with
#'   \code{season = "dry"}. The package dataset \code{\link{contdry}} contains
#'   a pre-computed 2022 example.
#' @param pot_wet \code{\link[terra]{SpatRaster}} (or \code{PackedSpatRaster})
#'   of Upper Floridan Aquifer potentiometric head for the wet season, as
#'   returned by \code{\link{util_gw_getcontour}} with
#'   \code{season = "wet"}. The package dataset \code{\link{contwet}} contains
#'   a pre-computed 2022 example.
#' @param yrrng integer vector of length 2, start and end year for the load
#'   estimates, e.g. \code{c(2022, 2024)}. The same gradients derived from
#'   \code{pot_dry} and \code{pot_wet} are applied to every year in the range.
#' @param wqdat data frame of Floridan aquifer TN and TP concentrations (mg/L)
#'   as returned by \code{\link{util_gw_getwq}}, with columns \code{bay_seg},
#'   \code{tn_mgl}, and \code{tp_mgl}. When \code{NULL} (default), hardcoded
#'   concentrations from the 2022-2024 loading analysis are used.
#' @param summtime character, temporal summarization: \code{'month'} (default)
#'   returns one row per segment per month, \code{'year'} sums to annual totals.
#'
#' @details
#' Estimates groundwater loads to each Tampa Bay segment for three aquifer
#' layers following the methodology in Zarbock et al. (1994).
#'
#' \strong{Floridan aquifer:}
#' Flow is computed with Darcy's Law:
#' \deqn{Q = 7.4805 \times 10^{-6} \cdot T \cdot I \cdot L}
#' where \eqn{T} is transmissivity (ft\eqn{^2}/day), \eqn{I} is the hydraulic
#' gradient (ft/mile), and \eqn{L} is the flow zone length (miles). \eqn{Q}
#' is in MGD. Nutrient loads (kg/month) are:
#' \deqn{\text{load} = Q \cdot C \cdot 8.342 \cdot 30.5 / 2.2}
#' where \eqn{C} is the TN or TP concentration (mg/L). Hydrologic load
#' (m\eqn{^3}/month) is \eqn{Q \cdot 3785 \cdot 30.5}.
#'
#' \strong{Hydraulic gradients:}
#' Gradients are computed once from \code{pot_dry} and \code{pot_wet} via
#' \code{\link{util_gw_grad}} and applied to every year in \code{yrrng}.
#' Update \code{pot_dry} and \code{pot_wet} with fresh outputs from
#' \code{\link{util_gw_getcontour}} when new FDEP potentiometric surface maps
#' become available. See \code{\link{util_gw_grad}} for details on search
#' areas, zero-gradient segments, and benchmark warnings.
#'
#' \strong{Surficial and intermediate aquifers:}
#' Loads are fixed constants per segment. Surficial values are from
#' \code{gwupdate95-98_final.xls} (1995-1998 SWFWMD monitoring data).
#' Intermediate values are means from SWFWMD monitoring over 1999-2003.
#' These have not changed since the original analysis.
#'
#' \strong{Season assignment:}
#' Months 1-6 and 11-12 are dry season; months 7-10 are wet season.
#'
#' @return A data frame with columns:
#' \itemize{
#'   \item \code{Year}: integer
#'   \item \code{Month}: integer (omitted when \code{summtime = 'year'})
#'   \item \code{source}: character, \code{"GW"}
#'   \item \code{segment}: character, bay segment name
#'   \item \code{tn_load}: numeric, total nitrogen load (tons/month or tons/year)
#'   \item \code{tp_load}: numeric, total phosphorus load (tons/month or tons/year)
#'   \item \code{hy_load}: numeric, hydrologic load (million m\eqn{^3}/month or
#'     million m\eqn{^3}/year)
#' }
#'
#' @references
#' Zarbock, H., A. Janicki, D. Wade, D. Heimbuch, and H. Wilson. 1994.
#' Estimates of Total Nitrogen, Total Phosphorus, and Total Suspended Solids
#' Loadings to Tampa Bay, Florida. Technical Publication #04-94. Prepared by
#' Coastal Environmental, Inc. Prepared for Tampa Bay National Estuary Program.
#' St. Petersburg, FL.
#'
#' @export
#'
#' @examples
#' # contdry and contwet are pre-computed 2022 package datasets
#' gw <- anlz_gw(contdry, contwet, yrrng = c(2022, 2024))
#' head(gw)
#'
#' # annual totals
#' anlz_gw(contdry, contwet, yrrng = c(2022, 2024), summtime = 'year')
#'
#' \dontrun{
#' # update rasters from FDEP for a new year, then compute loads
#' pot_dry <- util_gw_getcontour("dry", 2025)
#' pot_wet <- util_gw_getcontour("wet", 2025)
#' gw <- anlz_gw(pot_dry, pot_wet, yrrng = c(2025, 2025))
#'
#' # pass concentrations from the Water Atlas API
#' gw <- anlz_gw(pot_dry, pot_wet, yrrng = c(2025, 2025),
#'               wqdat = util_gw_getwq())
#' }
anlz_gw <- function(pot_dry, pot_wet, yrrng = c(2022, 2024), wqdat = NULL,
                    summtime = c('month', 'year')) {

  summtime <- match.arg(summtime)

  # -------------------------------------------------------------------------
  # 1. Floridan aquifer hydraulic gradient (I, ft/mile) per segment and season
  #    Gradients are derived once from the supplied rasters and applied to all
  #    years in yrrng.  Pass updated rasters from util_gw_getcontour() when
  #    new FDEP potentiometric surface maps are available.
  # -------------------------------------------------------------------------
  gd <- util_gw_grad(pot_dry, season = "dry")
  gw <- util_gw_grad(pot_wet, season = "wet")

  grad_df <- rbind(
    data.frame(season = "dry", gd, stringsAsFactors = FALSE),
    data.frame(season = "wet", gw, stringsAsFactors = FALSE)
  )
  grad_df <- grad_df[grad_df$bay_seg %in% 1L:7L, ]

  # -------------------------------------------------------------------------
  # 2. Floridan aquifer TN/TP concentrations (mg/L)
  # -------------------------------------------------------------------------
  if (is.null(wqdat)) {
    # Hardcoded concentrations from the 2022-2024 analysis.
    # Segments 1-2 updated from Pasco County well data (SWFWMD stations 18340
    # and 18965); segments 3-7 from gwupdate95-98_final.xls (unchanged since
    # 1995-1998 and used in every loading script through 2021).
    wqdat <- data.frame(
      bay_seg = 1L:7L,
      tn_mgl  = c(0.1000, (0.1000 + 0.4133) / 2,
                  0.025, 0.025, 0.022, 0.025, 0.025),
      tp_mgl  = c(0.0293, (0.0293 + 0.0283) / 2,
                  0.137, 0.137, 0.118, 0.125, 0.114)
    )
  }

  # -------------------------------------------------------------------------
  # 3. Floridan aquifer transmissivity (T, ft²/day) and flow zone length (L, miles)
  #    Source: Zarbock et al. (1994) Tampa Bay groundwater loading model
  # -------------------------------------------------------------------------
  fl_params <- data.frame(
    bay_seg = 1L:7L,
    t       = c( 48500, 150000, 66000, 66000, 48500, 100000, 100000),
    l       = c(32.0,  15.2,   8.0,   9.6,   8.5,   1.2,    7.2)
  )

  # -------------------------------------------------------------------------
  # 4. Fixed surficial and intermediate aquifer loads (kg/month; m3/month)
  #    Surficial: gwupdate95-98_final.xls (1995-1998 SWFWMD monitoring)
  #    Intermediate: SWFWMD monitoring means, 1999-2003
  # -------------------------------------------------------------------------
  fixed_loads <- data.frame(
    bay_seg = 1L:7L,
    tns     = c(0.56, 0.50, 0.53, 0.64, 0.38, 0.06, 0.36),
    tps     = c(2.24, 1.35, 3.06, 3.67, 3.59, 1.02, 6.31),
    h2os    = c(51123.2, 15095.2, 16580.5, 19896.6, 13212.6, 1813.5, 11191.8),
    tnin    = c(0.0, 0.5,  1.7,  0.5,  0.0, 0.1, 0.9),
    tpin    = c(0.0, 9.4,  13.2, 4.3,  0.0, 0.2, 2.6),
    h2oin   = c(0,   53200, 41115, 13489, 0,  1991, 21664)
  )

  # -------------------------------------------------------------------------
  # 5. Build monthly grid, assign season, join gradients
  # -------------------------------------------------------------------------
  grid <- expand.grid(
    Year    = seq(yrrng[1], yrrng[2]),
    Month   = 1L:12L,
    bay_seg = 1L:7L,
    stringsAsFactors = FALSE
  )

  grid$season <- ifelse(grid$Month %in% c(1:6, 11:12), "dry", "wet")

  grid <- merge(grid, grad_df,     by = c("season", "bay_seg"))
  grid <- merge(grid, wqdat,       by = "bay_seg")
  grid <- merge(grid, fl_params,   by = "bay_seg")
  grid <- merge(grid, fixed_loads, by = "bay_seg")

  # -------------------------------------------------------------------------
  # 6. Darcy's Law: Floridan aquifer flow (MGD) and monthly loads
  #    Q  (MGD)        = 7.4805e-6 * T * I * L
  #    tn/tpfl (kg/mo) = Q * C(mg/L) * 8.342(lb/gal) * 30.5(d/mo) / 2.2(lb/kg)
  #    h2ofl (m3/mo)   = Q * 3785(m3/MGal) * 30.5(d/mo)
  # -------------------------------------------------------------------------
  grid$q     <- 7.4805e-6 * grid$grad * grid$t * grid$l
  grid$tnfl  <- grid$q * grid$tn_mgl * 8.342 * 30.5 / 2.2
  grid$tpfl  <- grid$q * grid$tp_mgl * 8.342 * 30.5 / 2.2
  grid$h2ofl <- grid$q * 3785 * 30.5

  # -------------------------------------------------------------------------
  # 7. Total loads: Floridan + surficial + intermediate
  #    Convert: kg/month -> tons/month (/907.1847); m3/month -> Mm3 (/1e6)
  # -------------------------------------------------------------------------
  seg_names <- c(
    "1" = "Old Tampa Bay",    "2" = "Hillsborough Bay",
    "3" = "Middle Tampa Bay", "4" = "Lower Tampa Bay",
    "5" = "Boca Ciega Bay",   "6" = "Terra Ceia Bay",
    "7" = "Manatee River"
  )

  out <- data.frame(
    Year    = grid$Year,
    Month   = grid$Month,
    source  = "GW",
    segment = seg_names[as.character(grid$bay_seg)],
    tn_load = (grid$tnfl + grid$tns + grid$tnin) / 907.1847,
    tp_load = (grid$tpfl + grid$tps + grid$tpin) / 907.1847,
    hy_load = (grid$h2ofl + grid$h2os + grid$h2oin) / 1e6,
    stringsAsFactors = FALSE,
    row.names = NULL
  )

  out <- out[order(out$segment, out$Year, out$Month), ]

  if (summtime == 'year') {
    out <- aggregate(
      cbind(tn_load, tp_load, hy_load) ~ Year + source + segment,
      data = out,
      FUN  = sum
    )
    out <- out[order(out$segment, out$Year), ]
  }

  rownames(out) <- NULL
  out

}
