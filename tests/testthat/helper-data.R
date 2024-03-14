library(dplyr)

pth <- system.file('extdata/ps_dom_hillsco_falkenburg_2019.txt', package = 'tbeploads')
fls <- list.files(system.file('extdata/', package = 'tbeploads'), pattern = '\\.txt$', full.names = TRUE)
