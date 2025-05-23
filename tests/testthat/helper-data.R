library(dplyr)

psdompth <- system.file('extdata/ps_dom_hillsco_falkenburg_2019.txt', package = 'tbeploads')
psindpth <- system.file('extdata/ps_ind_busch_busch_2020.txt', package = 'tbeploads')
fls <- list.files(system.file('extdata/', package = 'tbeploads'), full.names = TRUE)
psdomfls <- fls[grepl('ps_dom', fls)]
psindfls <- fls[grepl('ps_ind_', fls)]
indmlfls <- fls[grepl('ps_indml', fls)]
vernafl <- system.file('extdata/verna-raw.csv', package = 'tbeploads')
dps <- anlz_dps_facility(psdomfls)
ips <- anlz_ips_facility(psindfls)
ml <- anlz_ml_facility(indmlfls)
