# Remove point source loads from non-point source load estimates

Subtract gaged industrial and domestic point source loads from NPS model
output to isolate true non-point source loads.

## Usage

``` r
anlz_nps_psremove(nps, ips, dps, ad_ap = TRUE, summtime = c("month", "year"))
```

## Arguments

- nps:

  data frame of NPS loads from
  [`anlz_nps`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps.md)
  with `summ = 'basin'` and `summtime = 'month'`

- ips:

  data frame of IPS loads from
  [`anlz_ips`](https://tbep-tech.github.io/tbeploads/reference/anlz_ips.md)
  with `summ = 'basin'` and `summtime = 'month'`

- dps:

  data frame of DPS loads from
  [`anlz_dps`](https://tbep-tech.github.io/tbeploads/reference/anlz_dps.md)
  with `summ = 'basin'` and `summtime = 'month'`

- ad_ap:

  logical, whether to apply fixed monthly AD/AP TN reductions from the
  2007 RA allocation analysis. Default `TRUE`.

- summtime:

  character, one of `'month'` or `'year'`. Controls whether the output
  is monthly or annual. Default is `'month'`.

## Value

data frame with columns for `Year`, `Month` (if `summtime = 'month'`),
`source` (always `"NPS"`), `segment`, `tn_load`, `tp_load`, `tss_load`,
`bod_load`, and `hy_load`. Loads are in short tons per month or year;
hydrologic load is in cubic meters per month or year. Column order
matches the output of
[`anlz_ips`](https://tbep-tech.github.io/tbeploads/reference/anlz_ips.md)
and
[`anlz_dps`](https://tbep-tech.github.io/tbeploads/reference/anlz_dps.md).

## Details

Gaged NPS loads (estimated from stream gauges) include point source
loads discharged upstream of the gauge. This function subtracts IPS and
DPS loads in gaged basins from the combined NPS model output so that
point source contributions are not double-counted.

Only IPS and DPS records in gaged basins (identified via
[`dbasing`](https://tbep-tech.github.io/tbeploads/reference/dbasing.md))
are subtracted. Nested basin identifiers (02301000, 02301300 → 02301500;
02303000, 02303330 → 02304500; 02299950 → LMANATEE) are reassigned to
their parent basins before summing, consistent with the handling in
[`anlz_nps`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps.md).

When `ad_ap = TRUE`, fixed monthly TN reductions from the 2007 RA
allocation analysis (AD/AP) are subtracted from the segment-level NPS
totals. These values represent the annual reduction divided into monthly
increments:

- Old Tampa Bay:

  -2.41 short tons/month

- Hillsborough Bay:

  -4.31 short tons/month

- Middle Tampa Bay:

  -2.29 short tons/month

- Lower Tampa Bay:

  -0.36 short tons/month

- Manatee River:

  -2.74 short tons/month (representing the combined reduction for
  segments 55, 6, and 7 as applied in the 2022-2024 RA)

Other segments (Boca Ciega Bay, Boca Ciega Bay South, Terra Ceia Bay)
receive no AD/AP adjustment.

## See also

[`anlz_nps`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps.md),
[`anlz_ips`](https://tbep-tech.github.io/tbeploads/reference/anlz_ips.md),
[`anlz_dps`](https://tbep-tech.github.io/tbeploads/reference/anlz_dps.md)

## Examples

``` r
if (FALSE) { # \dontrun{
nps <- anlz_nps(yrrng = c('2021-01-01', '2023-12-31'), tbbase = tbbase,
  rain = rain, allwq = allwq, allflo = allflo, vernafl = vernafl,
  summ = 'basin', summtime = 'month')

ipsfls <- list.files(system.file('extdata/', package = 'tbeploads'),
  pattern = 'ps_ind_', full.names = TRUE)
dpsfls <- list.files(system.file('extdata/', package = 'tbeploads'),
  pattern = 'ps_dom', full.names = TRUE)

ips <- anlz_ips(ipsfls, summ = 'basin', summtime = 'month')
dps <- anlz_dps(dpsfls, summ = 'basin', summtime = 'month')

anlz_nps_psremove(nps, ips, dps)
} # }
```
