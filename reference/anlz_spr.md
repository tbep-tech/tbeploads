# Calculate spring loads to Hillsborough Bay

Calculate spring loads to Hillsborough Bay

## Usage

``` r
anlz_spr(
  tbwxlpth,
  wqpth = NULL,
  yrrng = c(2022, 2024),
  summ = c("spring", "basin", "segment"),
  summtime = c("month", "year"),
  sulphurflow = NULL,
  verbose = TRUE
)
```

## Arguments

- tbwxlpth:

  character string, file path to the Tampa Bay Water discharge Excel
  workbook (.xlsx) for Lithia and Buckhorn springs. The workbook must
  contain one sheet per device, named by device ID: 3381 (Lithia Minor),
  4586 (Lithia Major), 3388 (Buckhorn Upper), and 3649 (Buckhorn Lower).
  Each sheet must contain columns `DeviceID`, `MeasureDateTime`,
  `Value`, `MeasureType`, and `Units`.

- wqpth:

  character string or `NULL` (default). File path to spring water
  quality data (.csv). Must contain columns `spring`, `year`, `month`,
  `tn(mg/L)`, and `tp(mg/L)` with one row per sample. Spring names must
  match `"Lithia"`, `"Buckhorn"`, and `"Sulphur"`. When `NULL`, water
  quality data are retrieved automatically from external APIs: Lithia
  and Buckhorn concentrations are fetched from the Water Atlas API
  (SWFWMD stations 17805 and 18276) and Sulphur Spring concentrations
  are fetched via
  [`read_importepc`](https://rdrr.io/pkg/tbeptools/man/read_importepc.html)
  (EPC station 174).

- yrrng:

  integer vector of length 2, start and end year for the analysis, e.g.
  `c(2022, 2024)`.

- summ:

  chr string indicating how the returned data are summarized, see
  details

- summtime:

  chr string indicating how the returned data are summarized temporally
  (month or year), see details

- sulphurflow:

  data frame of daily Sulphur Spring discharge already retrieved by
  [`util_nps_getusgsflow`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getusgsflow.md),
  or `NULL` (default) to fetch from the USGS API.

- verbose:

  logical, if `TRUE` (default) progress messages are printed when water
  quality data are retrieved via API (`wqpth = NULL`).

## Value

A data frame whose structure depends on `summ`:

- `'spring'`: one row per spring per time period, with columns `source`,
  `spring`, `site`, `segment`, `yr`, `mo` (dropped for annual),
  `flow_cfs`, `tn_mgl`, `tp_mgl`, `tss_mgl`, `h2oload` (m3), `tnload`
  (kg), `tpload` (kg), `tssload` (kg).

- `'basin'`: one row per drainage basin per time period, with columns
  `source`, `majbasin`, `segment`, `yr`, `mo` (dropped for annual),
  `h2oload` (m3), `tnload` (kg), `tpload` (kg), `tssload` (kg).

- `'segment'`: one row per bay segment per time period, with columns
  `source`, `segment`, `yr`, `mo` (dropped for annual), `h2oload` (m3),
  `tnload` (kg), `tpload` (kg), `tssload` (kg).

For annual output (`summtime = 'year'`), load columns are summed over
months and `flow_cfs` (spring level only) is the annual mean.

## Details

Loads are calculated for Lithia, Buckhorn, and Sulphur springs, all of
which discharge to Hillsborough Bay (bay segment 2).

**Discharge data (Lithia and Buckhorn):** The Excel workbook supplied in
`tbwxlpth` contains one sheet per device. Device IDs map to sub-springs
as follows: 3381 = Lithia Minor, 4586 = Lithia Major, 3388 = Buckhorn
Upper, 3649 = Buckhorn Lower. Flow values in MGD are converted to CFS (1
MGD = 1.547 CFS); values already in CFS are used as-is. Lithia total
flow is the sum of Minor and Major. Buckhorn total flow is Lower minus
Upper, because the two gauges bracket the spring input on the same
stream reach.

Contact for gage data is Cathleen Jonas, <cjonas@tampabaywater.org>.
Device IDs 3381, 4586, 3388, and 3649 should be bundled with requests
for Tampa Bypass Canal data (device ID 957) and Bell Shoals data (device
ID 4626) used in the NPS workflow.

**Discharge data (Sulphur Springs):** Daily CFS values for station
02306000 are retrieved from the USGS NWIS API via
[`util_nps_getusgsflow`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getusgsflow.md).
A pre-fetched data frame can be supplied via the `sulphurflow` argument
to avoid the API call.

**Interpolation:** Because springs are assumed never to have zero
discharge, all gaps in the daily discharge record are filled by linear
interpolation between observed values
([`na.approx`](https://rdrr.io/pkg/zoo/man/na.approx.html) with
`rule = 2`). Leading or trailing gaps are filled with the nearest
observed value.

**Water quality data (file path):** When `wqpth` is supplied, sample
concentrations (mg/L) for TN and TP are read from the CSV. These data
are from FDEP's Impaired Waters Rule dataset available at
<https://publicfiles.dep.state.fl.us/dear/iwr/>. Annual mean
concentrations are computed per spring and joined to monthly flow
estimates. If a year within `yrrng` has no WQ observations for a given
spring, the grand mean across all available years is substituted.

**Water quality data (API, `wqpth = NULL`):** When `wqpth` is `NULL`,
water quality data are fetched automatically via
[`util_spr_getwq`](https://tbep-tech.github.io/tbeploads/reference/util_spr_getwq.md).
Lithia (SWFWMD station 17805, Lithia Main Spring) and Buckhorn (SWFWMD
station 18276, Buckhorn Main Spring) concentrations are retrieved from
the [Water Atlas API](https://dev.api.wateratlas.org) (`WIN_21FLSWFD`
data source). These are the same quarterly SWFWMD observations that
underlie the FDEP IWR file. Sulphur Spring (EPC station 174) is
retrieved via
[`read_importepc`](https://rdrr.io/pkg/tbeptools/man/read_importepc.html),
providing monthly observations from the Environmental Protection
Commission of Hillsborough County.

**TSS concentrations:** When `wqpth` is supplied, TSS concentrations are
assigned from a fixed lookup table derived from the historical SAS-based
loading model (SPRMOD2). When `wqpth = NULL`, TSS values from the API or
EPC source are used where available; any spring-year with no observed
TSS falls back to the same fixed values. The fixed values are: Sulphur
Springs (02306000) = 4.4 mg/L, Buckhorn Springs (02301695) = 4.0 mg/L,
Lithia Springs (02301600) = 4.0 mg/L.

**Load calculation:** Monthly mean flows (CFS) are computed from the
complete daily discharge series. Loads are then:
\$\$h2oload\\(m^3/month) = \overline{Q}\_{cfs} \times 86400 \times
\frac{365}{12} \times 28.32 \times 10^{-3}\$\$ \$\$load\\(kg/month) =
h2oload \times C\_{mg/L} \times 10^{-3}\$\$

**Spatial summaries:** The data are summarized differently based on the
`summ` and `summtime` arguments. All loading data are summed based on
these arguments, e.g., by bay segment (`summ = 'segment'`) and year
(`summtime = 'year'`). For springs, valid options for `summ` are
`'spring'` (one row per spring per time period), `'basin'` (loads summed
within drainage basins: Lithia and Buckhorn combined into
`"Alafia River"`, Sulphur into `"Hillsborough River"`), and `'segment'`
(all springs summed to bay segment 2, Hillsborough Bay).

## Examples

``` r
tbwxlpth <- system.file('extdata/sprflow2224.xlsx', package = 'tbeploads')
wqpth    <- system.file('extdata/sprwq2224.csv',    package = 'tbeploads')

# monthly per-spring loads using a local water quality file
anlz_spr(tbwxlpth = tbwxlpth, wqpth = wqpth, yrrng = c(2022, 2024))
#> # A tibble: 108 × 14
#>    source spring   site     segment    yr    mo flow_cfs tn_mgl tp_mgl tss_mgl
#>    <chr>  <chr>    <chr>      <int> <dbl> <dbl>    <dbl>  <dbl>  <dbl>   <dbl>
#>  1 SPRING Buckhorn 02301695       2  2022     1     9.46   2.26 0.0478       4
#>  2 SPRING Buckhorn 02301695       2  2022     2    10.8    2.26 0.0478       4
#>  3 SPRING Buckhorn 02301695       2  2022     3    10.1    2.26 0.0478       4
#>  4 SPRING Buckhorn 02301695       2  2022     4     9.94   2.26 0.0478       4
#>  5 SPRING Buckhorn 02301695       2  2022     5     7.94   2.26 0.0478       4
#>  6 SPRING Buckhorn 02301695       2  2022     6     8.96   2.26 0.0478       4
#>  7 SPRING Buckhorn 02301695       2  2022     7     9.33   2.26 0.0478       4
#>  8 SPRING Buckhorn 02301695       2  2022     8    10.4    2.26 0.0478       4
#>  9 SPRING Buckhorn 02301695       2  2022     9    10.4    2.26 0.0478       4
#> 10 SPRING Buckhorn 02301695       2  2022    10    13.2    2.26 0.0478       4
#> # ℹ 98 more rows
#> # ℹ 4 more variables: h2oload <dbl>, tnload <dbl>, tpload <dbl>, tssload <dbl>

# annual basin-level totals
anlz_spr(tbwxlpth = tbwxlpth, wqpth = wqpth, yrrng = c(2022, 2024),
          summ = 'basin', summtime = 'year')
#> # A tibble: 6 × 8
#>   source majbasin           segment    yr   h2oload  tnload tpload tssload
#>   <chr>  <chr>                <int> <dbl>     <dbl>   <dbl>  <dbl>   <dbl>
#> 1 SPRING Alafia River             2  2022 51778360. 117185.  3194. 207113.
#> 2 SPRING Alafia River             2  2023 49855415. 110389.  3225. 199422.
#> 3 SPRING Alafia River             2  2024 53199624. 119112.  3360. 212798.
#> 4 SPRING Hillsborough River       2  2022 17180010.   3087.  1277.  75592.
#> 5 SPRING Hillsborough River       2  2023 11199647.   1542.  1509.  49278.
#> 6 SPRING Hillsborough River       2  2024 20197069.   3009.  1979.  88867.

# monthly segment-level totals
anlz_spr(tbwxlpth = tbwxlpth, wqpth = wqpth, yrrng = c(2022, 2024),
          summ = 'segment')
#> # A tibble: 36 × 8
#>    source segment    yr    mo  h2oload tnload tpload tssload
#>    <chr>    <int> <dbl> <dbl>    <dbl>  <dbl>  <dbl>   <dbl>
#>  1 SPRING       2  2022     1 5992578. 10138.   392.  24628.
#>  2 SPRING       2  2022     2 4842061.  9449.   307.  19658.
#>  3 SPRING       2  2022     3 3520026.  7945.   215.  14084.
#>  4 SPRING       2  2022     4 5021268.  8819.   324.  20574.
#>  5 SPRING       2  2022     5 3756722.  7675.   237.  15186.
#>  6 SPRING       2  2022     6 4234204.  8633.   267.  17119.
#>  7 SPRING       2  2022     7 5623595.  9685.   366.  23079.
#>  8 SPRING       2  2022     8 6611417. 10641.   435.  27275.
#>  9 SPRING       2  2022     9 7012684. 11028.   463.  28981.
#> 10 SPRING       2  2022    10 7447179. 11734.   489.  30772.
#> # ℹ 26 more rows

if (FALSE) { # \dontrun{
# retrieve water quality from APIs automatically (no local file needed)
anlz_spr(tbwxlpth = tbwxlpth, yrrng = c(2022, 2024))
} # }
```
