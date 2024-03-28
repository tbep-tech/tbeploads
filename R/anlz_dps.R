#' Calculate DPS reuse and end of pipe and summarize
#'
#' Calculate DPS reuse and end of pipe and summarize
#'
#' @param fls vector of file paths to raw entity data, one to many
#' @param summ chr string indicating how the returned data are summarized, see details
#' @param summtime chr string indicating how the returned data are summarized temporally (month or year), see details
#'
#' @details
#' Input data files in \code{fls} are first processed by \code{\link{anlz_dps_facility}} to calculate DPS reuse and end of pipe for each facility and outfall.  The data can then be summarized differently based on the \code{summ} and \code{summtime} arguments.  All loading data are summed basd on these arguments, e.g., by bay segment (\code{summ = 'segment'}) and year (\code{summtime = 'year'}).
#'
#' @return data frame with loading data for TP, TN, TSS, and BOD as tons per month/year and hydro load as million cubic meters per month/year
#' @export
#'
#' @seealso \code{\link{anlz_dps_facility}}
#'
#' @examples
#' fls <- list.files(system.file('extdata/', package = 'tbeploads'),
#'   pattern = '\\.txt$', full.names = TRUE)
#' anlz_dps(fls)
anlz_dps <- function(fls, summ = c('entity', 'facility', 'segment', 'all'), summtime = c('month', 'year')){

  summ <- match.arg(summ)
  summtime <- match.arg(summtime)

  # get facility and outfall level data
  dpsbyfac <- anlz_dps_facility(fls)

  # remove bcb, bcbs from dpsbyfac
  dpsld <- dpsbyfac  |>
    dplyr::filter(coastco != "580") |>
    dplyr::arrange(coastco) |>
    dplyr::inner_join(dbasing, by = "coastco")

  # create bcb north and south load subsets
  bcbnorth <- dpsbyfac |>
    dplyr::filter(coastco == "580") |>
    dplyr::mutate(dplyr::across(dplyr::contains("load"), ~ .x * 0.589),
           bayseg = 5)

  bcbsouth <- dpsbyfac |>
    dplyr::filter(coastco == "580") |>
    dplyr::mutate(dplyr::across(dplyr::contains("load"), ~ .x * 0.411),
           bayseg = 55)

  bcb <- dplyr::bind_rows(bcbnorth, bcbsouth) |>
    dplyr::inner_join(dbasing, by = c("coastco", "bayseg"))

  # combine orig with refactored bcb data, redo segment
  dpsld <- dplyr::bind_rows(dpsld, bcb) |>
    dplyr::arrange(coastco) |>
    dplyr::mutate(
      segment = dplyr::case_when(
        basin == "LTARPON"  ~ 1,
        basin == "02306647" ~ 1,
        basin == "02307000" ~ 1,
        basin == "02307359" ~ 1,
        basin == "206-1"    ~ 1,
        basin == "TBYPASS"  ~ 2,
        basin == "02301750" ~ 2,
        basin == "206-2"    ~ 2,
        basin == "02300700" ~ 2,
        basin == "02301000" ~ 2,
        basin == "02301300" ~ 2,
        basin == "02301500" ~ 2,
        basin == "02301695" ~ 2,
        basin == "204-2"    ~ 2,
        basin == "02303000" ~ 2,
        basin == "02303330" ~ 2,
        basin == "02304500" ~ 2,
        basin == "205-2"    ~ 2,
        basin == "02300500" ~ 3,
        basin == "02300530" ~ 3,
        basin == "203-3"    ~ 3,
        basin == "206-3C"   ~ 3,
        basin == "206-3E"   ~ 3,
        basin == "206-3W"   ~ 3,
        basin == "206-4"    ~ 4,
        basin == "206-5" ~  55,
        basin == "207-5" & bayseg == 5  ~ 5,
        basin == "207-5" & bayseg == 55 ~ 55,
        basin == "206-6"    ~ 6,
        basin == "EVERSRES" ~ 7,
        basin == "LMANATEE" ~ 7,
        basin == "202-7"    ~ 7,
        basin == "02299950" ~ 7
      ),
      bayseg = segment,
      segment = dplyr::case_when(
        bayseg == 1 ~ "Old Tampa Bay",
        bayseg == 2 ~ "Hillsborough Bay",
        bayseg == 3 ~ "Middle Tampa Bay",
        bayseg == 4 ~ "Lower Tampa Bay",
        bayseg == 5 ~ "Boca Ciega Bay",
        bayseg == 6 ~ "Terra Ceia Bay",
        bayseg == 7 ~ "Manatee River",
        bayseg == 55 ~ "Boca Ciega Bay South",
        TRUE ~ NA_character_
      ),
      source = dplyr::case_when(
        grepl('^D', source) ~ "DPS - end of pipe",
        grepl('^R', source) ~ "DPS - reuse"
      )
    ) |>
    dplyr::select(-basin, -hectare, -coastco, -name, -bayseg)

  # remove south cross bayou, not in RA
  dpsld <- dpsld |>
    dplyr::filter(!(facility %in% 'South Cross Bayou WRF'))

  ##
  # summarize by selection

  out <- dpsld
  if(summtime == 'month'){

    if(summ == 'facility')

      out <- out |>
        dplyr::summarise(dplyr::across(dplyr::contains("load"), ~ sum(., na.rm = TRUE)),
                  .by = c(Year, Month, source, entity, facility, segment))

    if(summ == 'entity')

      out <- out |>
        dplyr::summarise(dplyr::across(dplyr::contains("load"), ~ sum(., na.rm = TRUE)),
                  .by = c(Year, Month, source, entity, segment))

    if(summ == 'segment')

      out <- out |>
        dplyr::summarise(dplyr::across(dplyr::contains("load"), ~ sum(., na.rm = TRUE)),
                  .by = c(Year, Month, source, segment))

    if(summ == 'all')

      out <- out |>
        dplyr::summarise(dplyr::across(dplyr::contains("load"), ~ sum(., na.rm = TRUE)),
                  .by = c(Year, Month, source))

    out <- out |>
      dplyr::arrange(source, Year, Month)

  }

  if(summtime == 'year'){

    if(summ == 'facility')

      out <- out |>
        dplyr::summarise(dplyr::across(dplyr::contains("load"), ~ sum(., na.rm = TRUE)),
                  .by = c(Year, source, entity, facility, segment))

    if(summ == 'entity')

      out <- out |>
        dplyr::summarise(dplyr::across(dplyr::contains("load"), ~ sum(., na.rm = TRUE)),
                  .by = c(Year, source, entity, segment))

    if(summ == 'segment')

      out <- out |>
        dplyr::summarise(dplyr::across(dplyr::contains("load"), ~ sum(., na.rm = TRUE)),
                  .by = c(Year, source, segment))

    if(summ == 'all')

      out <- out |>
        dplyr::summarise(dplyr::across(dplyr::contains("load"), ~ sum(., na.rm = TRUE)),
                  .by = c(Year, source))

    out <- out |>
      dplyr::arrange(source, Year)

  }

  return(out)

}
