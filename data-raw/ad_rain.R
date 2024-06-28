
noaa_key <- Sys.getenv("NOAA_KEY")
yrs <- 2017:2023
ad_rain <- util_ad_getrain(yrs, noaa_key = noaa_key)

usethis::use_data(ad_rain, overwrite = TRUE)
