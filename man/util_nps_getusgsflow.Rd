% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/util_nps_getusgflow.R
\name{util_nps_getusgsflow}
\alias{util_nps_getusgsflow}
\title{Get flow data from USGS for NPS calculations}
\usage{
util_nps_getusgsflow(site = NULL, yrrng = c("2021-01-01", "2023-12-31"))
}
\arguments{
\item{site}{A character vector of USGS site numbers. If NULL, defaults to a predefined set of sites. Default is NULL, see details.}

\item{yrrng}{A vector of two dates in 'YYYY-MM-DD' format, specifying the date range to retrieve flow data. Default is from '2021-01-01' to '2023-12-31'.}
}
\value{
A data frame of daily flow values in cfs for fifteen stations
}
\description{
Get flow data from USGS for NPS calculations
}
\details{
Stations are from the USGS NWIS database and include 02299950, 02300042, 02300500, 02300700, 02301000, 02301300, 02301500, 02301750, 02303000, 02303330, 02304500, 02306647, 02307000, 02307359, and 02307498.
}
\examples{
usgsflo <- util_nps_getusgsflow()
}
