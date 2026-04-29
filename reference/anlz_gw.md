# Calculate groundwater loads to Tampa Bay segments

Calculate groundwater loads to Tampa Bay segments

## Usage

``` r
anlz_gw(
  pot_dry,
  pot_wet,
  yrrng = c(2022, 2024),
  wqdat = NULL,
  summtime = c("month", "year")
)
```

## Arguments

- pot_dry:

  [`SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
  (or `PackedSpatRaster`) of Upper Floridan Aquifer potentiometric head
  for the dry season, as returned by
  [`util_gw_getcontour`](https://tbep-tech.github.io/tbeploads/reference/util_gw_getcontour.md)
  with `season = "dry"`. The package dataset
  [`contdry`](https://tbep-tech.github.io/tbeploads/reference/contdry.md)
  contains a pre-computed 2022 example.

- pot_wet:

  [`SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
  (or `PackedSpatRaster`) of Upper Floridan Aquifer potentiometric head
  for the wet season, as returned by
  [`util_gw_getcontour`](https://tbep-tech.github.io/tbeploads/reference/util_gw_getcontour.md)
  with `season = "wet"`. The package dataset
  [`contwet`](https://tbep-tech.github.io/tbeploads/reference/contwet.md)
  contains a pre-computed 2022 example.

- yrrng:

  integer vector of length 2, start and end year for the load estimates,
  e.g. `c(2022, 2024)`. The same gradients derived from `pot_dry` and
  `pot_wet` are applied to every year in the range.

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

**Hydraulic gradients:** Gradients are computed once from `pot_dry` and
`pot_wet` via
[`util_gw_grad`](https://tbep-tech.github.io/tbeploads/reference/util_gw_grad.md)
and applied to every year in `yrrng`. Update `pot_dry` and `pot_wet`
with fresh outputs from
[`util_gw_getcontour`](https://tbep-tech.github.io/tbeploads/reference/util_gw_getcontour.md)
when new FDEP potentiometric surface maps become available. See
[`util_gw_grad`](https://tbep-tech.github.io/tbeploads/reference/util_gw_grad.md)
for details on search areas, zero-gradient segments, and benchmark
warnings.

**Surficial and intermediate aquifers:** Loads are fixed constants per
segment. Surficial values are from `gwupdate95-98_final.xls` (1995-1998
SWFWMD monitoring data). Intermediate values are means from SWFWMD
monitoring over 1999-2003. These have not changed since the original
analysis.

**Season assignment:** Months 1-6 and 11-12 are dry season; months 7-10
are wet season.

## References

Zarbock, H., A. Janicki, D. Wade, D. Heimbuch, and H. Wilson. 1994.
Estimates of Total Nitrogen, Total Phosphorus, and Total Suspended
Solids Loadings to Tampa Bay, Florida. Technical Publication \#04-94.
Prepared by Coastal Environmental, Inc. Prepared for Tampa Bay National
Estuary Program. St. Petersburg, FL.

## Examples

``` r
# contdry and contwet are pre-computed 2022 package datasets
gw <- anlz_gw(contdry, contwet, yrrng = c(2022, 2024))
head(gw)
#>   Year Month source        segment      tn_load     tp_load   hy_load
#> 1 2022     1     GW Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 2 2022     2     GW Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 3 2022     3     GW Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 4 2022     4     GW Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 5 2022     5     GW Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 6 2022     6     GW Boca Ciega Bay 0.0004188783 0.003957298 0.0132126

# annual totals
anlz_gw(contdry, contwet, yrrng = c(2022, 2024), summtime = 'year')
#>    Year source          segment     tn_load    tp_load    hy_load
#> 1  2022     GW   Boca Ciega Bay  0.00502654 0.04748757  0.1585512
#> 2  2023     GW   Boca Ciega Bay  0.00502654 0.04748757  0.1585512
#> 3  2024     GW   Boca Ciega Bay  0.00502654 0.04748757  0.1585512
#> 4  2022     GW Hillsborough Bay 19.88198988 2.37177288 70.9236779
#> 5  2023     GW Hillsborough Bay 19.88198988 2.37177288 70.9236779
#> 6  2024     GW Hillsborough Bay 19.88198988 2.37177288 70.9236779
#> 7  2022     GW  Lower Tampa Bay  0.10842020 0.61693145  3.7816227
#> 8  2023     GW  Lower Tampa Bay  0.10842020 0.61693145  3.7816227
#> 9  2024     GW  Lower Tampa Bay  0.10842020 0.61693145  3.7816227
#> 10 2022     GW    Manatee River  0.13199801 0.64376879  4.5718074
#> 11 2023     GW    Manatee River  0.13199801 0.64376879  4.5718074
#> 12 2024     GW    Manatee River  0.13199801 0.64376879  4.5718074
#> 13 2022     GW Middle Tampa Bay  0.25632137 1.45807586  8.9083788
#> 14 2023     GW Middle Tampa Bay  0.25632137 1.45807586  8.9083788
#> 15 2024     GW Middle Tampa Bay  0.25632137 1.45807586  8.9083788
#> 16 2022     GW    Old Tampa Bay  6.54776566 1.94595506 59.8399180
#> 17 2023     GW    Old Tampa Bay  6.54776566 1.94595506 59.8399180
#> 18 2024     GW    Old Tampa Bay  6.54776566 1.94595506 59.8399180
#> 19 2022     GW   Terra Ceia Bay  0.01797800 0.09544564  0.6201936
#> 20 2023     GW   Terra Ceia Bay  0.01797800 0.09544564  0.6201936
#> 21 2024     GW   Terra Ceia Bay  0.01797800 0.09544564  0.6201936

if (FALSE) { # \dontrun{
# update rasters from FDEP for a new year, then compute loads
pot_dry <- util_gw_getcontour("dry", 2025)
pot_wet <- util_gw_getcontour("wet", 2025)
gw <- anlz_gw(pot_dry, pot_wet, yrrng = c(2025, 2025))

# pass concentrations from the Water Atlas API
gw <- anlz_gw(pot_dry, pot_wet, yrrng = c(2025, 2025),
              wqdat = util_gw_getwq())
} # }
```
