# Historic 1992-1994 mean total water load baseline by bay segment and basin

Historic 1992-1994 mean total water load baseline by bay segment and
basin

## Usage

``` r
hydro_baseline
```

## Format

A `data.frame`

## Details

Mean total water load for the 1992-1994 baseline period, used for
hydrologic normalization in the allocation assessment. Values are in
million cubic meters per year.

- `bay_seg`: Integer bay segment identifier

- `basin`: Drainage basin identifier

- `mean_h2o_9294`: Mean 1992-1994 total water load (million m3/yr)

See "data-raw/hydro_baseline.R" for creation.

## Examples

``` r
hydro_baseline
#> # A tibble: 29 × 3
#>    bay_seg basin    mean_h2o_9294
#>      <int> <chr>            <dbl>
#>  1       1 02306647         14.5 
#>  2       1 02307000         22.1 
#>  3       1 02307359          5.10
#>  4       1 206-1           100.  
#>  5       1 LTARPON          19.8 
#>  6       2 02300700         43.9 
#>  7       2 02301500        224.  
#>  8       2 02301695          3.86
#>  9       2 02301750          8.66
#> 10       2 02304500        116.  
#> # ℹ 19 more rows
```
