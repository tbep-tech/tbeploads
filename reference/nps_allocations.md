# TBNMC TN load allocations for NPS/MS4 entities

TBNMC TN load allocations for NPS/MS4 entities

## Usage

``` r
nps_allocations
```

## Format

A `data.frame`

## Details

TN load allocations assigned to non-point source and MS4 jurisdictions
under the Tampa Bay Nitrogen Management Consortium (TBNMC) framework.

- `bay_seg`: Integer bay segment identifier (1, 2, 3, 4, 55)

- `entity`: Short entity name used for joining

- `entity_full`: Full entity name

- `type`: Allocation type (e.g., MS4, Agriculture, Other)

- `alloc_pct`: Fractional allocation share (0-1)

- `alloc_tons`: Allocation in tons TN per year

See "data-raw/nps_allocations.R" for creation.

## Examples

``` r
nps_allocations
#> # A tibble: 80 × 6
#>    bay_seg entity          entity_full            type  alloc_pct alloc_tons
#>      <int> <chr>           <chr>                  <chr>     <dbl>      <dbl>
#>  1       1 CHEVAL WEST     Cheval West            MS4      0.0018        0.7
#>  2       1 CLEARWATER      City of Clearwater     MS4      0.0271       10.6
#>  3       1 HERITAGE HARBOR Heritage Harbor        MS4      0.0015        0.6
#>  4       1 HILLSBOROUGH    Hillsborough County    MS4      0.233        91.6
#>  5       1 LARGO           City of Largo          MS4      0.014         5.5
#>  6       1 MacDill AFB     MacDill Air Force Base MS4      0.0009        0.4
#>  7       1 OLDSMAR         City of Oldsmar        MS4      0.0138        5.4
#>  8       1 PALM BAY        Palm Bay               MS4      0.0001        0  
#>  9       1 PARK PLACE      Park Place             MS4      0.001         0.4
#> 10       1 PASCO           Pasco County           MS4      0.0044        1.7
#> # ℹ 70 more rows
```
