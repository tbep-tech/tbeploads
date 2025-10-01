#' Fill in missing water quality values for non-point source (NPS) data
#'
#' @param wq A data frame of water quality data returned by \code{util_nps_getwq}
#' @param yrrng A vector of two dates in 'YYYY-MM-DD' format, specifying the date range to retrieve flow data. Default is from '2021-01-01' to '2023-12-31'.
#'
#' @details Missing end date monthly values are filled with prior 5 year averages. Then, missing monthly values are linearly interpolated using \code{\link[zoo]{na.approx}}.
#'
#' @return Input data frame with missing data filled as described above.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' data(allwq)
#' wq <- util_nps_fillmiswq(allwq)
#' }
util_nps_fillmiswq <- function(wq, yrrng = c('2021-01-01', '2023-12-31')){

  yrrng <- as.Date(yrrng)
  yrsel <- lubridate::year(yrrng)

  out <- wq |>
    dplyr::arrange(basin, yr, mo) |>
    tidyr::complete(
      basin,
      yr = tidyr::full_seq(yr, 1),
      mo = 1:12
    ) |>
    # Calculate 5-year averages from PRIOR years only
    dplyr::group_by(basin, mo) |>
    dplyr::mutate(
      tn_mgl_avg5 = purrr::map_dbl(yr, ~mean(tn_mgl[yr >= .x - 5 & yr < .x], na.rm = TRUE)),
      tp_mgl_avg5 = purrr::map_dbl(yr, ~mean(tp_mgl[yr >= .x - 5 & yr < .x], na.rm = TRUE)), 
      tss_mgl_avg5 = purrr::map_dbl(yr, ~mean(tss_mgl[yr >= .x - 5 & yr < .x], na.rm = TRUE)),
      bod_mgl_avg5 = purrr::map_dbl(yr, ~mean(bod_mgl[yr >= .x - 5 & yr < .x], na.rm = TRUE))
    ) |>
    dplyr::ungroup() |>
    # Identify min and max years
    dplyr::mutate(
      min_yr = min(yr, na.rm = TRUE),
      max_yr = max(yr, na.rm = TRUE)
    ) |>
    # Fill January for min year and December for max year using 5-year averages
    dplyr::mutate(
      tn_mgl = dplyr::case_when(
        (yr == min_yr & mo == 1 & is.na(tn_mgl)) ~ tn_mgl_avg5,
        (yr == max_yr & mo == 12 & is.na(tn_mgl)) ~ tn_mgl_avg5,
        TRUE ~ tn_mgl
      ),
      tp_mgl = dplyr::case_when(
        (yr == min_yr & mo == 1 & is.na(tp_mgl)) ~ tp_mgl_avg5,
        (yr == max_yr & mo == 12 & is.na(tp_mgl)) ~ tp_mgl_avg5,
        TRUE ~ tp_mgl
      ), 
      tss_mgl = dplyr::case_when(
        (yr == min_yr & mo == 1 & is.na(tss_mgl)) ~ tss_mgl_avg5,
        (yr == max_yr & mo == 12 & is.na(tss_mgl)) ~ tss_mgl_avg5,
        TRUE ~ tss_mgl
      ),
      bod_mgl = dplyr::case_when(
        (yr == min_yr & mo == 1 & is.na(bod_mgl)) ~ bod_mgl_avg5,
        (yr == max_yr & mo == 12 & is.na(bod_mgl)) ~ bod_mgl_avg5,
        TRUE ~ bod_mgl
      )
    ) |>
    dplyr::select(-tn_mgl_avg5, -tp_mgl_avg5, -tss_mgl_avg5, -bod_mgl_avg5, -min_yr, -max_yr) |>
    # Linear interpolation for all basins
    dplyr::mutate(tn_mgl = zoo::na.approx(tn_mgl, na.rm = FALSE), .by = basin) |>
    dplyr::mutate(tp_mgl = zoo::na.approx(tp_mgl, na.rm = FALSE), .by = basin) |> 
    dplyr::mutate(tss_mgl = zoo::na.approx(tss_mgl, na.rm = FALSE), .by = basin) |>
    dplyr::mutate(bod_mgl = zoo::na.approx(bod_mgl, na.rm = FALSE), .by = basin) |>
    dplyr::filter(yr >= yrsel[1] & yr <= yrsel[2])
  
  return(out)

}
