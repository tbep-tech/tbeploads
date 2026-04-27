# Groundwater (GW)

``` r
library(tbeploads)
```

Groundwater loads to Tampa Bay are estimated using the three-aquifer
framework from Zarbock et al. (1994). The
[`anlz_gw()`](https://tbep-tech.github.io/tbeploads/reference/anlz_gw.md)
function computes monthly TN, TP, and hydrologic loads for seven bay
segments (1 = Old Tampa Bay through 7 = Manatee River).

## Methodology

Three aquifer types contribute to each bay segment each month.

**Floridan aquifer:** Flow is estimated with Darcy’s Law: Q = 7.4805 x
10^-6 x T x I x L, where T is transmissivity (ft²/day), I is the
hydraulic gradient (ft/mile), and L is the flow zone length (miles). Q
is in million gallons per day (MGD). Monthly nutrient loads (kg/month)
are Q x C x 8.342 x 30.5 / 2.2, where C is the TN or TP concentration in
mg/L. Monthly hydrologic load (m³/month) is Q x 3785 x 30.5.
Transmissivity and flow zone length are fixed constants per segment from
Zarbock et al. (1994). Hydraulic gradients are season-specific: months
1-6 and 11-12 are dry season; months 7-10 are wet season. Segments 4-7
have zero gradient in the dry season; segment 5 has zero gradient in
both seasons.

**Surficial and intermediate aquifers:** Loads are fixed monthly
constants per segment derived from 1995-1998 (surficial) and 1999-2003
(intermediate) SWFWMD monitoring data. These values have not changed
since the original analysis.

## Floridan aquifer concentrations

Floridan aquifer TN and TP concentrations (mg/L) can be obtained from
the [Water Atlas API](https://dev.api.wateratlas.org) using
[`util_gw_getwq()`](https://tbep-tech.github.io/tbeploads/reference/util_gw_getwq.md).
The default stations are 18340 (CR 581 North Fldn) and 18965 (SR 52 and
CR 581 Deep), the two Pasco County Floridan aquifer monitoring wells
used in the 2022-2024 loading analysis. Segment 1 (Old Tampa Bay) uses
the first station mean only; segment 2 (Hillsborough Bay) uses the
arithmetic mean of both station means. Segments 3-7 retain fixed
historical values from the 1995-1998 SWFWMD analysis that have been used
unchanged in every loading cycle through 2021.

``` r
# Requires internet access; retrieves Floridan aquifer concentrations
wqdat <- util_gw_getwq()
```

When `wqdat = NULL` (the default in
[`anlz_gw()`](https://tbep-tech.github.io/tbeploads/reference/anlz_gw.md)),
hardcoded concentrations from the 2022-2024 analysis are used directly.

## Estimating groundwater loads

[`anlz_gw()`](https://tbep-tech.github.io/tbeploads/reference/anlz_gw.md)
requires only a year range. Hardcoded 2021 FDEP potentiometric surface
gradients are used for all years because updated contours were not
available when the 2022-2024 analysis was run.

``` r
gw <- anlz_gw(yrrng = c(2022, 2024))

head(gw)
#>   Year Month source        segment      tn_load     tp_load   hy_load
#> 1 2022     1     GW Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 2 2022     2     GW Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 3 2022     3     GW Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 4 2022     4     GW Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 5 2022     5     GW Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 6 2022     6     GW Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
```

Load columns are in tons/month and `hy_load` is in million m³/month.

To pass concentrations retrieved from the API:

``` r
# Requires internet access
wqdat <- util_gw_getwq()
gw_api <- anlz_gw(yrrng = c(2022, 2024), wqdat = wqdat)
```

## Temporal summary

Setting `summtime = 'year'` sums monthly loads to annual totals. The
`Month` column is dropped.

``` r
anlz_gw(yrrng = c(2022, 2024), summtime = 'year')
#>    Year source          segment     tn_load    tp_load    hy_load
#> 1  2022     GW   Boca Ciega Bay  0.00502654 0.04748757  0.1585512
#> 2  2023     GW   Boca Ciega Bay  0.00502654 0.04748757  0.1585512
#> 3  2024     GW   Boca Ciega Bay  0.00502654 0.04748757  0.1585512
#> 4  2022     GW Hillsborough Bay 20.72632859 2.46652041 73.9028084
#> 5  2023     GW Hillsborough Bay 20.72632859 2.46652041 73.9028084
#> 6  2024     GW Hillsborough Bay 20.72632859 2.46652041 73.9028084
#> 7  2022     GW  Lower Tampa Bay  0.10948950 0.62279120  3.8203550
#> 8  2023     GW  Lower Tampa Bay  0.10948950 0.62279120  3.8203550
#> 9  2024     GW  Lower Tampa Bay  0.10948950 0.62279120  3.8203550
#> 10 2022     GW    Manatee River  0.10249411 0.50923100  3.5031130
#> 11 2023     GW    Manatee River  0.10249411 0.50923100  3.5031130
#> 12 2024     GW    Manatee River  0.10249411 0.50923100  3.5031130
#> 13 2022     GW Middle Tampa Bay  0.28633333 1.62254143  9.9954764
#> 14 2023     GW Middle Tampa Bay  0.28633333 1.62254143  9.9954764
#> 15 2024     GW Middle Tampa Bay  0.28633333 1.62254143  9.9954764
#> 16 2022     GW    Old Tampa Bay  6.58537094 1.95697341 60.1804539
#> 17 2023     GW    Old Tampa Bay  6.58537094 1.95697341 60.1804539
#> 18 2024     GW    Old Tampa Bay  6.58537094 1.95697341 60.1804539
#> 19 2022     GW   Terra Ceia Bay  0.01894529 0.10028212  0.6552311
#> 20 2023     GW   Terra Ceia Bay  0.01894529 0.10028212  0.6552311
#> 21 2024     GW   Terra Ceia Bay  0.01894529 0.10028212  0.6552311
```
