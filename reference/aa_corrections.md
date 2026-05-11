# Allocation assessment TN load corrections by bay segment and entity

Allocation assessment TN load corrections by bay segment and entity

## Usage

``` r
aa_corrections
```

## Format

A `data.frame` with 43 rows and 4 columns:

- bay_seg:

  Integer bay segment identifier

- entity:

  MS4 jurisdiction or entity name

- ad_tons:

  Atmospheric deposition TN offset (tons/yr)

- project_tons:

  Net permitted project TN offset (tons/yr); negative values indicate a
  load credit

## Details

TN load offsets applied before hydrologic normalization in
[`anlz_aa`](https://tbep-tech.github.io/tbeploads/reference/anlz_aa.md)
for the 2022-2024 TBNMC assessment period. Values are sourced from the
SAS script `7_Basin_assessment2224.sas` and cover two correction types:
atmospheric deposition (AD) loads apportioned to each entity
jurisdiction, and net permitted project (AP) load credits. FDACS
agriculture entries (`entity = "All"`) carry irrigation AP reductions
only (`ad_tons = 0`). Negative `project_tons` values reflect project
credits that increase the allowable load.

See `data-raw/aa_corrections.R` for construction.

## Examples

``` r
aa_corrections
#> # A tibble: 42 × 4
#>    bay_seg entity        ad_tons project_tons
#>      <int> <chr>           <dbl>        <dbl>
#>  1       1 CLEARWATER       1.36         6.15
#>  2       1 HILLSBOROUGH     8.8          0   
#>  3       1 LARGO            0.51         0.03
#>  4       1 MacDill AFB      0.03         0   
#>  5       1 OLDSMAR          0.5          0   
#>  6       1 PINELLAS         5.34         1.65
#>  7       1 PINELLAS PARK    0.41         0   
#>  8       1 SAFETY HARBOR    0.5          0.88
#>  9       1 ST PETERSBURG    0.45         0   
#> 10       1 Tampa            1.96         0.11
#> # ℹ 32 more rows
```
