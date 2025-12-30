# Get flow data from USGS for NPS calculations

Get flow data from USGS for NPS calculations

## Usage

``` r
util_nps_getusgsflow(
  site = NULL,
  yrrng = c("2021-01-01", "2023-12-31"),
  verbose = TRUE
)
```

## Arguments

- site:

  A character vector of USGS site numbers. If NULL, defaults to a
  predefined set of sites. Default is NULL, see details.

- yrrng:

  A vector of two dates in 'YYYY-MM-DD' format, specifying the date
  range to retrieve flow data. Default is from '2021-01-01' to
  '2023-12-31'.

- verbose:

  logical indicating whether to print verbose output

## Value

A data frame of daily flow values in cfs for fifteen stations

## Details

Stations are from the USGS NWIS database and include 02299950, 02300042,
02300500, 02300700, 02301000, 02301300, 02301500, 02301750, 02303000,
02303330, 02304500, 02306647, 02307000, 02307359, and 02307498. Uses the
[`read_waterdata_daily`](https://rdrr.io/pkg/dataRetrieval/man/read_waterdata_daily.html)
function from the `dataRetrieval` package.

## Examples

``` r
if (FALSE) { # \dontrun{
usgsflow <- util_nps_getusgsflow()
} # }
```
