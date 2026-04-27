# Non-Point Source (NPS)

``` r
library(tbeploads)
```

Non-point source (NPS) estimates are obtained for gaged and ungaged
locations in the watershed, then combined for the final result. Skip to
the [final sub-section](#nps-final) to understand how to obtain all
estimates together. Separate approaches for gaged and ungaged estimates
are described first for documentation purposes.

## Gaged locations

Gaged estimates are obtained using the
[`anlz_nps_gaged()`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps_gaged.md)
function that retrieves flow and water quality data, then combines them
to calculate TN, TP, TSS, BOD, and hydrologic loads.

Required external flow data are Lake Manatee, Tampa Bypass, and Alafia
River Bell Shoals. These are not available from the USGS API and must be
obtained from the contacts listed in
[`util_nps_getextflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getextflow.md).
USGS flow data are obtained from an API for stations 02299950, 02300042,
02300500, 02300700, 02301000, 02301300, 02301500, 02301750, 02303000,
02303330, 02304500, 02306647, 02307000, 02307359, and 02307498. A
preprocessed USGS flow data frame can be provided to the `usgsflow`
argument. The
[`usgsflow`](https://tbep-tech.github.io/tbeploads/reference/usgsflow.md)
data object is provided with the package to avoid re-downloading the
data. Similarly, all flow data can be provided to the `allflo` argument.
The
[`allflo`](https://tbep-tech.github.io/tbeploads/reference/allflo.md)
data object included with the package has both external and USGS flow
data.

Water Quality data are obtained from the FDEP WIN database API,
tbeptools, or local files as described in
[`util_nps_getwq()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getwq.md).
Chosen stations are ER2 and UM2 for Manatee County and station 06-06 for
Pinellas County. Environmental Protection Commission (EPC) of
Hillsborough County stations retained are 105, 113, 114, 132, 141, 138,
142, and 147. Manatee or Pinellas County data can be imported from local
files using the `mancopth` and `pincopth` arguments, respectively. If
these are not provided, the function will attempt to retrieve data from
the FDEP WIN database using `read_importwqwin()` from tbeptools. The EPC
data are retrieved using `read_importepc()` from tbeptools. The
[`allwq`](https://tbep-tech.github.io/tbeploads/reference/allwq.md) data
object included with the package has external data and USGS flow data
and can used with the `allwq` argument.

The function assumes that the water quality data are in mg/L and flow
data are in cfs. Missing water quality data are filled with previous
five year averages for the end months, then linearly interpolated using
[`util_nps_fillmiswq()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_fillmiswq.md).

Water quality and flow inputs to
[`anlz_nps_gaged()`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps_gaged.md)
can be provided numerous ways:

1.  Manatee and Pinellas County water quality data provided as local
    files and EPC data automatically retrieved from the API
2.  All water quality data provided locally using a single object with
    the `allwq` argument (see the
    [`allwq`](https://tbep-tech.github.io/tbeploads/reference/allwq.md)
    dataset for the format, created using
    [`util_nps_getwq()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getwq.md))
3.  Flow data provided using local files for Lake Manatee, Bell Shoals,
    and Tampa Bypass, USGS data retrieved automatically from the API
4.  Flow data provided using local files for Lake Manatee, Bell Shoals,
    and Tampa Bypass, USGS data provided locally using the `usgsflow`
    argument (see the
    [`usgsflow`](https://tbep-tech.github.io/tbeploads/reference/usgsflow.md)
    dataset for the format, created using
    [`util_nps_getusgsflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getusgsflow.md))
5.  All flow data provided locally using the `allflo` argument (see the
    [`allflo`](https://tbep-tech.github.io/tbeploads/reference/allflo.md)
    dataset for the format, created using
    [`util_nps_getflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getflow.md)).

In all cases, input data can retrieved from APIs with the exception of
flow data for Lake Manatee, Bell Shoals, and Tampa Bypass (see the help
file for
[`util_nps_getextflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getextflow.md)
for how to get these data). The following example uses combined water
quality and flow data included with the package for convenience.

``` r
# external files included with the package
data(allwq)
data(allflo)

# get gaged NPS loads
nps_gaged <- anlz_nps_gaged(yrrng = c('2021-01-01', '2023-12-31'), allwq = allwq, allflo = allflo)
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

In all use cases for the function, a data frame is returned with columns
for basin, year, month, TN in mg/L, TP in mg/L, TSS in mg/L, BOD in
mg/L, flow in liters/month, hydrologic load in m3/month, TN load in
kg/month, TP load in kg/month, TSS load in kg/month, and BOD load in
kg/month.

## Ungaged locations

Ungaged (unmonitored basins) estimates are obtained using
[`anlz_nps_ungaged()`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps_ungaged.md).
The approach combines spatial land use data, rainfall patterns,
hydrologic modeling, and empirical relationships to estimate monthly
nutrient and sediment loads. The function requires combined spatial data
for bay segment, basin, entity jurisdiction, land use data, and soils
(obtained with
[`util_nps_tbbase()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_tbbase.md)),
rainfall data (obtained with
[`util_getrain()`](https://tbep-tech.github.io/tbeploads/reference/util_getrain.md)),
and flow data (obtained with
[`util_nps_getflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getflow.md)).

The first step is updating the combined spatial data if any of the input
datasets have changed. The required inputs are land use
([`tblu2023`](https://tbep-tech.github.io/tbeploads/reference/tblu2023.md)),
soil data
([`tbsoil`](https://tbep-tech.github.io/tbeploads/reference/tbsoil.md)),
jurisdiction
([`tbjuris`](https://tbep-tech.github.io/tbeploads/reference/tbjuris.md)),
and sub-basin data
([`tbsubshed`](https://tbep-tech.github.io/tbeploads/reference/tbsubshed.md)).
The function
[`util_nps_tbbase()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_tbbase.md)
combines these datasets into a single spatial object that is used for
ungaged load estimation using
[`util_nps_union()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_union.md).
The function requires GDAL to be installed and accessible in the system
PATH, or the path to GDAL binaries can be provided using the `gdal_path`
argument.

Land use and soil data can be updated using the
[`util_nps_getswfwmd()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getswfwmd.md)
function. These data are also stored internally with the package for
easy retrieval, as are the remaining datasets.

``` r
tblu2023 <- util_nps_getswfwmd('lulc2023')
tbsoil <- util_nps_getswfwmd('soil')
```

Then, the combined layer,
[`tbbase`](https://tbep-tech.github.io/tbeploads/reference/tbbase.md),
can be created (takes an hour or two).

``` r
data(tbsubshed)
data(tbjuris)
data(tblu2023)
data(tbsoil)
tbbase <- util_nps_tbbase(tbsubshed, tbjuris, tblu2023, tbsoil, gdal_path = "C:/OSGeo4W/bin", chunk_size = 1000)
```

The
[`tbbase`](https://tbep-tech.github.io/tbeploads/reference/tbbase.md)
data object is also included with the package for convenience.

``` r
head(tbbase)
#> # A tibble: 6 × 9
#>   bay_seg basin    drnfeat entity     FLUCCSCODE CLUCSID IMPROVED hydgrp area_ha
#>     <dbl> <chr>    <chr>   <chr>           <dbl>   <dbl>    <int> <chr>    <dbl>
#> 1       1 02304500 LAKE    HILLSBORO…       1100       1        1 A      0.00253
#> 2       1 02304500 LAKE    HILLSBORO…       1100       1        1 A/D    0.00653
#> 3       1 02304500 LAKE    HILLSBORO…       1200       2        1 A      0.0321 
#> 4       1 02304500 LAKE    HILLSBORO…       1200       2        1 A/D    0.0126 
#> 5       1 02304500 LAKE    HILLSBORO…       1400       4        1 A      0.00969
#> 6       1 02304500 LAKE    HILLSBORO…       1400       4        1 A/D    0.00779
```

Next, rainfall data must be obtained for the watershed. These data can
be obtained using the
[`util_getrain()`](https://tbep-tech.github.io/tbeploads/reference/util_getrain.md)
function. The function retrieves daily rainfall data from NWIS NCDC
stations in the watershed and returns a data frame with daily rainfall
totals for each station. These data are always provided to the
[`anlz_nps_ungaged()`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps_ungaged.md)
using the `rain` argument and not downloaded automatically to reduce
execution time. The
[`rain`](https://tbep-tech.github.io/tbeploads/reference/rain.md) data
object included with the package is provided for convenience.

Flow data are also required to estimate ungaged loads. This is the same
dataset used to estimate gaged loads. These data can be obtained using
the
[`util_nps_getflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getflow.md)
function. The function retrieves flow data from USGS stations in the
watershed and also uses external flow data for Lake Manatee, Tampa
Bypass, and Bell Shoals (see the help file for
[`util_nps_getextflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getextflow.md)
for how to retrieve these data). A preprocessed USGS flow data frame can
be provided to the `usgsflow` argument. The
[`usgsflow`](https://tbep-tech.github.io/tbeploads/reference/usgsflow.md)
data object is provided with the package to avoid re-downloading the
data. Similarly, all flow data can be provided to the `allflo` argument.
The
[`allflo`](https://tbep-tech.github.io/tbeploads/reference/allflo.md)
data object included with the package has both external and USGS flow
data.

Once the required data are prepared, ungaged loads can be estimated
using
[`anlz_nps_ungaged()`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps_ungaged.md).
The following describes the general methods for how the ungaged loads
are estimated in four steps.

### 1. Data Preparation

Using the inputs described above, the first step processes land use data
for logistic regression modeling and calculates inverse
distance-weighted rainfall data for each sub-basin. This ensures that
each basin receives rainfall estimates that account for spatial
variability across the watershed based on the proximity and influence of
nearby rain gauges.

### 2. Flow Estimation

A logistic regression model predicts monthly streamflow in ungaged
basins using several key variables:

- **Rainfall variables**: Current month rainfall plus 2-month lagged
  rainfall to capture antecedent moisture conditions
- **Land use percentages**: Proportions of urban, agriculture, wetlands,
  and forest cover within each basin
- **Seasonal patterns**: Separate treatment for wet season
  (July-October) and dry season (November-June)
- **Urban development intensity**: Basins are classified into Group A
  (\<19% urban) or Group B (≥19% urban)
- **Hydrologic soil characteristics**: Soil group properties that
  influence infiltration and runoff

### 3. Runoff Coefficient Application

Land use and soil-specific runoff coefficients are applied to distribute
the predicted basin flows across different landscape types within each
basin.

### 4. Load Calculation

Pollutant loads are estimated using Event Mean Concentrations (EMCs) for
different land use categories, calculating:

- Total Nitrogen (TN) loads
- Total Phosphorus (TP) loads
- Total Suspended Solids (TSS) loads
- Biochemical Oxygen Demand (BOD) loads
- Stormwater-specific loads (with different EMCs for certain categories)

The fundamental equation for pollutant load estimation is:

**Load = Flow × EMC × Unit Conversions**

Where EMCs (Event Mean Concentrations) represent the average pollutant
concentrations in stormwater runoff for different land use types. EMCs
vary by land use category (CLUCSID) based on empirical studies of
stormwater quality. Special handling is applied for water bodies and
certain wetland types (CLUCSIDs 18, 20), which are assigned zero
stormwater loads since these areas do not generate surface runoff in the
same manner as terrestrial land uses.

All together, the above can be implemented as follows. Flow inputs (as
cubic feet per second) to
[`anlz_nps_ungaged()`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps_ungaged.md)
can be provided numerous ways:

1.  Flow data provided using local files for Lake Manatee, Bell Shoals,
    and Tampa Bypass, USGS data retrieved automatically from the API
2.  Flow data provided using local files for Lake Manatee, Bell Shoals,
    and Tampa Bypass, USGS data provided locally using the `usgsflow`
    argument (see the
    [`usgsflow`](https://tbep-tech.github.io/tbeploads/reference/usgsflow.md)
    dataset for the format, created using
    [`util_nps_getusgsflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getusgsflow.md))
3.  All flow data provided locally using the `allflo` argument (see the
    [`allflo`](https://tbep-tech.github.io/tbeploads/reference/allflo.md)
    dataset for the format, created using
    [`util_nps_getflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getflow.md)).

In all cases, input data can retrieved from APIs with the exception of
flow data for Lake Manatee, Bell Shoals, and Tampa Bypass (see the help
file for
[`util_nps_getextflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getextflow.md)
for how to get these data). The following example uses combined flow
data included with the package for convenience. See above for how to
create the
[`tbbase`](https://tbep-tech.github.io/tbeploads/reference/tbbase.md)
and [`rain`](https://tbep-tech.github.io/tbeploads/reference/rain.md)
data objects if updated data are needed.

``` r
# required inputs
data(tbbase)
data(rain)
data(allflo)

nps_ungaged <- anlz_nps_ungaged(yrrng = c('2021-01-01', '2023-12-31'), tbbase = tbbase, rain = rain,
                                allflo = allflo)
#> Prepping rain data...
#> Estimating ungaged NPS loads...

head(nps_ungaged)
#> # A tibble: 6 × 12
#>   bay_seg basin     yr    mo clucsid h2oload tnload tpload tssload bodload  area
#>     <dbl> <chr>  <dbl> <dbl>   <dbl>   <dbl>  <dbl>  <dbl>   <dbl>   <dbl> <dbl>
#> 1       1 02306…  2021     1       1   7661.   14.6   2.40    137.    33.7  210.
#> 2       1 02306…  2021     1       2  59344.  133.   20.2    2156.   439.   971.
#> 3       1 02306…  2021     1       3 108271.  225.   39.9    6912.  1191.  1267.
#> 4       1 02306…  2021     1       4  81852.  159.   22.9    6766.  1408.   481.
#> 5       1 02306…  2021     1       5  58995.   96.6  15.8    5542.   566.   371.
#> 6       1 02306…  2021     1       7  27446.   32.4   4.12    549.   225.   281.
#> # ℹ 1 more variable: bas_area <dbl>
```

A data frame is returned with columns for bay segment, basin, year,
month, clucsid (land use code), hydrologic load in m3/month, TN load in
kg/month, TP load in kg/month, TSS load in kg/month, BOD load in
kg/month, area (hectares, basin/clucsid combination), and basin area
(hectares).

## Combined gaged and ungaged loads

Refer to the prior sections for details on how the separate loads for
gaged and ungaged portions of the watershed are calculated. The
[`anlz_nps()`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps.md)
function described below can be used to combine all steps. The function
estimates non-point source (NPS) loads for Tampa Bay by combining gaged
and ungaged NPS loads. Gaged loads are estimated using flow and water
quality data. Ungaged loads are estimated using rainfall, flow, event
mean concentration, land use, and soils data. The function also
incorporates atmospheric concentration data from the Verna Wellfield
site.

Pre-processed inputs for
[`tbbase`](https://tbep-tech.github.io/tbeploads/reference/tbbase.md),
[`rain`](https://tbep-tech.github.io/tbeploads/reference/rain.md),
[`allwq`](https://tbep-tech.github.io/tbeploads/reference/allwq.md), and
[`allflo`](https://tbep-tech.github.io/tbeploads/reference/allflo.md)
are used. See the help file for
[`util_prepverna()`](https://tbep-tech.github.io/tbeploads/reference/util_prepverna.md)
for how to obtain the file for atmospheric concentration data. See above
for how to recreate these files if updated data are needed.

``` r
data(tbbase)
data(rain)
data(allwq)
data(allflo)
vernafl <- system.file('extdata/verna-raw.csv', package = 'tbeploads')

nps <- anlz_nps(yrrng = c('2021-01-01', '2023-12-31'), tbbase = tbbase, rain = rain,
                vernafl = vernafl, allwq = allwq, allflo = allflo)
#> Estimating ungaged NPS loads...
#> Estimating gaged NPS loads...
#> Combining atmospheric data with ungaged NPS loads...
#> Combining ungaged and gaged NPS loads, estimating final...

head(nps)
#> # A tibble: 6 × 10
#>    Year Month source segment     basin tn_load tp_load tss_load bod_load hy_load
#>   <dbl> <dbl> <chr>  <chr>       <chr>   <dbl>   <dbl>    <dbl>    <dbl>   <dbl>
#> 1  2021     1 NPS    Boca Ciega… 207-5    2.42   0.404     80.8    14.5    1.22 
#> 2  2021     2 NPS    Boca Ciega… 207-5    1.65   0.276     55.3     9.94   0.834
#> 3  2021     3 NPS    Boca Ciega… 207-5    1.37   0.228     45.6     8.21   0.689
#> 4  2021     4 NPS    Boca Ciega… 207-5    1.58   0.263     52.6     9.46   0.794
#> 5  2021     5 NPS    Boca Ciega… 207-5    1.21   0.200     40.1     7.20   0.604
#> 6  2021     6 NPS    Boca Ciega… 207-5    2.64   0.441     88.4    15.9    1.33
```

Unlike the individual gaged and ungaged functions,
[`anlz_nps()`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps.md)
returns loading results in tons per month or year depending on the
summary arguments. Hydrologic load is returned as million cubic meters
per month or year.

The following functions are used internally and are provided here for
reference on the components used in the calculations. Not all are used
depending on the inputs provided.

- [`anlz_nps_ungaged()`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps_ungaged.md):
  Estimates ungaged NPS loads.
- [`anlz_nps_gaged()`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps_gaged.md):
  Estimates gaged NPS loads.
- [`util_nps_fillmiswq()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_fillmiswq.md):
  Fills missing water quality data with linear interpolation.
- [`util_nps_getflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getflow.md):
  Gets flow estimates for NPS gaged and ungaged calculations.
- [`util_nps_getusgsflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getusgsflow.md):
  Gets USGS flow data for NPS calculations, used in
  [`util_nps_getflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getflow.md).
- [`util_nps_getextflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getextflow.md):
  Gets external flow data (Lake Manatee, Tampa Bypass, and Bell Shoals),
  used in
  [`util_nps_getflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getflow.md).
- [`util_nps_getwq()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getwq.md):
  Gets water quality data for NPS gaged calculations.
- [`util_nps_preprain()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_preprain.md):
  Prepares and formats rainfall data.
- [`util_nps_preplog()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_preplog.md):
  Prepares land use data for logistic regression modeling.
- [`util_nps_segment()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_segment.md):
  Assigns basins to bay segments.
- [`util_prepverna()`](https://tbep-tech.github.io/tbeploads/reference/util_prepverna.md):
  Prepares and fills missing data with five-year means for the Verna
  Wellfield site data.

Results can be summarized by basin, segment, baywide, monthly, or
annually using the `summ` and `summtime` arguments. By default, loads
are returned monthly for each basin. Note that Boca Ciega Bay and Boca
Ciega Bay South results are returned separately. Only Boca Ciega Bay
South is used when estimating total bay loads.

Loads by land use type (using CLUCSID) can also be returned if
`aslu = TRUE`. These results only apply to ungaged loading estimates.

``` r
npslu <- anlz_nps(yrrng = c('2021-01-01', '2023-12-31'), tbbase = tbbase, rain = rain,
                allwq = allwq, allflo = allflo, vernafl = vernafl, aslu = TRUE)
#> Estimating ungaged NPS loads...
#> Combining atmospheric data with ungaged NPS loads...
#> Summarizing ungaged NPS loads by land use...

head(npslu)
#> # A tibble: 6 × 11
#>    Year Month source segment       basin lu    tn_load tp_load tss_load bod_load
#>   <dbl> <dbl> <chr>  <chr>         <chr> <chr>   <dbl>   <dbl>    <dbl>    <dbl>
#> 1  2021     1 NPS    Boca Ciega B… 207-5 Barr… 7.11e-5 5.74e-7 0.000631  8.32e-5
#> 2  2021     2 NPS    Boca Ciega B… 207-5 Barr… 4.86e-5 3.92e-7 0.000431  5.69e-5
#> 3  2021     3 NPS    Boca Ciega B… 207-5 Barr… 4.02e-5 3.24e-7 0.000356  4.70e-5
#> 4  2021     4 NPS    Boca Ciega B… 207-5 Barr… 4.63e-5 3.73e-7 0.000411  5.41e-5
#> 5  2021     5 NPS    Boca Ciega B… 207-5 Barr… 3.52e-5 2.84e-7 0.000313  4.12e-5
#> 6  2021     6 NPS    Boca Ciega B… 207-5 Barr… 7.78e-5 6.27e-7 0.000690  9.10e-5
#> # ℹ 1 more variable: hy_load <dbl>
```

Note that results from
[`anlz_nps()`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps.md)
are returned in units of tons/month for TN, TP, TSS, and BOD and million
cubic meters/month for hydrologic load if `summtime = 'month'` or
tons/year for TN, TP, TSS, and BOD and million cubic meters/year for
hydrologic load if `summtime = 'year'`. Results from the gaged and
ungaged functions are returned in kg for TN, TP, TSS, and BOD and m3 for
hydrologic load.

## Removing point source loads from gaged NPS estimates

Because stream gauges measure total flow at a location, gaged NPS load
estimates from
[`anlz_nps()`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps.md)
include any point source discharges upstream of the gauge. The
[`anlz_nps_psremove()`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps_psremove.md)
function subtracts the IPS and DPS loads occurring in gaged basins from
the NPS totals so that point source contributions are not
double-counted. Only point source loads in basins classified as “Gaged”
in the `dbasing` lookup table are subtracted. Loads in ungaged basins
are unaffected.

The function requires pre-computed basin-level monthly loads from
[`anlz_nps()`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps.md),
[`anlz_ips()`](https://tbep-tech.github.io/tbeploads/reference/anlz_ips.md),
and
[`anlz_dps()`](https://tbep-tech.github.io/tbeploads/reference/anlz_dps.md),
all called with `summ = 'basin'` and `summtime = 'month'`. Nested basin
identifiers (e.g., 02301000, 02301300) are reassigned to their parent
basins (02301500, 02304500) before summing, consistent with the handling
already applied inside
[`anlz_nps()`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps.md).

An optional AD/AP TN adjustment (`ad_ap = TRUE` by default) applies
fixed monthly reductions from the 2007 RA allocation analysis to the
segment-level NPS totals: Old Tampa Bay (−2.41 tons/month), Hillsborough
Bay (−4.31 tons/month), Middle Tampa Bay (−2.29 tons/month), Lower Tampa
Bay (−0.36 tons/month), and Manatee River (−2.74 tons/month,
representing the combined reduction for segments 55, 6, and 7). Only TN
is adjusted. TP, TSS, BOD, and hydrologic loads are unchanged.

``` r
# pre-compute basin-level monthly loads for each source
ipsfls <- list.files(system.file('extdata/', package = 'tbeploads'),
  pattern = 'ps_ind_', full.names = TRUE)
dpsfls <- list.files(system.file('extdata/', package = 'tbeploads'),
  pattern = 'ps_dom', full.names = TRUE)

nps_basin <- anlz_nps(yrrng = c('2021-01-01', '2023-12-31'), tbbase = tbbase,
  rain = rain, vernafl = vernafl, allwq = allwq, allflo = allflo,
  summ = 'basin', summtime = 'month')
#> Estimating ungaged NPS loads...
#> Estimating gaged NPS loads...
#> Combining atmospheric data with ungaged NPS loads...
#> Combining ungaged and gaged NPS loads, estimating final...
ips_basin <- anlz_ips(ipsfls, summ = 'basin', summtime = 'month')
dps_basin <- anlz_dps(dpsfls, summ = 'basin', summtime = 'month')

# subtract gaged PS loads and apply AD/AP TN adjustment
nps_psremoved <- anlz_nps_psremove(nps_basin, ips_basin, dps_basin)

head(nps_psremoved)
#> # A tibble: 6 × 9
#>    Year Month source segment        tn_load tp_load tss_load bod_load hy_load
#>   <dbl> <dbl> <chr>  <chr>            <dbl>   <dbl>    <dbl>    <dbl>   <dbl>
#> 1  2021     1 NPS    Boca Ciega Bay    2.42   0.404     80.8    14.5    1.22 
#> 2  2021     2 NPS    Boca Ciega Bay    1.65   0.276     55.3     9.94   0.834
#> 3  2021     3 NPS    Boca Ciega Bay    1.37   0.228     45.6     8.21   0.689
#> 4  2021     4 NPS    Boca Ciega Bay    1.58   0.263     52.6     9.46   0.794
#> 5  2021     5 NPS    Boca Ciega Bay    1.21   0.200     40.1     7.20   0.604
#> 6  2021     6 NPS    Boca Ciega Bay    2.64   0.441     88.4    15.9    1.33
```

Results are returned at the segment/month level with the same column
structure as
[`anlz_ips()`](https://tbep-tech.github.io/tbeploads/reference/anlz_ips.md)
and
[`anlz_dps()`](https://tbep-tech.github.io/tbeploads/reference/anlz_dps.md).
Annual totals can be obtained by setting `summtime = 'year'`. Load units
are tons for TN, TP, TSS, and BOD and million cubic meters for
hydrologic load.
