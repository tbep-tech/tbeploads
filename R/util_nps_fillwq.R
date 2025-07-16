#' Fill in missing water quality values for non-point source (NPS) data
#'
#' @param wq A data frame of water quality data returned by \code{util_nps_getwq}
#'
#' @details Missing end date monthly values are filled with prior 5 year averages. Then, missing monthly values are linearly interpolated using \code{\link[zoo]{na.approx}}.  This function will need to be updated each RA period with correct averages.
#'
#' @return Input data frame with missing data filled as described above.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' manopth <- system.file('extdata/nps_wq_manco.txt', package = 'tbeploads')
#' pincopth <- system.file('extdata/nps_wq_pinco.txt', package = 'tbeploads')
#' wq <- util_nps_getwq(c('2021-01-01', '2023-12-31'), mancopth = manopth,
#'   pincopth = pincopth, verbose = F)
#' wq <- util_nps_fillmiswq(wq)
#' }
util_nps_fillmiswq <- function(wq){

  out <- wq |>
    dplyr::mutate(
      tn_mgl = dplyr::case_when(
        (basin == "LTARPON" & yr == 2023 & mo == 12) ~ mean(c(0.62, 0.83, 0.9, 0.87, 0.9)),   # Fill in missing end date monthly values with prior 5 year averages
        (basin == "LTARPON" & yr == 2021 & mo == 1) ~ mean(c(0.65, 0.59, 0.84, 0.9, 0.87)),
        (basin == "LMANATEE" & yr == 2023 & mo == 12) ~ mean(c(0.962, 1.216, 1.099, 1.253)),
        (basin == "EVERSRES" & yr == 2023 & mo == 12) ~ mean(c(0.666, 0.778, 0.812, 0.871)),
        TRUE ~ tn_mgl
        ),
      tp_mgl = dplyr::case_when(
        (basin == "LTARPON" & yr == 2023 & mo == 12) ~ mean(c(0.04, 0.05, 0.04, 0.05, 0.03)),
        (basin == "LTARPON" & yr == 2021 & mo == 1) ~ mean(c(0.05, 0.03, 0.04, 0.05, 0.04)),
        (basin == "LMANATEE" & yr == 2023 & mo == 12) ~ mean(c(0.472, 0.322, 0.3, 0.48)),
        (basin == "EVERSRES" & yr == 2023 & mo == 12) ~ mean(c(0.432, 0.097, 0.039, 0.072)),
        TRUE ~ tp_mgl
        ),
      tss_mgl = dplyr::case_when(
        (basin == "LTARPON" & yr == 2023 & mo == 12) ~ mean(c(2, 2, 2, 3, 3)),
        (basin == "LTARPON" & yr == 2021 & mo == 1) ~ mean(c(3, 2, 3, 3, 3)),
        (basin == "LMANATEE" & yr == 2023 & mo == 12) ~ mean(c(1.8, 1.4, 1.3, 4)),
        (basin == "EVERSRES" & yr == 2023 & mo == 12) ~ mean(c(4, 3.4, 2.8, 4.1)),
        TRUE ~ tss_mgl
        ),
      bod_mgl = dplyr::case_when(
        (basin == "LTARPON" & yr == 2023 & mo == 12) ~ mean(c(1, 2.6, 2.9, 3.2, 2.3)),
        TRUE ~ bod_mgl)
      ) |>
    dplyr::mutate(tn_mgl = zoo::na.approx(tn_mgl), .by = basin) |>    # Linear interpolate missing monthly WQ concentration values
    dplyr::mutate(tp_mgl = zoo::na.approx(tp_mgl), .by = basin)

  return(out)

}
