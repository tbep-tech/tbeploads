# TBNMC TN load allocations for IPS point source facilities

TBNMC TN load allocations for IPS point source facilities

## Usage

``` r
ps_allocations
```

## Format

A `data.frame`

## Details

TN load allocations assigned to individual industrial point source
facilities under the Tampa Bay Nitrogen Management Consortium (TBNMC)
framework.

- `entity`: Entity name (owner/operator)

- `facname`: Facility name as used in
  [`facilities`](https://tbep-tech.github.io/tbeploads/reference/facilities.md)

- `permit`: NPDES permit number

- `alloc_pct`: Fractional allocation share (0-1)

- `alloc_tons`: Allocation in tons TN per year. For `ishared` permits,
  this is the group's collective allocation (the same value repeated on
  every member row), not an individual permit allocation

- `hydro_affected`: Logical; `TRUE` for permits whose IPS load
  [`anlz_aa`](https://tbep-tech.github.io/tbeploads/reference/anlz_aa.md)
  hydrologically normalizes

- `ishared`: Logical; `TRUE` when the permit is jointly assessed against
  a collective allocation shared with other permits (see `alloc_tons`)

The 19 Mosaic facilities in Hillsborough Bay (Bartow, Bonnie, Ft.
Lonesome, Green Bay, Hookers Prairie, Mulberry Phosphogypsum Stack,
Mulberry Plant, New Wales Chemical Plant, Nichols Mine, Plant City,
Riverview, Riverview Stack Closure, South Pierce, Tampa Ammonia
Terminal, Tampa Marine Terminal, Hopewell, Kingsford, Port Sutton, Black
Point) share a single 124.1 ton/year allocation (`ishared = TRUE`).
Kinder Morgan Tampaplex, Port Sutton, and Hartford Terminal likewise
share a single 25.0 ton/year allocation. All other permits are
non-shared (`ishared = FALSE`).

## Examples

``` r
ps_allocations
#> # A tibble: 39 × 7
#>    entity facname             permit alloc_pct alloc_tons hydro_affected ishared
#>    <chr>  <chr>               <chr>      <dbl>      <dbl> <lgl>          <lgl>  
#>  1 CSX    CSX - Rockport New… FL016…    0.0072         6  FALSE          FALSE  
#>  2 Mosaic Point Source - Bon… FL000…    0.0145       124. TRUE           TRUE   
#>  3 Mosaic Point Source - Pla… FL000…    0.0009       124. TRUE           TRUE   
#>  4 Mosaic Point Source - Tam… FL018…    0.0002       124. TRUE           TRUE   
#>  5 Mosaic Point Source - Tam… FL016…    0.0006       124. TRUE           TRUE   
#>  6 Mosaic Point Source - Bar… FL000…    0.001        124. TRUE           TRUE   
#>  7 Mosaic Point Source - Ft.… FL003…    0.0025       124. TRUE           TRUE   
#>  8 Mosaic Point Source - Gre… FL000…    0.0064       124. TRUE           TRUE   
#>  9 Mosaic Point Source - Hoo… FL003…    0.0052       124. TRUE           TRUE   
#> 10 Mosaic Point Source - Hop… FL003…    0.0025       124. TRUE           TRUE   
#> # ℹ 29 more rows
```
