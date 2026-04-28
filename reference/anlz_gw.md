# Calculate groundwater loads to Tampa Bay segments

Calculate groundwater loads to Tampa Bay segments

## Usage

``` r
anlz_gw(yrrng = c(2022, 2024), wqdat = NULL, summtime = c("month", "year"))
```

## Arguments

- yrrng:

  integer vector of length 2, start and end year, e.g. `c(2022, 2024)`.

- wqdat:

  data frame of Floridan aquifer TN and TP concentrations (mg/L) as
  returned by
  [`util_gw_getwq`](https://tbep-tech.github.io/tbeploads/reference/util_gw_getwq.md),
  with columns `bay_seg`, `tn_mgl`, and `tp_mgl`. When `NULL` (default),
  hardcoded concentrations from the 2022-2024 loading analysis are used.

- summtime:

  character, temporal summarization: `'month'` (default) returns one row
  per segment per month, `'year'` sums to annual totals.

## Value

A data frame with columns:

- `Year`: integer

- `Month`: integer (omitted when `summtime = 'year'`)

- `source`: character, `"GW"`

- `segment`: character, bay segment name

- `tn_load`: numeric, total nitrogen load (tons/month or tons/year)

- `tp_load`: numeric, total phosphorus load (tons/month or tons/year)

- `hy_load`: numeric, hydrologic load (million m\\^3\\/month or million
  m\\^3\\/year)

## Details

Estimates groundwater loads to each Tampa Bay segment for three aquifer
layers following the methodology in Zarbock et al. (1994).

**Floridan aquifer:** Flow is computed with Darcy's Law: \$\$Q = 7.4805
\times 10^{-6} \cdot T \cdot I \cdot L\$\$ where \\T\\ is transmissivity
(ft\\^2\\/day), \\I\\ is the hydraulic gradient (ft/mile), and \\L\\ is
the flow zone length (miles). \\Q\\ is in MGD. Nutrient loads (kg/month)
are: \$\$\text{load} = Q \cdot C \cdot 8.342 \cdot 30.5 / 2.2\$\$ where
\\C\\ is the TN or TP concentration (mg/L). Hydrologic load
(m\\^3\\/month) is \\Q \cdot 3785 \cdot 30.5\\.

**Hydraulic gradients:** The gradient section below contains a
commented-out framework that calls
[`util_gw_getcontour`](https://tbep-tech.github.io/tbeploads/reference/util_gw_getcontour.md)
and
[`util_gw_grad`](https://tbep-tech.github.io/tbeploads/reference/util_gw_grad.md)
to compute gradients dynamically from FDEP potentiometric surface
contours. The key challenge is that potentiometric high points for some
segments (notably Old Tampa Bay) lie north of the subwatershed boundary;
`util_gw_getcontour` accepts a `buf_dist` argument and `util_gw_grad`
accepts a `buf_segs` argument to expand the search area for those
segments. Until the buffer distances are calibrated against known SAS
gradients, hardcoded gradient values from the 2021 FDEP potentiometric
surface map are used (the same values applied for 2022-2024 in the
original SAS analysis, as no updated contours were available at that
time).

**Surficial and intermediate aquifers:** Loads are fixed constants per
segment. Surficial values are from `gwupdate95-98_final.xls` (1995-1998
SWFWMD monitoring data). Intermediate values are means from SWFWMD
monitoring over 1999-2003. These have not changed since the original
analysis.

**Season assignment:** Months 1-6 and 11-12 are dry season; months 7-10
are wet season.

## Examples

``` r
# monthly segment loads using hardcoded 2022-2024 gradients and concentrations
gw <- anlz_gw(yrrng = c(2022, 2024))
head(gw)
#>   Year Month source        segment      tn_load     tp_load   hy_load
#> 1 2022     1     GW Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 2 2022     2     GW Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 3 2022     3     GW Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 4 2022     4     GW Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 5 2022     5     GW Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 6 2022     6     GW Boca Ciega Bay 0.0004188783 0.003957298 0.0132126

# annual totals
gw <- anlz_gw(yrrng = c(2022, 2024), summtime = 'year')
head(gw)
#>   Year source          segment     tn_load    tp_load    hy_load
#> 1 2022     GW   Boca Ciega Bay  0.00502654 0.04748757  0.1585512
#> 2 2023     GW   Boca Ciega Bay  0.00502654 0.04748757  0.1585512
#> 3 2024     GW   Boca Ciega Bay  0.00502654 0.04748757  0.1585512
#> 4 2022     GW Hillsborough Bay 20.72632859 2.46652041 73.9028084
#> 5 2023     GW Hillsborough Bay 20.72632859 2.46652041 73.9028084
#> 6 2024     GW Hillsborough Bay 20.72632859 2.46652041 73.9028084

if (FALSE) { # \dontrun{
# pass concentrations from the Water Atlas API
gw <- anlz_gw(yrrng = c(2022, 2024), wqdat = util_gw_getwq())
head(gw)
} # }
```
