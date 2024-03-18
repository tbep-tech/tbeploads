library(dplyr)
library(haven)

# sas file from here T:/03_BOARDS_COMMITTEES/05_TBNMC/2022_RA_Update/01_FUNDING_OUT/DELIVERABLES/TO-9/datastick_deliverables/LoadingCodes&Datasets/2021/PointSource2021/Domestic2021/
dbasing <- haven::read_sas(here::here('data-raw/dbasing_0407.sas7bdat'))

dbasing <- dbasing |>
  janitor::clean_names() |>
  dplyr::rename(
    coastco = coast_co,
    coastno = coast_no,
    bayseg = bay_seg
  ) |>
  dplyr::mutate(
    bayseg = dplyr::case_when(
      bayseg == 5 & coastno %in% c(580, 602, 1003, 1031) ~ 55, # BCBS
      TRUE ~ bayseg
    ),
    hectare = dplyr::case_when(
      bayseg == 55 & coastno == 580 ~ hectare * 0.411,
      bayseg == 5 & coastno == 580 ~ hectare * 0.589,
      T ~ hectare
    ),
    name = case_when(
      bayseg == 1 ~ "Hillsborough Bay",
      bayseg == 2 ~ "Old Tampa Bay",
      bayseg == 3 ~ "Middle Tampa Bay",
      bayseg == 4 ~ "Lower Tampa Bay",
      bayseg == 5 ~ "Boca Ciega Bay",
      bayseg == 6 ~ "Terra Ceia Bay",
      bayseg == 7 ~ "Manatee River",
      bayseg == 55 ~ "Boca Ciega Bay South",
      TRUE ~ NA_character_
    )
  ) |>
  dplyr::select(coastco, basin = newgage, bayseg, name, hectare)

usethis::use_data(dbasing, overwrite = TRUE)
