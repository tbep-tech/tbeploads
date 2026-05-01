#' Create NPS disaggregation factors for allocation assessment
#'
#' @param tbbase Data frame returned from \code{\link{util_nps_tbbase}} containing
#'   land use, soils, and jurisdiction data. Must include columns \code{bay_seg},
#'   \code{basin}, \code{drnfeat}, \code{entity}, \code{CLUCSID}, \code{hydgrp},
#'   and \code{area_ha}.
#' @param rcclucsid Data frame of runoff coefficients by land use class and
#'   hydrologic soil group. See \code{\link{rcclucsid}}.
#' @param emc Data frame of event mean concentrations by land use class. Must
#'   include columns \code{clucsid} and \code{mean_tn}. See \code{\link{emc}}.
#'
#' @returns A named list with two elements:
#' \describe{
#'   \item{rc}{Data frame of RC factors: \code{bay_seg}, \code{basin},
#'     \code{entity}, \code{category}, \code{clucsid}, \code{factor_rc}.
#'     \code{factor_rc} is each entity's fractional share of the weighted area ×
#'     runoff coefficient within each basin × CLUCSID combination. Sums to 1
#'     across all entities for each basin × CLUCSID.}
#'   \item{tn}{Data frame of TN factors: \code{bay_seg}, \code{basin},
#'     \code{clucsid}, \code{factor_tn}.
#'     \code{factor_tn} is each CLUCSID's fractional share of basin TN load,
#'     weighted by area × event mean TN concentration. Sums to 1 across all
#'     CLUCSIDs for each basin.}
#' }
#'
#' @details
#' These factors are used by \code{\link{anlz_aa}} to disaggregate basin-level
#' NPS loads to individual MS4 jurisdictions (entities).
#'
#' Two factors are required because the disaggregation is a two-step process
#' matching the original SAS workflow:
#'
#' \describe{
#'   \item{TN factor (\code{factor_tn})}{Distributes total basin TN load among
#'     land use classes. Based on area × event mean TN concentration per CLUCSID.
#'     Jurisdiction is not required, sums to basin total.}
#'   \item{RC factor (\code{factor_rc})}{Distributes each land use class's TN and
#'     water loads among MS4 entities based on each entity's share of that land
#'     use type's weighted runoff (area × runoff coefficient). Jurisdiction is
#'     required here, i.e., \code{tbbase} includes the entity overlay.}
#' }
#'
#' Annual runoff coefficient: \code{rc = (dry_rc * 8 + wet_rc * 4) / 12}.
#'
#' Basin remapping matches the SAS preprocessing: nested basins 02303000 and
#' 02303330 are assigned to 02304500; 02301000 and 02301300 to 02301500;
#' 02299950 to LMANATEE; basin 206-5 is assigned to bay_seg 55.
#' Basin 02307359 is excluded entirely.
#'
#' Non-contributing drainage features (\code{drnfeat == "NONCON"}) and
#' water/tidal CLUCSIDs (17, 21, 22) are excluded from both factors.
#'
#' Compound hydrologic soil groups (e.g., \code{"A/D"}) are simplified to
#' their primary group (\code{"A"}) before joining runoff coefficients.
#'
#' These factors are specific to a land use layer and should be rebuilt
#' whenever the underlying \code{tbbase} changes.
#'
#' @export
#'
#' @examples
#' data(tbbase)
#' data(rcclucsid)
#' data(emc)
#' nps_factors <- util_aa_npsfactors(tbbase, rcclucsid, emc)
util_aa_npsfactors <- function(tbbase, rcclucsid, emc) {

  # Basin remapping and exclusions to match SAS preprocessing
  remap_basins <- function(df) {
    df |>
      dplyr::mutate(
        basin = dplyr::case_when(
          basin %in% c("02303000", "02303330") ~ "02304500",
          basin %in% c("02301000", "02301300") ~ "02301500",
          basin == "02299950"                  ~ "LMANATEE",
          TRUE                                 ~ basin
        ),
        bay_seg = dplyr::if_else(basin == "206-5", 55L, as.integer(bay_seg))
      ) |>
      dplyr::filter(!basin %in% c("02307359"))
  }

  # Shared pre-processing: exclude non-contributing areas, water, and tidal
  # Simplify compound hydrologic soil groups (A/D -> A, etc.)
  base_clean <- tbbase |>
    dplyr::filter(drnfeat != "NONCON", !CLUCSID %in% c(17L, 21L, 22L)) |>
    dplyr::rename(clucsid = CLUCSID) |>
    dplyr::mutate(hydgrp = dplyr::case_when(
      hydgrp == "A/D" ~ "A",
      hydgrp == "B/D" ~ "B",
      hydgrp == "C/D" ~ "C",
      TRUE            ~ hydgrp
    )) |>
    remap_basins()

  # ---- RC factors -------------------------------------------------------
  # factor_rc = entity's share of (area x RC) for each basin x clucsid.
  # Jurisdiction is required: each entity owns a fraction of each land use
  # type's runoff within a basin, proportional to entity area x runoff coeff.

  rc_lookup <- rcclucsid |>
    dplyr::rename(hydgrp = hsg) |>
    dplyr::mutate(rc = (dry_rc * 8 + wet_rc * 4) / 12) |>
    dplyr::select(clucsid, hydgrp, rc)

  landbase <- base_clean |>
    dplyr::group_by(bay_seg, basin, entity, clucsid, hydgrp) |>
    dplyr::summarise(area_ha = sum(area_ha, na.rm = TRUE), .groups = "drop") |>
    dplyr::left_join(rc_lookup, by = c("clucsid", "hydgrp")) |>
    dplyr::mutate(mult = area_ha * rc)

  clucs_totals <- landbase |>
    dplyr::group_by(bay_seg, basin, clucsid) |>
    dplyr::summarise(total_mult = sum(mult, na.rm = TRUE), .groups = "drop")

  rc_factors <- landbase |>
    dplyr::left_join(clucs_totals, by = c("bay_seg", "basin", "clucsid")) |>
    dplyr::mutate(
      factor_rc = dplyr::if_else(total_mult > 0, mult / total_mult, 0),
      category  = dplyr::case_when(
        clucsid %in% c(8L, 10L, 11L, 12L, 13L, 14L)    ~ "Agriculture",
        clucsid %in% c(6L, 9L, 15L, 16L, 18L, 19L, 20L) ~ "Other",
        TRUE                                              ~ NA_character_
      )
    ) |>
    dplyr::group_by(bay_seg, basin, entity, category, clucsid) |>
    dplyr::summarise(factor_rc = sum(factor_rc, na.rm = TRUE), .groups = "drop")

  # ---- TN factors -------------------------------------------------------
  # factor_tn = clucsid's share of basin TN load.
  # No entity breakdown needed — jurisdiction is not required for TN factors.

  tn_base <- base_clean |>
    dplyr::group_by(bay_seg, basin, clucsid) |>
    dplyr::summarise(area_ha = sum(area_ha, na.rm = TRUE), .groups = "drop") |>
    dplyr::left_join(emc |> dplyr::select(clucsid, mean_tn), by = "clucsid") |>
    dplyr::mutate(mult = area_ha * mean_tn)

  basin_totals <- tn_base |>
    dplyr::group_by(bay_seg, basin) |>
    dplyr::summarise(total_mult = sum(mult, na.rm = TRUE), .groups = "drop")

  tn_factors <- tn_base |>
    dplyr::left_join(basin_totals, by = c("bay_seg", "basin")) |>
    dplyr::mutate(factor_tn = dplyr::if_else(total_mult > 0, mult / total_mult, 0)) |>
    dplyr::select(bay_seg, basin, clucsid, factor_tn)

  list(rc = rc_factors, tn = tn_factors)

}
