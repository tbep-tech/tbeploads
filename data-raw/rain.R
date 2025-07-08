
noaa_key <- Sys.getenv("NOAA_KEY")
yrs <- 2017:2023
rain <- util_getrain(yrs, noaa_key = noaa_key)

usethis::use_data(rain, overwrite = TRUE)
