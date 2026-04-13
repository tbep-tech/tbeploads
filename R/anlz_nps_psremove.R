#' Remove point source loads from non-point source load estimates
#'
#' Subtract gaged industrial and domestic point source loads from NPS model
#' output to isolate true non-point source loads.
#'
#' @param nps data frame of NPS loads from \code{\link{anlz_nps}} with
#'   \code{summ = 'basin'} and \code{summtime = 'month'}
#' @param ips data frame of IPS loads from \code{\link{anlz_ips}} with
#'   \code{summ = 'basin'} and \code{summtime = 'month'}
#' @param dps data frame of DPS loads from \code{\link{anlz_dps}} with
#'   \code{summ = 'basin'} and \code{summtime = 'month'}
#' @param ad_ap logical, whether to apply fixed monthly AD/AP TN reductions
#'   from the 2007 RA allocation analysis. Default \code{TRUE}.
#' @param summtime character, one of \code{'month'} or \code{'year'}.
#'   Controls whether the output is monthly or annual. Default is \code{'month'}.
#'
#' @details
#' Gaged NPS loads (estimated from stream gauges) include point source loads
#' discharged upstream of the gauge. This function subtracts IPS and DPS loads
#' in gaged basins from the combined NPS model output so that point source
#' contributions are not double-counted.
#'
#' Only IPS and DPS records in gaged basins (identified via \code{\link{dbasing}})
#' are subtracted. Nested basin identifiers (02301000, 02301300 → 02301500;
#' 02303000, 02303330 → 02304500; 02299950 → LMANATEE) are reassigned to their
#' parent basins before summing, consistent with the handling in
#' \code{\link{anlz_nps}}.
#'
#' When \code{ad_ap = TRUE}, fixed monthly TN reductions from the 2007 RA
#' allocation analysis (AD/AP) are subtracted from the segment-level NPS totals.
#' These values represent the annual reduction divided into monthly increments:
#' \describe{
#'   \item{Old Tampa Bay}{-2.41 short tons/month}
#'   \item{Hillsborough Bay}{-4.31 short tons/month}
#'   \item{Middle Tampa Bay}{-2.29 short tons/month}
#'   \item{Lower Tampa Bay}{-0.36 short tons/month}
#'   \item{Manatee River}{-2.74 short tons/month (representing the combined
#'     reduction for segments 55, 6, and 7 as applied in the 2022-2024 RA)}
#' }
#' Other segments (Boca Ciega Bay, Boca Ciega Bay South, Terra Ceia Bay) receive
#' no AD/AP adjustment.
#'
#' @return data frame with columns for \code{Year}, \code{Month} (if
#'   \code{summtime = 'month'}), \code{source} (always \code{"NPS"}),
#'   \code{segment}, \code{tn_load}, \code{tp_load}, \code{tss_load},
#'   \code{bod_load}, and \code{hy_load}.  Loads are in short tons per month or
#'   year; hydrologic load is in cubic meters per month or year.  Column order
#'   matches the output of \code{\link{anlz_ips}} and \code{\link{anlz_dps}}.
#'
#' @seealso \code{\link{anlz_nps}}, \code{\link{anlz_ips}}, \code{\link{anlz_dps}}
#'
#' @export
#'
#' @examples
#' \dontrun{
#' nps <- anlz_nps(yrrng = c('2021-01-01', '2023-12-31'), tbbase = tbbase,
#'   rain = rain, allwq = allwq, allflo = allflo, vernafl = vernafl,
#'   summ = 'basin', summtime = 'month')
#'
#' ipsfls <- list.files(system.file('extdata/', package = 'tbeploads'),
#'   pattern = 'ps_ind_', full.names = TRUE)
#' dpsfls <- list.files(system.file('extdata/', package = 'tbeploads'),
#'   pattern = 'ps_dom', full.names = TRUE)
#'
#' ips <- anlz_ips(ipsfls, summ = 'basin', summtime = 'month')
#' dps <- anlz_dps(dpsfls, summ = 'basin', summtime = 'month')
#'
#' anlz_nps_psremove(nps, ips, dps)
#' }
anlz_nps_psremove <- function(nps, ips, dps, ad_ap = TRUE,
                              summtime = c('month', 'year')) {

  summtime <- match.arg(summtime)

  # Gaged basins from the package lookup table
  gaged_basins <- dbasing |>
    dplyr::select(basin, gagetype) |>
    dplyr::distinct() |>
    dplyr::filter(gagetype == "Gaged") |>
    dplyr::pull(basin)

  # Nested basin reassignment (mirrors anlz_nps handling)
  reassign_basins <- function(x) {
    dplyr::case_when(
      x == "02301000" ~ "02301500",
      x == "02301300" ~ "02301500",
      x == "02303000" ~ "02304500",
      x == "02303330" ~ "02304500",
      x == "02299950" ~ "LMANATEE",
      TRUE ~ x
    )
  }

  # Subset IPS and DPS to gaged basins and negate loads
  ips_gaged <- ips |>
    dplyr::filter(basin %in% gaged_basins) |>
    dplyr::mutate(
      dplyr::across(dplyr::contains("load"), ~ .x * -1),
      source = "NPS"
    )

  dps_gaged <- dps |>
    dplyr::filter(basin %in% gaged_basins) |>
    dplyr::mutate(
      dplyr::across(dplyr::contains("load"), ~ .x * -1),
      source = "NPS"
    )

  # Combine NPS model output with negated gaged PS loads; reassign nested basins
  combined <- dplyr::bind_rows(nps, ips_gaged, dps_gaged) |>
    dplyr::mutate(basin = reassign_basins(basin))

  # Sum all sources to monthly segment totals
  monthly <- combined |>
    dplyr::summarise(
      dplyr::across(dplyr::contains("load"), ~ sum(.x, na.rm = TRUE)),
      .by = c(Year, Month, segment)
    ) |>
    dplyr::mutate(source = "NPS") |>
    dplyr::select(Year, Month, source, segment,
                  tn_load, tp_load, tss_load, bod_load, hy_load) |>
    dplyr::arrange(segment, Year, Month)

  # Apply AD/AP monthly TN reductions (short tons/month) if requested
  if (ad_ap) {
    adap_tn <- data.frame(
      segment        = c("Old Tampa Bay", "Hillsborough Bay",
                         "Middle Tampa Bay", "Lower Tampa Bay", "Manatee River"),
      adap_reduction = c(2.41, 4.31, 2.29, 0.36, 2.74),
      stringsAsFactors = FALSE
    )
    monthly <- monthly |>
      dplyr::left_join(adap_tn, by = "segment") |>
      dplyr::mutate(
        tn_load        = tn_load - dplyr::coalesce(adap_reduction, 0),
        adap_reduction = NULL
      )
  }

  if (summtime == 'year') {
    out <- monthly |>
      dplyr::summarise(
        dplyr::across(dplyr::contains("load"), ~ sum(.x, na.rm = TRUE)),
        .by = c(Year, source, segment)
      ) |>
      dplyr::arrange(segment, Year)
  } else {
    out <- monthly
  }

  return(out)

}
