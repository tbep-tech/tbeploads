# Estimated non-point source (NPS) ungaged loads

Estimated non-point source (NPS) ungaged loads

## Usage

``` r
anlz_nps_ungaged(
  yrrng = c("2021-01-01", "2023-12-31"),
  tbbase,
  rain,
  lakemanpth = NULL,
  tampabypth = NULL,
  bellshlpth = NULL,
  allflo = NULL,
  usgsflow = NULL,
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

- lakemanpth:

  character, path to the file containing the Lake Manatee flow data, see
  details

- tampabypth:

  character, path to the file containing the Tampa Bypass flow data, see
  details

- bellshlpth:

  character, path to the file containing the Bell shoals data, see
  details

- allflo:

  data frame of flow data, if already available from
  [`util_nps_getflow`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getflow.md),
  otherwise NULL and the function will retrieve the data

- usgsflow:

  data frame of USGS flow data, if already available from
  [`util_nps_getusgsflow`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getusgsflow.md),
  otherwise NULL and the function will retrieve the data. Default is
  NULL. Does not apply if `allflo` is provided.

- verbose:

  logical indicating whether to print verbose output

## Value

A data frame with monthly pollutant load estimates containing the
following columns:

- `bay_seg`: Bay segment identifier (1: Old Tampa Bay, 2: Hillsborough
  Bay, 3: Middle Tampa Bay, 4: Lower Tampa Bay, 5: Upper Boca Ciega Bay,
  6: Terra Ceia Bay, 7: Manatee River, 55: Lower Boca Ciega Bay)

- `basin`: Basin identifier (USGS gage number or internal code)

- `yr`: Year

- `mo`: Month (1-12)

- `clucsid`: Consolidated Land Use Classification System ID

- `h2oload`: Water load (cubic meters)

- `tnload`: Total nitrogen load (kg)

- `tpload`: Total phosphorus load (kg)

- `tssload`: Total suspended solids load (kg)

- `stnload`: Stormwater total nitrogen load (kg)

- `stpload`: Stormwater total phosphorus load (kg)

- `stssload`: Stormwater total suspended solids load (kg)

- `bodload`: Biochemical oxygen demand load (kg)

- `area`: Land use area (hectares)

- `bas_area`: Total basin area (hectares)

## Details

This function estimates pollutant loads from non-point sources in
ungaged (unmonitored) basins within the Tampa Bay watershed. The
approach combines spatial land use data, rainfall patterns, hydrologic
modeling, and empirical relationships to estimate monthly nutrient and
sediment loads. Several steps are followed:

1.  **Data Preparation**: Processes land use data for logistic
    regression modeling and calculates inverse distance-weighted
    rainfall data for each sub-basin.

2.  **Flow Estimation**: Uses a logistic regression model to predict
    monthly streamflow in ungaged basins based on:

    - Current month rainfall and 2-month lagged rainfall

    - Land use percentages (urban, agriculture, wetlands, forest)

    - Seasonal patterns (wet season: July-October, dry season:
      November-June)

    - Urban development intensity (Group A: \<19% urban, Group B: ≥19%
      urban)

    - Hydrologic soil group characteristics

3.  **Runoff Coefficient Application**: Applies land use and
    soil-specific runoff coefficients to distribute predicted flows
    across different landscape types within each basin.

4.  **Load Calculation**: Estimates pollutant loads using Event Mean
    Concentrations (EMCs) for different land use categories (CLUCSID),
    calculating:

    - Total Nitrogen (TN) loads

    - Total Phosphorus (TP) loads

    - Total Suspended Solids (TSS) loads

    - Biochemical Oxygen Demand (BOD) loads

    - Stormwater-specific loads (with different EMCs for certain
      categories)

**Spatial Framework:**

The analysis uses a nested spatial hierarchy:

- **Bay Segments**: Major subdivisions of Tampa Bay (1-7, with 55 for
  Lower Boca Ciega Bay)

- **Basins**: Hydrologic sub-basins, including both USGS gaged and
  ungaged areas

- **Land Use Polygons**: Detailed spatial units combining jurisdiction,
  land use (FLUCCS codes), and soil characteristics

**Flow Prediction Models:**

The function uses season- and development-specific regression equations:

- Separate models for wet vs. dry seasons

- Separate models for low-development (Group A) vs. high-development
  (Group B) areas

- Models account for antecedent moisture conditions through lagged
  rainfall terms

**Load Estimation:**

Pollutant loads are calculated as:
`Load = Flow × EMC × Unit Conversions`

Where EMCs vary by land use category (CLUCSID). Special handling is
applied for water bodies and certain wetland types (CLUCSIDs 18, 20),
which are assigned zero stormwater loads.

Requires the following inputs:

- `tbbase`: A data frame containing polygon areas for the combined data
  layer of bay segment, basin, jurisdiction, land use data, and soils,
  Stored as
  [`tbbase`](https://tbep-tech.github.io/tbeploads/reference/tbbase.md)
  or created (takes an hour or so) with
  [`util_nps_tbbase`](https://tbep-tech.github.io/tbeploads/reference/util_nps_tbbase.md).

- `rain`: A data frame of rainfall data. See
  [`rain`](https://tbep-tech.github.io/tbeploads/reference/rain.md).

- `lakemanpth`: character, path to the file containing the Lake Manatee
  flow data. See
  [`util_nps_getextflow`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getextflow.md).
  Only applies if `allflo` is not provided.

- `tampabypth`: character, path to the file containing the Tampa Bypass
  flow data. See
  [`util_nps_getextflow`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getextflow.md).
  Only applies if `allflo` is not provided.

- `bellshlpth`: character, path to the file containing the Bell shoals
  data. See
  [`util_nps_getextflow`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getextflow.md).
  Only applies if `allflo` is not provided.

USGS gaged flows are also used, as returned by
[`util_nps_getusgsflow`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getusgsflow.md)
and combined with the external flow data using
[`util_nps_getextflow`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getextflow.md)
and
[`util_nps_getflow`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getflow.md).

## Examples

``` r
# external flow sources
data(tbbase)
data(rain)
data(allflo)

nps_ungaged <- anlz_nps_ungaged(
  yrrng = c('2021-01-01', '2023-12-31'), 
  tbbase = tbbase,
  rain = rain, 
  allflo = allflo
)
#> Prepping rain data...
#> Estimating ungaged NPS loads...

head(nps_ungaged)
#> # A tibble: 6 × 12
#>   bay_seg basin     yr    mo clucsid h2oload tnload tpload tssload bodload  area
#>     <dbl> <chr>  <dbl> <dbl>   <dbl>   <dbl>  <dbl>  <dbl>   <dbl>   <dbl> <dbl>
#> 1       1 02306…  2021     1       1   7660.   14.6   2.40    137.    33.7  210.
#> 2       1 02306…  2021     1       2  59331.  133.   20.2    2156.   439.   971.
#> 3       1 02306…  2021     1       3 108248.  225.   39.9    6911.  1191.  1267.
#> 4       1 02306…  2021     1       4  81834.  159.   22.9    6765.  1408.   481.
#> 5       1 02306…  2021     1       5  58983.   96.6  15.8    5540.   566.   371.
#> 6       1 02306…  2021     1       7  27440.   32.4   4.12    549.   225.   281.
#> # ℹ 1 more variable: bas_area <dbl>
```
