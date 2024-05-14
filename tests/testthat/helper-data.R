library(dplyr)

psdompth <- system.file('extdata/ps_dom_hillsco_falkenburg_2019.txt', package = 'tbeploads')
fls <- list.files(system.file('extdata/', package = 'tbeploads'), full.names = TRUE)
psdomfls <- fls[grepl('ps_dom', fls)]
dps <- anlz_dps_facility(psdomfls)
