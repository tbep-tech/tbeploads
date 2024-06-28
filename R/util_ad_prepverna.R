#' Prep Verna Wellfield data for use in AD calculations
#'
#' Prep Verna Wellfield data for use in AD calculations
#'
#' @param fl text string for the file path to the Verna Wellfield data
#' @param fillmis logical indicating whether to fill missing data with monthly means
#'
#' @return A data frame with total nitrogen and phosphorus estimates as mg/l for each year and month of the input data
#'
#' @details
#' Raw data can be obtained from <https://nadp.slh.wisc.edu/sites/ntn-FL41/>.  Total nitrogen and phosphorus concentrations are estimated from ammonium and nitrate concentrations using the following relationships:
#'
#' \deqn{TNConc = NH4 * 0.78 + NO3 * 0.23}
#' \deqn{TPConc = 0.01262 * TNConc + 0.00110}
#'
#' The first equation corrects for the % of ions in either that is N, and the second is a regression relationship between TBADS TN and TP, applied to Verna.
#'
#' @export
#'
#' @examples
#' fl <- list.files(system.file('extdata/', package = 'tbeploads'),
#'   pattern = 'verna-raw', full.names = TRUE)
#' util_ad_prepverna(fl)
util_ad_prepverna <- function(fl, fillmis = T){

  # import raw, subset relevant, fill -9 as NA
  dat <- read.csv(fl, header = T, stringsAsFactors = F) |>
    dplyr::select(
      Year = yr,
      Month = seas,
      nh4 = NH4,
      no3 = NO3
    ) |>
    dplyr::mutate(
      nh4 = ifelse(nh4 == -9, NA, nh4),
      no3 = ifelse(no3 == -9, NA, no3)
    )

  # fill missing annual data by monthly means from other years
  if(fillmis){

    # get monthly ave
    datave <- dat |>
      dplyr::summarise(
        nh4ave = mean(nh4, na.rm = T),
        no3ave = mean(no3, na.rm = T),
        .by = Month
      )

    # fill missing with ave
    dat <- tidyr::crossing(
        Year = unique(dat$Year),
        Month = 1:12
      ) |>
      dplyr::left_join(dat, by = c('Year', 'Month')) |>
      dplyr::left_join(datave, by = 'Month') |>
      dplyr::mutate(
        nh4 = ifelse(is.na(nh4), nh4ave, nh4),
        no3 = ifelse(is.na(no3), no3ave, no3)
      ) |>
      dplyr::select(-nh4ave, -no3ave)

  }

  # create tn and tp estimates from nh4 and no3
  out <- dat |>
    dplyr::mutate(
      nh4 = nh4 * 0.78, # NADP data are reported as mg NO3 and mg NH4, this corrects for % of ions that is N;
      no3 = no3 * 0.23,
      TNConc = nh4 + no3,
      TPConc = 0.01262 * TNConc + 0.00110 # from regression relationship between TBADS TN and TP, applied to Verna;
    ) %>%
    dplyr::select(Year, Month, TNConc, TPConc)

  return(out)

}
