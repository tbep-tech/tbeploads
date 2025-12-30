# Calculate non-point source (NPS) loads for Tampa Bay

Calculate non-point source (NPS) loads for Tampa Bay

## Usage

``` r
anlz_nps(
  yrrng = c("2021-01-01", "2023-12-31"),
  tbbase,
  rain,
  mancopth = NULL,
  pincopth = NULL,
  lakemanpth = NULL,
  tampabypth = NULL,
  bellshlpth = NULL,
  vernafl,
  allflo = NULL,
  allwq = NULL,
  usgsflow = NULL,
  summ = c("basin", "segment", "all"),
  summtime = c("month", "year"),
  aslu = FALSE,
  verbose = TRUE
)
```

## Arguments

- yrrng:

  A vector of two dates in 'YYYY-MM-DD' format, specifying the date
  range to retrieve flow data. Default is from '2021-01-01' to
  '2023-12-31'.

- tbbase:

  data frame containing polygon areas for the combined data layer of bay
  segment, basin, jurisdiction, land use data, and soils, see details

- rain:

  data frame of rainfall data, see details

- mancopth:

  character, path to the Manatee County water quality data file, see
  details

- pincopth:

  character, path to the Pinellas County water quality data file, see
  details

- lakemanpth:

  character, path to the file containing the Lake Manatee flow data, see
  details

- tampabypth:

  character, path to the file containing the Tampa Bypass flow data, see
  details

- bellshlpth:

  character, path to the file containing the Bell shoals data, see
  details

- vernafl:

  character vector of file path to Verna Wellfield atmospheric
  concentration data

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
  NULL.

- summ:

  chr string indicating how the returned data are summarized, see
  details

- summtime:

  chr string indicating how the returned data are summarized temporally
  (month or year), see details

- aslu:

  logical indicating whether to summarize by land use type (ungaged
  loads only), default is FALSE

- verbose:

  logical indicating whether to print verbose output

## Value

A data frame of non-point source loads for Tampa Bay, including columns
for year, month, bay segment, basin, and loads for total nitrogen (TN),
total phosphorus (TP), total suspended solids (TSS), biochemical oxygen
demand (BOD), and hydrology using default values for the `summ` and
`summtime` arguments. TN, TP, TSS, and BOD Loads are tons per month or
year depending on the `summtime` argument. Hydrologic loads are cubic
meters per month or year depending on the `summtime` argument.

## Details

The function estimates non-point source (NPS) loads for Tampa Bay by
combining ungaged and gaged NPS loads. Ungaged loads are estimated using
rainfall, flow, event mean concentration, land use, and soils data,
while gaged loads are estimated using water quality data and flow data.
The function also incorporates atmospheric concentration data from the
Verna Wellfield site.

The data are summarized differently based on the `summ` and `summtime`
arguments. All loading data are summed based on these arguments, e.g.,
by bay segment (`summ = 'segment'`) and year (`summtime = 'year'`).
Options for `summ` are 'basin' to summarize across sub-basins within bay
segments, 'segment' to summarize by bay segment, and 'all' to summarize
total load. Loads can also be summarized by land use type with the
`summ` and `summtime` argumets by setting `aslu = TRUE`. Land use type
summaries only apply to ungaged load estimates. Options for `summtime`
are 'month' to summarize by month and 'year' to summarize by year. The
default is to summarize by basin and month.

The following functions are used internally and are provided here for
reference on the components used in the calculations:

- [`anlz_nps_ungaged`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps_ungaged.md):
  Estimates ungaged NPS loads.

- [`anlz_nps_gaged`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps_gaged.md):
  Estimates gaged NPS loads.

- [`util_nps_fillmiswq`](https://tbep-tech.github.io/tbeploads/reference/util_nps_fillmiswq.md):
  Fills missing water quality data with linear interpolation.

- [`util_nps_getflow`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getflow.md):
  Gets flow estimates for NPS gaged and ungaged calculations.

- [`util_nps_getusgsflow`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getusgsflow.md):
  Gets USGS flow data for NPS calculations, used in
  [`util_nps_getflow`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getflow.md).

- [`util_nps_getextflow`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getextflow.md):
  Gets external flow data (Lake Manatee, Tampa Bypass, and Bell Shoals),
  used in
  [`util_nps_getflow`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getflow.md).

- [`util_nps_getwq`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getwq.md):
  Gets water quality data for NPS gaged calculations.

- [`util_nps_preprain`](https://tbep-tech.github.io/tbeploads/reference/util_nps_preprain.md):
  Prepares and formats rainfall data.

- [`util_nps_preplog`](https://tbep-tech.github.io/tbeploads/reference/util_nps_preplog.md):
  Prepares land use data for logistic regression modeling.

- [`util_nps_segment`](https://tbep-tech.github.io/tbeploads/reference/util_nps_segment.md):
  Assigns basins to bay segments.

- [`util_prepverna`](https://tbep-tech.github.io/tbeploads/reference/util_prepverna.md):
  Prepares and fills missing data with five-year means for the Verna
  Wellfield site data.

## Examples

``` r
data(tbbase)
data(rain)
data(allwq)
data(allflo)
vernafl <- system.file('extdata/verna-raw.csv', package = 'tbeploads')

nps <- anlz_nps(
  yrrng = c('2021-01-01', '2023-12-31'), 
  tbbase = tbbase, 
  rain = rain, 
  allwq = allwq,
  allflo = allflo,  
  vernafl = vernafl, 
)
#> Estimating ungaged NPS loads...
#> Estimating gaged NPS loads...
#> Combining atmospheric data with ungaged NPS loads...
#> Combining ungaged and gaged NPS loads, estimating final...

head(nps)
#> # A tibble: 6 × 10
#>    Year Month source segment     basin tn_load tp_load tss_load bod_load hy_load
#>   <dbl> <dbl> <chr>  <chr>       <chr>   <dbl>   <dbl>    <dbl>    <dbl>   <dbl>
#> 1  2021     1 NPS    Boca Ciega… 207-5    2.43   0.398     80.8    14.5   1.22e6
#> 2  2021     2 NPS    Boca Ciega… 207-5    1.65   0.270     54.8     9.85  8.26e5
#> 3  2021     3 NPS    Boca Ciega… 207-5    1.37   0.224     45.5     8.18  6.86e5
#> 4  2021     4 NPS    Boca Ciega… 207-5    1.58   0.258     52.5     9.43  7.91e5
#> 5  2021     5 NPS    Boca Ciega… 207-5    1.21   0.198     40.2     7.23  6.06e5
#> 6  2021     6 NPS    Boca Ciega… 207-5    2.68   0.440     89.4    16.1   1.35e6
```
