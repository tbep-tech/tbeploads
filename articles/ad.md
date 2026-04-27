# Atmospheric Deposition (AD)

``` r
library(tbeploads)
```

Loading from atmospheric deposition (AD) for bay segments in the Tampa
Bay watershed are calculated using rainfall data from weather stations
in the watershed and atmospheric concentration data from the Verna
Wellfield site. Rainfall data must be obtained using the
[`util_getrain()`](https://tbep-tech.github.io/tbeploads/reference/util_getrain.md)
function before calculating loads. For convenience, daily rainfall data
from 2017 to 2023 at sites in the watershed are included with the
package in the
[`rain`](https://tbep-tech.github.io/tbeploads/reference/rain.md)
object.

``` r
head(rain)
#> # A tibble: 6 × 6
#>   station date        Year Month   Day rainfall
#>     <dbl> <date>     <int> <dbl> <int>    <dbl>
#> 1     228 2017-01-01  2017     1     1     0   
#> 2     228 2017-01-02  2017     1     2     0   
#> 3     228 2017-01-03  2017     1     3     0   
#> 4     228 2017-01-04  2017     1     4     0   
#> 5     228 2017-01-05  2017     1     5     0.02
#> 6     228 2017-01-06  2017     1     6     0
```

The Verna Wellfield data must also be obtained from
<https://nadp.slh.wisc.edu/sites/ntn-FL41/> as monthly observations.
This file is also included with the package and can be found using
[`system.file()`](https://rdrr.io/r/base/system.file.html) as follows:

``` r
vernafl <- system.file('extdata/verna-raw.csv', package = 'tbeploads')
vernafl
#> [1] "/home/runner/work/_temp/Library/tbeploads/extdata/verna-raw.csv"
```

During load calculation, the Verna data are converted to total nitrogen
and total phosphorus from ammonium and nitrate concentration data using
the
[`util_prepverna()`](https://tbep-tech.github.io/tbeploads/reference/util_prepverna.md)
function. Total nitrogen and phosphorus concentrations are estimated
from ammonium and nitrate concentrations (mg/L) using the following
relationships:

$$TN = NH_{4}^{+}*0.78 + NO_{3}^{-}*0.23$$

$$TP = 0.01262*TN + 0.00110$$

The first equation corrects for the % of ions in ammonium and nitrate
that are N, and the second is a regression relationship between TBADS TN
and TP, applied to Verna.

AD loads are estimated using the
[`anlz_ad()`](https://tbep-tech.github.io/tbeploads/reference/anlz_ad.md)
function, where total hydrologic load by bay segment is calculated from
the rain data and total nitrogen and phosphorus load is calculated by
multiplying hydrologic load by the atmospheric deposition concentrations
from the Verna data. Total hydrologic load for each bay segment is
calculated using daily estimates of rainfall at NWIS NCDC sites in the
watershed. This is done as a weighted mean of rainfall at the measured
sites relative to grid locations in each bay segment. The weights are
based on distance of the grid cells from the closest site as inverse
distance squared. Total hydrologic load for a sub-watershed is then
estimated by converting inches/month to m3/month using the area of each
bay segment. The distance data and bay segment areas are contained in
the file included with the package.

``` r
head(ad_distance)
#>   segment    seg_x   seg_y matchsit  distance     invdist2     area
#> 1       1 344902.2 3080488      520 26000.117 1.479277e-09 23407.05
#> 2       1 344902.2 3080488      940 39711.285 6.341210e-10 23407.05
#> 3       1 344902.2 3080488      945 44691.735 5.006631e-10 23407.05
#> 4       1 344902.2 3080488     1632 22105.640 2.046416e-09 23407.05
#> 5       1 344902.2 3080488     2806  8649.245 1.336730e-08 23407.05
#> 6       1 344902.2 3080488     3986 47920.032 4.354776e-10 23407.05
```

The total nitrogen and phosphorus loads are then estimated for each bay
segment by multiplying the total hydrologic load by the total nitrogen
and phosphorus concentrations in the Verna data. The loading
calculations also include a wet/dry deposition conversion factor to
account for differences in loading during the rainy and dry seasons.

Using
[`anlz_ad()`](https://tbep-tech.github.io/tbeploads/reference/anlz_ad.md)
to estimate AD load is done as follows, where
[`rain`](https://tbep-tech.github.io/tbeploads/reference/rain.md) is the
rain data and `vernafl` is the path to the Verna Wellfield data.

``` r
anlz_ad(rain, vernafl)
#> # A tibble: 672 × 7
#>     Year Month source segment        tn_load tp_load hy_load
#>    <int> <dbl> <chr>  <chr>            <dbl>   <dbl>   <dbl>
#>  1  2017     1 AD     Boca Ciega Bay   0.721  0.0140    1.98
#>  2  2017     2 AD     Boca Ciega Bay   0.945  0.0168    1.95
#>  3  2017     3 AD     Boca Ciega Bay   0.950  0.0181    2.48
#>  4  2017     4 AD     Boca Ciega Bay   3.05   0.0482    3.90
#>  5  2017     5 AD     Boca Ciega Bay   9.06   0.131     6.89
#>  6  2017     6 AD     Boca Ciega Bay   9.67   0.178    22.5 
#>  7  2017     7 AD     Boca Ciega Bay  10.8    0.189    26.2 
#>  8  2017     8 AD     Boca Ciega Bay   5.58   0.120    24.6 
#>  9  2017     9 AD     Boca Ciega Bay   2.14   0.0553   14.1 
#> 10  2017    10 AD     Boca Ciega Bay   2.03   0.0368    5.56
#> # ℹ 662 more rows
```

Results can be summarized by segment, baywide, monthly, or annually
using the `summ` and `summtime` arguments. By default, loads are
returned monthly for each segment. Note that Boca Ciega Bay and Boca
Ciega Bay South results are returned separately. Only Boca Ciega Bay
South is used when estimating total bay loads.
