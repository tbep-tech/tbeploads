#' Utility function for non-point source (NPS) workflow to create land use and soil data
#'
#' @param tbbase Input data frame returned from \code{\link{util_nps_tbbase}}
#'
#' @returns A data frame summarizing land use and soil by bay segment, sub-basin, drainage feature, CLUCSID, hydrologic group, and improved status.
#'
#' @export
#'
#' @examples
#' data(tbbase)
#' util_nps_landsoil(tbbase)
util_nps_landsoil <- function(tbbase){

  out <- tbbase |>
    dplyr::mutate(
      drnfeat = dplyr::case_when(
        drnfeat != "NONCON" ~ "CON",
        TRUE ~ drnfeat
      ),
      hydgrp = dplyr::case_when(
        hydgrp == "A/D" ~ "A",
        hydgrp == "B/D" ~ "B",
        hydgrp == "C/D" ~ "C",
        TRUE ~ hydgrp
      )
    ) |>
    dplyr::rename(
      clucsid = CLUCSID,
      improved = IMPROVED
    ) |>
    dplyr::summarise(
      area = sum(area_ha),
      .by = c("bay_seg", "basin", "drnfeat", "clucsid", "hydgrp", "improved")
    )

  return(out)

}
