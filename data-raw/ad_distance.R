library(dplyr)
library(here)

##
# create distance (m) and inv distance squared (1/m^2) between target and NWS sites

# Load data frame for NWS rainfall station coordinates
nwssite <- read.csv(here('data-raw/nwssite.csv'))

# Create data frame for target coordinates
targetxy <- read.csv(file = "./data-raw/ad_targetxy.csv")

# Create a data frame to store ad_distance calculations
ad_distance <- data.frame(target = numeric(),
                       targ_x = numeric(),
                       targ_y = numeric(),
                       matchsit = character(),
                       distance = numeric(),
                       invdist2 = numeric(),
                       stringsAsFactors = FALSE)

# Define labels for the variables
names(ad_distance) <- c("target", "targ_x", "targ_y", "matchsit", "distance", "invdist2")

# Loop through each target location
for (i in 1:nrow(targetxy)) {
  # Loop through each National Weather Service (NWS) site
  for (j in 1:nrow(nwssite)) {
    # Calculate ad_distance between the target and NWS site
    distance_ij <- sqrt((targetxy$targ_x[i] - nwssite$nws_x[j])^2 + (targetxy$targ_y[i] - nwssite$nws_y[j])^2)

    # Check if the distance is within the radius
    if (distance_ij < 50000) {
      # Store the information in the distance data frame
      ad_distance[nrow(ad_distance) + 1, ] <- c(targetxy$target[i],
                                          targetxy$targ_x[i],
                                          targetxy$targ_y[i],
                                          nwssite$nwssite[j],
                                          distance_ij,
                                          1/(distance_ij^2))
    }
  }
}

usethis::use_data(ad_distance, overwrite = TRUE)
