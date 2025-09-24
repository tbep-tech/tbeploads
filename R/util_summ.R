#' Summarize load estimates
#'
#' Summarize load estimates
#'
#' @param dat Pre-processed data frame of load estimates, see examples
#' @param summ `r summ_params('summ')`
#' @param summtime `r summ_params('summtime')`
#'
#' @details `r summ_params('descrip')`
#'
#' @return Data frame with summarized loading data based on user-supplied arguments
#' @export
#'
#' @examples
#' fls <- list.files(system.file('extdata/', package = 'tbeploads'),
#'   pattern = 'ps_ind_', full.names = TRUE)
#'
#' ipsbyfac <- anlz_ips_facility(fls)
#'
#' # add bay segment and source
#' # there should only be loads to Hillsborough, Middle, and Lower Tampa Bay
#' ipsld <- ipsbyfac  |>
#'   dplyr::arrange(coastco) |>
#'   dplyr::left_join(dbasing, by = "coastco") |>
#'   dplyr::mutate(
#'     segment = dplyr::case_when(
#'       bayseg == 1 ~ "Old Tampa Bay",
#'       bayseg == 2 ~ "Hillsborough Bay",
#'       bayseg == 3 ~ "Middle Tampa Bay",
#'       bayseg == 4 ~ "Lower Tampa Bay",
#'       TRUE ~ NA_character_
#'     ),
#'     source = 'IPS'
#'   ) |>
#'   dplyr::select(-basin, -hectare, -coastco, -name, -bayseg)
#'
#' util_summ(ipsld, summ = 'entity', summtime = 'year')
util_summ <- function(dat, summ = c('entity', 'facility', 'basin', 'segment', 'all'), summtime = c('month', 'year')){

  summ <- match.arg(summ)
  summtime <- match.arg(summtime)

  ##
  # summarize by selection

  if(summtime == 'month'){

    if(summ == 'facility')

      out <- dat |>
        dplyr::summarise(dplyr::across(dplyr::contains("load"), ~ sum(., na.rm = TRUE)),
                         .by = c(Year, Month, source, entity, facility, segment)) |>
        dplyr::arrange(entity, facility, segment, Year, Month, source)

    if(summ == 'entity')

      out <- dat |>
        dplyr::summarise(dplyr::across(dplyr::contains("load"), ~ sum(., na.rm = TRUE)),
                         .by = c(Year, Month, source, entity, segment)) |>
        dplyr::arrange(entity, segment, Year, Month, source)

    if(summ == 'segment')

      out <- dat |>
        dplyr::summarise(dplyr::across(dplyr::contains("load"), ~ sum(., na.rm = TRUE)),
                         .by = c(Year, Month, source, segment)) |>
        dplyr::arrange(segment, Year, Month, source)

    if(summ == 'basin')

      out <- dat |>
        dplyr::summarise(dplyr::across(dplyr::contains("load"), ~ sum(., na.rm = TRUE)),
                         .by = c(Year, Month, source, segment, basin)) |>
        dplyr::arrange(segment, basin, Year, Month, source)
    
    if(summ == 'all')

      out <- dat |>
        dplyr::filter(segment != "Boca Ciega Bay") |>
        dplyr::summarise(dplyr::across(dplyr::contains("load"), ~ sum(., na.rm = TRUE)),
                         .by = c(Year, Month, source)) |>
        dplyr::arrange(Year, Month, source)

  }

  if(summtime == 'year'){

    if(summ == 'facility')

      out <- dat |>
        dplyr::summarise(dplyr::across(dplyr::contains("load"), ~ sum(., na.rm = TRUE)),
                         .by = c(Year, source, entity, facility, segment)) |>
        dplyr::arrange(entity, facility, segment, Year, source)

    if(summ == 'entity')

      out <- dat |>
        dplyr::summarise(dplyr::across(dplyr::contains("load"), ~ sum(., na.rm = TRUE)),
                         .by = c(Year, source, entity, segment)) |>
        dplyr::arrange(entity, segment, Year, source)

    if(summ == 'segment')

      out <- dat |>
        dplyr::summarise(dplyr::across(dplyr::contains("load"), ~ sum(., na.rm = TRUE)),
                         .by = c(Year, source, segment)) |>
        dplyr::arrange(segment, Year, source)

        if(summ == 'basin')

    if(summ == 'basin')

      out <- dat |>
        dplyr::summarise(dplyr::across(dplyr::contains("load"), ~ sum(., na.rm = TRUE)),
                         .by = c(Year, source, segment, basin)) |>
        dplyr::arrange(segment, basin, Year, source)
    
    if(summ == 'all')

      out <- dat |>
        dplyr::filter(segment != "Boca Ciega Bay") |>
        dplyr::summarise(dplyr::across(dplyr::contains("load"), ~ sum(., na.rm = TRUE)),
                         .by = c(Year, source)) |>
        dplyr::arrange(Year, source)

  }

  return(out)

}
