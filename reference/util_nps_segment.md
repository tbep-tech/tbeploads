# Create bay segment column for non-point source (NPS) load data

Create bay segment column for non-point source (NPS) load data

## Usage

``` r
util_nps_segment(dat)
```

## Arguments

- dat:

  data frame with a `basin` and `bay_seg` columns

## Value

The same data frame with an additional `segment` column indicating the
major bay segment associated with each row

## Details

This is a simple helper function used internally with
[`anlz_nps`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps.md)
and
[`util_nps_lusumm`](https://tbep-tech.github.io/tbeploads/reference/util_nps_lusumm.md)
to create a `segment` column based on the `basin` and `bay_seg` columns.

## Examples

``` r
dat <- data.frame(
  basin = c("LTARPON", "TBYPASS", "02300500", "206-4", "EVERSRES", "UNKNOWN"),
  bay_seg = c(1, 2, 3, 4, 7, NA)
)
util_nps_segment(dat)
#>      basin bay_seg          segment
#> 1  LTARPON       1    Old Tampa Bay
#> 2  TBYPASS       2 Hillsborough Bay
#> 3 02300500       3 Middle Tampa Bay
#> 4    206-4       4  Lower Tampa Bay
#> 5 EVERSRES       7    Manatee River
#> 6  UNKNOWN      NA             <NA>
```
