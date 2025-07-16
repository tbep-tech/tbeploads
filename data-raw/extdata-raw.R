library(here)
library(tidyverse)


# randomize data in inst/extdata files based on their statistical characteristics -------------

# file list
fls <- list.files(here('inst/extdata'), pattern = 'txt', full.names = TRUE)

# columns to exclude
nmsexc <- c('Permit.Number', 'Facility.Name', 'Year', 'Month', 'Outfall.ID')

# function to randomize the vector based on the mean and sd
rn_fun <- function(x){

  if(all(is.na(x)))
    return(x)

  if(!all(is.numeric(x)))
    return(x)

  x <- log(x + 1e-8)

  avex <- mean(x, na.rm = T)
  sdx <- sd(x, na.rm = T)
  if(is.na(sdx))
    sdx <- abs(avex)
  lenx <- length(x)

  x <- rlnorm(lenx, avex, sdx)

  return(x)

}

dat <- tibble::tibble(
    fls = fls
  ) |>
  dplyr::group_by(fls) |>
  tidyr::nest(.key = 'dat') |>
  dplyr::mutate(
    dat = purrr::map(fls, read.table, skip = 0, sep = '\t', header = T),
    dat = purrr::map(dat, function(x){

      x |>
        dplyr::mutate(
          dplyr::across(
            !dplyr::any_of(nmsexc), rn_fun
          )
        )

    })
  )

walk2(dat$fls, dat$dat, ~ write.table(.y, here(.x), sep = '\t', row.names = F, quote = F))
