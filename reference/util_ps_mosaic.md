# Fill missing concentration data for Mosaic industrial point source facilities

Fill total phosphorus, total suspended solids, and biological oxygen
demand for Mosaic industrial point source records, which contain only
flow and total nitrogen.

## Usage

``` r
util_ps_mosaic(dat)
```

## Arguments

- dat:

  data frame for a single Mosaic facility with columns `Facility.Name`,
  `Outfall.ID`, `Year`, `Month`, `Average.Daily.Flow..ADF...mgd.`, and
  `Total.N`

## Value

A data frame with columns: `Permit.Number`, `Facility.Name`,
`Outfall.ID`, `Year`, `Month`, `Average.Daily.Flow..ADF...mgd.`,
`Total.N`, `Total.N.Unit`, `Total.P`, `Total.P.Unit`, `TSS`, `TSS.Unit`,
`BOD`, `BOD.Unit`.

## Details

Mosaic data contain only average daily flow (MGD) and total nitrogen
(TN, mg/L). Total phosphorus (TP), total suspended solids (TSS), and
biological oxygen demand (BOD) are not measured and are filled with
historical averages derived from earlier permit compliance data
(2008-2011 averages unless otherwise noted).

The general fill rule is: if average daily flow is zero or missing, TP,
TSS, and BOD are set to `NA`; if flow is positive they are assigned the
per-facility (or per-outfall) historical average. A few facilities
always receive the historical fill regardless of flow and these include
Mosaic Bartow, Green Bay, New Wales, South Pierce, and Bonnie outfall
D-003. Missing flow values are replaced with zero. A permit number is
added for each facility from FDEP permit records.

## Fill values (mg/L)

- Mosaic Bartow (all outfalls):

  TP = 1.61, TSS = 8.38, BOD = 9.6, always filled

- Mosaic Bonnie D-001:

  TP = 0.73, TSS = 26.46, BOD = 9.6

- Mosaic Bonnie D-003:

  TP = 2.30, TSS = 6.58, BOD = 9.6, always filled

- Mosaic Bonnie D-005:

  TP = 0.18, TSS = 3.40, BOD = 9.6

- Mosaic Bonnie D-006:

  TP = 0.85, TSS = 1.63, BOD = 9.6

- Mosaic Bonnie D-04A:

  TP = 0.50, TSS = 2.26, BOD = 9.6

- Mosaic Bonnie D-007A:

  TP = 0.23, TSS = 1.70, BOD = 9.6

- Mosaic Four Corners D-001, D-003:

  TP = 1.12, TSS = 12.7, BOD = 9.6

- Mosaic Green Bay (all outfalls):

  TP = 4.23, TSS = 7.90, BOD = 9.6, always filled

- Mosaic Hookers Point (Ammonia Terminal) (all outfalls):

  TP = 25.3, TSS = 9.35, BOD = 9.6

- Mosaic Lonesome (all outfalls):

  TP = 0.016, TSS = 2.4, BOD = 9.6

- Mosaic Mulberry D-002:

  TP = 2.21, TSS = 5.07, BOD = 9.6

- Mosaic Mulberry Phospho Stack D-001F:

  TP = 6.67, TSS = 6.78, BOD = 9.6

- Mosaic New Wales (all outfalls):

  TP = 0.27, TSS = 4.9, BOD = 9.6, always filled

- Mosaic Nichols (all outfalls):

  TP = 0.21, TSS = 1.95, BOD = 1.85

- Mosaic Plant City (all outfalls):

  TP = 0.65, TSS = 12.0, BOD = 9.6

- Mosaic Port Sutton (all outfalls):

  TP = 0.66, TSS = 14.4, BOD = 9.6

- Mosaic Riverview D-005B, D-021:

  TP = 10.65, TSS = 11.49, BOD = 1.8

- Mosaic Riverview D-025:

  TP = 10.65, TSS = 8.70, BOD = 1.8

- Mosaic South Pierce (all outfalls):

  TP = 1.50, TSS = 3.58, BOD = 9.6, always filled

- Mosaic Tampa Marine Terminal SW-1:

  TP = 22.0, TSS = 49.6, BOD = 9.6

- Mosaic Tampa Marine Terminal SW-3:

  TP = 25.3, TSS = 9.33, BOD = 9.6

Mosaic Black Point (fka Yara), Mosaic Hookers Prairie, and Mosaic
Riverview Stack Closure have no established fill values; TP, TSS, and
BOD will be `NA` for those facilities (and for any Riverview or Four
Corners outfall not listed above).

Note that this function may need to be updated if new data become
available or if there are changes in the fill rules. The current fill
values and rules are based on historical permit compliance data and may
not reflect future conditions.

## Examples

``` r
dat <- data.frame(
  Facility.Name = rep('Mosaic Bartow', 3),
  Outfall.ID = rep('D-001', 3),
  Year = rep(2022L, 3),
  Month = 1:3,
  Average.Daily.Flow..ADF...mgd. = c(0.57, 0, 0.43),
  Total.N = c(3.94, NA, 2.11)
)
util_ps_mosaic(dat)
#>   Permit.Number Facility.Name Outfall.ID Year Month
#> 1     FL0001589 Mosaic Bartow      D-001 2022     1
#> 2     FL0001589 Mosaic Bartow      D-001 2022     2
#> 3     FL0001589 Mosaic Bartow      D-001 2022     3
#>   Average.Daily.Flow..ADF...mgd. Total.N Total.N.Unit Total.P Total.P.Unit  TSS
#> 1                           0.57    3.94         mg/L    1.61         mg/L 8.38
#> 2                           0.00      NA                 1.61         mg/L 8.38
#> 3                           0.43    2.11         mg/L    1.61         mg/L 8.38
#>   TSS.Unit BOD BOD.Unit
#> 1     mg/L 9.6     mg/L
#> 2     mg/L 9.6     mg/L
#> 3     mg/L 9.6     mg/L
```
