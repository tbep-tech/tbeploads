# Data frame of all water quality data used in [`anlz_nps_gaged`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps_gaged.md)

Data frame of all water quality data used in
[`anlz_nps_gaged`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps_gaged.md)

## Usage

``` r
allwq
```

## Format

A `data.frame` of monthly mean water quality data for select stations

## Details

Monthly water quality data for select stations used for estimating
non-point source gaged loads. Created using the
[`util_nps_getwq`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getwq.md)
function. Includes data from Manatee, Pinellas, and Hillsborough (EPCHC)
counties. The data frame contains the following columns:

- `basin`: Character string for the basin or station location

- `yr`: Year of the observation

- `mo`: Month of the observation

- `tn_mgl`: Numeric value for Total Nitrogen in mg/L

- `tp_mgl`: Numeric value for Total Phosphorus in mg/L

- `tss_mgl`: Numeric value for Total Suspended Solids in mg/L

- `bod_mgl`: Numeric value for Biochemical Oxygen Demand in mg/L

## See also

[`util_nps_getwq`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getwq.md)

## Examples

``` r
allwq
#> # A tibble: 730 × 7
#>    basin       yr    mo tn_mgl tp_mgl tss_mgl bod_mgl
#>    <chr>    <dbl> <dbl>  <dbl>  <dbl>   <dbl>   <dbl>
#>  1 02300500  2019     1  0.795  0.192      NA      NA
#>  2 02300500  2019     2  0.804  0.26       NA      NA
#>  3 02300500  2019     3  0.778  0.22       NA      NA
#>  4 02300500  2019     4  0.781  0.249      NA      NA
#>  5 02300500  2019     5  0.977  0.345      NA      NA
#>  6 02300500  2019     6  1.45   0.356      NA      NA
#>  7 02300500  2019     7  1.46   0.369      NA      NA
#>  8 02300500  2019     8  1.46   0.398      NA      NA
#>  9 02300500  2019     9  0.932  0.273      NA      NA
#> 10 02300500  2019    10  1.05   0.349      NA      NA
#> # ℹ 720 more rows
```
