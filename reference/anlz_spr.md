# Calculate spring loads to Hillsborough Bay

Calculate spring loads to Hillsborough Bay

## Usage

``` r
anlz_spr(tbwpth, wqpth, yrrng = c(2021, 2021), sulphurflow = NULL)
```

## Arguments

- tbwpth:

  character vector of file paths to TBW discharge data (tab-delimited
  .txt) for Lithia and Buckhorn springs. Files must contain columns:
  DeviceID, MeasureDateTime, Value, MeasureType, Units. Device IDs 3381
  (Lithia Minor), 4586 (Lithia Major), 3388 (Buckhorn Upper), and 3649
  (Buckhorn Lower) are expected across one or more files.

- wqpth:

  character string, file path to spring water quality data (.xlsx).
  Expected to contain annual mean concentrations (mg/L) of TN, TP, and
  TSS by spring and year.

- yrrng:

  integer vector of length 2, start and end year for the analysis, e.g.
  `c(2021, 2021)`.

- sulphurflow:

  data frame of daily Sulphur Spring discharge already retrieved by
  [`util_nps_getusgsflow`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getusgsflow.md),
  or `NULL` (default) to fetch from the USGS API.

## Value

A data frame with one row per spring per month with columns: `source`
("SPRING"), `spring`, `site` (USGS station ID), `segment` (2), `yr`,
`mo`, `flow_cfs` (monthly mean), `tn_mgl`, `tp_mgl`, `tss_mgl`,
`h2oload` (m3/month), `tnload` (kg/month), `tpload` (kg/month),
`tssload` (kg/month).

## Details

Loads are calculated for Lithia, Buckhorn, and Sulphur springs, all of
which discharge to Hillsborough Bay (bay segment 2).

**Discharge data (TBW – Lithia and Buckhorn):** Files provided in
`tbwpth` contain weekly point measurements. Device IDs map to
sub-springs as follows: 3381 = Lithia Minor, 4586 = Lithia Major, 3388 =
Buckhorn Upper, 3649 = Buckhorn Lower. Flow values in MGD are converted
to CFS (1 MGD = 1.547 CFS). Lithia total flow is the sum of Minor and
Major. Buckhorn total flow is Lower minus Upper, because the two gauges
bracket the spring input on the same stream reach.

**Discharge data (USGS – Sulphur Spring):** Daily CFS values for station
02306000 are retrieved from the USGS NWIS API via
[`util_nps_getusgsflow`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getusgsflow.md).
A pre-fetched data frame can be supplied via the `sulphurflow` argument
to avoid a repeat API call.

**Interpolation:** Because springs are assumed never to have zero
discharge, all gaps in the daily discharge record are filled by linear
interpolation between observed values
([`na.approx`](https://rdrr.io/pkg/zoo/man/na.approx.html) with
`rule = 2`). Leading or trailing gaps are filled with the nearest
observed value.

**Water quality data:** Annual mean concentrations (mg/L) for TN, TP,
and TSS are derived from `wqpth`. If a year within `yrrng` has no WQ
observations for a given spring, the grand mean across all available
years is substituted.

**Load calculation:** Monthly mean flows (CFS) are computed from the
complete daily discharge series. Loads are then:
\$\$h2oload\\(m^3/month) = \overline{Q}\_{cfs} \times 86400 \times
\frac{365}{12} \times 28.32 \times 10^{-3}\$\$ \$\$load\\(kg/month) =
h2oload \times C\_{mg/L} \times 10^{-3}\$\$

## Examples

``` r
if (FALSE) { # \dontrun{
tbwpth <- c('3381_2021.txt', '4586_2021.txt', '3388_2021.txt', '3649_2021.txt')
anlz_spr(
  tbwpth  = tbwpth,
  wqpth   = 'Springs_WQ21RP.xlsx',
  yrrng   = c(2021, 2021)
)
} # }
```
