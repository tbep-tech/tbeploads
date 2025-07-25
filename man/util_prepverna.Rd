% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/util_prepverna.R
\name{util_prepverna}
\alias{util_prepverna}
\title{Prep Verna Wellfield data for use in AD and NPS calculations}
\usage{
util_prepverna(fl, fillmis = T)
}
\arguments{
\item{fl}{text string for the file path to the Verna Wellfield data}

\item{fillmis}{logical indicating whether to fill missing data with monthly means}
}
\value{
A data frame with total nitrogen and phosphorus estimates as mg/l for each year and month of the input data
}
\description{
Prep Verna Wellfield data for use in AD and NPS calculations
}
\details{
Raw data can be obtained from \url{https://nadp.slh.wisc.edu/sites/ntn-FL41/} as monthly observations.  Total nitrogen and phosphorus concentrations are estimated from ammonium and nitrate concentrations (mg/L) using the following relationships:

\deqn{TN = NH_4^+ * 0.78 + NO_3^- * 0.23}
\deqn{TP = 0.01262 * TN + 0.00110}

The first equation corrects for the \% of ions in ammonium and nitrate that is N, and the second is a regression relationship between TBADS TN and TP, applied to Verna.
}
\examples{
fl <- system.file('extdata/verna-raw.csv', package = 'tbeploads')
util_prepverna(fl)
}
