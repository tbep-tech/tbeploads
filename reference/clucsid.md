# Lookup table for FLUCCSCODE conversion to CLUCSID and IMPROVED

Lookup table for FLUCCSCODE conversion to CLUCSID and IMPROVED

## Usage

``` r
clucsid
```

## Format

A data frame

## Details

Used to create the
[`tbbase`](https://tbep-tech.github.io/tbeploads/reference/tbbase.md)
combined layer with jurisdictions, land use, soils, and sub-basins, used
in
[`util_nps_tbbase`](https://tbep-tech.github.io/tbeploads/reference/util_nps_tbbase.md).

- `FLUCCSCODE`: Numeric value for the Florida Land Use, Cover and Forms
  Classification System (FLUCCS) code

- `CLUCSID`: Numeric value for the coastal land use code, from JEI

- `IMPROVED`: Numeric value for whether the code is improved (1) or not
  (0)

- `DESCRIPTION`: Character description of the CLUCSID code

## Examples

``` r
if (FALSE) { # \dontrun{
clucsid <- read.csv('data-raw/clucsid.csv', stringsAsFactors = F, header = T)

save(clucsid, file = 'data/clucsid.RData', compress = 'xz')
} # }
clucsid
#>    FLUCCSCODE CLUCSID IMPROVED                              DESCRIPTION
#> 1        1100       1        1                  Low Density Residential
#> 2        1200       2        1               Medium Density Residential
#> 3        1300       3        1                 High Density Residential
#> 4        1400       4        1                               Commercial
#> 5        1700       7        1 Institutional, Transportation, Utilities
#> 6        1800       8        0                              Range Lands
#> 7        1820       8        1                              Range Lands
#> 8        1900       8        0                              Range Lands
#> 9        2100      10        1                                  Pasture
#> 10       2600       8        0                              Range Lands
#> 11       3300       8        0                              Range Lands
#> 12       4340      15        0                           Upland Forests
#> 13       4400      15        0                           Upland Forests
#> 14       5200      16        0                               Freshwater
#> 15       5300      16        0                               Freshwater
#> 16       6150      18        0             Forested Freshwater Wetlands
#> 17       6210      18        0             Forested Freshwater Wetlands
#> 18       6300      18        0             Forested Freshwater Wetlands
#> 19       6400      20        0         Non-forested Freshwater Wetlands
#> 20       6410      20        0         Non-forested Freshwater Wetlands
#> 21       6430      20        0         Non-forested Freshwater Wetlands
#> 22       6440      16        0                               Freshwater
#> 23       6520      21        0                              Tidal Flats
#> 24       6530      20        0         Non-forested Freshwater Wetlands
#> 25       8100       7        1 Institutional, Transportation, Utilities
#> 26       8300       7        1 Institutional, Transportation, Utilities
#> 27       1500       5        1                               Industrial
#> 28       3200       8        0                              Range Lands
#> 29       4100      15        0                           Upland Forests
#> 30       5100      16        0                               Freshwater
#> 31       6200      18        0             Forested Freshwater Wetlands
#> 32       7400       9        0                             Barren Lands
#> 33       2200      11        1                                   Groves
#> 34       2400      13        1                                  Nursery
#> 35       2500      16        1                               Freshwater
#> 36       3100       8        0                              Range Lands
#> 37       4110      15        0                           Upland Forests
#> 38       4300      15        0                           Upland Forests
#> 39       6100      18        0             Forested Freshwater Wetlands
#> 40       8200       7        1 Institutional, Transportation, Utilities
#> 41       4200      15        0                           Upland Forests
#> 42       4120      15        0                           Upland Forests
#> 43       6110      18        0             Forested Freshwater Wetlands
#> 44       6500      21        0                              Tidal Flats
#> 45       1600       6        1                                   Mining
#> 46       5400      17        0                                Saltwater
#> 47       6120      19        0                       Saltwater Wetlands
#> 48       6420      19        0                       Saltwater Wetlands
#> 49       6600      17        0                                Saltwater
#> 50       7100       9        0                             Barren Lands
#> 51       2140      14        1                      Row and Field Crops
#> 52       1650       6        1                                   Mining
#> 53       2300      12        1                                 Feedlots
#> 54       6460      16        0                               Freshwater
#> 55       7200       9        0                             Barren Lands
#> 56       3000       8        0                              Range Lands
#> 57       5720      17        0                                Saltwater
#> 58       5700      17        0                                Saltwater
```
