#' Calculate IPS loads and summarize
#'
#' Calculate IPS loads and summarize
#'
#' @param fls vector of file paths to raw entity data, one to many
#' @param summ chr string indicating how the returned data are summarized, see details
#' @param summtime chr string indicating how the returned data are summarized temporally (month or year), see details
#'
#' @details
#' Input data files in \code{fls} are first processed by \code{\link{anlz_ips_facility}} to calculate IPS loads for each facility and outfall.  The data can then be summarized differently based on the \code{summ} and \code{summtime} arguments.  All loading data are summed based on these arguments, e.g., by bay segment (\code{summ = 'segment'}) and year (\code{summtime = 'year'}).
#'
#' @return data frame with loading data for TP, TN, TSS, and BOD as tons per month/year and hydro load as million cubic meters per month/year
#' @export
#'
#' @seealso \code{\link{anlz_ips_facility}}
#'
#' @examples
#' fls <- list.files(system.file('extdata/', package = 'tbeploads'),
#'   pattern = 'ps_ind', full.names = TRUE)
#' anlz_ips(fls)
anlz_ips <- function(fls, summ = c('entity', 'facility', 'segment', 'all'), summtime = c('month', 'year')){

  summ <- match.arg(summ)
  summtime <- match.arg(summtime)

  # get facility and outfall level data
  ipsbyfac <- anlz_ips_facility(fls)

  # add bay segment and source, there should only b loads to hills, middle, and lower tampa bay
  ipsld <- ipsbyfac  |>
    dplyr::arrange(coastco) |>
    dplyr::left_join(dbasing, by = "coastco") |>
    dplyr::mutate(
      segment = dplyr::case_when(
        bayseg == 1 ~ "Old Tampa Bay",
        bayseg == 2 ~ "Hillsborough Bay",
        bayseg == 3 ~ "Middle Tampa Bay",
        bayseg == 4 ~ "Lower Tampa Bay",
        TRUE ~ NA_character_
      ),
      source = 'IPS'
    ) |>
    dplyr::select(-basin, -hectare, -coastco, -name, -bayseg)

  ##
  # summarize by selection

  out <- ipsld
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
