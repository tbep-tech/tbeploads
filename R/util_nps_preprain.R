#' Prep rain data for non-point source (NPS) ungaged load estimates
#'
#' @param rain data frame of rainfall data, see \code{\link{rain}}
#' @param yrrng numeric vector of a single year or a two year range to filter the data, defaults to NULL (no filtering)
#'
#' @returns A data frame of monthly total rainfall (inches) by drainage basin
#'
#' @details The inverse distance weighting scheme of the drainage basin to the rain gauge is used (with \code{\link{nps_distance}}) to estimate a cumulative monthly total rainfall, including lags of one and two months.
#'
#' @export
#'
#' @examples
#' util_nps_preprain(rain)
#'
#' util_nps_preprain(rain, yrrng = c(2021))
util_nps_preprain <- function(rain, yrrng = NULL){

  tb_mo_rain <- rain |>
    dplyr::rename(
      yr = Year,
      mo = Month
    ) |>
    dplyr::summarise(
      tpcp_in = sum(rainfall),
      n = dplyr::n(),
      .by = c(station, yr, mo)
    )

  # Merge distance and precipitation datasets
  all_data <- merge(nps_distance, tb_mo_rain, by.x = "matchsit", by.y = "station")

  # Sort the data frame by specified columns
  all <- all_data |>
    dplyr::arrange(target, yr, mo) |>
    tidyr::drop_na(tpcp_in)

  # Calculate weighted mean of 'tpcp_in' using 'invdist2' as weight
  db <- all |>
    dplyr::summarise(
      tpcp = weighted.mean(tpcp_in, as.numeric(invdist2), na.rm = T),
      .by = c(target, yr, mo)
    ) |>
    dplyr::rename(basin = target)

  npsrain <- db |>
    dplyr::mutate(
      lag1rain = dplyr::lag(tpcp, n = 1, order_by = basin),
      lag2rain = dplyr::lag(tpcp, n = 2, order_by = basin),
      .by = basin
    ) |>
    dplyr::rename(rain = tpcp)

  rainout <- npsrain |>
    dplyr::filter(basin != "02301500" & basin != "02303330" & basin != "02304500")

  rainnest <- npsrain |>
    dplyr::filter(basin %in% c("02301500", "02301000", "02301300",
                        "02303000", "02303330", "02304500")) |>
    dplyr::mutate(
      landarea = dplyr::case_when(
        basin == "02301000" ~ 34978.50,
        basin == "02301300" ~ 14599.80,
        basin == "02301500" ~ 38517.64,
        basin == "02303000" ~ 62612.93,
        basin == "02303330" ~ 42463.05,
        basin == "02304500" ~ 62025.35,
        TRUE ~ NA_real_),
      basin = dplyr::case_when(
        basin == "02301000" ~ "02301500",
        basin == "02301300" ~ "02301500",
        basin == "02303330" ~ "02304500",
        basin == "02303000" ~ "02303330",
        TRUE ~ basin)
    ) |>                    # Keep original basin if not matched
    dplyr::filter(!(basin == "02301000" | basin == "02301300"))           # Exclude original basins from output

  tbnestr <- rainnest |>
    dplyr::summarise(
      rain = weighted.mean(rain, landarea, na.rm = TRUE),
      lag1rain = weighted.mean(lag1rain, landarea, na.rm = TRUE),
      lag2rain = weighted.mean(lag2rain, landarea, na.rm = TRUE),
      .by = c(basin, yr, mo)
    )

  out <- dplyr::bind_rows(rainout, tbnestr) |>
    dplyr::arrange(basin, yr, mo)

  if(!is.null(yrrng)){

    if(length(yrrng) == 2)
      stopifnot(yrrng[2] > yrrng[1])

    if(length(yrrng) == 1)
      yrrng <- c(yrrng, yrrng)

    out <- out |>
      dplyr::filter(yr >= yrrng[1] & yr <= yrrng[2])
  }

  return(out)

}
