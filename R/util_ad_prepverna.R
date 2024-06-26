util_ad_prepverna <- function(fl, fillmis = T){

  dat <- read.csv(fl, header = T, stringsAsFactors = F) |>
    dplyr::mutate(Month = seas + 0) |>
    dplyr::select(
      Year = yr,
      Month = mo,
      nh4 = NH4,
      no3 = NO3
    )

  # fill missing annual data by monthly means from other years
  if(fillmis)
    dat <- dat #|>
      # dplyr::mutate(
      #   nh4
      # )

  dat <- dat |>
    mutate(
      nh4 = nh4 * 0.78, # NADP data are reported as mg NO3 and mg NH4, this corrects for % of ions that is N;
      no3 = no3 * 0.23,
      TNConc = nh4 + no3,
      TPConc = 0.01262 * TNConc + 0.00110 # from regression relationship between TBADS TN and TP, applied to Verna;
    ) %>%
    select(yr, mo, TNConc, TPConc)

}
