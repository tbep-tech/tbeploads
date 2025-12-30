# Calculate material loss (ML) loads and summarize

Calculate material loss (ML) loads and summarize

## Usage

``` r
anlz_ml(
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

data frame with loading data for TN as tons per month/year. Columns for
TP, TSS, BOD, and hydrologic load are also returned with zero load for
consistency with other point source load calculation functions.

## Details

Input data files in `fls` are first processed by
[`anlz_ml_facility`](https://tbep-tech.github.io/tbeploads/reference/anlz_ml_facility.md)
to calculate ML loads for each facility. The data are summarized
differently based on the `summ` and `summtime` arguments. All loading
data are summed based on these arguments, e.g., by bay segment
(`summ = 'segment'`) and year (`summtime = 'year'`). Options for `summ`
are 'entity' to summarize by entity only, 'facility' to summarize by
facility only, 'segment' to summarize by bay segment, and 'all' to
summarize total load. Options for `summtime` are 'month' to summarize by
month and 'year' to summarize by year. The default is to summarize by
entity and month.

## See also

[`anlz_ml_facility`](https://tbep-tech.github.io/tbeploads/reference/anlz_ml_facility.md)

## Examples

``` r
fls <- list.files(system.file('extdata/', package = 'tbeploads'),
  pattern = 'ps_indml', full.names = TRUE)
anlz_ml(fls)
#> # A tibble: 60 × 10
#>     Year Month source entity segment   tn_load tp_load tss_load bod_load hy_load
#>    <int> <int> <chr>  <chr>  <chr>       <dbl>   <int>    <int>    <int>   <int>
#>  1  2020     1 ML     CSX    Hillsbor…  0.0743       0        0        0       0
#>  2  2020     2 ML     CSX    Hillsbor…  0.0743       0        0        0       0
#>  3  2020     3 ML     CSX    Hillsbor…  0.0743       0        0        0       0
#>  4  2020     4 ML     CSX    Hillsbor…  0.0743       0        0        0       0
#>  5  2020     5 ML     CSX    Hillsbor…  0.0743       0        0        0       0
#>  6  2020     6 ML     CSX    Hillsbor…  0.0743       0        0        0       0
#>  7  2020     7 ML     CSX    Hillsbor…  0.0743       0        0        0       0
#>  8  2020     8 ML     CSX    Hillsbor…  0.0743       0        0        0       0
#>  9  2020     9 ML     CSX    Hillsbor…  0.0743       0        0        0       0
#> 10  2020    10 ML     CSX    Hillsbor…  0.0743       0        0        0       0
#> # ℹ 50 more rows
```
