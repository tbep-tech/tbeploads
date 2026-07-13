# TBNMC TN load allocations for industrial material loss (ML) facilities

TBNMC TN load allocations for industrial material loss (ML) facilities

## Usage

``` r
ml_allocations
```

## Format

A `data.frame`

## Details

TN load allocations assigned to industrial material loss facilities
under the Tampa Bay Nitrogen Management Consortium (TBNMC) framework.
One row per facility, always.

- `entity`: Entity name matching the
  [`facilities`](https://tbep-tech.github.io/tbeploads/reference/facilities.md)
  table convention

- `facname`: Facility name matching the
  [`facilities`](https://tbep-tech.github.io/tbeploads/reference/facilities.md)
  table convention

- `bay_seg`: Integer bay segment identifier (2 = Hillsborough Bay, 4 =
  Lower Tampa Bay)

- `alloc_tons`: Allocation in tons TN per year. For `ishared`
  facilities, this is the group's collective allocation (the same value
  repeated on every member row), not an individual facility allocation

- `ishared`: Logical; `TRUE` when the facility is jointly assessed
  against a collective allocation shared with other facilities (see
  `alloc_tons`)

The three Mosaic material loss facilities (Big Bend, Riverview, Tampa
Marine) share a single 9.9 ton/year allocation in Hillsborough Bay
(`ishared = TRUE` on all three rows). Kinder Morgan Port Sutton and
Tampaplex Material Losses are each assessed individually against their
own distinct allocation (`ishared = FALSE`), despite the misleadingly
similar names to the shared IPS Kinder Morgan group; Kinder Morgan Port
Manatee is likewise a separate, non-shared facility.

## Examples

``` r
ml_allocations
#> # A tibble: 8 × 5
#>   entity        facname                    bay_seg alloc_tons ishared
#>   <chr>         <chr>                        <int>      <dbl> <lgl>  
#> 1 CSX           Rockport                         2      5.63  FALSE  
#> 2 CSX           Newport                          2      5.63  FALSE  
#> 3 Kinder Morgan Kinder Morgan Port Sutton        2      1.8   FALSE  
#> 4 Kinder Morgan Kinder Morgan Tampaplex          2      3.38  FALSE  
#> 5 Kinder Morgan Kinder Morgan Port Manatee       4      0.299 FALSE  
#> 6 Mosaic        Riverview                        2      9.9   TRUE   
#> 7 Mosaic        Tampa Marine                     2      9.9   TRUE   
#> 8 Mosaic        Big Bend                         2      9.9   TRUE   
```
