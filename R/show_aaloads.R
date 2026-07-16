#' Bay segment table of TN loads by year
#'
#' @param aa_data data frame returned by \code{\link{anlz_aa}} called with
#'   \code{annavg = FALSE}
#' @param bay_seg integer bay segment identifier, one of \code{1L} (Old Tampa
#'   Bay), \code{2L} (Hillsborough Bay), \code{3L} (Middle Tampa Bay),
#'   \code{4L} (Lower Tampa Bay), or \code{55L} (Remaining Lower Tampa Bay).
#' @param gw_data data frame returned by \code{\link{anlz_gw}} called with
#'   \code{summtime = 'year'}.
#' @param spr_data data frame returned by \code{\link{anlz_spr}} called with
#'   \code{summ = 'segment'} and \code{summtime = 'year'}.
#' @param ad_data data frame returned by \code{\link{anlz_ad}} called with
#'   \code{summ = 'segment'} and \code{summtime = 'year'}.
#' @param yrrng optional integer vector of length 2 restricting the displayed
#'   years to a subset of those already present in \code{aa_data}. Default
#'   \code{NULL} shows all years present.
#' @param digits numeric indicating decimal precision for the year columns.
#'   Default \code{1}.
#' @param family chr string indicating font family for text labels
#' @param txtsz numeric indicating font size
#'
#' @returns A \code{\link[flextable]{flextable}} object with one row per
#'   entity/facility in \code{bay_seg}, grouped into sections by source, and one
#'   column per year.
#'
#' @details
#' Rows are grouped into sections using \code{aa_data}'s \code{source}
#' column: \code{"MS4"} (\code{source} of \code{"MS4"} or
#' \code{"Nonpoint Source/MS4"}), \code{"Industrial Point Source"}
#' (\code{source == "IPS"}), \code{"Domestic Point Source - end of pipe"}
#' and \code{"Domestic Point Source - reuse"} (\code{source == "DPS - end of
#' pipe"}/\code{"DPS - reuse"}), \code{"Material Losses"} (\code{source ==
#' "ML"}), and \code{"Nonpoint Source"} (the
#' \code{"All"} (FDACS) and \code{"Non-MS4/Ag NPS"} aggregate rows from
#' \code{aa_data}, plus two rows built from \code{gw_data}/\code{spr_data}/
#' \code{ad_data} - see below; other unmatched \code{source = NA} rows in
#' \code{aa_data} are negligible land-use slivers dropped by
#' \code{\link{anlz_aa}} at its 0.01 tons/yr threshold in most years but not
#' all, and are excluded here rather than shown as a spurious partial row).
#' Each facility/entity keeps its own row, even for \code{ishared}
#' shared-allocation groups (see \code{\link{anlz_aa}}). Row labels combine
#' the owning entity with the facility name (e.g., \code{"Mosaic - Riverview"}).
#'
#' \strong{Atmospheric Deposition and Other (Groundwater, Springs,
#' Conservation)}: \code{gw_data}, \code{spr_data}, and \code{ad_data} are mapped
#' to \code{bay_seg} the same way \code{\link{anlz_aa}} does internally
#' (Terra Ceia Bay and Manatee River summed into segment 55; Boca Ciega Bay
#' variants dropped, consistent with the allocation framework's existing
#' exclusion) and filtered to the requested \code{bay_seg}. \code{ad_data}'s
#' \code{tn_load} becomes the \code{"Atmospheric Deposition"} row.
#' \code{gw_data}'s and \code{spr_data}'s \code{tn_load} (\code{spr_data}
#' only has rows for Hillsborough Bay - other segments that have no contribution
#' receive \code{0}) plus \code{aa_data}'s \code{seg_conserv_tn} (TN removed by the
#' conservation-land correction already computed inside \code{anlz_aa()},
#' exposed as a segment total rather than sourced separately) become the
#' \code{"Other (Groundwater, Springs, Conservation)"} row. Both are
#' zero-filled for years with no matching input, same as facility/entity
#' rows.
#'
#' A facility/entity with a real allocation but no load data for a given
#' year (or any year at all) is \code{NA} in \code{aa_data} by design (see
#' \code{\link{anlz_aa}}); here it displays as \code{0} rather than blank.
#'
#' Values shown are always \code{load_tons} (raw, unnormalized loads), never
#' \code{eff_load_tons}.
#'
#' A bolded \code{"Total Load"} row sums every displayed row for each year
#' (including the AD and Other rows). A bolded \code{"Normalized Load"} row
#' below it applies one hydrologic-normalization ratio to the whole segment's
#' Total Load:
#'
#' \deqn{
#'   \text{Normalized Load} = \text{Total Load} \times
#'   \frac{\text{baseline\_h2o}}{\text{seg\_h2o\_total} + \text{gw\_hy\_load} +
#'   \text{spr\_hy\_load} + \text{ad\_hy\_load}}
#' }
#'
#' where the denominator is \code{aa_data}'s \code{seg_h2o_total} (NPS+IPS+DPS
#' combined) plus \code{gw_data}/\code{spr_data}/\code{ad_data}'s own
#' \code{hy_load}, and \code{baseline_h2o} is a hardcoded 1992-1994 baseline
#' hydrologic load (million m3/yr) per bay segment:
#'
#' \tabular{lr}{
#'   \strong{bay\_seg} \tab \strong{baseline\_h2o} \cr
#'   1 Old Tampa Bay \tab 449.44 \cr
#'   2 Hillsborough Bay \tab 895.62 \cr
#'   3 Middle Tampa Bay \tab 645.25 \cr
#'   4 Lower Tampa Bay \tab 361.19 \cr
#'   55 Remaining Lower Tampa Bay \tab 422.709
#' }
#'
#' An additional \code{"Average"} column, appended after the year columns,
#' gives each row's own mean across the displayed years.
#'
#' @concept show
#'
#' @export
#'
#' @examples
#' \dontrun{
#' aa_data <- anlz_aa(c(2022, 2024), dps, ips, ml, nps, tbbase, annavg = FALSE)
#' gw_data <- anlz_gw(contdry, contwet, yrrng = c(2022, 2024), summtime = 'year')
#' spr_data <- anlz_spr(tbwxlpth, wqpth, yrrng = c(2022, 2024),
#'   summ = 'segment', summtime = 'year')
#' ad_data <- anlz_ad(rain, vernafl, summ = 'segment', summtime = 'year')
#' show_aaloads(aa_data, bay_seg = 2L, gw_data, spr_data, ad_data)
#' }
show_aaloads <- function(aa_data, bay_seg, gw_data, spr_data, ad_data, yrrng = NULL,
                         digits = 1, family = "Arial", txtsz = 11) {

  required_cols <- c("year", "seg_h2o_total", "seg_conserv_tn")
  missing_cols <- setdiff(required_cols, names(aa_data))
  if (length(missing_cols) > 0)
    stop(
      "aa_data is missing column(s): ", paste(missing_cols, collapse = ", "),
      " - call anlz_aa() with annavg = FALSE"
    )

  if (length(bay_seg) != 1 || !bay_seg %in% c(1L, 2L, 3L, 4L, 55L))
    stop("bay_seg must be a single value, one of 1, 2, 3, 4, 55")

  dat <- aa_data[aa_data$bay_seg == bay_seg, ]

  if (!is.null(yrrng)) {
    yrs <- seq(min(yrrng), max(yrrng))
    dat <- dat[dat$year %in% yrs, ]
  }

  if (nrow(dat) == 0)
    stop("no rows in aa_data for bay_seg = ", bay_seg)

  segment_label <- unique(dat$segment)[1]
  yrs_present <- sort(unique(dat$year))
  yr_cols <- as.character(yrs_present)

  # bay-segment-level totals (repeated on every aa_data row for a bay_seg/year
  # - see anlz_aa()); captured here before dat is piped through the
  # entity-level pivot below, which drops every column except the ones it
  # needs.
  seg_totals <- dat |> dplyr::distinct(.data$year, .data$seg_h2o_total, .data$seg_conserv_tn)

  # Returns a value per yr_cols (zero-filled) from a (year, value) pair of
  # vectors - used to place gw_data/spr_data/ad_data/seg_totals values (keyed
  # by year, not necessarily covering every year in yrs_present) onto the
  # table's year columns.
  year_vals <- function(yrs, vals) {
    out <- rep(0, length(yrs_present))
    names(out) <- yr_cols
    idx <- match(yrs, yrs_present)
    ok  <- !is.na(idx) & !is.na(vals)
    out[idx[ok]] <- vals[ok]
    out
  }

  # gw_data/spr_data/ad_data key on segment name, not bay_seg - map/aggregate
  # the same way anlz_aa() does internally (Terra Ceia Bay + Manatee River ->
  # 55; Boca Ciega Bay variants excluded from the allocation framework).
  seg_map <- c(
    "Old Tampa Bay" = 1L, "Hillsborough Bay" = 2L, "Middle Tampa Bay" = 3L,
    "Lower Tampa Bay" = 4L, "Terra Ceia Bay" = 55L, "Manatee River" = 55L
  )
  agg_by_seg <- function(x, seg) {
    x |>
      dplyr::mutate(bay_seg = seg_map[.data$segment]) |>
      dplyr::filter(!is.na(.data$bay_seg), .data$bay_seg == seg) |>
      dplyr::group_by(.data$Year) |>
      dplyr::summarise(
        tn_load = sum(.data$tn_load, na.rm = TRUE),
        hy_load = sum(.data$hy_load, na.rm = TRUE),
        .groups = "drop"
      )
  }
  gw_agg  <- agg_by_seg(gw_data, bay_seg)
  spr_agg <- agg_by_seg(spr_data, bay_seg)
  ad_agg  <- agg_by_seg(ad_data, bay_seg)

  h2o_vals    <- year_vals(seg_totals$year, seg_totals$seg_h2o_total)
  conserv_vals <- year_vals(seg_totals$year, seg_totals$seg_conserv_tn)
  gw_vals     <- year_vals(gw_agg$Year, gw_agg$tn_load)
  gw_hy_vals  <- year_vals(gw_agg$Year, gw_agg$hy_load)
  spr_vals    <- year_vals(spr_agg$Year, spr_agg$tn_load)
  spr_hy_vals <- year_vals(spr_agg$Year, spr_agg$hy_load)
  ad_vals     <- year_vals(ad_agg$Year, ad_agg$tn_load)
  ad_hy_vals  <- year_vals(ad_agg$Year, ad_agg$hy_load)

  other_vals    <- gw_vals + spr_vals + conserv_vals
  total_h2o_vals <- h2o_vals + gw_hy_vals + spr_hy_vals + ad_hy_vals

  # 1992-1994 baseline hydrologic load (million m3/yr) per bay segment, used
  # as the numerator of the segment-wide normalization ratio below. Unlike
  # entity-level normalization (anlz_aa(), sourced from hydro_baseline, which
  # only covers NPS+IPS+DPS water), this must also reflect historical
  # GW+SPR+AD water, so it isn't derivable from hydro_baseline alone. Values
  # extracted directly from the "Normalized Load" formula (=C6*baseline/total_h2o)
  # in the TBNMC partner's draft annual loading workbooks (see Details).
  baseline_h2o <- c(`1` = 449.44, `2` = 895.62, `3` = 645.25, `4` = 361.19, `55` = 422.709)

  section_order <- c(
    "MS4", "Industrial Point Source", "Domestic Point Source - end of pipe",
    "Domestic Point Source - reuse", "Material Losses", "Nonpoint Source"
  )

  # entity_label combines owner (entity_full, falling back to entity) with
  # facname, except when facname already names/contains the owner (e.g. IPS
  # "Mosaic - Bartow", DPS "City of Lakeland") - combining those verbatim
  # would just duplicate the owner name. ML/CSX-style facnames ("Riverview",
  # "Newport") don't self-identify their owner at all, so those get combined
  # ("Mosaic - Riverview", "CSX - Newport") for context. A handful of IPS
  # facnames also carry an uninformative "Point Source - " prefix (e.g.
  # "Point Source - Hopewell"), scrubbed before combining.
  facname_clean <- gsub("^Point Source\\s*-\\s*", "", dat$facname, ignore.case = TRUE)

  owner <- dplyr::coalesce(dat$entity_full, dat$entity)
  owner_in_facname <- mapply(function(o, f) {
    if (is.na(o) || is.na(f)) return(FALSE)
    grepl(toupper(o), toupper(f), fixed = TRUE)
  }, owner, facname_clean)

  dat <- dat |>
    dplyr::mutate(
      entity_label = dplyr::case_when(
        is.na(facname_clean) ~ owner,
        is.na(owner) ~ facname_clean,
        owner_in_facname ~ facname_clean,
        TRUE ~ paste0(owner, " - ", facname_clean)
      ),
      section = dplyr::case_when(
        is.na(.data$source) ~ "Nonpoint Source",
        .data$source %in% c("MS4", "Nonpoint Source/MS4") ~ "MS4",
        .data$source == "IPS" ~ "Industrial Point Source",
        .data$source == "DPS - end of pipe" ~ "Domestic Point Source - end of pipe",
        .data$source == "DPS - reuse" ~ "Domestic Point Source - reuse",
        .data$source == "ML" ~ "Material Losses",
        TRUE ~ .data$source
      )
    ) |>
    # Drop negligible unmatched NPS/MS4 land-use slivers (e.g. "None"): these
    # have source = NA like the real "All"/"Non-MS4/Ag NPS" aggregates, but
    # anlz_aa()'s 0.01 tons/yr drop threshold is applied per year, so a
    # sliver just above that threshold in one year (and below it, dropped,
    # in others) would otherwise show up as a spurious partial row.
    dplyr::filter(!(.data$section == "Nonpoint Source" &
                      !.data$entity %in% c("All", "Non-MS4/Ag NPS")))

  wide <- dat |>
    tidyr::pivot_wider(
      id_cols = c("section", "entity_label", "facname", "permit"),
      names_from = "year",
      values_from = "load_tons"
    ) |>
    # A facility/entity with a real allocation but no load data in a given
    # year (or any year) is NA in aa_data by design (see anlz_aa()); for
    # display, missing load is treated as zero rather than left blank.
    dplyr::mutate(dplyr::across(dplyr::all_of(yr_cols), ~ dplyr::coalesce(.x, 0)))

  present_sections <- section_order[section_order %in% unique(wide$section)]

  build_divider <- function(label) {
    row <- tibble::tibble(entity_label = label)
    for (yc in yr_cols) row[[yc]] <- NA_real_
    row
  }

  row_idx <- 0L
  divider_idx <- integer(0)
  blocks <- list()
  for (sec in present_sections) {
    sec_rows <- wide[wide$section == sec, ] |>
      dplyr::arrange(.data$entity_label) |>
      dplyr::select("entity_label", dplyr::all_of(yr_cols))

    if (sec == "Nonpoint Source") {
      extra <- tibble::tibble(
        entity_label = c("Atmospheric Deposition", "Other (Groundwater, Springs, Conservation)")
      )
      for (yc in yr_cols) extra[[yc]] <- c(ad_vals[[yc]], other_vals[[yc]])
      sec_rows <- dplyr::bind_rows(sec_rows, extra)
    }

    blocks[[length(blocks) + 1]] <- build_divider(sec)
    divider_idx <- c(divider_idx, row_idx + 1L)
    row_idx <- row_idx + 1L
    blocks[[length(blocks) + 1]] <- sec_rows
    row_idx <- row_idx + nrow(sec_rows)
  }

  # Total Load sums every displayed row for each year, including the AD and
  # Other rows injected into the Nonpoint Source section above (which are
  # not part of `wide`, since they come from gw_data/spr_data/ad_data/
  # seg_conserv_tn rather than aa_data).
  wide_vals <- sapply(yr_cols, \(yc) sum(wide[[yc]], na.rm = TRUE))
  total_vals <- wide_vals + ad_vals + other_vals

  total_row <- tibble::tibble(entity_label = "Total Load")
  for (yc in yr_cols) total_row[[yc]] <- unname(total_vals[yc])
  total_idx <- row_idx + 1L
  baseline_val <- baseline_h2o[as.character(bay_seg)]
  normalized_vals <- total_vals * (baseline_val / total_h2o_vals)

  normalized_row <- tibble::tibble(entity_label = "Normalized Load")
  for (yc in yr_cols) normalized_row[[yc]] <- unname(normalized_vals[yc])
  normalized_idx <- total_idx + 1L

  tab <- dplyr::bind_rows(blocks, total_row, normalized_row)

  # Row-wise average across the displayed years (NOT a column summary row);
  # divider rows are all-NA so rowMeans(na.rm = TRUE) gives NaN - reset those
  # to NA so they render blank like the rest of the divider row.
  avg_vals <- rowMeans(as.matrix(tab[yr_cols]), na.rm = TRUE)
  avg_vals[is.nan(avg_vals)] <- NA_real_
  tab$Average <- avg_vals

  ft <- flextable::flextable(tab) |>
    flextable::set_header_labels(entity_label = "Entity") |>
    flextable::colformat_double(j = c(yr_cols, "Average"), digits = digits, na_str = "") |>
    flextable::align(j = c(yr_cols, "Average"), align = "center", part = "all") |>
    flextable::bold(i = c(divider_idx, total_idx, normalized_idx)) |>
    flextable::border_inner() |>
    flextable::border_outer() |>
    flextable::set_caption(
      paste0(segment_label, " TN loads by year (", min(yrs_present), "-", max(yrs_present), ")")
    ) |>
    flextable::font(fontname = family, part = "all") |>
    flextable::fontsize(size = txtsz, part = "all") |>
    flextable::autofit()

  for (idx in divider_idx)
    ft <- flextable::merge_at(ft, i = idx, j = seq_len(ncol(tab)))

  ft

}
