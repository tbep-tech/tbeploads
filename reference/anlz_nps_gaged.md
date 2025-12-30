# Calculate non-point source (NPS) loads for gaged basins

Calculate non-point source (NPS) loads for gaged basins

## Usage

``` r
anlz_nps_gaged(
  yrrng = c("2021-01-01", "2023-12-31"),
  mancopth = NULL,
  pincopth = NULL,
  lakemanpth = NULL,
  tampabypth = NULL,
  bellshlpth = NULL,
  allflo = NULL,
  allwq = NULL,
  usgsflow = NULL,
  verbose = TRUE
)
```

## Arguments

- yrrng:

  A vector of two dates in 'YYYY-MM-DD' format, specifying the date
  range to retrieve flow data. Default is from '2021-01-01' to
  '2023-12-31'.

- mancopth:

  character, path to the Manatee County water quality data file, see
  details

- pincopth:

  character, path to the Pinellas County water quality data file, see
  details

- lakemanpth:

  character, path to the file containing the Lake Manatee flow data

- tampabypth:

  character, path to the file containing the Tampa Bypass flow data

- bellshlpth:

  character, path to the file containing the Bell shoals data

- allflo:

  data frame of flow data, if already available from
  [`util_nps_getflow`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getflow.md),
  otherwise NULL and the function will retrieve the data

- allwq:

  data frame of water quality data, if already available from
  [`util_nps_getwq`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getwq.md),
  otherwise NULL and the function will retrieve the data.

- usgsflow:

  data frame of USGS flow data, if already available from
  [`util_nps_getusgsflow`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getusgsflow.md),
  otherwise NULL and the function will retrieve the data. Default is
  NULL. Does not apply if `allflo` is provided.

- verbose:

  logical indicating whether to print verbose output

## Value

A data frame with columns for basin, year, month, TN in mg/L, TP in
mg/L, TSS in mg/L, BOD in mg/L, flow in liters/month, hydrologic load in
m3/month, TN load in kg/month, TP load in kg/month, TSS load in
kg/month, and BOD load in kg/month.

## Details

The function uses
[`util_nps_getflow`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getflow.md)
to retrieve flow data and
[`util_nps_getwq`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getwq.md)
to retrieve water quality data. It then combines these datasets and
calculates loads for TN, TP, TSS, BOD, and hydrologic load. See the help
files for each function for more details.

Required external data inputs are Lake Manatee, Tampa Bypass, and Alafia
River Bell Shoals flow data. These are not available from the USGS API
and must be obtained from the contacts listed in
[`util_nps_getextflow`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getextflow.md).
USGS flow data are for stations 02299950, 02300042, 02300500, 02300700,
02301000, 02301300, 02301500, 02301750, 02303000, 02303330, 02304500,
02306647, 02307000, 02307359, and 02307498. The USGS flow data are from
the NWIS database as returned by
[`read_waterdata_daily`](https://rdrr.io/pkg/dataRetrieval/man/read_waterdata_daily.html)
using
[`util_nps_getusgsflow`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getusgsflow.md).
A preprocessed USGS flow data frame can be provided using the `usgsflow`
argument to avoid re-downloading the data. All inputs for flow can be
superceded by providing a complete flow data frame using the `allflo`
argument.

Water Quality data are obtained from the FDEP WIN database API,
tbeptools, or local files as described in
[`util_nps_getwq`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getwq.md).
Chosen stations are ER2 and UM2 for Manatee County and station 06-06 for
Pinellas County. Environmental Protection Commission (EPC) of
Hillsborough County stations retained are 105, 113, 114, 132, 141, 138,
142, and 147. Manatee or Pinellas County data can be imported from local
files using the `mancopth` and `pincopth` arguments, respectively. If
these are not provided, the function will attempt to retrieve data from
the FDEP WIN database using `read_importwqwin` from tbeptools. The EPC
data are retrieved using `read_importepc` from tbeptools. All inputs for
water quality can be superceded by providing a complete water quality
data frame using the `allwq` argument.

The function assumes that the water quality data are in mg/L and flow
data are in cfs. Missing water quality data are filled with previous
five year averages for the end months, then linearly interpolated using
[`util_nps_fillmiswq`](https://tbep-tech.github.io/tbeploads/reference/util_nps_fillmiswq.md).

## Examples

``` r
data(allwq)
data(allflo)

nps_gaged <- anlz_nps_gaged(
  yrrng = c('2021-01-01', '2023-12-31'), 
  allflo = allflo,
  allwq = allwq
)
#> Estimating gaged NPS loads...

head(nps_gaged)
#> # A tibble: 6 × 13
#>   basin      yr    mo tn_mgl tp_mgl tss_mgl bod_mgl   flow h2oload tnload tpload
#>   <chr>   <dbl> <dbl>  <dbl>  <dbl>   <dbl>   <dbl>  <dbl>   <dbl>  <dbl>  <dbl>
#> 1 023005…  2021     1  0.862  0.222      NA      NA 4.71e9  4.71e6  4063.  1046.
#> 2 023005…  2021     2  1.13   0.358      NA      NA 9.10e9  9.10e6 10280.  3257.
#> 3 023005…  2021     3  0.941  0.327      NA      NA 4.62e9  4.62e6  4351.  1512.
#> 4 023005…  2021     4  0.964  0.44       NA      NA 8.04e9  8.04e6  7755.  3540.
#> 5 023005…  2021     5  0.334  0.286      NA      NA 2.07e9  2.07e6   692.   593.
#> 6 023005…  2021     6  0.871  0.341      NA      NA 4.12e9  4.12e6  3585.  1403.
#> # ℹ 2 more variables: tssload <dbl>, bodload <dbl>
```
