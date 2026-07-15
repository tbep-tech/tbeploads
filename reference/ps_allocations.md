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

- `group_id`: Character identifier for the shared group a permit belongs
  to (`NA` when `ishared` is `FALSE`). Provided so shared-group
  membership can be recovered directly rather than inferred from
  matching `entity` + `alloc_tons`

The 19 Mosaic facilities in Hillsborough Bay (Bartow, Bonnie, Ft.
Lonesome, Green Bay, Hookers Prairie, Mulberry Phosphogypsum Stack,
Mulberry Plant, New Wales Chemical Plant, Nichols Mine, Plant City,
Riverview, Riverview Stack Closure, South Pierce, Tampa Ammonia
Terminal, Tampa Marine Terminal, Hopewell, Kingsford, Port Sutton, Black
Point) share a single 124.1 ton/year allocation (`ishared = TRUE`,
`group_id = "ips_mosaic_hb"`). Kinder Morgan Tampaplex, Port Sutton, and
Hartford Terminal likewise share a single 25.0 ton/year allocation
(`group_id = "ips_kinder_morgan"`). All other permits are non-shared
(`ishared = FALSE`, `group_id = NA`).

## Examples

``` r
ps_allocations
#> # A tibble: 39 × 8
#>    entity facname    permit alloc_pct alloc_tons hydro_affected ishared group_id
#>    <chr>  <chr>      <chr>      <dbl>      <dbl> <lgl>          <lgl>   <chr>   
#>  1 CSX    CSX - Roc… FL016…    0.0072         6  FALSE          FALSE   NA      
#>  2 Mosaic Point Sou… FL000…    0.0145       124. TRUE           TRUE    ips_mos…
#>  3 Mosaic Point Sou… FL000…    0.0009       124. TRUE           TRUE    ips_mos…
#>  4 Mosaic Point Sou… FL018…    0.0002       124. TRUE           TRUE    ips_mos…
#>  5 Mosaic Point Sou… FL016…    0.0006       124. TRUE           TRUE    ips_mos…
#>  6 Mosaic Point Sou… FL000…    0.001        124. TRUE           TRUE    ips_mos…
#>  7 Mosaic Point Sou… FL003…    0.0025       124. TRUE           TRUE    ips_mos…
#>  8 Mosaic Point Sou… FL000…    0.0064       124. TRUE           TRUE    ips_mos…
#>  9 Mosaic Point Sou… FL003…    0.0052       124. TRUE           TRUE    ips_mos…
#> 10 Mosaic Point Sou… FL003…    0.0025       124. TRUE           TRUE    ips_mos…
#> # ℹ 29 more rows
```
