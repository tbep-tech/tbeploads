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

- `entity`: Entity name matching the
  [`facilities`](https://tbep-tech.github.io/tbeploads/reference/facilities.md)
  table convention

- `facname`: Facility name matching the
  [`facilities`](https://tbep-tech.github.io/tbeploads/reference/facilities.md)
  table convention; `NA` for shared-allocation groups (see below)

- `bay_seg`: Integer bay segment identifier (2 = Hillsborough Bay, 4 =
  Lower Tampa Bay)

- `alloc_tons`: Allocation in tons TN per year

- `ishared`: Logical; `TRUE` when the allocation is shared across
  multiple facilities. When `TRUE`, the combined load from all
  facilities belonging to the same entity and bay segment is compared to
  the single `alloc_tons` value.

The three Mosaic material loss facilities (Big Bend, Riverview, Tampa
Marine) share a single 3.30 ton/year allocation in Hillsborough Bay;
they are represented by one row (`ishared = TRUE`, `facname = NA`).
Kinder Morgan Port Sutton and Tampaplex are likewise assessed jointly
against the sum of their two individual allocations and represented by
one row (`ishared = TRUE`, `facname = NA`); Kinder Morgan Port Manatee
is a separate, non-shared facility. All other entries are non-shared
(`ishared = FALSE`) with one row per facility.

## Examples

``` r
ml_allocations
#> # A tibble: 5 × 5
#>   entity        facname                    bay_seg alloc_tons ishared
#>   <chr>         <chr>                        <int>      <dbl> <lgl>  
#> 1 CSX           Rockport                         2      5.63  FALSE  
#> 2 CSX           Newport                          2      5.63  FALSE  
#> 3 Kinder Morgan Kinder Morgan Port Manatee       4      0.299 FALSE  
#> 4 Mosaic        NA                               2      3.3   TRUE   
#> 5 Kinder Morgan NA                               2      5.18  TRUE   
```
