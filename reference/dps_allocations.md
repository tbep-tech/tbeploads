# TBNMC TN load allocations for DPS domestic wastewater facilities

TBNMC TN load allocations for DPS domestic wastewater facilities

## Usage

``` r
dps_allocations
```

## Format

A `data.frame`

## Details

TN load allocations assigned to individual domestic point source (DPS)
facilities under the Tampa Bay Nitrogen Management Consortium (TBNMC)
framework.

- `entity`: Short entity name matching the
  [`facilities`](https://tbep-tech.github.io/tbeploads/reference/facilities.md)
  table convention (e.g., `"Clearwater"`, `"Hillsborough Co."`)

- `entity_full`: Full entity name as listed in the source allocation
  file (e.g., `"City of Clearwater"`, `"Hillsborough County"`)

- `facname`: Facility name matching the
  [`facilities`](https://tbep-tech.github.io/tbeploads/reference/facilities.md)
  table convention

- `bay_seg`: Integer bay segment identifier (1 = Old Tampa Bay, 2 =
  Hillsborough Bay, 3 = Middle Tampa Bay, 4 = Lower Tampa Bay, 55 =
  Remaining Lower Tampa Bay)

- `source`: DPS discharge type; one of `"DPS - end of pipe"` (direct
  surface water discharge) or `"DPS - reuse"` (reclaimed water reuse)

- `alloc_tons`: Allocation in tons TN per year

TECO Big Bend and Tropicana are not included: TECO is an industrial
reuse customer rather than a direct discharger, and Tropicana is
classified as an industrial point source in the
[`facilities`](https://tbep-tech.github.io/tbeploads/reference/facilities.md)
table. Neither can be matched to DPS load data from
[`anlz_dps_facility`](https://tbep-tech.github.io/tbeploads/reference/anlz_dps_facility.md).

See `"data-raw/dps_allocations.R"` for creation.

## Examples

``` r
dps_allocations
#> # A tibble: 48 × 6
#>    entity     entity_full        facname               bay_seg source alloc_tons
#>    <chr>      <chr>              <chr>                   <int> <chr>       <dbl>
#>  1 Bradenton  City of Bradenton  City of Bradenton WRF      55 DPS -…     18.6  
#>  2 Bradenton  City of Bradenton  City of Bradenton WRF      55 DPS -…      0.642
#>  3 Clearwater City of Clearwater City of Clearwater E…       1 DPS -…      9.28 
#>  4 Clearwater City of Clearwater City of Clearwater N…       1 DPS -…     16.6  
#>  5 Clearwater City of Clearwater City of Clearwater E…       1 DPS -…      0.105
#>  6 Clearwater City of Clearwater City of Clearwater N…       1 DPS -…      1.07 
#>  7 Lakeland   City of Lakeland   City of Lakeland            2 DPS -…     20    
#>  8 Lakeland   City of Lakeland   City of Lakeland            2 DPS -…      0.181
#>  9 Largo      City of Largo      City of Largo               1 DPS -…     16.4  
#> 10 Largo      City of Largo      City of Largo               1 DPS -…      2.58 
#> # ℹ 38 more rows
```
