# Fill in missing water quality values for non-point source (NPS) data

Fill in missing water quality values for non-point source (NPS) data

## Usage

``` r
util_nps_fillmiswq(wq, yrrng = c("2021-01-01", "2023-12-31"))
```

## Arguments

- wq:

  A data frame of water quality data returned by `util_nps_getwq`

- yrrng:

  A vector of two dates in 'YYYY-MM-DD' format, specifying the date
  range to retrieve flow data. Default is from '2021-01-01' to
  '2023-12-31'.

## Value

Input data frame with missing data filled as described above.

## Details

Missing end date monthly values are filled with prior 5 year averages.
Then, missing monthly values are linearly interpolated using
[`na.approx`](https://rdrr.io/pkg/zoo/man/na.approx.html).

## Examples

``` r
if (FALSE) { # \dontrun{
data(allwq)
wq <- util_nps_fillmiswq(allwq)
} # }
```
