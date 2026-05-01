#' Allocation assessment for NPS/MS4 entities and IPS facilities
#'
#' @param yrrng Integer vector of years to include, e.g. \code{2022:2024}.
#' @param nps_data Data frame from \code{\link{anlz_nps}} called with
#'   \code{summ = 'basin'} and \code{summtime = 'year'}. Required columns:
#'   \code{Year}, \code{source}, \code{segment}, \code{basin}, \code{tn_load},
#'   \code{hy_load}.
#' @param ips_data Data frame from \code{\link{anlz_ips_facility}}. Required
#'   columns: \code{Year}, \code{Month}, \code{entity}, \code{facility},
#'   \code{coastco}, \code{tn_load}.
#' @param tbbase data frame containing polygon areas for the combined data 
#'   layer of bay segment, basin, jurisdiction, land use data, and soils, see details
#' @param corrections Data frame with columns \code{bay_seg}, \code{entity},
#'   \code{ad_tons}, and \code{project_tons}. Use \code{\link{aa_corrections}}
#'   as a zero-row placeholder when actual corrections are not yet available.
#'
#' @returns A data frame with one row per entity (NPS/MS4) or facility (IPS)
#'   per bay segment:
#' \describe{
#'   \item{bay_seg}{Integer bay segment identifier}
#'   \item{segment}{Bay segment name}
#'   \item{entity}{MS4 entity name or IPS operator name}
#'   \item{entity_full}{Full entity name from \code{\link{nps_allocations}}
#'     (NPS rows only)}
#'   \item{facname}{Facility name (IPS rows only)}
#'   \item{permit}{NPDES permit number (IPS rows only)}
#'   \item{source}{Allocation type: \code{"MS4"},
#'     \code{"Nonpoint Source/MS4"}, or \code{"IPS"}}
#'   \item{alloc_pct}{Fractional TN allocation (0-1)}
#'   \item{alloc_tons}{Allocation in TN tons per year}
#'   \item{eff_load_tons}{Mean hydrologically-normalized TN load (tons/yr),
#'     averaged over \code{yrrng}}
#'   \item{pass}{Logical: \code{eff_load_tons <= alloc_tons}; \code{NA} when
#'     allocation or effective load is missing}
#' }
#'
#' @details
#' Entities present in the computed loads but absent from the allocation tables
#' are retained in the output with \code{NA} allocation fields so that
#' unmatched entries are visible for troubleshooting.
#'
#' \strong{NPS/MS4 path}
#'
#' Basin-level NPS loads from \code{nps_data} are disaggregated to individual
#' MS4 entities using the output (created internally) from \code{\link{util_aa_npsfactors}}
#' that combines \code{\link{tbbase}}, \code{\link{rcclucsid}}, and \code{\link{emc}}
#' into:
#' 
#' \enumerate{
#'   \item \code{factor_tn} distributes basin TN load among land use classes.
#'   \item \code{factor_rc} distributes each land use class's load among
#'     entities proportional to area × runoff coefficient.
#' }
#'
#' Agricultural land use (category \code{"Agriculture"}) is attributed to the
#' aggregate entity \code{"All"} regardless of the underlying MS4 jurisdiction.
#'
#' After disaggregation, loads and 1992-1994 baseline water volumes are summed
#' across basins to the segment level. TN corrections (\code{ad_tons} +
#' \code{project_tons}) are subtracted before hydrologic normalization:
#'
#' \deqn{
#'   \text{eff\_tn} = (\text{tn\_entity} - \text{corr\_tons}) \times
#'   \frac{\text{mean\_h2o\_9294}}{\text{h2o\_entity}}
#' }
#'
#' Bay segments Terra Ceia Bay (6) and Manatee River (7) are merged into
#' segment 55 (Remaining Lower Tampa Bay) after disaggregation, consistent
#' with the \code{\link{hydro_baseline}} encoding and TBNMC reporting.
#' Boca Ciega Bay (segment 5) is excluded from the allocation framework.
#'
#' \strong{IPS path}
#'
#' Annual IPS facility TN loads are normalized using the same ratio:
#'
#' \deqn{
#'   \text{eff\_tn} = \text{tn\_load} \times
#'   \frac{\text{mean\_h2o\_9294}}{\text{basin\_nps\_h2o}}
#' }
#'
#' where \code{basin\_nps\_h2o} is the annual NPS water load from
#' \code{nps_data} for the same basin and year. Effective loads are summed
#' across basins per permit per bay segment, then averaged over \code{yrrng}.
#'
#' DPS (domestic wastewater) facilities are not included; they are outside the
#' TBNMC allocation framework.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' nps <- anlz_nps(
#'   yrrng  = c("2022-01-01", "2024-12-31"),
#'   tbbase = tbbase,
#'   rain   = rain,
#'   allwq  = allwq,
#'   allflo = allflo,
#'   vernafl = system.file("extdata/verna-raw.csv", package = "tbeploads"),
#'   summ     = "basin",
#'   summtime = "year"
#' )
#' fls <- list.files(system.file("extdata/", package = "tbeploads"),
#'   pattern = "ps_ind_", full.names = TRUE)
#' ips <- anlz_ips_facility(fls)
#' anlz_aa(2022:2024, nps, ips, tbbase, aa_corrections)
#' }
anlz_aa <- function(yrrng, nps_data, ips_data, tbbase, corrections) {

  # Segment name → bay_seg (Boca Ciega Bay = 5 is excluded from allocation)
  seg_bay <- c(
    "Old Tampa Bay"        = 1L,
    "Hillsborough Bay"     = 2L,
    "Middle Tampa Bay"     = 3L,
    "Lower Tampa Bay"      = 4L,
    "Terra Ceia Bay"       = 6L,
    "Manatee River"        = 7L,
    "Boca Ciega Bay South" = 55L
  )

  bay_label <- c(
    `1`  = "Old Tampa Bay",
    `2`  = "Hillsborough Bay",
    `3`  = "Middle Tampa Bay",
    `4`  = "Lower Tampa Bay",
    `55` = "Remaining Lower Tampa Bay"
  )

  # Basin remapping: nested basins merged in anlz_nps output
  remap_basins <- function(x) {
    dplyr::case_when(
      x %in% c("02303000", "02303330") ~ "02304500",
      x %in% c("02301000", "02301300") ~ "02301500",
      x == "02299950"                  ~ "LMANATEE",
      TRUE                             ~ x
    )
  }

  # ---- Shared: annual NPS basin loads (used by both paths) -----------------

  nps_annual <- nps_data |>
    dplyr::filter(.data$Year %in% yrrng, .data$source == "NPS") |>
    dplyr::mutate(bay_seg = seg_bay[.data$segment]) |>
    dplyr::filter(!is.na(.data$bay_seg)) |>
    dplyr::group_by(.data$bay_seg, .data$basin, .data$Year) |>
    dplyr::summarise(
      tn_load = sum(.data$tn_load, na.rm = TRUE),
      hy_load = sum(.data$hy_load, na.rm = TRUE),
      .groups = "drop"
    )

  # ---- NPS path ------------------------------------------------------------

  nps_factors <- util_aa_npsfactors(tbbase, rcclucsid, emc)

  # Disaggregate basin TN to entity × clucsid × year.
  # hy_load (full basin NPS water) is carried forward unchanged — it is the
  # normalization denominator for all entities in that basin, matching the SAS
  # approach where ratio1_2224 basin water overwrites any entity-level water.
  entity_clucsid <- nps_annual |>
    dplyr::left_join(nps_factors$tn, by = c("bay_seg", "basin")) |>
    dplyr::left_join(nps_factors$rc, by = c("bay_seg", "basin", "clucsid")) |>
    dplyr::mutate(
      entity    = dplyr::if_else(
        !is.na(.data$category) & .data$category == "Agriculture",
        "All",
        .data$entity
      ),
      tn_entity = .data$tn_load * .data$factor_tn * .data$factor_rc
    )

  # Sum TN over clucsids; carry one copy of basin hy_load per entity-basin-year
  entity_basin_yr <- entity_clucsid |>
    dplyr::group_by(.data$bay_seg, .data$basin, .data$entity, .data$Year) |>
    dplyr::summarise(
      tn_entity = sum(.data$tn_entity, na.rm = TRUE),
      hy_load   = dplyr::first(.data$hy_load),
      .groups = "drop"
    ) |>
    # Terra Ceia (6) and Manatee River (7) merge into 55 to match hydro_baseline
    dplyr::mutate(
      bay_seg = dplyr::if_else(.data$bay_seg %in% c(6L, 7L), 55L, .data$bay_seg)
    )

  # Attach 1992-1994 baseline water; sum across basins → bay_seg × entity × year.
  # Both hy_load and mean_h2o_9294 are summed as basin totals — the ratio of
  # their sums is the hydrologic normalization factor applied to entity TN.
  entity_seg_yr <- entity_basin_yr |>
    dplyr::left_join(hydro_baseline, by = c("bay_seg", "basin")) |>
    dplyr::group_by(.data$bay_seg, .data$entity, .data$Year) |>
    dplyr::summarise(
      tn_entity     = sum(.data$tn_entity,     na.rm = TRUE),
      hy_load       = sum(.data$hy_load,       na.rm = TRUE),
      mean_h2o_9294 = sum(.data$mean_h2o_9294, na.rm = TRUE),
      .groups = "drop"
    )

  # Sum corrections per bay_seg × entity (ad + project; 0 when absent)
  corr_summ <- corrections |>
    dplyr::group_by(.data$bay_seg, .data$entity) |>
    dplyr::summarise(
      corr_tons = sum(.data$ad_tons + .data$project_tons, na.rm = TRUE),
      .groups = "drop"
    )

  # Apply corrections, then normalize: eff_tn = tn_corrected × (mean9294 / basin_h2o)
  nps_normalized <- entity_seg_yr |>
    dplyr::left_join(corr_summ, by = c("bay_seg", "entity")) |>
    dplyr::mutate(
      corr_tons    = dplyr::coalesce(.data$corr_tons, 0),
      tn_corrected = .data$tn_entity - .data$corr_tons,
      eff_tn       = dplyr::if_else(
        .data$hy_load > 0,
        .data$tn_corrected * (.data$mean_h2o_9294 / .data$hy_load),
        NA_real_
      )
    )

  # Average effective TN over years
  nps_mean <- nps_normalized |>
    dplyr::group_by(.data$bay_seg, .data$entity) |>
    dplyr::summarise(
      eff_load_tons = mean(.data$eff_tn, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      eff_load_tons = dplyr::if_else(
        is.nan(.data$eff_load_tons), NA_real_, .data$eff_load_tons
      )
    )

  # Full join with allocations; retain unmatched rows on both sides
  nps_out <- nps_allocations |>
    dplyr::full_join(nps_mean, by = c("bay_seg", "entity")) |>
    dplyr::mutate(
      segment = bay_label[as.character(.data$bay_seg)],
      source  = .data$type,
      facname = NA_character_,
      permit  = NA_character_,
      pass    = dplyr::if_else(
        !is.na(.data$alloc_tons) & !is.na(.data$eff_load_tons),
        .data$eff_load_tons <= .data$alloc_tons,
        NA
      )
    ) |>
    dplyr::select(
      "bay_seg", "segment", "entity", "entity_full",
      "facname", "permit", "source",
      "alloc_pct", "alloc_tons", "eff_load_tons", "pass"
    )

  # ---- IPS path ------------------------------------------------------------

  # Industrial facility lookup with basin remapping to match nps_annual
  ips_fac <- facilities |>
    dplyr::filter(grepl("Industrial", .data$source)) |>
    dplyr::rename(bay_seg = "bayseg") |>
    dplyr::mutate(
      bay_seg = as.integer(.data$bay_seg),
      basin   = remap_basins(.data$basin)
    ) |>
    dplyr::filter(!is.na(.data$basin), !is.na(.data$permit)) |>
    dplyr::select("entity", "facname", "coastco", "bay_seg", "basin", "permit")

  # Annual IPS TN loads joined to facility metadata
  ips_annual <- ips_data |>
    dplyr::filter(.data$Year %in% yrrng) |>
    dplyr::group_by(.data$Year, .data$entity, .data$facility, .data$coastco) |>
    dplyr::summarise(tn_ips = sum(.data$tn_load, na.rm = TRUE), .groups = "drop") |>
    dplyr::left_join(ips_fac, by = c("entity", "coastco")) |>
    dplyr::filter(!is.na(.data$basin)) |>
    dplyr::select(-"facility")

  # Normalize per facility-basin-year using NPS basin water loads
  ips_normalized <- ips_annual |>
    dplyr::left_join(
      nps_annual |>
        dplyr::select("bay_seg", "basin", "Year", nps_h2o = "hy_load"),
      by = c("bay_seg", "basin", "Year")
    ) |>
    dplyr::left_join(hydro_baseline, by = c("bay_seg", "basin")) |>
    dplyr::mutate(
      eff_tn = dplyr::if_else(
        !is.na(.data$nps_h2o) & .data$nps_h2o > 0,
        .data$tn_ips * (.data$mean_h2o_9294 / .data$nps_h2o),
        NA_real_
      )
    )

  # Sum across basins per permit × entity × facname × bay_seg × year, then average
  ips_mean <- ips_normalized |>
    dplyr::group_by(.data$bay_seg, .data$entity, .data$facname, .data$permit, .data$Year) |>
    dplyr::summarise(eff_tn = sum(.data$eff_tn, na.rm = TRUE), .groups = "drop") |>
    dplyr::group_by(.data$bay_seg, .data$entity, .data$facname, .data$permit) |>
    dplyr::summarise(
      eff_load_tons = mean(.data$eff_tn, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      eff_load_tons = dplyr::if_else(
        is.nan(.data$eff_load_tons), NA_real_, .data$eff_load_tons
      )
    )

  # Full join with allocations on permit; retain unmatched on both sides
  ips_out <- ips_mean |>
    dplyr::full_join(
      ps_allocations |>
        dplyr::rename(entity_ps = "entity", facname_ps = "facname"),
      by = "permit"
    ) |>
    dplyr::mutate(
      entity  = dplyr::coalesce(.data$entity,     .data$entity_ps),
      facname = dplyr::coalesce(.data$facname,     .data$facname_ps),
      segment      = bay_label[as.character(.data$bay_seg)],
      source       = "IPS",
      entity_full  = NA_character_,
      pass         = dplyr::if_else(
        !is.na(.data$alloc_tons) & !is.na(.data$eff_load_tons),
        .data$eff_load_tons <= .data$alloc_tons,
        NA
      )
    ) |>
    dplyr::select(
      "bay_seg", "segment", "entity", "entity_full",
      "facname", "permit", "source",
      "alloc_pct", "alloc_tons", "eff_load_tons", "pass"
    )

  # ---- Combine -------------------------------------------------------------

  dplyr::bind_rows(nps_out, ips_out) |>
    dplyr::arrange(.data$bay_seg, .data$source, .data$entity)

}
