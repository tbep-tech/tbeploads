allwq <- util_nps_getwq(yrrng = c('2019-01-01', '2024-12-31'), verbose = T)

usethis::use_data(allwq, overwrite = TRUE)
