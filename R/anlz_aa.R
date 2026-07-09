#' Allocation assessment for DPS, IPS, and NPS/MS4 entities
#'
#' @param yrrng Integer vector of length 2, start and end year, e.g., \code{c(2022, 2024)}.
#' @param dps_data Data frame from \code{\link{anlz_dps_facility}}. Required
#'   columns: \code{Year}, \code{Month}, \code{entity}, \code{facility},
#'   \code{coastco}, \code{tn_load}.
#' @param ips_data Data frame from \code{\link{anlz_ips_facility}}. Required
#'   columns: \code{Year}, \code{Month}, \code{entity}, \code{facility},
#'   \code{coastco}, \code{tn_load}.
#' @param ml_data Data frame from \code{\link{anlz_ml_facility}}. Required
#'   columns: \code{Year}, \code{Month}, \code{entity}, \code{facility},
#'   \code{tn_load}.
#' @param nps_data Data frame from \code{\link{anlz_nps}} called with
#'   \code{summ = 'basin'} and \code{summtime = 'year'}. Required columns:
#'   \code{Year}, \code{source}, \code{segment}, \code{basin}, \code{tn_load},
#'   \code{hy_load}. TN loads represent NPS contributions only and are not
#'   corrected for point-source loads.
#' @param tbbase data frame containing polygon areas for the combined data
#'   layer of bay segment, basin, jurisdiction, land use data, and soils, see details
#' @returns A data frame with one row per entity (NPS/MS4) or facility (IPS)
#'   per bay segment:
#' \describe{
#'   \item{bay_seg}{Integer bay segment identifier}
#'   \item{segment}{Bay segment name}
#'   \item{entity}{MS4 entity name or facility operator}
#'   \item{entity_full}{Full entity name from \code{\link{nps_allocations}}
#'     (NPS rows only)}
#'   \item{facname}{Facility name (IPS, DPS, and non-shared ML rows)}
#'   \item{permit}{NPDES permit number (IPS rows only)}
#'   \item{source}{Allocation type: \code{"MS4"},
#'     \code{"Nonpoint Source/MS4"}, \code{"IPS"},
#'     \code{"DPS - end of pipe"}, \code{"DPS - reuse"}, or \code{"ML"}}
#'   \item{alloc_pct}{Fractional TN allocation (0-1)}
#'   \item{alloc_tons}{Allocation in TN tons per year}
#'   \item{eff_load_tons}{Mean hydrologically-normalized TN load (tons/yr),
#'     averaged over \code{yrrng}; equals \code{load_tons} for DPS and ML (no
#'     normalization applied) and for IPS facilities not flagged
#'     \code{hydro_affected} in \code{\link{ps_allocations}}. NPS/MS4 rows and
#'     \code{hydro_affected} IPS facilities are normalized}
#'   \item{load_tons}{Mean annual TN load (tons/yr) without hydrologic
#'     normalization, averaged over \code{yrrng}}
#'   \item{pass}{Logical: \code{eff_load_tons <= alloc_tons}; \code{NA} when
#'     allocation or effective load is missing}
#' }
#'
#' @details
#' Entities present in the computed loads but absent from the allocation tables
#' are retained in the output with \code{NA} allocation fields so that
#' unmatched entries are visible for troubleshooting.
#'
#' \strong{DPS path}
#'
#' DPS facility TN loads require no hydrologic normalization. Monthly loads
#' from \code{dps_data} are summed to annual totals per facility, averaged
#' over \code{yrrng}, and compared directly against the \code{\link{dps_allocations}}
#' table. The join key is \code{entity + facname + bay\_seg + source}, where
#' \code{source} distinguishes direct surface water discharge
#' (\code{"DPS - end of pipe"}) from reclaimed water reuse
#' (\code{"DPS - reuse"}). Bay segment 5 (Boca Ciega Bay) is excluded
#' and bayseg 6/7 are remapped to 55.
#'
#' \strong{IPS path}
#'
#' Raw facility loads are joined to facility metadata on \code{entity +
#' facname} (not \code{coastco}), since several distinct permits share a
#' single coastco. Monthly loads are summed to annual totals per permit per
#' bay segment and averaged over \code{yrrng}, matching RP's own draft
#' TN-loading tables, which apply hydrologic normalization to only a subset
#' of IPS facilities (mostly Mosaic mining operations, flagged via the
#' \code{hydro_affected} column added to \code{\link{ps_allocations}}) and
#' leave the rest unnormalized. For \code{hydro_affected} permits:
#'
#' \deqn{
#'   \text{eff\_tn} = \text{tn\_load} \times
#'   \frac{\text{mean\_h2o\_9294}}{\text{basin\_total\_h2o}}
#' }
#'
#' where \code{basin\_total\_h2o} is the annual total basin water load for
#' the same basin and year, computed differently depending on whether the
#' basin is gaged (per \code{\link{dbasing}}): for gaged basins, NPS water is
#' estimated from a stream gauge and so already reflects any upstream IPS +
#' DPS discharge, so \code{basin\_total\_h2o} is the NPS water alone; for
#' ungaged basins, the modeled NPS-only water excludes point-source
#' discharge entirely, so IPS and DPS water are added to it (matching the
#' SAS \code{ratio1\_2224} construction, which sums all three sources for
#' the same basin/year regardless of gage status). All other IPS facilities,
#' and any facility with no \code{ps_allocations} match, use the raw
#' (unnormalized) load.
#'
#' \strong{ML path}
#'
#' Material loss TN loads require no hydrologic normalization. Monthly loads
#' from \code{ml_data} are summed to annual totals per facility, averaged
#' over \code{yrrng}, and compared against the \code{\link{ml_allocations}}
#' table. Facilities with \code{ishared = FALSE} are assessed individually on
#' entity + facname + bay segment. Facilities with \code{ishared = TRUE}
#' (currently the three Mosaic facilities in Hillsborough Bay) have their
#' loads summed to an entity + bay segment total before comparison to the
#' single shared allocation.
#' 
#' \strong{NPS/MS4 path}
#'
#' TN loads in \code{nps_data} are NPS-only; no point-source correction is
#' applied to the input loads. Basin-level NPS loads are disaggregated to
#' individual MS4 entities using the output (created internally) from
#' \code{\link{util_aa_npsfactors}}
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
#' Before summing across CLUCSIDs, each entity's disaggregated TN load is
#' scaled by \code{(1 - conserv\_frac)} using \code{\link{conserv_correction}},
#' which provides entity- and CLUCSID-specific fractions of area times runoff
#' coefficient attributable to conservation land. This removes the conservation
#' land contribution that is absent from the tbeploads-built \code{\link{tbbase}}.
#'
#' After disaggregation, loads and 1992-1994 baseline water volumes are summed
#' across basins to the segment level. TN corrections from \code{\link{aa_corrections}}
#' (\code{ad_tons} + \code{project_tons}) are subtracted before hydrologic normalization:
#'
#' \deqn{
#'   \text{eff\_tn} = (\text{tn\_entity} - \text{corr\_tons}) \times
#'   \frac{\text{mean\_h2o\_9294}}{\text{total\_h2o}}
#' }
#'
#' \code{total_h2o} is the same gaged/ungaged-gated basin water quantity
#' described in the IPS path below (NPS water alone for gaged basins; NPS +
#' IPS + DPS for ungaged basins).
#'
#' Bay segments Terra Ceia Bay (6) and Manatee River (7) are merged into
#' segment 55 (Remaining Lower Tampa Bay) after disaggregation, consistent
#' with the \code{\link{hydro_baseline}} encoding and TBNMC reporting.
#' Boca Ciega Bay (segment 5) is excluded from the allocation framework.
#' 
#' @export
#'
#' @examples
#' \dontrun{
#' fls_dps <- list.files(system.file("extdata/", package = "tbeploads"),
#'   pattern = "ps_dom_", full.names = TRUE)
#' dps <- anlz_dps_facility(fls_dps)
#' fls_ips <- list.files(system.file("extdata/", package = "tbeploads"),
#'   pattern = "ps_ind_", full.names = TRUE)
#' ips <- anlz_ips_facility(fls_ips)
#' fls_ml <- list.files(system.file("extdata/", package = "tbeploads"),
#'   pattern = "ps_indml", full.names = TRUE)
#' ml <- anlz_ml_facility(fls_ml)
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
#' 
#' anlz_aa(c(2022, 2024), dps, ips, ml, nps, tbbase)
#' }
anlz_aa <- function(yrrng, dps_data, ips_data, ml_data, nps_data, tbbase) {

  yrrng <- seq(min(yrrng), max(yrrng))

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

  # ---- Shared: facility-to-basin lookups for total H2O normalization ------
  # SAS ratio1_2224 (the normalization denominator) sums NPS + DPS + IPS water
  # for each basin and year. Reproduce that here.

  ips_fac_h2o <- facilities |>
    dplyr::filter(grepl("Industrial", .data$source)) |>
    dplyr::rename(bay_seg = "bayseg") |>
    dplyr::mutate(
      bay_seg = as.integer(.data$bay_seg),
      basin   = remap_basins(.data$basin)
    ) |>
    dplyr::filter(!is.na(.data$basin), !is.na(.data$coastco)) |>
    dplyr::select("entity", "coastco", "bay_seg", "basin") |>
    dplyr::distinct()

  dps_fac_h2o <- facilities |>
    dplyr::filter(grepl("Domestic", .data$source)) |>
    dplyr::rename(bay_seg = "bayseg") |>
    dplyr::mutate(
      bay_seg = as.integer(.data$bay_seg),
      basin   = remap_basins(.data$basin)
    ) |>
    dplyr::filter(!is.na(.data$basin), !is.na(.data$coastco), .data$bay_seg != 5L) |>
    dplyr::select("entity", "coastco", "bay_seg", "basin") |>
    dplyr::distinct()

  # Gaged/ungaged basin classification from dbasing. Gaged basins' NPS water
  # is estimated from a stream gauge and so already reflects any upstream IPS
  # + DPS discharge; adding ips_basin_h2o/dps_basin_h2o on top would
  # double-count that water. Ungaged basins' NPS water is a modeled estimate
  # that excludes point-source discharge entirely, so it must be added back
  # in to reconstruct total basin water (see anlz_nps_psremove(), which
  # performs the mirror-image subtraction for TN loads).
  gagetype_lu <- dbasing |>
    dplyr::mutate(basin = remap_basins(.data$basin)) |>
    dplyr::select("basin", "gagetype") |>
    dplyr::distinct()

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

  # IPS basin H2O (million m3/yr)
  ips_basin_h2o <- ips_data |>
    dplyr::filter(.data$Year %in% yrrng) |>
    dplyr::group_by(.data$Year, .data$entity, .data$coastco) |>
    dplyr::summarise(hy_load_ips = sum(.data$hy_load, na.rm = TRUE), .groups = "drop") |>
    dplyr::left_join(ips_fac_h2o, by = c("entity", "coastco")) |>
    dplyr::filter(!is.na(.data$basin)) |>
    dplyr::group_by(.data$bay_seg, .data$basin, .data$Year) |>
    dplyr::summarise(hy_load_ips = sum(.data$hy_load_ips, na.rm = TRUE), .groups = "drop")

  # DPS basin H2O (million m3/yr; reuse already attenuated by anlz_dps_facility)
  dps_basin_h2o <- dps_data |>
    dplyr::filter(.data$Year %in% yrrng) |>
    dplyr::group_by(.data$Year, .data$entity, .data$coastco) |>
    dplyr::summarise(hy_load_dps = sum(.data$hy_load, na.rm = TRUE), .groups = "drop") |>
    dplyr::left_join(dps_fac_h2o, by = c("entity", "coastco")) |>
    dplyr::filter(!is.na(.data$basin)) |>
    dplyr::group_by(.data$bay_seg, .data$basin, .data$Year) |>
    dplyr::summarise(hy_load_dps = sum(.data$hy_load_dps, na.rm = TRUE), .groups = "drop")

  # Total basin H2O (matches SAS ratio1_2224 construction): for gaged basins,
  # NPS hy_load already IS the total (gauge-measured, inclusive of upstream
  # point-source discharge); for ungaged basins, IPS + DPS must be added to
  # the modeled NPS-only estimate to get the true total.
  nps_annual <- nps_annual |>
    dplyr::left_join(ips_basin_h2o, by = c("bay_seg", "basin", "Year")) |>
    dplyr::left_join(dps_basin_h2o, by = c("bay_seg", "basin", "Year")) |>
    dplyr::left_join(gagetype_lu, by = "basin") |>
    dplyr::mutate(
      total_h2o = dplyr::if_else(
        dplyr::coalesce(.data$gagetype, "Ungaged") == "Gaged",
        .data$hy_load,
        .data$hy_load +
          dplyr::coalesce(.data$hy_load_ips, 0) +
          dplyr::coalesce(.data$hy_load_dps, 0)
      )
    ) |>
    dplyr::select(-dplyr::any_of(c("hy_load_ips", "hy_load_dps", "gagetype")))

  # ---- NPS path ------------------------------------------------------------

  nps_factors <- util_aa_npsfactors(tbbase, rcclucsid, emc)

  # Disaggregate basin TN to entity × clucsid × year.
  # total_h2o (NPS+DPS+IPS basin water) is carried forward — it is the
  # normalization denominator for all entities in that basin, matching the SAS
  # ratio1_2224 construction (script 6) which sums all source water per basin.
  entity_clucsid <- nps_annual |>
    dplyr::left_join(nps_factors$tn, by = c("bay_seg", "basin"),
                     relationship = "many-to-many") |>
    dplyr::left_join(nps_factors$rc, by = c("bay_seg", "basin", "clucsid"),
                     relationship = "many-to-many") |>
    dplyr::mutate(
      entity    = dplyr::case_when(
        !is.na(.data$category) & .data$category == "Agriculture"  ~ "All",
        TRUE ~ .data$entity
      ),
      tn_entity = .data$tn_load * .data$factor_tn * .data$factor_rc
    )

  # Scale down MS4 entity TN by the conservation land fraction for each
  # basin x clucsid. Agriculture rows (entity = "All") are left unchanged.
  # conserv_correction rows with no matching basin/clucsid join as NA and
  # are skipped (coalesce to the unscaled value).
  entity_clucsid <- entity_clucsid |>
    dplyr::left_join(conserv_correction, by = c("bay_seg", "basin", "entity", "clucsid")) |>
    dplyr::mutate(
      tn_entity = dplyr::if_else(
        !is.na(.data$conserv_frac),
        .data$tn_entity * (1 - .data$conserv_frac),
        .data$tn_entity
      )
    ) |>
    dplyr::select(-"conserv_frac")

  # Sum TN over clucsids; carry one copy of basin total_h2o per entity-basin-year
  entity_basin_yr <- entity_clucsid |>
    dplyr::group_by(.data$bay_seg, .data$basin, .data$entity, .data$Year) |>
    dplyr::summarise(
      tn_entity = sum(.data$tn_entity, na.rm = TRUE),
      total_h2o = dplyr::first(.data$total_h2o),
      .groups = "drop"
    ) |>
    # Terra Ceia (6) and Manatee River (7) merge into 55 to match hydro_baseline
    dplyr::mutate(
      bay_seg = dplyr::if_else(.data$bay_seg %in% c(6L, 7L), 55L, .data$bay_seg)
    )

  # Attach 1992-1994 baseline water; sum across basins → bay_seg × entity × year.
  # Both total_h2o and mean_h2o_9294 are summed as basin totals — the ratio of
  # their sums is the hydrologic normalization factor applied to entity TN.
  entity_seg_yr <- entity_basin_yr |>
    dplyr::left_join(hydro_baseline, by = c("bay_seg", "basin")) |>
    dplyr::group_by(.data$bay_seg, .data$entity, .data$Year) |>
    dplyr::summarise(
      tn_entity     = sum(.data$tn_entity,     na.rm = TRUE),
      total_h2o     = sum(.data$total_h2o,     na.rm = TRUE),
      mean_h2o_9294 = sum(.data$mean_h2o_9294, na.rm = TRUE),
      .groups = "drop"
    )

  # Sum corrections per bay_seg × entity (ad + project; 0 when absent)
  corr_summ <- aa_corrections |>
    dplyr::group_by(.data$bay_seg, .data$entity) |>
    dplyr::summarise(
      corr_tons = sum(.data$ad_tons + .data$project_tons, na.rm = TRUE),
      .groups = "drop"
    )

  # Apply corrections, then normalize: eff_tn = tn_corrected × (mean9294 / total_h2o)
  nps_normalized <- entity_seg_yr |>
    dplyr::left_join(corr_summ, by = c("bay_seg", "entity"),
                     relationship = "many-to-one") |>
    dplyr::mutate(
      corr_tons    = dplyr::coalesce(.data$corr_tons, 0),
      tn_corrected = .data$tn_entity - .data$corr_tons,
      eff_tn       = dplyr::if_else(
        .data$total_h2o > 0,
        .data$tn_corrected * (.data$mean_h2o_9294 / .data$total_h2o),
        NA_real_
      )
    )

  # Sum over years then divide by length(yrrng); missing years contribute zero
  nps_mean <- nps_normalized |>
    dplyr::group_by(.data$bay_seg, .data$entity) |>
    dplyr::summarise(
      eff_load_tons = sum(.data$eff_tn,       na.rm = TRUE) / length(yrrng),
      load_tons     = sum(.data$tn_corrected, na.rm = TRUE) / length(yrrng),
      .groups = "drop"
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
      "alloc_pct", "alloc_tons", "eff_load_tons", "load_tons", "pass"
    )

  # ---- IPS path ------------------------------------------------------------

  # Industrial facility lookup with basin remapping to match nps_annual.
  # Joined below on entity + facname (not coastco): several distinct permits
  # share one coastco (e.g. Kinder Morgan Port Sutton and Tampaplex both sit
  # at coastco 528), so entity + coastco alone is not a unique key and would
  # cross-match a facility's raw load onto every other permit sharing its
  # coastco.
  ips_fac <- facilities |>
    dplyr::filter(grepl("Industrial", .data$source)) |>
    dplyr::rename(bay_seg = "bayseg") |>
    dplyr::mutate(
      bay_seg = as.integer(.data$bay_seg),
      basin   = remap_basins(.data$basin)
    ) |>
    dplyr::filter(!is.na(.data$basin), !is.na(.data$permit)) |>
    dplyr::select("entity", "facname", "bay_seg", "basin", "permit")

  # Annual IPS TN loads joined to facility metadata via entity + facname
  ips_annual <- ips_data |>
    dplyr::filter(.data$Year %in% yrrng) |>
    dplyr::group_by(.data$Year, .data$entity, .data$facility, .data$coastco) |>
    dplyr::summarise(tn_ips = sum(.data$tn_load, na.rm = TRUE), .groups = "drop") |>
    dplyr::left_join(ips_fac, by = c("entity", "facility" = "facname")) |>
    dplyr::filter(!is.na(.data$basin)) |>
    dplyr::rename(facname = "facility")

  # Normalize per facility-basin-year using total basin water loads (gated by
  # gagetype, see the shared nps_annual$total_h2o construction above).
  # Applied only to permits flagged hydro_affected in ps_allocations below —
  # RP's own draft loading tables mark a specific subset of IPS facilities
  # with a "Hydrologically Affected" row label; every other facility (and
  # any with no ps_allocations match) is left unnormalized.
  ips_normalized <- ips_annual |>
    dplyr::left_join(
      nps_annual |>
        dplyr::select("bay_seg", "basin", "Year", nps_h2o = "total_h2o"),
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

  # Sum across basins per permit × entity × facname × bay_seg × year, then
  # divide by length(yrrng) so missing years contribute zero
  ips_mean <- ips_normalized |>
    dplyr::group_by(.data$bay_seg, .data$entity, .data$facname, .data$permit, .data$Year) |>
    dplyr::summarise(
      tn_ips = sum(.data$tn_ips, na.rm = TRUE),
      eff_tn = sum(.data$eff_tn, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::group_by(.data$bay_seg, .data$entity, .data$facname, .data$permit) |>
    dplyr::summarise(
      load_tons        = sum(.data$tn_ips, na.rm = TRUE) / length(yrrng),
      eff_load_tons_hy  = sum(.data$eff_tn, na.rm = TRUE) / length(yrrng),
      .groups = "drop"
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
      eff_load_tons = dplyr::if_else(
        dplyr::coalesce(.data$hydro_affected, FALSE),
        .data$eff_load_tons_hy,
        .data$load_tons
      ),
      pass         = dplyr::if_else(
        !is.na(.data$alloc_tons) & !is.na(.data$eff_load_tons),
        .data$eff_load_tons <= .data$alloc_tons,
        NA
      )
    ) |>
    dplyr::select(
      "bay_seg", "segment", "entity", "entity_full",
      "facname", "permit", "source",
      "alloc_pct", "alloc_tons", "eff_load_tons", "load_tons", "pass"
    )

  # ---- DPS path ------------------------------------------------------------

  # Domestic facility lookup: recode source type and remap bay_seg encoding
  dps_fac <- facilities |>
    dplyr::filter(grepl("Domestic", .data$source)) |>
    dplyr::rename(bay_seg = "bayseg") |>
    dplyr::mutate(
      bay_seg = as.integer(.data$bay_seg),
      bay_seg = dplyr::if_else(.data$bay_seg %in% c(6L, 7L), 55L, .data$bay_seg),
      dps_source = dplyr::case_when(
        grepl("SW",    .data$source) ~ "DPS - end of pipe",
        grepl("REUSE", .data$source) ~ "DPS - reuse"
      )
    ) |>
    dplyr::filter(.data$bay_seg != 5L) |>
    dplyr::select("entity", "facname", "coastco", "bay_seg", "dps_source") |> 
    dplyr::distinct()

  # Annual DPS TN per entity + coastco + type + year; facname resolved via coastco join
  dps_annual <- dps_data |>
    dplyr::filter(.data$Year %in% yrrng) |>
    dplyr::mutate(
      dps_source = dplyr::case_when(
        grepl("^D", .data$source) ~ "DPS - end of pipe",
        grepl("^R", .data$source) ~ "DPS - reuse"
      )
    ) |>
    dplyr::group_by(.data$Year, .data$entity, .data$coastco, .data$dps_source) |>
    dplyr::summarise(tn_dps = sum(.data$tn_load, na.rm = TRUE), .groups = "drop") |>
    dplyr::left_join(dps_fac, by = c("entity", "coastco", "dps_source")) |>
    dplyr::filter(!is.na(.data$facname)) |>
    dplyr::group_by(.data$Year, .data$bay_seg, .data$entity, .data$facname, .data$dps_source) |>
    dplyr::summarise(tn_dps = sum(.data$tn_dps, na.rm = TRUE), .groups = "drop")

  # Sum over years then divide by length(yrrng); missing years contribute zero
  dps_mean <- dps_annual |>
    dplyr::group_by(.data$bay_seg, .data$entity, .data$facname, .data$dps_source) |>
    dplyr::summarise(
      eff_load_tons = sum(.data$tn_dps, na.rm = TRUE) / length(yrrng),
      .groups = "drop"
    )

  # Full join with DPS allocations; retain unmatched rows on both sides
  dps_out <- dps_allocations |>
    dplyr::rename(dps_source = "source") |>
    dplyr::full_join(dps_mean, by = c("entity", "facname", "bay_seg", "dps_source")) |>
    dplyr::mutate(
      segment   = bay_label[as.character(.data$bay_seg)],
      source    = .data$dps_source,
      permit    = NA_character_,
      alloc_pct = NA_real_,
      load_tons = .data$eff_load_tons,
      pass      = dplyr::if_else(
        !is.na(.data$alloc_tons) & !is.na(.data$eff_load_tons),
        .data$eff_load_tons <= .data$alloc_tons,
        NA
      )
    ) |>
    dplyr::select(
      "bay_seg", "segment", "entity", "entity_full",
      "facname", "permit", "source",
      "alloc_pct", "alloc_tons", "eff_load_tons", "load_tons", "pass"
    )

  # ---- ML path ------------------------------------------------------------

  # Material loss facility lookup: entity + facname → bay_seg (no basin or coastco)
  ml_fac <- facilities |>
    dplyr::filter(grepl("Material", .data$source)) |>
    dplyr::rename(bay_seg = "bayseg") |>
    dplyr::mutate(bay_seg = as.integer(.data$bay_seg)) |>
    dplyr::select("entity", "facname", "bay_seg")

  # Annual ML TN loads joined to facility metadata via entity + facname
  ml_annual <- ml_data |>
    dplyr::filter(.data$Year %in% yrrng) |>
    dplyr::group_by(.data$Year, .data$entity, .data$facility) |>
    dplyr::summarise(tn_ml = sum(.data$tn_load, na.rm = TRUE), .groups = "drop") |>
    dplyr::left_join(ml_fac, by = c("entity", "facility" = "facname")) |>
    dplyr::filter(!is.na(.data$bay_seg)) |>
    dplyr::rename(facname = "facility")

  # Sum over years then divide by length(yrrng); missing years contribute zero
  ml_mean <- ml_annual |>
    dplyr::group_by(.data$bay_seg, .data$entity, .data$facname) |>
    dplyr::summarise(
      eff_load_tons = sum(.data$tn_ml, na.rm = TRUE) / length(yrrng),
      .groups = "drop"
    )

  # Non-shared: one output row per facility; full join on entity + facname + bay_seg
  ml_out_ns <- ml_allocations |>
    dplyr::filter(!.data$ishared) |>
    dplyr::select(-"ishared") |>
    dplyr::full_join(ml_mean, by = c("entity", "facname", "bay_seg")) |>
    dplyr::mutate(
      segment     = bay_label[as.character(.data$bay_seg)],
      source      = "ML",
      entity_full = NA_character_,
      permit      = NA_character_,
      alloc_pct   = NA_real_,
      load_tons   = .data$eff_load_tons,
      pass        = dplyr::if_else(
        !is.na(.data$alloc_tons) & !is.na(.data$eff_load_tons),
        .data$eff_load_tons <= .data$alloc_tons,
        NA
      )
    ) |>
    dplyr::select(
      "bay_seg", "segment", "entity", "entity_full",
      "facname", "permit", "source",
      "alloc_pct", "alloc_tons", "eff_load_tons", "load_tons", "pass"
    )

  # Shared: sum loads across all facilities in the shared group (entity + bay_seg),
  # then compare to the single combined allocation
  shared_keys <- ml_allocations |>
    dplyr::filter(.data$ishared) |>
    dplyr::select("entity", "bay_seg") |>
    dplyr::distinct()

  ml_mean_shared <- ml_mean |>
    dplyr::semi_join(shared_keys, by = c("entity", "bay_seg")) |>
    dplyr::group_by(.data$bay_seg, .data$entity) |>
    dplyr::summarise(
      eff_load_tons = sum(.data$eff_load_tons, na.rm = TRUE),
      .groups = "drop"
    )

  ml_out_shared <- ml_allocations |>
    dplyr::filter(.data$ishared) |>
    dplyr::select(-"ishared", -"facname") |>
    dplyr::full_join(ml_mean_shared, by = c("entity", "bay_seg")) |>
    dplyr::mutate(
      segment     = bay_label[as.character(.data$bay_seg)],
      source      = "ML",
      entity_full = NA_character_,
      facname     = NA_character_,
      permit      = NA_character_,
      alloc_pct   = NA_real_,
      load_tons   = .data$eff_load_tons,
      pass        = dplyr::if_else(
        !is.na(.data$alloc_tons) & !is.na(.data$eff_load_tons),
        .data$eff_load_tons <= .data$alloc_tons,
        NA
      )
    ) |>
    dplyr::select(
      "bay_seg", "segment", "entity", "entity_full",
      "facname", "permit", "source",
      "alloc_pct", "alloc_tons", "eff_load_tons", "load_tons", "pass"
    )

  ml_out <- dplyr::bind_rows(ml_out_ns, ml_out_shared)

  # ---- Combine -------------------------------------------------------------

  dplyr::bind_rows(nps_out, ips_out, dps_out, ml_out) |>
    dplyr::arrange(.data$bay_seg, .data$source, .data$entity)

}
