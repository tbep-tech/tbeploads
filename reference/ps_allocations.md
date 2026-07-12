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

- `hydro_affected`: Logical; `TRUE` for permits whose IPS load
  [`anlz_aa`](https://tbep-tech.github.io/tbeploads/reference/anlz_aa.md)
  hydrologically normalizes

## Examples

``` r
ps_allocations
#> # A tibble: 36 × 6
#>    entity facname                     permit alloc_pct alloc_tons hydro_affected
#>    <chr>  <chr>                       <chr>      <dbl>      <dbl> <lgl>         
#>  1 CSX    CSX - Rockport Newport      FL016…    0.0072        7.5 FALSE         
#>  2 Mosaic Point Source - Bonnie (fka… FL000…    0.0145       15.1 TRUE          
#>  3 Mosaic Point Source - Plant City … FL000…    0.0009        0.9 TRUE          
#>  4 Mosaic Point Source - Tampa Ammon… FL018…    0.0002        0.2 TRUE          
#>  5 Mosaic Point Source - Tampa Marin… FL016…    0.0006        0.6 TRUE          
#>  6 Mosaic Point Source - Bartow       FL000…    0.001         1.1 TRUE          
#>  7 Mosaic Point Source - Ft. Lonesome FL003…    0.0025        2.6 TRUE          
#>  8 Mosaic Point Source - Green Bay    FL000…    0.0064        6.6 TRUE          
#>  9 Mosaic Point Source - Hookers Pra… FL003…    0.0052        5.5 TRUE          
#> 10 Mosaic Point Source - Hopewell     FL003…    0.0025        2.6 TRUE          
#> # ℹ 26 more rows
```
