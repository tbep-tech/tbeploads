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

- `alloc_tons`: Allocation in tons TN per year

## Examples

``` r
ps_allocations
#> # A tibble: 30 × 5
#>    entity facname                                    permit alloc_pct alloc_tons
#>    <chr>  <chr>                                      <chr>      <dbl>      <dbl>
#>  1 CSX    Rockport  (fka Eastern Terminals)          FL016…    0.0072        7.5
#>  2 Mosaic Point Source - Bonnie (fka CF Bartow)      FL000…    0.0145       15.1
#>  3 Mosaic Point Source - Plant City (fka CF)         FL000…    0.0009        0.9
#>  4 Mosaic Point Source - Tampa Ammonia Terminal (fk… FL018…    0.0002        0.2
#>  5 Mosaic Point Source - Tampa Marine (fka CF Phosp… FL016…    0.0006        0.6
#>  6 Mosaic Point Source - Bartow                      FL000…    0.001         1.1
#>  7 Mosaic Point Source - Ft. Lonesome                FL003…    0.0025        2.6
#>  8 Mosaic Point Source - Green Bay                   FL000…    0.0064        6.6
#>  9 Mosaic Point Source - Hookers Prairie             FL003…    0.0052        5.5
#> 10 Mosaic Point Source - Hopewell                    FL003…    0.0025        2.6
#> # ℹ 20 more rows
```
