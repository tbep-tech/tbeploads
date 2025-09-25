usgsflow <- util_nps_getusgsflow(yrrng = c('2021-01-01', '2023-12-31'), verbose = TRUE)

usethis::use_data(usgsflow, overwrite = TRUE)
