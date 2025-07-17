#' Utility function to create non-point source (NPS) ungaged land use and soil runoff coefficients
#'
#' @param tbbase Data frame returned from \code{\link{util_nps_tbbase}} containing land use and soil data.
#' @param yrexp Years to expand the data frame to include all months for each year.
#'
#' @returns A data frame with land use (CLUCSID) and soil runoff coefficients by year and month.
#'
#' @export
#'
#' @examples
#' data(tbbase)
#'
#' util_nps_landsoilrc(tbbase, yrexp = c(2021:2023))
util_nps_landsoilrc <- function(tbbase, yrexp = c(2021:2023)){

  rc <- rcclucsid |>
    dplyr::rename(hydgrp = hsg)

  landsoil <- util_nps_landsoil(tbbase) |>
    dplyr::filter(drnfeat != "NONCON") |>
    dplyr::mutate(
      basin = dplyr::case_when(
        basin == "02303000" ~ "02304500",
        basin == "02303330" ~ "02304500",
        basin == "02301000" ~ "02301500",
        basin == "02301300" ~ "02301500",
        TRUE ~ basin
        )
    ) |>
    dplyr::filter(!basin %in% c("02301000", "02301300", "02303000", "02303330", "02307359")) |>
    dplyr::select(bay_seg, basin, drnfeat, clucsid, hydgrp, area) |>
    dplyr::inner_join(rc, by = c("clucsid", "hydgrp")) |>
    tidyr::expand_grid(mo = 1:12) |>
    dplyr::mutate(
      rc = ifelse(mo %in% c(7, 8, 9, 10), wet_rc, dry_rc),
      rca = rc * area
    )

  tot_rca <- landsoil |>
    dplyr::summarise(
      tot_rca = sum(rca, na.rm = TRUE),
      .by = c('basin', 'bay_seg', 'mo')
    )

  out <- landsoil |>
     dplyr::left_join(tot_rca, by = c("bay_seg", "basin", "mo")) |>
     tidyr::expand_grid(yr = yrexp)

  return(out)

}
