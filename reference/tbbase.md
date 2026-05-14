# Combined spatial data required for non-point source (NPS) ungaged estimate

Combined spatial data required for non-point source (NPS) ungaged
estimate

## Usage

``` r
tbbase
```

## Format

A summarized data frame containing the union of all inputs showing major
bay segment, sub-basin (basin), drainage feature (drnfeat), jurisdiction
(entity), land use/land cover (FLUCCSCODE), CLUCSID, IMPROVED,
hydrologic group (hydgrp), and area in hectures. These represent all
relevant spatial combinations in the Tampa Bay watershed.

See "data-raw/tbbase.R" for creation.

## Examples

``` r
tbbase
#> # A tibble: 21,122 × 9
#>    bay_seg basin    drnfeat entity    FLUCCSCODE CLUCSID IMPROVED hydgrp area_ha
#>      <dbl> <chr>    <chr>   <chr>          <dbl>   <dbl>    <int> <chr>    <dbl>
#>  1       1 02304500 LAKE    HILLSBOR…       1100       1        1 A      2.53e-3
#>  2       1 02304500 LAKE    HILLSBOR…       1100       1        1 A/D    6.53e-3
#>  3       1 02304500 LAKE    HILLSBOR…       1200       2        1 A      3.21e-2
#>  4       1 02304500 LAKE    HILLSBOR…       1200       2        1 A/D    1.26e-2
#>  5       1 02304500 LAKE    HILLSBOR…       1400       4        1 A      9.69e-3
#>  6       1 02304500 LAKE    HILLSBOR…       1400       4        1 A/D    7.79e-3
#>  7       1 02304500 LAKE    HILLSBOR…       1700       7        1 A/D    1.55e-4
#>  8       1 02304500 LAKE    HILLSBOR…       1900       8        0 A      5.45e-3
#>  9       1 02304500 LAKE    HILLSBOR…       1900       8        0 A/D    5.74e-3
#> 10       1 02304500 LAKE    HILLSBOR…       2600       8        0 A      2.28e-3
#> # ℹ 21,112 more rows
```
