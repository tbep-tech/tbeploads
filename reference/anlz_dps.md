# Calculate DPS reuse and end of pipe loads and summarize

Calculate DPS reuse and end of pipe loads and summarize

## Usage

``` r
anlz_dps(
  fls,
  summ = c("entity", "facility", "segment", "all"),
  summtime = c("month", "year")
)
```

## Arguments

- fls:

  vector of file paths to raw entity data, one to many

- summ:

  chr string indicating how the returned data are summarized, see
  details

- summtime:

  chr string indicating how the returned data are summarized temporally
  (month or year), see details

## Value

data frame with loading data for TP, TN, TSS, and BOD as tons per
month/year and hydro load as million cubic meters per month/year

## Details

Input data files in `fls` are first processed by
[`anlz_dps_facility`](https://tbep-tech.github.io/tbeploads/reference/anlz_dps_facility.md)
to calculate DPS reuse and end of pipe for each facility and outfall.
The data are summarized differently based on the `summ` and `summtime`
arguments. All loading data are summed based on these arguments, e.g.,
by bay segment (`summ = 'segment'`) and year (`summtime = 'year'`).

## See also

[`anlz_dps_facility`](https://tbep-tech.github.io/tbeploads/reference/anlz_dps_facility.md)

## Examples

``` r
fls <- list.files(system.file('extdata/', package = 'tbeploads'),
  pattern = 'ps_dom', full.names = TRUE)
anlz_dps(fls)
#> # A tibble: 108 × 10
#>     Year Month source   entity segment tn_load tp_load tss_load bod_load hy_load
#>    <int> <int> <chr>    <chr>  <chr>     <dbl>   <dbl>    <dbl>    <dbl>   <dbl>
#>  1  2021     1 DPS - e… Clear… Old Ta…  0.862  6.04     0.452    1.14     0.663 
#>  2  2021     1 DPS - r… Clear… Old Ta…  0.102  0.00852  0.00844  0.0473   0.165 
#>  3  2021     2 DPS - e… Clear… Old Ta…  1.37   1.15     0.553    2.87     0.948 
#>  4  2021     2 DPS - r… Clear… Old Ta…  0.210  0.0416   0.0169   0.0244   0.319 
#>  5  2021     3 DPS - e… Clear… Old Ta…  1.70   0.575    0.982    3.31     1.83  
#>  6  2021     3 DPS - r… Clear… Old Ta…  0.261  0.0439   0.0194   0.0554   0.417 
#>  7  2021     4 DPS - e… Clear… Old Ta…  0.344  0.0801   0.105    0.656    0.194 
#>  8  2021     4 DPS - r… Clear… Old Ta…  0.0472 0.00602  0.00245  0.00499  0.0563
#>  9  2021     5 DPS - e… Clear… Old Ta…  1.09   0.460    0.603    2.23     0.874 
#> 10  2021     5 DPS - r… Clear… Old Ta…  0.0354 0.00281  0.00298  0.00885  0.0729
#> # ℹ 98 more rows
```
