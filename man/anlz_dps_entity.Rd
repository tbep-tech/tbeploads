% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/anlz_dps_entity.R
\name{anlz_dps_entity}
\alias{anlz_dps_entity}
\title{Calculate DPS reuse and end of pipe from raw entity data}
\usage{
anlz_dps_entity(fls)
}
\arguments{
\item{fls}{vector of file paths to raw entity data, one to many}
}
\value{
data frame with loading data for TP, TN, TSS, and BOD as tons per month and hydro load as million cubic meters per month.  Information for each entity, facility, and outfall is retained.
}
\description{
Calculate DPS reuse and end of pipe from raw entity data
}
\details{
Input data should include flow as million gallons per day, and conc as mg/L.  Steps include:
\enumerate{
\item Multiply flow by day in month to get million gallons per month
\item Multiply flow by 3785.412 to get cubic meters per month
\item Multiply N by flow and divide by 1000 to get kg N per month
\item Multiply m3 by 1000 to get L, then divide by 1e6 to convert mg to kg, same as dividing by 1000
\item TN, TP, TSS, BOD dps reuse is multiplied by attenuation factor for land application (varies by location)
\item Hydro load (m3 / mo) is also attenuated for the reuse, multiplied by 0.6 (40\% attenuation)
}
}
\examples{
fls <- list.files(system.file('extdata/', package = 'tbeploads'),
  pattern = '\\\\.txt$', full.names = TRUE)
anlz_dps_entity(fls)
}
\seealso{
\code{\link{anlz_dps}}
}
