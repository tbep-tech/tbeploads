# Get flow data from for NPS calculations at gaged sites

Get flow data from for NPS calculations at gaged sites

## Usage

``` r
util_nps_getflow(
  lakemanpth = NULL,
  tampabypth = NULL,
  bellshlpth = NULL,
  yrrng = c(2021, 2023),
  usgsflow = NULL,
  verbose = TRUE
)
```

## Arguments

- lakemanpth:

  character, path to the file containing the Lake Manatee flow data

- tampabypth:

  character, path to the file containing the Tampa Bypass flow data

- bellshlpth:

  character, path to the file containing the Bell shoals data

- yrrng:

  vector of two integers, the year range for which to retrieve flow
  data. Default is c(2021, 2023).

- usgsflow:

  data frame of USGS flow data, if already available from
  [`util_nps_getusgsflow`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getusgsflow.md),
  otherwise NULL and the function will retrieve the data. Default is
  NULL.

- verbose:

  logical indicating whether to print verbose output

## Value

A data frame of monthly mean flow for fifteen USGS stations and three
external flow sites

## Details

Missing flow values are linearly interpolated using
[`na.approx`](https://rdrr.io/pkg/zoo/man/na.approx.html). The function
combines external and USGS API flow data using the `util_nps_getextflow`
and `util_nps_getusgsflow` functions.

A preprocessed USGS flow data frame can be provided using the `usgsflow`
argument to avoid re-downloading the data.

## See also

[`util_nps_getextflow`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getextflow.md),
[`util_nps_getusgsflow`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getusgsflow.md)

## Examples

``` r
if (FALSE) { # \dontrun{
usgsflow <- util_nps_getusgsflow(yrrng = as.Date(c('2021-01-01', '2023-12-31')))
} # }
lakemanpth <- system.file('extdata/nps_extflow_lakemanatee.xlsx', package = 'tbeploads')
tampabypth <- system.file('extdata/nps_extflow_tampabypass.xlsx', package = 'tbeploads')
bellshlpth <- system.file('extdata/nps_extflow_bellshoals.xls', package = 'tbeploads')
allflo <- util_nps_getflow(lakemanpth, tampabypth, bellshlpth, usgsflow = usgsflow)
```
