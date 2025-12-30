# Data frame of daily rainfall data from NOAA NCDC National Weather Service (NWS) sites from 2017 to 2023

Data frame of daily rainfall data from NOAA NCDC National Weather
Service (NWS) sites from 2017 to 2023

## Usage

``` r
rain
```

## Format

A `data.frame`

## Details

Used for estimating atmospheric deposition and non-point source ungaged
loads. Created using the
[`util_getrain`](https://tbep-tech.github.io/tbeploads/reference/util_getrain.md)
function. The data frame contains the following columns:

- `station`: Character string for the station id

- `date`: Date for the observation

- `Year`: Numeric value for the year of the observation

- `Month`: Numeric value for the month of the observation

- `Day`: Numeric value for the day of the observation

- `rainfall`: Numeric value for the amount of rainfall in inches

## See also

[`util_getrain`](https://tbep-tech.github.io/tbeploads/reference/util_getrain.md)

## Examples

``` r
rain
#> # A tibble: 37,999 × 6
#>    station date        Year Month   Day rainfall
#>      <dbl> <date>     <int> <dbl> <int>    <dbl>
#>  1     228 2017-01-01  2017     1     1     0   
#>  2     228 2017-01-02  2017     1     2     0   
#>  3     228 2017-01-03  2017     1     3     0   
#>  4     228 2017-01-04  2017     1     4     0   
#>  5     228 2017-01-05  2017     1     5     0.02
#>  6     228 2017-01-06  2017     1     6     0   
#>  7     228 2017-01-07  2017     1     7     0.05
#>  8     228 2017-01-08  2017     1     8     0.16
#>  9     228 2017-01-09  2017     1     9     0   
#> 10     228 2017-01-10  2017     1    10     0   
#> # ℹ 37,989 more rows
```
