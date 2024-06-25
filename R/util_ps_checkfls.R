#' Create a data frame of formatting issues with point source input files
#'
#' Create a data frame of formatting issues with point source input files
#'
#' @param fls vector of file paths to raw facility data, one to many
#'
#' @details The \code{chk} column indicates the issue with the file and will indicate \code{"ok"} if no issues are found, \code{"read error"} if the file cannot be read, and \code{"check columns"} if the column names are not as expected.  Any file not showing \code{"ok"} should be checked for issues.
#'
#' All files are checked with \code{\link{util_ps_checkuni}} if a file does not have a read error.
#'
#' The function cannot be used with files for material losses.
#'
#' @importFrom tidyr unnest
#' @importFrom tibble enframe
#'
#' @return A \code{data.frame} with three columns indicating \code{name} for the file name, \code{chk} for the file issue, and \code{nms} for a concatenated string of column names for the file
#'
#' @export
#'
#' @examples
#' fls <- system.file('extdata/ps_dom_hillsco_falkenburg_2019.txt', package = 'tbeploads')
#' util_ps_checkfls(fls)
util_ps_checkfls <- function(fls){

  out <- vector(length = length(fls), mode = 'list')
  names(out) <- basename(fls)
  for(fl in fls){

    # read in file
    dat <- try(read.table(fl, sep = '\t', header = T, skip = 0), silent = T)

    if(inherits(dat, 'try-error')){
      chk <- 'read error'
      nms <- NA
      cmb <- data.frame(chk = chk, nms = nms)
      out[[basename(fl)]] <- cmb
      next()
    }

    # check column names
    chk <- try(util_ps_checkuni(dat), silent = T)
    if(inherits(chk, 'try-error')){
      chk <- 'check columns'
    } else {
      chk <- 'ok'
    }

    nms <- paste0(names(dat), collapse = ', ')
    cmb <- data.frame(chk = chk, nms = nms)
    out[[basename(fl)]] <- cmb

  }

  out <- enframe(out) |>
    unnest('value')

  return(out)

}
