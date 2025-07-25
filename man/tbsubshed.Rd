% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tbsubshed.R
\docType{data}
\name{tbsubshed}
\alias{tbsubshed}
\title{Simple feature polygons of sub-watersheds in the Tampa Bay Estuary Program boundary}
\format{
A \code{\link[sf]{sf}} object
}
\usage{
tbsubshed
}
\description{
Simple feature polygons of sub-watersheds in the Tampa Bay Estuary Program boundary
}
\details{
Used for estimating ungaged non-point source (NPS) loads. The data includes bay segment as follows:

\itemize{
\item 1: Old Tampa Bay
\item 2: Hillsborough Bay
\item 3: Middle Tampa Bay
\item 4: Lower Tampa Bay
\item 5: Boca Ciega Bay
\item 6: Terra Ceia Bay
\item 7: Manatee River
\item 55: Boca Ciega Bay South
}

Projection is NAD83(2011) / Florida West (ftUS), CRS 6443.
}
\examples{
\dontrun{
prj <- 6443

tbsubshed <- sf::st_read("./data-raw/gis/TBEP_Major_Basins_NAD1983_SP_FIPS0902_FT.shp") |>
  sf::st_transform(prj) |>
  sf::st_buffer(dist = 0) |>
  dplyr::mutate(
    bay_seg = dplyr::case_when(
      BASINNAME \%in\% c('Coastal Old Tampa Bay') ~ 1,
      BASINNAME \%in\% c('Alafia River', 'Coastal Hillsborough Bay', 'Hillsborough River') ~ 2,
      BASINNAME \%in\% c('Coastal Middle Tampa Bay', 'Little Manatee River') ~ 3,
      BASINNAME \%in\% c('Coastal Lower Tampa Bay') ~ 4,
      BASINNAME \%in\% c('Upper Boca Ciega Bay') ~ 5,
      BASINNAME \%in\% c('Coastal Terra Ceia Bay') ~ 6,
      BASINNAME \%in\% c('Manatee River') ~ 7,
      BASINNAME \%in\% c('Lower Boca Ciega Bay') ~ 55,
    )
  ) |>
  dplyr::group_by(bay_seg) |>
  dplyr::summarise(geometry = sf::st_union(geometry), .groups = "drop")

save(tbsubshed, file = 'data/tbsubshed.RData', compress = 'xz')
}
tbsubshed
}
\keyword{datasets}
