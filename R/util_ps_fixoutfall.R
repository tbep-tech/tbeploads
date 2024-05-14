#' Light edits to the outfall ID column for point source data
#'
#' Light edits to the outfall ID column for point source data
#'
#' @param dat data frame from raw entity data as \code{data.frame}
#'
#' @details
#' The outfall ID column is edited lightly to remove any leading or trailing white space, a hyphen is added between letters and numbers if missing, and "Outfall" prefix is removed if presenn.
#'
#' @return Input data frame as is, with any edits to the outfall ID column.
#'
#' @export
#'
#' @examples
#' pth <- system.file('extdata/ps_ind_busch_busch_2020.txt', package = 'tbeploads')
#' dat <- read.table(pth, skip = 0, sep = '\t', header = TRUE)
#' util_ps_fixoutfall(dat)
util_ps_fixoutfall <- function(dat){

  out <- dat |>
    dplyr::mutate(
      Outfall.ID = gsub('Outfall', '', Outfall.ID),
      Outfall.ID = trimws(Outfall.ID),
      Outfall.ID = gsub('([A-Za-z])([0-9])', '\\1-\\2', Outfall.ID)
    )

  return(out)

}
