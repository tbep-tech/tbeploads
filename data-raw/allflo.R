lakemanpth <- system.file('extdata/nps_extflow_lakemanatee.xlsx', package = 'tbeploads')
tampabypth <- system.file('extdata/nps_extflow_tampabypass.xlsx', package = 'tbeploads')
bellshlpth <- system.file('extdata/nps_extflow_bellshoals.xls', package = 'tbeploads')
data(usgsflow)

allflo <- util_nps_getflow(lakemanpth, tampabypth, bellshlpth, 
  yrrng = c(2021, 2023), usgsflow = usgsflow, verbose = T)

usethis::use_data(allflo, overwrite = TRUE)
