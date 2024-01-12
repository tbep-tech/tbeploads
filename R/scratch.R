library(haven)
library(here)
library(dplyr)

data(facilities)

pth <- 'T:/03_BOARDS_COMMITTEES/05_TBNMC/2022_RA_Update/01_FUNDING_OUT/DELIVERABLES/TO-9/datastick_deliverables/LoadingCodes&Datasets/'

# fls <- list.files(pth, pattern = '\\.txt$', recursive = T, full.names = F)
# fls2 <- fls %>%
#   grep('Domestic', ., value = T) %>%
#   grep('Hills|Pete|Clearwater|Largo|Oldsmar|Pinellas', ., value = T)
# write.csv(fls2, file = here('inst/extdata/tmp.csv'), row.names = F))

# file crosswalk for otb

cw <- read.csv(here('inst/extdata/otbdpscrosswalk.csv'), stringsAsFactors = F) %>%
  unite('flnm', source, entityshr, facnameshr, year, sep = '_', remove = F)

out <- ls()
for(i in 1:nrow(cw)){

  # setup names
  fl <- paste0(pth, cw$fl[i])
  nm <- cw$flnm[i]
  flout <- here('inst/extdata/', paste0(nm, '.txt'))

  # copy file
  file.copy(fl, flout)

  # read in file
  tmp <- try(read.csv(flout, sep = '\t'), silent = T)
  if(class(tmp) == 'try-error')
    tmp <- NA

  tmp <- list(tmp)
  names(tmp) <- nm

  out <- c(out, tmp)

}



