# Data frame of USGS stream flow data from the USGS NWIS database for 2021 to 2023

Data frame of USGS stream flow data from the USGS NWIS database for 2021
to 2023

## Usage

``` r
usgsflow
```

## Format

A `data.frame`

## Details

Daily flow data at select stations used for estimating non-point source
gaged and ungaged loads. Created using the
[`util_nps_getusgsflow`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getusgsflow.md)
function. The file is provided to reduce calls to the USGS API. The data
frame contains the following columns:

- `site_no`: Character string for the site number

- `date`: Date for the observation

- `flow_cfs`: Numeric value for the daily flow in cubic feet per second
  (cfs)

## See also

[`util_nps_getusgsflow`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getusgsflow.md)

## Examples

``` r
usgsflow
#> # A tibble: 16,361 × 3
#>    site_no  date       flow_cfs
#>    <chr>    <date>        <dbl>
#>  1 02299950 2021-01-01     21.1
#>  2 02299950 2021-01-02     20  
#>  3 02299950 2021-01-03     20.8
#>  4 02299950 2021-01-04     21.5
#>  5 02299950 2021-01-05     19.4
#>  6 02299950 2021-01-06     19.2
#>  7 02299950 2021-01-07     19.5
#>  8 02299950 2021-01-08     22.1
#>  9 02299950 2021-01-09     26.8
#> 10 02299950 2021-01-10     23  
#> # ℹ 16,351 more rows
```
