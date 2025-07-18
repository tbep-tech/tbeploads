% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/util_nps_getswfwmd.R
\name{util_nps_getswfwmd}
\alias{util_nps_getswfwmd}
\title{Retrieve non-point source (NPS) supporting data from SWFWMD web services}
\usage{
util_nps_getswfwmd(dat, max_records = 1000, verbose = TRUE)
}
\arguments{
\item{dat}{Character string indicating the type of data to retrieve. Options are 'soil', 'lulc2020', or 'lulc2023'.}

\item{max_records}{Integer specifying the maximum number of records to retrieve in each request. Default is 1000.}

\item{verbose}{Logical indicating whether to print verbose output. Default is TRUE.}
}
\value{
A simple features object for the relevant data, clipped by the Tampa Bay watershed boundary (\code{\link{tbfullshed}}).
}
\description{
Retrieve non-point source (NPS) supporting data from SWFWMD web services
}
\details{
This function retrieves data from the SWFWMD web services for soils and land use/land cover (LULC) for the years 2020 and 2023. Soils data from \url{https://www25.swfwmd.state.fl.us/arcgis12/rest/services/BaseVector} and land use data from \url{https://www25.swfwmd.state.fl.us/arcgis12/rest/services/OpenData}.
}
\examples{
\dontrun{
# Retrieve soil data
soil_data <- util_nps_getswfwmd('soil')

# Retrieve LULC data for 2020
lulc2020_data <- util_nps_getswfwmd('lulc2020')

# Retrieve LULC data for 2023
lulc2023_data <- util_nps_getswfwmd('lulc2023')

}
}
