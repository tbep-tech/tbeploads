# Download FDEP Upper Floridan Aquifer potentiometric surface contour lines

Download FDEP Upper Floridan Aquifer potentiometric surface contour
lines

## Usage

``` r
util_gw_getcontour(
  season = c("dry", "wet"),
  yr,
  max_records = 1000,
  verbose = TRUE
)
```

## Arguments

- season:

  character, `"dry"` or `"wet"`

- yr:

  integer, year for which to retrieve data. Biannual (May/September)
  observations are available from 2010 through 2022.

- max_records:

  integer, maximum number of records per paginated request. Default is
  1000.

- verbose:

  logical, if `TRUE` (default) progress messages are printed during
  download.

## Value

An [`sf`](https://r-spatial.github.io/sf/reference/sf.html) object of
`LINESTRING` features with columns `CONTOUR` (integer, feet MSL) and
`MONTH_YEAR` (character), in the same CRS as
[`tbfullshed`](https://tbep-tech.github.io/tbeploads/reference/tbfullshed.md)
(EPSG 6443). Returns `NULL` if no features are found for the requested
season/year.

## Details

Downloads contour lines representing the potentiometric surface of the
Upper Floridan Aquifer from the Florida Department of Environmental
Protection / Florida Geological Survey ArcGIS REST service
(<https://ca.dep.state.fl.us/arcgis/rest/services/OpenData/FGS_PUBLIC/MapServer/8>).

Contours are available biannually: `"dry"` season maps to May of `yr`
and `"wet"` season maps to September of `yr`. Results are spatially
filtered to the Tampa Bay watershed
([`tbfullshed`](https://tbep-tech.github.io/tbeploads/reference/tbfullshed.md))
and clipped to that boundary before return.

The `CONTOUR` field contains potentiometric surface elevations in feet
above mean sea level. These are used to compute the hydraulic gradient
driving Floridan Aquifer discharge to Tampa Bay segments (Darcy's Law).

## Examples

``` r
if (FALSE) { # \dontrun{
dry_contours <- util_gw_getcontour("dry", 2022)
wet_contours <- util_gw_getcontour("wet", 2022)
} # }
```
