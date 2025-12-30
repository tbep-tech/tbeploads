# Calculate IPS loads and summarize

Calculate IPS loads and summarize

## Usage

``` r
anlz_ips(
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
[`anlz_ips_facility`](https://tbep-tech.github.io/tbeploads/reference/anlz_ips_facility.md)
to calculate IPS loads for each facility and outfall. The data are
summarized differently based on the `summ` and `summtime` arguments. All
loading data are summed based on these arguments, e.g., by bay segment
(`summ = 'segment'`) and year (`summtime = 'year'`).

## See also

[`anlz_ips_facility`](https://tbep-tech.github.io/tbeploads/reference/anlz_ips_facility.md)

## Examples

``` r
fls <- list.files(system.file('extdata/', package = 'tbeploads'),
  pattern = 'ps_ind_', full.names = TRUE)
anlz_ips(fls)
#> # A tibble: 60 × 10
#>     Year Month source entity   segment tn_load tp_load tss_load bod_load hy_load
#>    <int> <int> <chr>  <chr>    <chr>     <dbl>   <dbl>    <dbl>    <dbl>   <dbl>
#>  1  2020     1 IPS    Busch G… Hillsb…  0.0195 0.00253    0.443    0.850  0.0804
#>  2  2020     2 IPS    Busch G… Hillsb…  0.0306 0.00328    0.544    1.04   0.0987
#>  3  2020     3 IPS    Busch G… Hillsb…  0.0972 0.00925    1.39     2.68   0.253 
#>  4  2020     4 IPS    Busch G… Hillsb…  0.0398 0.0258     0.522    1.00   0.0946
#>  5  2020     5 IPS    Busch G… Hillsb…  0.0820 0.00514    0.506    0.971  0.0917
#>  6  2020     6 IPS    Busch G… Hillsb…  0.0112 0.00594    0.355    0.681  0.0644
#>  7  2020     7 IPS    Busch G… Hillsb…  0.0430 0.00413    0.506    0.971  0.0918
#>  8  2020     8 IPS    Busch G… Hillsb…  0.0167 0.00225    0.199    0.382  0.0361
#>  9  2020     9 IPS    Busch G… Hillsb…  0.0226 0.00307    0.332    0.638  0.0603
#> 10  2020    10 IPS    Busch G… Hillsb…  0.0187 0.0186     0.333    0.638  0.0603
#> # ℹ 50 more rows
```
