library(dplyr)
library(here)

# Load data frame for NWS rainfall station coordinates
nwssite <- read.csv(file = "./data-raw/nwssite.csv")

# Create data frame for target coordinates
targetxy <- read.csv(file = "./data-raw/nps_targetxy.csv")

# Create a data frame to store distance calculations
nps_distance <- data.frame(target = numeric(),
                       targ_x = numeric(),
                       targ_y = numeric(),
                       matchsit = character(),
                       distance = numeric(),
                       invdist2 = numeric(),
                       stringsAsFactors = FALSE)

# Loop through each target location
for (i in 1:nrow(targetxy)) {
  # Loop through each National Weather Service (NWS) site
  for (j in 1:nrow(nwssite)) {
    # Calculate distance between the target and NWS site
    distance_ij <- sqrt((targetxy$targ_x[i] - nwssite$nws_x[j])^2 + (targetxy$targ_y[i] - nwssite$nws_y[j])^2)

    # Check if the distance is within the radius
    if (distance_ij < 50000) {
      # Store the information in the distance data frame
      nps_distance[nrow(nps_distance) + 1, ] <- c(targetxy$target[i],
                                          targetxy$targ_x[i],
                                          targetxy$targ_y[i],
                                          nwssite$nwssite[j],
                                          distance_ij,
                                          1/(distance_ij^2))
    }
  }
}

usethis::use_data(nps_distance, overwrite = TRUE)
