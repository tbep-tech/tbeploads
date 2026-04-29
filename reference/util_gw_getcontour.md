# Download and rasterize FDEP Upper Floridan Aquifer potentiometric surface

Download and rasterize FDEP Upper Floridan Aquifer potentiometric
surface

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

  character, `"dry"` or `"wet"`.

- yr:

  integer, year for which to retrieve data. Biannual (May/September)
  observations are available from approximately 2010 onward.

- max_records:

  integer, maximum records per paginated API request. Default 1000.

- verbose:

  logical, print download and interpolation progress. Default `TRUE`.

## Value

A
[`SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
of potentiometric head (ft above MSL) at 1-mile resolution in the CRS of
[`tbfullshed`](https://tbep-tech.github.io/tbeploads/reference/tbfullshed.md)
(EPSG 6443). Returns `NULL` with a warning if no features are found for
the requested season/year.

## Details

Downloads Upper Floridan Aquifer potentiometric surface contour lines
from the FDEP / Florida Geological Survey ArcGIS REST service
(<https://ca.dep.state.fl.us/arcgis/rest/services/OpenData/FGS_PUBLIC/MapServer/8>)
and interpolates them to a 1-mile `SpatRaster` using inverse distance
weighting (IDW).

**Spatial extent:** The API query covers the Tampa Bay watershed
([`tbfullshed`](https://tbep-tech.github.io/tbeploads/reference/tbfullshed.md))
buffered outward by 40 miles (211,200 US Survey Feet), converted to
WGS84. This wider extent captures the Polk County potentiometric
highlands that drive groundwater flow to Hillsborough Bay and
surrounding segments.

**Interpolation:** Contour line vertices are used as elevation
observations and interpolated to a 1-mile grid via IDW (5-mile radius,
power = 2). Cells more than 5 miles from any contour vertex are left
`NA` to avoid extrapolation into data-sparse regions. Five passes of a
3x3 focal mean then fill small gaps. The 5-mile radius was chosen to
bridge typical contour spacing in the Tampa Bay region without
extrapolating into the panhandle or coastal areas.

**Season mapping:**

- `"dry"` maps to May of `yr`

- `"wet"` maps to September of `yr`

## Examples

``` r
if (FALSE) { # \dontrun{
pot_dry <- util_gw_getcontour("dry", 2022)
pot_wet <- util_gw_getcontour("wet", 2022)
} # }
```
