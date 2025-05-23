library(dplyr)
library(here)

##
# create distance (m) and inv distance squared (1/m^2) between segment locations and NWS sites

# Load data frame for NWS rainfall station coordinates
nwssite <- read.csv(here('data-raw/nwssite.csv'))

# Create data frame for segment coordinates
segmentxy <- read.csv(file = "./data-raw/ad_targetxy.csv") |>
  rename(
    segment = target,
    seg_x = targ_x,
    seg_y = targ_y
  )

# Create a data frame to store ad_distance calculations
ad_distance <- data.frame(segment = numeric(),
                       seg_x = numeric(),
                       seg_y = numeric(),
                       matchsit = numeric(),
                       distance = numeric(),
                       invdist2 = numeric(),
                       stringsAsFactors = FALSE)

# Loop through each segment location
for (i in 1:nrow(segmentxy)) {
  # Loop through each National Weather Service (NWS) site
  for (j in 1:nrow(nwssite)) {
    # Calculate ad_distance between the segment and NWS site
    distance_ij <- sqrt((segmentxy$seg_x[i] - nwssite$nws_x[j])^2 + (segmentxy$seg_y[i] - nwssite$nws_y[j])^2)

    # Check if the distance is within the radius
    if (distance_ij < 50000) {
      # Store the information in the distance data frame
      ad_distance[nrow(ad_distance) + 1, ] <- c(segmentxy$segment[i],
                                          segmentxy$seg_x[i],
                                          segmentxy$seg_y[i],
                                          nwssite$nwssite[j],
                                          distance_ij,
                                          1/(distance_ij^2))
    }
  }
}

# add segment area
ad_distance <- ad_distance |>
  mutate(
    area = case_when(
      segment == 1 ~ 23407.05,
      segment == 2 ~ 10778.41,
      segment == 3 ~ 29159.64,
      segment == 4 ~ 24836.54,
      segment == 5 ~ 9121.87,
      segment == 6 ~ 1619.89,
      segment == 7 ~ 4153.22
    )
  )

usethis::use_data(ad_distance, overwrite = TRUE)
