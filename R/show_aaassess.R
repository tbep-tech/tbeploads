#' Bay segment table of allocation assessment by entity and facility
#'
#' @param aa_data data frame returned by \code{\link{anlz_aa}} called with
#'   \code{annavg = TRUE}
#' @param bay_seg integer bay segment identifier, one of \code{1} (Old Tampa
#'   Bay), \code{2} (Hillsborough Bay), \code{3} (Middle Tampa Bay),
#'   \code{4} (Lower Tampa Bay), or \code{55} (Remaining Lower Tampa Bay).
#' @param digits numeric indicating decimal precision for the Allocated Tons
#'   and Effective Load columns. Default \code{1}. Allocation % is always
#'   shown to two decimal places with a percent sign, independent of
#'   \code{digits}.
#' @param family chr string indicating font family for text labels
#' @param txtsz numeric indicating font size
#'
#' @returns A \code{\link[flextable]{flextable}} object with one row per
#'   facility/source nested under its owning entity, and a bolded "Total" row
#'   for any entity with more than one facility/source in \code{bay_seg}.
#'
#' @details
#' Rows are organized by \strong{Entity}. An entity's block gathers every row that
#' applies to it in \code{bay_seg} regardless of \code{source} (e.g. an entity
#' with both IPS and Material Losses facilities gets one combined block and
#' one combined Total).
#'
#' \strong{Facility column}: The displayed \code{Facility} text combines
#' \code{facname} and \code{source}: IPS rows show \code{facname} as-is;
#' DPS rows append \code{" (end of pipe)"} or
#' \code{" (reuse)"}; Material Losses rows append \code{" (Material
#' Losses)"}; MS4 rows (no \code{facname}) show \code{"MS4"}.
#'
#' \strong{Entity Total row}: a "unit" is either one shared group or one
#' standalone facility/entity row. An entity gets a bolded \code{"Total"} row
#' when it has more than one unit (regardless of how many display rows those
#' units span), summing \code{alloc_tons}/\code{eff_load_tons} once per
#' unit. Entities with exactly one unit (every MS4 row, and
#' any entity with only one facility) get no Total row. Allocation % is left
#' blank on the Total row.
#'
#' @concept show
#'
#' @export
#'
#' @examples
#' \dontrun{
#' aa_data <- anlz_aa(c(2022, 2024), dps, ips, ml, nps, tbbase)
#' show_aaassess(aa_data, bay_seg = 2L)
#' }
show_aaassess <- function(aa_data, bay_seg, digits = 1, family = "Arial", txtsz = 11) {

  if ("year" %in% names(aa_data))
    stop("aa_data has a year column - call anlz_aa() with annavg = TRUE (the default)")

  if (length(bay_seg) != 1 || !bay_seg %in% c(1L, 2L, 3L, 4L, 55L))
    stop("bay_seg must be a single value, one of 1, 2, 3, 4, 55")

  dat <- aa_data[aa_data$bay_seg == bay_seg, ]
  if (nrow(dat) == 0)
    stop("no rows in aa_data for bay_seg = ", bay_seg)

  segment_label <- unique(dat$segment)[1]

  # Drop every source = NA row: both the negligible unmatched NPS/MS4
  # land-use slivers anlz_aa() leaves behind in some years, and the real
  # "All" (FDACS)/"Non-MS4/Ag NPS" aggregate rows. Unlike show_aaloads(),
  # this is an allocation assessment table - those two aggregates have no
  # real allocation (alloc_pct/alloc_tons are always NA for them) and are
  # not broken out in RP's real draft assessment tables either, so they do
  # not belong here at all.
  dat <- dat[!is.na(dat$source), ]

  entity_label <- dplyr::coalesce(dat$entity_full, dat$entity)

  facname_clean <- gsub("^Point Source\\s*-\\s*", "", dat$facname, ignore.case = TRUE)

  facility_label <- dplyr::case_when(
    dat$source %in% c("MS4", "Nonpoint Source/MS4") ~ "MS4",
    dat$source == "IPS" ~ facname_clean,
    dat$source == "DPS - end of pipe" ~ paste0(facname_clean, " (end of pipe)"),
    dat$source == "DPS - reuse" ~ paste0(facname_clean, " (reuse)"),
    dat$source == "ML" ~ paste0(facname_clean, " (Material Losses)"),
    TRUE ~ facname_clean
  )

  # Used only to order rows within an entity block (not shown in the table).
  # MS4 sorts last within its entity's block (rather than first) since an
  # entity combining MS4 with other source types is otherwise led by the
  # least distinctive row.
  section_rank <- dplyr::case_when(
    dat$source == "IPS" ~ 1L,
    dat$source == "DPS - end of pipe" ~ 2L,
    dat$source == "DPS - reuse" ~ 3L,
    dat$source == "ML" ~ 4L,
    dat$source %in% c("MS4", "Nonpoint Source/MS4") ~ 5L,
    TRUE ~ 6L
  )

  # A unit is one shared allocation group (group_id) or one standalone row.
  unit_key <- dplyr::coalesce(dat$group_id, paste0("solo_", seq_len(nrow(dat))))

  # RP's draft assessment workbook merges alloc_pct/alloc_tons AND
  # eff_load_tons into one combined cell for most shared groups (e.g. the
  # Kinder Morgan IPS group), but for the 19-facility Mosaic Hillsborough Bay
  # IPS group it merges only alloc_pct/alloc_tons - each facility's own
  # individual effective load is shown on its own row, confirmed directly
  # from that workbook. Hardcoded here since it's a per-group formatting
  # choice in the source table, not something derivable from aa_data.
  unmerged_load_groups <- c("ips_mosaic_hb")

  first_non_na <- function(x) {
    idx <- which(!is.na(x))
    if (length(idx) == 0) return(NA_real_)
    x[idx[1]]
  }

  dat2 <- tibble::tibble(
    entity_label   = entity_label,
    facility_label = facility_label,
    section_rank   = section_rank,
    alloc_pct      = dat$alloc_pct,
    alloc_tons     = dat$alloc_tons,
    eff_load_tons  = dat$eff_load_tons,
    unit_key       = unit_key
  ) |>
    dplyr::group_by(.data$unit_key) |>
    dplyr::mutate(
      unit_alloc_pct  = first_non_na(.data$alloc_pct),
      unit_alloc_tons = first_non_na(.data$alloc_tons),
      # the group's combined effective load - always computed (used for the
      # entity Total row regardless of display), but only shown/merged on
      # each member row when its group isn't in unmerged_load_groups
      unit_eff_load   = sum(.data$eff_load_tons, na.rm = TRUE),
      display_eff_load = dplyr::if_else(
        .data$unit_key %in% unmerged_load_groups,
        .data$eff_load_tons,
        .data$unit_eff_load
      ),
      # keeps a shared group's member rows contiguous after arrange() below,
      # even when another of the entity's units would otherwise sort between
      # them alphabetically by facility_label alone
      unit_sort_key   = min(.data$facility_label, na.rm = TRUE)
    ) |>
    dplyr::ungroup() |>
    dplyr::arrange(tolower(.data$entity_label), .data$section_rank,
                    .data$unit_sort_key, .data$facility_label)

  entity_units <- dat2 |>
    dplyr::distinct(.data$entity_label, .data$unit_key) |>
    dplyr::count(.data$entity_label, name = "n_units")

  needs_total <- entity_units$entity_label[entity_units$n_units > 1]

  entity_totals <- dat2 |>
    dplyr::distinct(.data$entity_label, .data$unit_key, .data$unit_alloc_pct,
                     .data$unit_alloc_tons, .data$unit_eff_load) |>
    dplyr::group_by(.data$entity_label) |>
    dplyr::summarise(
      total_alloc_tons = sum(.data$unit_alloc_tons, na.rm = TRUE),
      total_eff_load   = sum(.data$unit_eff_load, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::filter(.data$entity_label %in% needs_total)

  # Build display rows entity-by-entity, tracking row ranges for the merges
  # applied below (Entity column merged per entity block; Allocation %/
  # Allocated Tons/Effective Load merged per shared-group unit).
  row_idx <- 0L
  bold_idx <- integer(0)
  merge_specs <- list()
  out_rows <- list()

  entities_sorted <- unique(dat2$entity_label)

  for (ent in entities_sorted) {

    ent_rows <- dat2[dat2$entity_label == ent, ]
    ent_start <- row_idx + 1L

    u_keys <- unique(ent_rows$unit_key)
    for (uk in u_keys) {
      u_rows <- ent_rows[ent_rows$unit_key == uk, ]
      block_start <- row_idx + 1L
      for (i in seq_len(nrow(u_rows))) {
        row_idx <- row_idx + 1L
        out_rows[[row_idx]] <- tibble::tibble(
          Entity        = ent,
          Facility      = u_rows$facility_label[i],
          alloc_pct     = u_rows$unit_alloc_pct[i],
          alloc_tons    = u_rows$unit_alloc_tons[i],
          eff_load_tons = u_rows$display_eff_load[i]
        )
      }
      block_end <- row_idx
      if (block_end > block_start) {
        merge_specs[[length(merge_specs) + 1]] <- list(rows = block_start:block_end, col = "alloc_pct")
        merge_specs[[length(merge_specs) + 1]] <- list(rows = block_start:block_end, col = "alloc_tons")
        if (!(uk %in% unmerged_load_groups))
          merge_specs[[length(merge_specs) + 1]] <- list(rows = block_start:block_end, col = "eff_load_tons")
      }
    }

    ent_end <- row_idx

    if (ent %in% entity_totals$entity_label) {
      tot <- entity_totals[entity_totals$entity_label == ent, ]
      row_idx <- row_idx + 1L
      out_rows[[row_idx]] <- tibble::tibble(
        Entity        = ent,
        Facility      = "Total",
        alloc_pct     = NA_real_,
        alloc_tons    = tot$total_alloc_tons,
        eff_load_tons = tot$total_eff_load
      )
      bold_idx <- c(bold_idx, row_idx)
      ent_end <- row_idx
    }

    if (ent_end > ent_start)
      merge_specs[[length(merge_specs) + 1]] <- list(rows = ent_start:ent_end, col = "Entity")
  }

  tab <- dplyr::bind_rows(out_rows)
  tab$alloc_pct <- tab$alloc_pct * 100

  ft <- flextable::flextable(tab) |>
    flextable::set_header_labels(
      Entity = "Entity", Facility = "Facility",
      alloc_pct = "Allocation %", alloc_tons = "Allocated Tons",
      eff_load_tons = "Effective Load (tons/yr)"
    ) |>
    flextable::colformat_double(
      j = c("alloc_tons", "eff_load_tons"), digits = digits, na_str = ""
    ) |>
    flextable::colformat_double(
      j = "alloc_pct", digits = 2, suffix = "%", na_str = ""
    ) |>
    flextable::align(
      j = c("alloc_pct", "alloc_tons", "eff_load_tons"), align = "center", part = "all"
    ) |>
    # top-aligns the Entity column so a merged multi-row cell's text sits at
    # the top of its span instead of vertically centered
    flextable::valign(j = "Entity", valign = "top", part = "body") |>
    flextable::bold(i = bold_idx) |>
    flextable::border_inner() |>
    flextable::border_outer() |>
    flextable::set_caption(paste0(segment_label, " allocation assessment")) |>
    flextable::font(fontname = family, part = "all") |>
    flextable::fontsize(size = txtsz, part = "all") |>
    flextable::autofit()

  for (m in merge_specs) {
    j_idx <- which(names(tab) == m$col)
    ft <- flextable::merge_at(ft, i = m$rows, j = j_idx)
  }

  ft

}
