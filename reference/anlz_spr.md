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
  quality data are retrieved automatically from external APIs. Lithia
  and Buckhorn concentrations are obtained from the Water Atlas API
  (SWFWMD stations 17805 and 18276) and Sulphur Spring concentrations
  are obtained via
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

  data frame of daily Sulphur Spring discharge or `NULL` (default) to
  obtain from the USGS API.

- verbose:

  logical, if `TRUE` (default) progress messages are printed when water
  quality data are retrieved via API (`wqpth = NULL`).

## Value

A data frame whose structure depends on `summ`:

- `'spring'`: one row per spring per time period, with columns `source`,
  `spring`, `site`, `segment`, `yr`, `mo` (dropped for annual),
  `hy_load` (1e6 m3), `tn_load` (tons), `tp_load` (tons), and `tss_load`
  (tons).

- `'basin'`: one row per drainage basin per time period, with columns
  `source`, `majbasin`, `segment`, `yr`, `mo` (dropped for annual),
  `hy_load` (1e6 m3), `tn_load` (tons), `tp_load` (tons), `tss_load`
  (tons).

- `'segment'`: one row per bay segment per time period, with columns
  `source`, `segment`, `yr`, `mo` (dropped for annual), `hy_load` (1e6
  m3), `tn_load` (tons), `tp_load` (tons), `tss_load` (tons).

For annual output (`summtime = 'year'`), load columns are summed over
months.

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
A data frame can also be supplied via the `sulphurflow` argument.

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
estimates. If a year within `yrrng` has no water quality observations
for a given spring, the grand mean across all available years is
substituted.

**Water quality data (API, `wqpth = NULL`):** When `wqpth` is `NULL`,
water quality data are obtained using
[`util_spr_getwq`](https://tbep-tech.github.io/tbeploads/reference/util_spr_getwq.md).
Lithia (SWFWMD station 17805, Lithia Main Spring) and Buckhorn (SWFWMD
station 18276, Buckhorn Main Spring) concentrations are retrieved from
the [Water Atlas API](https://dev.api.wateratlas.org) (`WIN_21FLSWFD`
data source). These are probably the same quarterly SWFWMD observations
included in the FDEP IWR file. Sulphur Spring (EPC station 174) is
retrieved via
[`read_importepc`](https://rdrr.io/pkg/tbeptools/man/read_importepc.html),
providing monthly observations from the Environmental Protection
Commission of Hillsborough County.

**TSS concentrations:** When `wqpth` is supplied, TSS concentrations are
assigned from a fixed lookup table derived from the historical SAS-based
loading model (SPRMOD2). When `wqpth = NULL`, TSS values from the API or
EPC source are used where available. Any spring-year with no observed
TSS falls back to the same fixed values. The fixed values are: Sulphur
Springs (02306000) = 4.4 mg/L, Buckhorn Springs (02301695) = 4.0 mg/L,
Lithia Springs (02301600) = 4.0 mg/L.

**Load calculation:** Monthly mean flows (CFS) are computed from the
complete daily discharge series. Loads are then:
\$\$hy_load\\(m^3/month) = \overline{Q}\_{cfs} \times 86400 \times
\frac{365}{12} \times 28.32 \times 10^{-3}\$\$ \$\$load\\(tons/month) =
hy_load \times C\_{mg/L} \times 10^{-3} / 907.1847\$\$

`hy_load` is converted to million m3 in the final output.

**Spatial summaries:** The data are summarized differently based on the
`summ` and `summtime` arguments. All loading data are summed based on
these arguments, e.g., by bay segment (`summ = 'segment'`) and year
(`summtime = 'year'`). For springs, valid options for `summ` are
`'spring'` (one row per spring per time period), `'basin'` (loads summed
within drainage basins. Lithia and Buckhorn combined into
`"Alafia River"`, Sulphur into `"Hillsborough River"`), and `'segment'`
(all springs summed to bay segment 2, Hillsborough Bay).

## Examples

``` r
tbwxlpth <- system.file('extdata/sprflow2224.xlsx', package = 'tbeploads')
wqpth    <- system.file('extdata/sprwq2224.csv',    package = 'tbeploads')

# monthly per-spring loads using a local water quality file
anlz_spr(tbwxlpth = tbwxlpth, wqpth = wqpth, yrrng = c(2022, 2024))
#> # A tibble: 108 × 10
#>    source spring   site     segment    yr    mo hy_load tn_load tp_load tss_load
#>    <chr>  <chr>    <chr>      <int> <dbl> <dbl>   <dbl>   <dbl>   <dbl>    <dbl>
#>  1 SPRING Buckhorn 02301695       2  2022     1   0.704    1.75  0.0370     3.10
#>  2 SPRING Buckhorn 02301695       2  2022     2   0.807    2.01  0.0425     3.56
#>  3 SPRING Buckhorn 02301695       2  2022     3   0.750    1.86  0.0395     3.31
#>  4 SPRING Buckhorn 02301695       2  2022     4   0.739    1.84  0.0389     3.26
#>  5 SPRING Buckhorn 02301695       2  2022     5   0.591    1.47  0.0311     2.60
#>  6 SPRING Buckhorn 02301695       2  2022     6   0.667    1.66  0.0351     2.94
#>  7 SPRING Buckhorn 02301695       2  2022     7   0.694    1.73  0.0365     3.06
#>  8 SPRING Buckhorn 02301695       2  2022     8   0.776    1.93  0.0408     3.42
#>  9 SPRING Buckhorn 02301695       2  2022     9   0.771    1.92  0.0406     3.40
#> 10 SPRING Buckhorn 02301695       2  2022    10   0.984    2.45  0.0518     4.34
#> # ℹ 98 more rows

# annual basin-level totals
anlz_spr(tbwxlpth = tbwxlpth, wqpth = wqpth, yrrng = c(2022, 2024),
          summ = 'basin', summtime = 'year')
#> # A tibble: 6 × 8
#>   source majbasin           segment    yr hy_load tn_load tp_load tss_load
#>   <chr>  <chr>                <int> <dbl>   <dbl>   <dbl>   <dbl>    <dbl>
#> 1 SPRING Alafia River             2  2022    51.8  129.      3.52    228. 
#> 2 SPRING Alafia River             2  2023    49.9  122.      3.56    220. 
#> 3 SPRING Alafia River             2  2024    53.2  131.      3.70    235. 
#> 4 SPRING Hillsborough River       2  2022    17.2    3.40    1.41     83.3
#> 5 SPRING Hillsborough River       2  2023    11.2    1.70    1.66     54.3
#> 6 SPRING Hillsborough River       2  2024    20.2    3.32    2.18     98.0

# monthly segment-level totals
anlz_spr(tbwxlpth = tbwxlpth, wqpth = wqpth, yrrng = c(2022, 2024),
          summ = 'segment')
#> # A tibble: 36 × 8
#>    source segment    yr    mo hy_load tn_load tp_load tss_load
#>    <chr>    <int> <dbl> <dbl>   <dbl>   <dbl>   <dbl>    <dbl>
#>  1 SPRING       2  2022     1    5.99   11.2    0.432     27.1
#>  2 SPRING       2  2022     2    4.84   10.4    0.338     21.7
#>  3 SPRING       2  2022     3    3.52    8.76   0.237     15.5
#>  4 SPRING       2  2022     4    5.02    9.72   0.357     22.7
#>  5 SPRING       2  2022     5    3.76    8.46   0.261     16.7
#>  6 SPRING       2  2022     6    4.23    9.52   0.295     18.9
#>  7 SPRING       2  2022     7    5.62   10.7    0.404     25.4
#>  8 SPRING       2  2022     8    6.61   11.7    0.479     30.1
#>  9 SPRING       2  2022     9    7.01   12.2    0.511     31.9
#> 10 SPRING       2  2022    10    7.45   12.9    0.539     33.9
#> # ℹ 26 more rows

if (FALSE) { # \dontrun{
# retrieve water quality from APIs automatically (no local file needed)
anlz_spr(tbwxlpth = tbwxlpth, yrrng = c(2022, 2024))
} # }
```
