# NPS disaggregation factors for allocation assessment

NPS disaggregation factors for allocation assessment

## Usage

``` r
nps_factors
```

## Format

A named `list` with two elements: `rc` and `tn`

## Details

Pre-computed disaggregation factors used by `anlz_aa` to allocate
basin-level NPS TN loads to individual MS4 jurisdictions. Created by
[`util_aa_npsfactors`](https://tbep-tech.github.io/tbeploads/reference/util_aa_npsfactors.md)
from
[`tbbase`](https://tbep-tech.github.io/tbeploads/reference/tbbase.md),
[`rcclucsid`](https://tbep-tech.github.io/tbeploads/reference/rcclucsid.md),
and [`emc`](https://tbep-tech.github.io/tbeploads/reference/emc.md).
[`tbbase`](https://tbep-tech.github.io/tbeploads/reference/tbbase.md) is
tied to specific land use and soils data and must be rebuilt whenever
update are available.

`rc`: Data frame of runoff coefficient factors

- `bay_seg`: Integer bay segment identifier

- `basin`: Drainage basin identifier

- `entity`: MS4 jurisdiction or entity name

- `category`: Allocation category (Agriculture, Other, or NA for urban
  MS4)

- `clucsid`: Land use class identifier

- `factor_rc`: Entity's fractional share of area x runoff coefficient
  within each basin x CLUCSID; sums to 1 across entities per basin x
  CLUCSID

`tn`: Data frame of TN concentration factors

- `bay_seg`: Integer bay segment identifier

- `basin`: Drainage basin identifier

- `clucsid`: Land use class identifier

- `factor_tn`: CLUCSID's fractional share of basin TN load weighted by
  area x event mean TN concentration; sums to 1 across CLUCSIDs per
  basin

See "data-raw/nps_factors.R" and
[`util_aa_npsfactors`](https://tbep-tech.github.io/tbeploads/reference/util_aa_npsfactors.md)
for creation.

## Examples

``` r
nps_factors
#> $rc
#> # A tibble: 1,937 × 6
#>    bay_seg basin    entity       category    clucsid factor_rc
#>      <int> <chr>    <chr>        <chr>         <dbl>     <dbl>
#>  1       1 02304500 HILLSBOROUGH Agriculture       8     1.000
#>  2       1 02304500 HILLSBOROUGH Other             9     1    
#>  3       1 02304500 HILLSBOROUGH Other            15     1    
#>  4       1 02304500 HILLSBOROUGH Other            16     0.984
#>  5       1 02304500 HILLSBOROUGH Other            20     1    
#>  6       1 02304500 HILLSBOROUGH NA                1     1    
#>  7       1 02304500 HILLSBOROUGH NA                2     0.988
#>  8       1 02304500 HILLSBOROUGH NA                3     1    
#>  9       1 02304500 HILLSBOROUGH NA                4     0.988
#> 10       1 02304500 HILLSBOROUGH NA                7     0.997
#> # ℹ 1,927 more rows
#> 
#> $tn
#> # A tibble: 693 × 4
#>    bay_seg basin    clucsid factor_tn
#>      <int> <chr>      <dbl>     <dbl>
#>  1       1 02304500       1   0.0669 
#>  2       1 02304500       2   0.486  
#>  3       1 02304500       3   0.197  
#>  4       1 02304500       4   0.104  
#>  5       1 02304500       5   0.00300
#>  6       1 02304500       7   0.0376 
#>  7       1 02304500       8   0.0554 
#>  8       1 02304500       9   0.0151 
#>  9       1 02304500      15   0.0163 
#> 10       1 02304500      16   0      
#> # ℹ 683 more rows
#> 
```
