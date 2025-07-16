#' Utility function for non-point source (NPS) ungaged workflow to prepare land use and soil data for logistic regression
#'
#' @param tbbase Input data frame returned from \code{\link{util_nps_tbbase}}.
#'
#' @returns A data frame with land use and soil areas in long format with bay segment and basins in the rows.
#' @export
#'
#' @examples
#' util_nps_preplog(tbbase)
util_nps_preplog <- function(tbbase){

  f3d <- util_nps_landsoil(tbbase) |>
    dplyr::mutate(
      bay_seg = dplyr::case_when(
        basin == "206-5" ~ 55,
        TRUE ~ bay_seg
        ),
      grp = dplyr::case_when(
        drnfeat == "CON" & clucsid < 10 ~ paste0("C_C0",as.character(clucsid),as.character(hydgrp)),
        drnfeat == "CON" & clucsid > 9 ~ paste0("C_C",as.character(clucsid),as.character(hydgrp)),
        drnfeat == "NONCON" & clucsid < 10 ~ paste0("NC_C0",as.character(clucsid),as.character(hydgrp)),
        drnfeat == "NONCON" & clucsid > 9 ~ paste0("NC_C",as.character(clucsid),as.character(hydgrp)),
        TRUE ~ NA
        )
      )

  tbland1 <- f3d |>
    dplyr::summarise(
      area = sum(area),
      .by = c('bay_seg', 'basin', 'grp')
      ) |>
    tidyr::spread(grp, area)

  tbland2 <- f3d |>
    dplyr::summarise(
      tot_area = sum(area),
      .by = c('bay_seg', 'basin')
      )

  #Nests and combines certain basins for logistic model
  tbland <- dplyr::left_join(tbland1, tbland2, by = c("bay_seg", "basin")) |>
    dplyr::mutate(original_basin = basin)

  out <- dplyr::bind_rows(
      dplyr::filter(tbland, basin == "02301000") |> dplyr::mutate(basin = "02301500"),
      dplyr::filter(tbland, basin == "02301300") |> dplyr::mutate(basin = "02301500"),
      dplyr::filter(tbland, basin == "02303330") |> dplyr::mutate(basin = "02304500"),
      dplyr::filter(tbland, basin == "02303000") |>
        dplyr::bind_rows(
          dplyr::mutate(tbland |> dplyr::filter(basin == "02303000"), basin = "02304500"),
          dplyr::mutate(tbland |> dplyr::filter(basin == "02303000"), basin = "02303330")),
      dplyr:: filter(tbland, basin == "02307359") |> dplyr::mutate(basin = "LTARPON")
    ) |>
    dplyr::summarise(
      dplyr::across(.cols = dplyr::where(is.numeric), .fns = sum),
      .by = c("bay_seg", "basin")
    )

  return(out)

}
