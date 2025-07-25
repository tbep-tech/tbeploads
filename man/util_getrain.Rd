% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/util_getrain.R
\name{util_getrain}
\alias{util_getrain}
\title{Get rainfall data at NOAA NCDC sites for atmospheric deposition and non-point source ungaged calculations}
\usage{
util_getrain(yrs, station = NULL, noaa_key, ntry = 5, quiet = FALSE)
}
\arguments{
\item{yrs}{numeric vector for the years of data to retrieve}

\item{station}{numeric vector of station numbers to retrieve, see details}

\item{noaa_key}{character for the NOAA API key}

\item{ntry}{numeric for the number of times to try to download the data}

\item{quiet}{logical to print progress in the console}
}
\value{
a data frame with the following columns:

\itemize{
\item \code{station}: numeric, the station id
\item \code{date}: Date, the date of the observation
\item \code{Year}: numeric, the year of the observation
\item \code{Month}: numeric, the month of the observation
\item \code{Day}: numeric, the day of the observation
\item \code{rainfall}: numeric, the amount of rainfall in inches
}
}
\description{
Get rainfall data at NOAA NCDC sites for atmospheric deposition and non-point source ungaged calculations
}
\details{
This function is used to retrieve a long-term record of rainfall for estimating AD and NPS ungaged loads.  It is used to create an input data file for load calculations and it is not used directly by any other functions due to download time.  A NOAA API key is required to use the function.

By default, rainfall data is retrieved for the following stations:

\itemize{
\item \code{228}: ARCADIA
\item \code{478}: BARTOW
\item \code{520}: BAY LAKE
\item \code{940}: BRADENTON EXPERIMENT
\item \code{945}: BRADENTON 5 ESE
\item \code{1046}: BROOKSVILLE CHIN HIL
\item \code{1163}: BUSHNELL 2 E
\item \code{1632}: CLEARWATER
\item \code{1641}: CLERMONT 7 S
\item \code{2806}: ST PETERSBURG WHITTD
\item \code{3153}: FORT GREEN 12 WSW
\item \code{3986}: HILLSBOROUGH RVR SP
\item \code{4707}: LAKE ALFRED EXP STN
\item \code{5973}: MOUNTAIN LAKE
\item \code{6065}: MYAKKA RIVER STATE P
\item \code{6880}: PARRISH
\item \code{7205}: PLANT CITY
\item \code{7851}: ST LEO
\item \code{7886}: ST PETERSBURG WHITTD
\item \code{8788}: TAMPA INTL ARPT
\item \code{8824}: TARPON SPNGS SWG PLT
\item \code{9176}: VENICE
\item \code{9401}: WAUCHULA 2 N
}
}
\examples{
\dontrun{
noaa_key <- Sys.getenv('NOAA_KEY')
util_getrain(2021, 228, noaa_key)
}
}
\seealso{
\code{\link{rain}}
}
