# Allocation assessment TN load corrections by bay segment and entity

Allocation assessment TN load corrections by bay segment and entity

## Usage

``` r
aa_corrections
```

## Format

A `data.frame`

## Details

TN load offsets applied before hydrologic normalization in
[`anlz_aa`](https://tbep-tech.github.io/tbeploads/reference/anlz_aa.md).
Two correction types are combined per entity: AD (atmospheric
deposition) load estimates from
[`anlz_ad`](https://tbep-tech.github.io/tbeploads/reference/anlz_ad.md),
and permitted project load credits. The current object is a zero-row
placeholder; it should be replaced with actual values when available.

- `bay_seg`: Integer bay segment identifier

- `entity`: MS4 jurisdiction or entity name

- `ad_tons`: Atmospheric deposition TN offset (tons/yr)

- `project_tons`: Permitted project TN offset (tons/yr)

See "data-raw/aa_corrections.R" for creation.

## Examples

``` r
aa_corrections
#> # A tibble: 0 × 4
#> # ℹ 4 variables: bay_seg <int>, entity <chr>, ad_tons <dbl>, project_tons <dbl>
```
