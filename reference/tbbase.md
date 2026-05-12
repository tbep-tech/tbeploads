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
#> # A tibble: 5,182 × 10
#>    bay_seg basin  drnfeat entity FLUCCSCODE CLUCSID IMPROVED hydgrp conservation
#>      <dbl> <chr>  <chr>   <chr>       <dbl>   <dbl>    <int> <chr>  <lgl>       
#>  1       1 02307… CANAL   HILLS…       1900       8        0 A      FALSE       
#>  2       1 02307… CANAL   HILLS…       1900       8        0 B/D    FALSE       
#>  3       1 02307… CANAL   HILLS…       4340      15        0 A      FALSE       
#>  4       1 02307… CANAL   HILLS…       4340      15        0 A/D    FALSE       
#>  5       1 02307… CANAL   HILLS…       4340      15        0 B/D    FALSE       
#>  6       1 02307… CANAL   HILLS…       8300       7        1 A      FALSE       
#>  7       1 02307… CANAL   HILLS…       8300       7        1 B/D    FALSE       
#>  8       1 02307… LAKE    HILLS…       1100       1        1 A/D    FALSE       
#>  9       1 02307… LAKE    HILLS…       6150      18        0 A/D    FALSE       
#> 10       1 02307… LAKE    HILLS…       6300      18        0 A/D    FALSE       
#> # ℹ 5,172 more rows
#> # ℹ 1 more variable: area_ha <dbl>
```
