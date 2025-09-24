#' Create bay segment column for non-point source (NPS) load data
#' 
#' Create bay segment column for non-point source (NPS) load data
#'
#' @param dat data frame with a `basin` and `bay_seg` columns
#'
#' @returns The same data frame with an additional `segment` column indicating the major bay segment associated with each row
#' 
#' @details
#' This is a simple helper function used internally with \code{\link{anlz_nps}} and \code{\link{util_nps_lusumm}} to create a `segment` column based on the `basin` and `bay_seg` columns.
#' 
#' @export
#' @examples
#' dat <- data.frame(
#'   basin = c("LTARPON", "TBYPASS", "02300500", "206-4", "EVERSRES", "UNKNOWN"),
#'   bay_seg = c(1, 2, 3, 4, 7, NA)
#' )
#' util_nps_segment(dat)
util_nps_segment <- function(dat){

  out <- dat |> 
    dplyr::mutate(
      segment = dplyr::case_when(
          basin %in% c("LTARPON", "02306647", "02307000", "02307359", "206-1") ~ 1,
          basin %in% c("TBYPASS", "02301750", "206-2", "02300700") ~ 2,
          basin %in% c("02301000", "02301300", "02303000", "02303330") ~ 2,
          basin %in% c("02301500", "02301695", "204-2") ~ 2,
          basin %in% c("02304500", "205-2") ~ 2,
          basin %in% c("02300500", "02300530", "203-3") ~ 3,
          basin %in% c("206-3C", "206-3E", "206-3W") ~ 3,
          basin == "206-4" ~ 4,
          basin == "206-5" | basin == "207-5" & bay_seg == 55 ~ 55,
          basin == "207-5" & bay_seg == 5 ~ 5,
          basin == "206-6" ~ 6,
          basin %in% c("EVERSRES", "LMANATEE", "202-7", "02299950") ~ 7,
          TRUE ~ NA
        ),
      segment = dplyr::case_when(
        segment == 1 ~ "Old Tampa Bay",
        segment == 2 ~ "Hillsborough Bay",
        segment == 3 ~ "Middle Tampa Bay",
        segment == 4 ~ "Lower Tampa Bay",
        segment == 5 ~ "Boca Ciega Bay",
        segment == 6 ~ "Terra Ceia Bay",
        segment == 7 ~ "Manatee River", 
        segment == 55 ~ "Boca Ciega Bay South", 
        TRUE ~ NA_character_
      )
    ) 
  
  return(out)
  
}