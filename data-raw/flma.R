library(devtools)
library(sf)

devtools::load_all()

# Florida Conservation Lands (FLMA) from FNAI.
# Download URL: https://www.fnai.org/Data.cfm (select "Florida Conservation Lands")

url <- "https://www.fnai.org/shapefiles/flma_202503.zip"

flma <- util_nps_getflma(url = url)

save(flma, file = "data/flma.RData", compress = "xz")
