# Calculate AD loads and summarize

Calculate AD loads and summarize

## Usage

``` r
anlz_ad(
  rain,
  vernafl,
  summ = c("segment", "all"),
  summtime = c("month", "year")
)
```

## Arguments

- rain:

  data frame of daily rainfall data from NOAA NCDC, obtained using
  [`util_getrain`](https://tbep-tech.github.io/tbeploads/reference/util_getrain.md)

- vernafl:

  character vector of file path to Verna Wellfield atmospheric
  concentration data

- summ:

  chr string indicating how the returned data are summarized, see
  details

- summtime:

  chr string indicating how the returned data are summarized temporally
  (month or year), see details

## Value

A data frame with nitrogen and phosphorus loads in tons/month,
hydrologic load in million m3/month, and segment, year, and month as
columns if `summ = 'segment'` and `summtime = 'month'`. Total load to
all segments can be returned if `summ = 'all'` and annual summaries can
be returned if `summtime = 'year'`. In the former case, the total
excludes the northern portion of Boca Ciega Bay that is not included in
the reasonable assurance boundaries. In the latter case, loads are the
sum of monthly estimates such that output is tons/yr for TN and TP and
as million m3/yr for hydrologic load.

## Details

Loading from atmospheric deposition (AD) for bay segments in the Tampa
Bay watershed are calculated using rainfall data and atmospheric
concentration data from the Verna Wellfield site. Rainfall data must be
obtained using the
[`util_getrain`](https://tbep-tech.github.io/tbeploads/reference/util_getrain.md)
function before calculating loads. For convenience, daily rainfall data
from 2017 to 2023 at sites in the watershed are included with the
package in the
[`rain`](https://tbep-tech.github.io/tbeploads/reference/rain.md)
object. The Verna Wellfield data must also be obtained from
<https://nadp.slh.wisc.edu/sites/ntn-FL41/> as monthly observations.
This file is also included with the package and can be found using
[`system.file`](https://rdrr.io/r/base/system.file.html) as in the
examples below. Internally, the Verna data are converted to total
nitrogen and total phosphorus from ammonium and nitrate concentration
data (see
[`util_prepverna`](https://tbep-tech.github.io/tbeploads/reference/util_prepverna.md)
for additional information).

The function first estimates the total hydrologic load for each bay
segment using daily estimates of rainfall at NWIS NCDC sites in the
watershed. This is done as a weighted mean of rainfall at the measured
sites relative to grid locations in each sub-watershed for the bay
segments. The weights are based on distance of the grid cells from the
closest site as inverse distance squared. Total hydrologic load for a
bay segment is then estimated by converting inches/month to m3/month
using the segment area. The distance data and bay segment areas are
contained in the
[`ad_distance`](https://tbep-tech.github.io/tbeploads/reference/ad_distance.md)
file included with the package.

The total nitrogen and phosphorus loads are then estimated for each bay
segment by multiplying the total hydrologic load by the total nitrogen
and phosphorus concentrations in the Verna data. The loading
calculations also include a wet/dry deposition conversion factor to
account for differences in loading during the rainy and dry seasons.

## See also

[`util_getrain`](https://tbep-tech.github.io/tbeploads/reference/util_getrain.md),
[`util_prepverna`](https://tbep-tech.github.io/tbeploads/reference/util_prepverna.md)

## Examples

``` r
vernafl <- system.file('extdata/verna-raw.csv', package = 'tbeploads')
data(rain)
anlz_ad(rain, vernafl)
#> # A tibble: 672 × 7
#>     Year Month source segment        tn_load tp_load hy_load
#>    <int> <dbl> <chr>  <chr>            <dbl>   <dbl>   <dbl>
#>  1  2017     1 AD     Boca Ciega Bay   0.721  0.0140    1.98
#>  2  2017     2 AD     Boca Ciega Bay   0.945  0.0168    1.95
#>  3  2017     3 AD     Boca Ciega Bay   0.950  0.0181    2.48
#>  4  2017     4 AD     Boca Ciega Bay   0      0         3.90
#>  5  2017     5 AD     Boca Ciega Bay   9.06   0.131     6.89
#>  6  2017     6 AD     Boca Ciega Bay   9.67   0.178    22.5 
#>  7  2017     7 AD     Boca Ciega Bay  10.8    0.189    26.2 
#>  8  2017     8 AD     Boca Ciega Bay   5.58   0.120    24.6 
#>  9  2017     9 AD     Boca Ciega Bay   2.14   0.0553   14.1 
#> 10  2017    10 AD     Boca Ciega Bay   0      0         5.56
#> # ℹ 662 more rows
```
