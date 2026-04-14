#' Calculate spring loads to Hillsborough Bay
#'
#' @param tbwpth character vector of file paths to TBW discharge data (tab-delimited .txt) for Lithia
#'   and Buckhorn springs. Files must contain columns: DeviceID, MeasureDateTime, Value, MeasureType,
#'   Units. Device IDs 3381 (Lithia Minor), 4586 (Lithia Major), 3388 (Buckhorn Upper), and 3649
#'   (Buckhorn Lower) are expected across one or more files.
#' @param wqpth character string, file path to spring water quality data (.xlsx). Expected to contain
#'   annual mean concentrations (mg/L) of TN, TP, and TSS by spring and year.
#' @param yrrng integer vector of length 2, start and end year for the analysis, e.g. \code{c(2021, 2021)}.
#' @param sulphurflow data frame of daily Sulphur Spring discharge already retrieved by
#'   \code{\link{util_nps_getusgsflow}}, or \code{NULL} (default) to fetch from the USGS API.
#'
#' @details
#' Loads are calculated for Lithia, Buckhorn, and Sulphur springs, all of which discharge to
#' Hillsborough Bay (bay segment 2).
#'
#' \strong{Discharge data (TBW -- Lithia and Buckhorn):}
#' Files provided in \code{tbwpth} contain weekly point measurements. Device IDs map to sub-springs as
#' follows: 3381 = Lithia Minor, 4586 = Lithia Major, 3388 = Buckhorn Upper, 3649 = Buckhorn Lower.
#' Flow values in MGD are converted to CFS (1 MGD = 1.547 CFS). Lithia total flow is the sum of
#' Minor and Major. Buckhorn total flow is Lower minus Upper, because the two gauges bracket the
#' spring input on the same stream reach.
#'
#' \strong{Discharge data (USGS -- Sulphur Spring):}
#' Daily CFS values for station 02306000 are retrieved from the USGS NWIS API via
#' \code{\link{util_nps_getusgsflow}}. A pre-fetched data frame can be supplied via the
#' \code{sulphurflow} argument to avoid a repeat API call.
#'
#' \strong{Interpolation:}
#' Because springs are assumed never to have zero discharge, all gaps in the daily discharge record
#' are filled by linear interpolation between observed values (\code{\link[zoo]{na.approx}} with
#' \code{rule = 2}). Leading or trailing gaps are filled with the nearest observed value.
#'
#' \strong{Water quality data:}
#' Annual mean concentrations (mg/L) for TN, TP, and TSS are derived from \code{wqpth}.
#' If a year within \code{yrrng} has no WQ observations for a given spring, the grand mean across
#' all available years is substituted.
#'
#' \strong{Load calculation:}
#' Monthly mean flows (CFS) are computed from the complete daily discharge series. Loads are then:
#' \deqn{h2oload\,(m^3/month) = \overline{Q}_{cfs} \times 86400 \times \frac{365}{12} \times 28.32 \times 10^{-3}}
#' \deqn{load\,(kg/month) = h2oload \times C_{mg/L} \times 10^{-3}}
#'
#' @return A data frame with one row per spring per month with columns:
#'   \code{source} ("SPRING"), \code{spring}, \code{site} (USGS station ID), \code{segment} (2),
#'   \code{yr}, \code{mo}, \code{flow_cfs} (monthly mean), \code{tn_mgl}, \code{tp_mgl},
#'   \code{tss_mgl}, \code{h2oload} (m3/month), \code{tnload} (kg/month), \code{tpload} (kg/month),
#'   \code{tssload} (kg/month).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' tbwpth <- c('3381_2021.txt', '4586_2021.txt', '3388_2021.txt', '3649_2021.txt')
#' anlz_spr(
#'   tbwpth  = tbwpth,
#'   wqpth   = 'Springs_WQ21RP.xlsx',
#'   yrrng   = c(2021, 2021)
#' )
#' }
anlz_spr <- function(tbwpth, wqpth, yrrng = c(2021, 2021), sulphurflow = NULL) {

  # device ID to spring / sub-spring lookup
  tbw_devices <- data.frame(
    deviceid  = c(3381L,         4586L,         3388L,            3649L),
    spring    = c("Lithia",      "Lithia",      "Buckhorn",       "Buckhorn"),
    subspring = c("minor",       "major",       "upper",          "lower"),
    stringsAsFactors = FALSE
  )

  date_seq <- seq.Date(
    as.Date(paste0(yrrng[1], "-01-01")),
    as.Date(paste0(yrrng[2], "-12-31")),
    by = "day"
  )

  # ---------------------------------------------------------------------------
  # 1. Read TBW discharge files (weekly point measurements)
  # ---------------------------------------------------------------------------
  tbw_raw <- lapply(tbwpth, function(f) {
    utils::read.delim(f, header = TRUE, sep = "\t", stringsAsFactors = FALSE,
                      na.strings = c("", "NA"))
  }) |>
    dplyr::bind_rows() |>
    dplyr::rename_with(tolower) |>
    dplyr::rename(date = measuredatetime) |>
    dplyr::mutate(
      deviceid = as.integer(deviceid),
      date     = as.Date(date, tryFormats = c("%m/%d/%Y %H:%M", "%m/%d/%Y", "%Y-%m-%d")),
      value    = suppressWarnings(as.numeric(value)),
      # convert MGD to CFS (1 MGD = 1.547 CFS); leave CFS unchanged
      flow_cfs = dplyr::if_else(toupper(units) == "MGD", value * 1.547, value)
    ) |>
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
      # linear interpolation; rule = 2 carries edge values for leading/trailing gaps
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
      site   = "02306000",
      yrrng  = paste0(yrrng, c("-01-01", "-12-31")),
      verbose = FALSE
    )
  }

  sulphur_daily <- sulphurflow |>
    dplyr::filter(site_no == "02306000") |>
    dplyr::select(date, flow_cfs) |>
    # fill to complete daily scaffold and interpolate any gaps
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
  # 6. Read water quality data and compute annual means per spring
  #
  # TODO: confirm column names in wqpth. The block below assumes the xlsx has
  #   columns for date (or year), spring name, TN (mg/L), TP (mg/L), TSS (mg/L).
  #   Rename/reformat as needed once the file structure is confirmed.
  # ---------------------------------------------------------------------------
  wq_raw <- readxl::read_excel(wqpth)

  # TODO: update the rename() and select() calls to match actual column names
  wq_annual <- wq_raw |>
    # dplyr::rename(date = <date_col>, spring = <spring_col>,
    #               tn_mgl = <tn_col>, tp_mgl = <tp_col>, tss_mgl = <tss_col>) |>
    dplyr::mutate(yr = lubridate::year(date)) |>
    dplyr::group_by(spring, yr) |>
    dplyr::summarise(
      tn_mgl  = mean(tn_mgl,  na.rm = TRUE),
      tp_mgl  = mean(tp_mgl,  na.rm = TRUE),
      tss_mgl = mean(tss_mgl, na.rm = TRUE),
      .groups = "drop"
    )

  # fill any years within yrrng that have no WQ data with grand mean per spring
  wq_filled <- wq_annual |>
    tidyr::complete(spring, yr = yrrng[1]:yrrng[2]) |>
    dplyr::group_by(spring) |>
    dplyr::mutate(
      tn_mgl  = dplyr::if_else(is.na(tn_mgl),  mean(tn_mgl,  na.rm = TRUE), tn_mgl),
      tp_mgl  = dplyr::if_else(is.na(tp_mgl),  mean(tp_mgl,  na.rm = TRUE), tp_mgl),
      tss_mgl = dplyr::if_else(is.na(tss_mgl), mean(tss_mgl, na.rm = TRUE), tss_mgl)
    ) |>
    dplyr::ungroup()

  # ---------------------------------------------------------------------------
  # 7. Join flow and WQ; calculate loads
  #
  # Load conversion (matching SAS SPRMOD2):
  #   h2oload (m3/month) = mean_cfs * 86400 s/day * (365/12) days/month * 28.32 L/ft3 * 1e-3 m3/L
  #   pollutant load (kg/month) = h2oload (m3) * 1000 L/m3 * C (mg/L) * 1e-6 kg/mg
  #                             = h2oload * C * 1e-3
  # ---------------------------------------------------------------------------
  out <- monthly_flow |>
    dplyr::left_join(wq_filled, by = c("spring", "yr")) |>
    dplyr::mutate(
      segment = 2L,   # all three springs drain to Hillsborough Bay
      source  = "SPRING",
      h2oload = flow_cfs * 86400 * (365 / 12) * 28.32 * 1e-3,
      tnload  = h2oload * tn_mgl  * 1e-3,
      tpload  = h2oload * tp_mgl  * 1e-3,
      tssload = h2oload * tss_mgl * 1e-3
    ) |>
    dplyr::select(source, spring, site, segment, yr, mo,
                  flow_cfs, tn_mgl, tp_mgl, tss_mgl,
                  h2oload, tnload, tpload, tssload)

  return(out)

}
