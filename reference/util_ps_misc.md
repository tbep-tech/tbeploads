# Fill missing concentration data for miscellaneous industrial point source facilities

Fill total phosphorus, total suspended solids, and biological oxygen
demand for miscellaneous industrial point source records where one or
more of these parameters are unmeasured and must be estimated from
historical averages.

## Usage

``` r
util_ps_misc(dat)
```

## Arguments

- dat:

  data frame for a single facility with columns matching the standard
  clean IPS format: `Permit.Number`, `Facility.Name`, `Outfall.ID`,
  `Year`, `Month`, `Average.Daily.Flow..ADF...mgd.`, `Total.N`,
  `Total.N.Unit`, `Total.P`, `Total.P.Unit`, `TSS`, `TSS.Unit`, `BOD`,
  `BOD.Unit`

## Value

The input data frame with `Total.P`, `TSS`, `BOD`, and their unit
columns updated. All other columns are returned unchanged except that
unit strings are standardised and concentrations are set to `NA` for
zero- or missing-flow months.

## Details

Unlike Mosaic facilities (see
[`util_ps_mosaic`](https://tbep-tech.github.io/tbeploads/reference/util_ps_mosaic.md)),
the facilities handled here already report some concentration parameters
from DMR data. This function fills only those parameters that are
chronically unmeasured, using historical averages or standard
assumptions. Measured values are preserved unless the fill rule
explicitly overrides them (e.g., Trademark Nitrogen TP and BOD are
always set to historical means regardless of any reported value).

The general fill rule is: when flow is zero or missing, all
concentrations are set to `NA`; when flow is positive, fill values are
applied to unmeasured parameters and measured values are retained for
everything else. Unit strings are standardised to `"mg/L"` when a value
is present and `""` otherwise.

As for the
[`util_ps_mosaic`](https://tbep-tech.github.io/tbeploads/reference/util_ps_mosaic.md)
function, \#' Note that this function may need to be updated if new data
become available or if there are changes in the fill rules. The current
fill values and rules are based on historical permit compliance data and
may not reflect future conditions.

## Fill values (mg/L)

- Alpha/ Owens Corning (D-001):

  TP = 1, TSS = 2, BOD = 6; last recorded BOD and TSS from Dec 2017
  minimal discharge; TP from Grizzle-Figg limits

- Big Bend Station (I-130):

  TP = 1.73, TSS = 12.11, BOD = 9.6; TP and TSS from 95-98 averages; BOD
  from Harper 1994

- Brewster Phosphogypsum Stack System (D-001):

  BOD = 9.6 (Harper 1994); TP and TSS from actual DMR measurements

- Busch Gardens (D-002):

  TSS = 5, BOD = 9.6 (Harper 1994); TP from actual DMR measurements

- Coronet Industries (D-002, D-004, D-005):

  BOD = 9.6 (Harper 1994); TP and TSS from actual DMR measurements

- CSX - ROCKPORT NEWPORT (D-001, D-002, D-008, D-010):

  TP = 0, TSS = 0, BOD = 9.6; no TP or TSS info; BOD same as Winston
  Yard previously

- CSX Winston Yard (D-002):

  TP = 0, TSS = 0, BOD = 9.6 (Harper 1994); no TP or TSS info

- Duke Energy-Bartow Plant (I-002):

  TP = 0, BOD = 9.6 (Harper 1994); TSS from actual DMR measurements; no
  TP measurements

- DRS Piney Point (D-001, D-002, D-003):

  BOD = 9.6 (Harper 1994); TP and TSS from actual DMR measurements

- Estech Agricola (D-001):

  BOD = 9.6 (Harper 1994); TP and TSS from actual DMR measurements

- H.L. Culbreath Bayside Power Station (I-038):

  TP = 1, TSS = 12.96, BOD = 9.6; TP from Grizzle-Figg limits; TSS avg
  2012-2014; BOD Harper 1994

- Lowry Park Zoo (D-001):

  TSS = 5, BOD = 9.6 (Harper 1994); TP from actual DMR measurements; TN
  and TP for September 2023 filled with adjacent-month means (TN =
  0.967, TP = 0.17)

- Trademark Nitrogen Corporation (D-001):

  TP = 0.13333, BOD = 1.09833; both filled with means from 1995-1998
  loadings regardless of measured values; TSS from actual DMR
  measurements

## See also

[`util_ps_mosaic`](https://tbep-tech.github.io/tbeploads/reference/util_ps_mosaic.md)
for filling missing data for Mosaic facilities

## Examples

``` r
dat <- data.frame(
  Permit.Number                  = rep('FL0185833', 3),
  Facility.Name                  = rep('Busch Gardens', 3),
  Outfall.ID                     = rep('D-002', 3),
  Year                           = rep(2022L, 3),
  Month                          = 1:3,
  Average.Daily.Flow..ADF...mgd. = c(0.78, 0.50, 0),
  Total.N                        = c(0.45, 0.06, NA),
  Total.N.Unit                   = c('mg/L', 'mg/L', ''),
  Total.P                        = c(0.08, 0.08, NA),
  Total.P.Unit                   = c('mg/L', 'mg/L', ''),
  TSS                            = c(NA, NA, NA),
  TSS.Unit                       = c('', '', ''),
  BOD                            = c(NA, NA, NA),
  BOD.Unit                       = c('', '', '')
)
util_ps_misc(dat)
#>   Permit.Number Facility.Name Outfall.ID Year Month
#> 1     FL0185833 Busch Gardens      D-002 2022     1
#> 2     FL0185833 Busch Gardens      D-002 2022     2
#> 3     FL0185833 Busch Gardens      D-002 2022     3
#>   Average.Daily.Flow..ADF...mgd. Total.N Total.N.Unit Total.P Total.P.Unit TSS
#> 1                           0.78    0.45         mg/L    0.08         mg/L   5
#> 2                           0.50    0.06         mg/L    0.08         mg/L   5
#> 3                           0.00      NA                   NA               NA
#>   TSS.Unit BOD BOD.Unit
#> 1     mg/L 9.6     mg/L
#> 2     mg/L 9.6     mg/L
#> 3           NA         
```
