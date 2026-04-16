#' Calculate spring loads to Hillsborough Bay
#'
#' @param tbwxlpth character string, file path to the Tampa Bay Water discharge Excel
#'   workbook (.xlsx) for Lithia and Buckhorn springs. The workbook must contain one sheet
#'   per device, named by device ID: 3381 (Lithia Minor), 4586 (Lithia Major),
#'   3388 (Buckhorn Upper), and 3649 (Buckhorn Lower). Each sheet must contain
#'   columns \code{DeviceID}, \code{MeasureDateTime}, \code{Value},
#'   \code{MeasureType}, and \code{Units}.
#' @param wqpth character string or \code{NULL} (default). File path to spring water
#'   quality data (.csv). Must contain columns \code{spring}, \code{year},
#'   \code{month}, \code{tn(mg/L)}, and \code{tp(mg/L)} with one row per sample.
#'   Spring names must match \code{"Lithia"}, \code{"Buckhorn"}, and
#'   \code{"Sulphur"}. When \code{NULL}, water quality data are retrieved
#'   automatically from external APIs. Lithia and Buckhorn concentrations are
#'   obtained from the Water Atlas API (SWFWMD stations 17805 and 18276) and
#'   Sulphur Spring concentrations are obtained via
#'   \href{https://tbep-tech.github.io/tbeptools/reference/read_importepc.html}{\code{read_importepc}} (EPC station 174).
#' @param yrrng integer vector of length 2, start and end year for the analysis,
#'   e.g. \code{c(2022, 2024)}.
#' @param summ `r summ_params('summ')`
#' @param summtime `r summ_params('summtime')`
#' @param sulphurflow data frame of daily Sulphur Spring discharge or \code{NULL} (default)
#'   to obtain from the USGS API.
#' @param verbose logical, if \code{TRUE} (default) progress messages are printed
#'   when water quality data are retrieved via API (\code{wqpth = NULL}).
#'
#' @details
#' Loads are calculated for Lithia, Buckhorn, and Sulphur springs, all of which
#' discharge to Hillsborough Bay (bay segment 2).
#'
#' \strong{Discharge data (Lithia and Buckhorn):}
#' The Excel workbook supplied in \code{tbwxlpth} contains one sheet per device.
#' Device IDs map to sub-springs as follows: 3381 = Lithia Minor, 4586 = Lithia
#' Major, 3388 = Buckhorn Upper, 3649 = Buckhorn Lower. Flow values in MGD are
#' converted to CFS (1 MGD = 1.547 CFS); values already in CFS are used as-is.
#' Lithia total flow is the sum of Minor and Major. Buckhorn total flow is Lower
#' minus Upper, because the two gauges bracket the spring input on the same
#' stream reach.
#'
#' Contact for gage data is Cathleen Jonas, <cjonas@tampabaywater.org>. Device IDs 3381, 4586, 3388, and 3649 should be bundled with requests for Tampa Bypass Canal data (device ID 957) and Bell Shoals data (device ID 4626) used in the NPS workflow.
#'
#' \strong{Discharge data (Sulphur Springs):}
#' Daily CFS values for station 02306000 are retrieved from the USGS NWIS API
#' via \code{\link{util_nps_getusgsflow}}. A data frame can also be
#' supplied via the \code{sulphurflow} argument.
#'
#' \strong{Interpolation:}
#' Because springs are assumed never to have zero discharge, all gaps in the
#' daily discharge record are filled by linear interpolation between observed
#' values (\code{\link[zoo]{na.approx}} with \code{rule = 2}). Leading or
#' trailing gaps are filled with the nearest observed value.
#'
#' \strong{Water quality data (file path):}
#' When \code{wqpth} is supplied, sample concentrations (mg/L) for TN and TP
#' are read from the CSV. These data are from FDEP's Impaired Waters Rule
#' dataset available at \url{https://publicfiles.dep.state.fl.us/dear/iwr/}.
#' Annual mean concentrations are computed per spring and joined to monthly flow
#' estimates. If a year within \code{yrrng} has no water quality observations for a given
#' spring, the grand mean across all available years is substituted.
#'
#' \strong{Water quality data (API, \code{wqpth = NULL}):}
#' When \code{wqpth} is \code{NULL}, water quality data are obtained using 
#' \code{\link{util_spr_getwq}}. Lithia (SWFWMD station
#' 17805, Lithia Main Spring) and Buckhorn (SWFWMD station 18276, Buckhorn Main
#' Spring) concentrations are retrieved from the
#' \href{https://dev.api.wateratlas.org}{Water Atlas API}
#' (\code{WIN_21FLSWFD} data source). These are probably the same quarterly SWFWMD
#' observations included in the FDEP IWR file. Sulphur Spring (EPC station
#' 174) is retrieved via \href{https://tbep-tech.github.io/tbeptools/reference/read_importepc.html}{\code{read_importepc}}, providing
#' monthly observations from the Environmental Protection Commission of
#' Hillsborough County.
#'
#' \strong{TSS concentrations:}
#' When \code{wqpth} is supplied, TSS concentrations are assigned from a fixed
#' lookup table derived from the historical SAS-based loading model (SPRMOD2).
#' When \code{wqpth = NULL}, TSS values from the API or EPC source are used
#' where available. Any spring-year with no observed TSS falls back to the same
#' fixed values. The fixed values are: Sulphur Springs (02306000) = 4.4 mg/L,
#' Buckhorn Springs (02301695) = 4.0 mg/L, Lithia Springs (02301600) = 4.0
#' mg/L.
#'
#' \strong{Load calculation:}
#' Monthly mean flows (CFS) are computed from the complete daily discharge
#' series. Loads are then:
#' \deqn{hy_load\,(m^3/month) = \overline{Q}_{cfs} \times 86400 \times \frac{365}{12} \times 28.32 \times 10^{-3}}
#' \deqn{load\,(tons/month) = hy_load \times C_{mg/L} \times 10^{-3} / 907.1847}
#'
#' \code{hy_load} is converted to million m3 in the final output.
#' 
#' \strong{Spatial summaries:}
#' `r summ_params('descrip')` For springs, valid options for \code{summ} are
#' \code{'spring'} (one row per spring per time period), \code{'basin'} (loads
#' summed within drainage basins. Lithia and Buckhorn combined into
#' \code{"Alafia River"}, Sulphur into \code{"Hillsborough River"}), and
#' \code{'segment'} (all springs summed to bay segment 2, Hillsborough Bay).
#'
#' @return A data frame whose structure depends on \code{summ}:
#' \itemize{
#'   \item \code{'spring'}: one row per spring per time period, with columns
#'     \code{source}, \code{spring}, \code{site}, \code{segment}, \code{yr},
#'     \code{mo} (dropped for annual), \code{hy_load} (1e6 m3), \code{tn_load} (tons), 
#'     \code{tp_load} (tons), and \code{tss_load} (tons).
#'   \item \code{'basin'}: one row per drainage basin per time period, with
#'     columns \code{source}, \code{majbasin}, \code{segment}, \code{yr},
#'     \code{mo} (dropped for annual), \code{hy_load} (1e6 m3), \code{tn_load} (tons),
#'     \code{tp_load} (tons), \code{tss_load} (tons).
#'   \item \code{'segment'}: one row per bay segment per time period, with
#'     columns \code{source}, \code{segment}, \code{yr}, \code{mo} (dropped for
#'     annual), \code{hy_load} (1e6 m3), \code{tn_load} (tons), \code{tp_load} (tons),
#'     \code{tss_load} (tons).
#' }
#' For annual output (\code{summtime = 'year'}), load columns are summed over
#' months.
#'
#' @export
#'
#' @examples
#' tbwxlpth <- system.file('extdata/sprflow2224.xlsx', package = 'tbeploads')
#' wqpth    <- system.file('extdata/sprwq2224.csv',    package = 'tbeploads')
#'
#' # monthly per-spring loads using a local water quality file
#' anlz_spr(tbwxlpth = tbwxlpth, wqpth = wqpth, yrrng = c(2022, 2024))
#'
#' # annual basin-level totals
#' anlz_spr(tbwxlpth = tbwxlpth, wqpth = wqpth, yrrng = c(2022, 2024),
#'           summ = 'basin', summtime = 'year')
#'
#' # monthly segment-level totals
#' anlz_spr(tbwxlpth = tbwxlpth, wqpth = wqpth, yrrng = c(2022, 2024),
#'           summ = 'segment')
#'
#' \dontrun{
#' # retrieve water quality from APIs automatically (no local file needed)
#' anlz_spr(tbwxlpth = tbwxlpth, yrrng = c(2022, 2024))
#' }
anlz_spr <- function(tbwxlpth, wqpth = NULL, yrrng = c(2022, 2024),
                     summ = c('spring', 'basin', 'segment'),
                     summtime = c('month', 'year'), sulphurflow = NULL,
                     verbose = TRUE) {

  summ     <- match.arg(summ)
  summtime <- match.arg(summtime)

  # device ID to spring / sub-spring lookup
  tbw_devices <- data.frame(
    deviceid  = c(3381L,    4586L,    3388L,     3649L),
    spring    = c("Lithia", "Lithia", "Buckhorn", "Buckhorn"),
    subspring = c("minor",  "major",  "upper",    "lower"),
    stringsAsFactors = FALSE
  )

  # TSS fixed concentrations (mg/L) from SAS SPRMOD2 historical loading model.
  # Values reflect the most recent period averages (last updated for 2021 data);
  # carried forward when no observed TSS is available.
  tss_site <- c(
    "02306000" = 4.4,  # Sulphur Spring
    "02301695" = 4.0,  # Buckhorn Spring
    "02301600" = 4.0   # Lithia Spring
  )

  # Basin assignment for each spring (from SAS SPRMOD3)
  basin_lookup <- data.frame(
    spring   = c("Lithia",       "Buckhorn",     "Sulphur"),
    majbasin = c("Alafia River", "Alafia River", "Hillsborough River"),
    stringsAsFactors = FALSE
  )

  date_seq <- seq.Date(
    as.Date(paste0(yrrng[1], "-01-01")),
    as.Date(paste0(yrrng[2], "-12-31")),
    by = "day"
  )

  # ---------------------------------------------------------------------------
  # 1. Read TBW discharge from Excel workbook (one sheet per device ID)
  # ---------------------------------------------------------------------------
  tbw_raw <- lapply(as.character(tbw_devices$deviceid), function(dev) {
    readxl::read_excel(tbwxlpth, sheet = dev) |>
      dplyr::rename_with(tolower) |>
      dplyr::rename(date = measuredatetime) |>
      dplyr::mutate(
        deviceid = as.integer(deviceid),
        date     = as.Date(date),
        value    = suppressWarnings(as.numeric(value)),
        # convert MGD to CFS if needed; spring sheets are already CFS
        flow_cfs = dplyr::if_else(toupper(units) == "MGD", value * 1.547, value)
      )
  }) |>
    dplyr::bind_rows() |>
    dplyr::inner_join(tbw_devices, by = "deviceid") |>
    dplyr::filter(!is.na(date), !is.na(flow_cfs),
                  lubridate::year(date) >= yrrng[1],
                  lubridate::year(date) <= yrrng[2]) |>
    dplyr::select(spring, subspring, date, flow_cfs)

  # ---------------------------------------------------------------------------
  # 2. Interpolate each sub-spring to a complete daily series
  # ---------------------------------------------------------------------------
  tbw_daily <- tbw_raw |>
    dplyr::group_by(spring, subspring) |>
    dplyr::group_modify(function(dat, key) {
      full <- dplyr::left_join(data.frame(date = date_seq), dat, by = "date")
      full$flow_cfs <- zoo::na.approx(full$flow_cfs, na.rm = FALSE, rule = 2)
      full
    }) |>
    dplyr::ungroup()

  # ---------------------------------------------------------------------------
  # 3. Combine sub-springs
  #    Lithia  : Minor + Major
  #    Buckhorn: Lower - Upper  (gauges bracket the spring on the same reach)
  # ---------------------------------------------------------------------------
  lithia_daily <- tbw_daily |>
    dplyr::filter(spring == "Lithia") |>
    dplyr::group_by(date) |>
    dplyr::summarise(flow_cfs = sum(flow_cfs, na.rm = TRUE), .groups = "drop") |>
    dplyr::mutate(spring = "Lithia", site = "02301600")

  buckhorn_daily <- tbw_daily |>
    dplyr::filter(spring == "Buckhorn") |>
    tidyr::pivot_wider(id_cols = date, names_from = subspring, values_from = flow_cfs) |>
    dplyr::mutate(flow_cfs = lower - upper) |>
    dplyr::select(date, flow_cfs) |>
    dplyr::mutate(spring = "Buckhorn", site = "02301695")

  # ---------------------------------------------------------------------------
  # 4. Retrieve Sulphur Spring (USGS 02306000) daily discharge via API
  # ---------------------------------------------------------------------------
  if (is.null(sulphurflow)) {
    sulphurflow <- util_nps_getusgsflow(
      site    = "02306000",
      yrrng   = paste0(yrrng, c("-01-01", "-12-31")),
      verbose = FALSE
    )
  }

  sulphur_daily <- sulphurflow |>
    dplyr::filter(site_no == "02306000") |>
    dplyr::select(date, flow_cfs) |>
    dplyr::full_join(data.frame(date = date_seq), by = "date") |>
    dplyr::arrange(date) |>
    dplyr::mutate(
      flow_cfs = zoo::na.approx(flow_cfs, na.rm = FALSE, rule = 2),
      spring   = "Sulphur",
      site     = "02306000"
    ) |>
    dplyr::filter(lubridate::year(date) >= yrrng[1],
                  lubridate::year(date) <= yrrng[2]) |>
    dplyr::select(date, flow_cfs, spring, site)

  # ---------------------------------------------------------------------------
  # 5. Combine all three springs and compute monthly mean flow (CFS)
  # ---------------------------------------------------------------------------
  monthly_flow <- dplyr::bind_rows(lithia_daily, buckhorn_daily, sulphur_daily) |>
    dplyr::mutate(yr = lubridate::year(date), mo = lubridate::month(date)) |>
    dplyr::group_by(spring, site, yr, mo) |>
    dplyr::summarise(flow_cfs = mean(flow_cfs, na.rm = TRUE), .groups = "drop")

  # ---------------------------------------------------------------------------
  # 6. Water quality: annual means per spring
  #    Source A (wqpth supplied): read from local CSV
  #    Source B (wqpth = NULL):   fetch from Water Atlas API + EPC via
  #                                util_spr_getwq()
  # ---------------------------------------------------------------------------
  if (!is.null(wqpth)) {

    wq_raw <- utils::read.csv(wqpth, check.names = FALSE, stringsAsFactors = FALSE)

    wq_annual <- wq_raw |>
      dplyr::rename(
        yr     = year,
        tn_mgl = `tn(mg/L)`,
        tp_mgl = `tp(mg/L)`
      ) |>
      dplyr::mutate(
        tn_mgl = suppressWarnings(as.numeric(tn_mgl)),
        tp_mgl = suppressWarnings(as.numeric(tp_mgl))
      ) |>
      dplyr::group_by(spring, yr) |>
      dplyr::summarise(
        tn_mgl = mean(tn_mgl, na.rm = TRUE),
        tp_mgl = mean(tp_mgl, na.rm = TRUE),
        .groups = "drop"
      ) |>
      dplyr::mutate(tss_mgl = NA_real_)  # TSS always from fixed lookup for file path

  } else {

    wq_annual <- util_spr_getwq(yrrng, verbose = verbose)

  }

  # Fill years within yrrng that have no TN/TP observations with the grand mean.
  # TSS is intentionally not filled here: NAs fall back to the fixed lookup below.
  wq_filled <- wq_annual |>
    tidyr::complete(spring, yr = yrrng[1]:yrrng[2]) |>
    dplyr::group_by(spring) |>
    dplyr::mutate(
      tn_mgl = dplyr::if_else(is.na(tn_mgl), mean(tn_mgl, na.rm = TRUE), tn_mgl),
      tp_mgl = dplyr::if_else(is.na(tp_mgl), mean(tp_mgl, na.rm = TRUE), tp_mgl)
    ) |>
    dplyr::ungroup()

  # ---------------------------------------------------------------------------
  # 7. Join flow and WQ; assign TSS; calculate loads
  #
  # hy_load (m3/month) = mean_cfs * 86400 s/d * (365/12) d/mo * 28.32 L/ft3 * 1e-3 m3/L
  # pollutant load (ton/month) = hy_load (m3) * C (mg/L) * 1e-3 / 907.1847 (kg/ton) to convert to tons
  # hy_load is converted to million m3 in the final output
  #
  # TSS: use observed value from wq_filled where available (API path); fall back
  # to fixed site-level constant when NA or NaN (both paths).
  # ---------------------------------------------------------------------------
  out <- monthly_flow |>
    dplyr::left_join(wq_filled, by = c("spring", "yr")) |>
    dplyr::mutate(
      tss_mgl = ifelse(
        is.na(tss_mgl) | is.nan(tss_mgl),
        unname(tss_site[site]),
        tss_mgl
      ),
      segment = 2L,
      source  = "SPRING",
      hy_load = flow_cfs * 86400 * (365 / 12) * 28.32 * 1e-3,
      tn_load  = hy_load * tn_mgl  * 1e-3 / 907.1847,  # convert kg to tons
      tp_load  = hy_load * tp_mgl  * 1e-3 / 907.1847,  # convert kg to tons
      tss_load = hy_load * tss_mgl * 1e-3 / 907.1847   # convert kg to tons
    ) |>
    dplyr::select(source, spring, site, segment, yr, mo,
                  hy_load, tn_load, tp_load, tss_load) |>
    dplyr::mutate(hy_load = hy_load / 1e6)  # convert to million m3

  # ---------------------------------------------------------------------------
  # 8. Spatial summarization (summ)
  # ---------------------------------------------------------------------------
  if (summ == 'basin') {

    out <- out |>
      dplyr::left_join(basin_lookup, by = "spring") |>
      dplyr::group_by(source, majbasin, segment, yr, mo) |>
      dplyr::summarise(
        hy_load = sum(hy_load, na.rm = TRUE),
        tn_load  = sum(tn_load,  na.rm = TRUE),
        tp_load  = sum(tp_load,  na.rm = TRUE),
        tss_load = sum(tss_load, na.rm = TRUE),
        .groups = "drop"
      )

  } else if (summ == 'segment') {

    out <- out |>
      dplyr::group_by(source, segment, yr, mo) |>
      dplyr::summarise(
        hy_load = sum(hy_load, na.rm = TRUE),
        tn_load  = sum(tn_load,  na.rm = TRUE),
        tp_load  = sum(tp_load,  na.rm = TRUE),
        tss_load = sum(tss_load, na.rm = TRUE),
        .groups = "drop"
      )

  }

  # ---------------------------------------------------------------------------
  # 9. Temporal summarization (summtime)
  # ---------------------------------------------------------------------------
  if (summtime == 'year') {

    if (summ == 'spring') {

      out <- out |>
        dplyr::group_by(source, spring, site, segment, yr) |>
        dplyr::summarise(
          hy_load  = sum(hy_load,   na.rm = TRUE),
          tn_load   = sum(tn_load,    na.rm = TRUE),
          tp_load   = sum(tp_load,    na.rm = TRUE),
          tss_load  = sum(tss_load,   na.rm = TRUE),
          .groups  = "drop"
        ) |>
        dplyr::arrange(spring, yr)

    } else if (summ == 'basin') {

      out <- out |>
        dplyr::group_by(source, majbasin, segment, yr) |>
        dplyr::summarise(
          hy_load = sum(hy_load, na.rm = TRUE),
          tn_load  = sum(tn_load,  na.rm = TRUE),
          tp_load  = sum(tp_load,  na.rm = TRUE),
          tss_load = sum(tss_load, na.rm = TRUE),
          .groups = "drop"
        ) |>
        dplyr::arrange(majbasin, yr)

    } else if (summ == 'segment') {

      out <- out |>
        dplyr::group_by(source, segment, yr) |>
        dplyr::summarise(
          hy_load = sum(hy_load, na.rm = TRUE),
          tn_load  = sum(tn_load,  na.rm = TRUE),
          tp_load  = sum(tp_load,  na.rm = TRUE),
          tss_load = sum(tss_load, na.rm = TRUE),
          .groups = "drop"
        ) |>
        dplyr::arrange(yr)

    }

  }

  return(out)

}
