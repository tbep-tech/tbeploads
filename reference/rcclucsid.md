# Lookup table for CLUCSID runoff coefficients

Lookup table for CLUCSID runoff coefficients

## Usage

``` r
rcclucsid
```

## Format

A data frame

## Details

Used to create the land use runoff coefficient data used in
[`util_nps_landsoilrc`](https://tbep-tech.github.io/tbeploads/reference/util_nps_landsoilrc.md).

- `clucsid`: Numeric value for CLUCSID

- `hsg`: Numeric value for the hydrologic soil group

- `dry_rc`: Numeric value for dry weather runoff coefficient

- `wet_rc`: Numeric value for wet weather runoff coefficient

## Examples

``` r
if (FALSE) { # \dontrun{
rcclucsid <- read.csv('data-raw/rc_clucsid.csv', stringsAsFactors = F, header = T)

save(rcclucsid, file = 'data/rcclucsid.RData', compress = 'xz')
} # }
rcclucsid
#>    clucsid hsg dry_rc wet_rc
#> 1        1   A   0.15   0.25
#> 2        1   B   0.18   0.28
#> 3        1   C   0.21   0.31
#> 4        1   D   0.24   0.34
#> 5        2   A   0.25   0.35
#> 6        2   B   0.30   0.40
#> 7        2   C   0.35   0.45
#> 8        2   D   0.40   0.50
#> 9        3   A   0.35   0.50
#> 10       3   B   0.42   0.57
#> 11       3   C   0.50   0.65
#> 12       3   D   0.58   0.75
#> 13       4   A   0.70   0.79
#> 14       4   B   0.74   0.83
#> 15       4   C   0.78   0.97
#> 16       4   D   0.82   0.91
#> 17       5   A   0.65   0.75
#> 18       5   B   0.70   0.80
#> 19       5   C   0.75   0.85
#> 20       5   D   0.80   0.90
#> 21       6   A   0.20   0.20
#> 22       6   B   0.30   0.30
#> 23       6   C   0.40   0.40
#> 24       6   D   0.50   0.50
#> 25       7   A   0.40   0.50
#> 26       7   B   0.45   0.55
#> 27       7   C   0.50   0.60
#> 28       7   D   0.55   0.65
#> 29       8   A   0.10   0.18
#> 30       8   B   0.14   0.22
#> 31       8   C   0.18   0.26
#> 32       8   D   0.22   0.30
#> 33       9   A   0.45   0.55
#> 34       9   B   0.50   0.60
#> 35       9   C   0.55   0.65
#> 36       9   D   0.60   0.70
#> 37      10   A   0.10   0.18
#> 38      10   B   0.14   0.22
#> 39      10   C   0.18   0.26
#> 40      10   D   0.22   0.30
#> 41      11   A   0.20   0.26
#> 42      11   B   0.23   0.29
#> 43      11   C   0.26   0.32
#> 44      11   D   0.29   0.33
#> 45      12   A   0.35   0.45
#> 46      12   B   0.40   0.50
#> 47      12   C   0.45   0.55
#> 48      12   D   0.50   0.60
#> 49      13   A   0.20   0.30
#> 50      13   B   0.25   0.35
#> 51      13   C   0.30   0.40
#> 52      13   D   0.35   0.45
#> 53      14   A   0.20   0.30
#> 54      14   B   0.25   0.35
#> 55      14   C   0.30   0.40
#> 56      14   D   0.35   0.45
#> 57      15   A   0.10   0.15
#> 58      15   B   0.13   0.18
#> 59      15   C   0.16   0.21
#> 60      15   D   0.19   0.24
#> 61      16   A   0.80   0.90
#> 62      16   B   0.80   0.90
#> 63      16   C   0.80   0.90
#> 64      16   D   0.80   0.90
#> 65      17   A   0.00   0.00
#> 66      17   B   0.00   0.00
#> 67      17   C   0.00   0.00
#> 68      17   D   0.00   0.00
#> 69      18   A   0.50   0.60
#> 70      18   B   0.55   0.65
#> 71      18   C   0.60   0.70
#> 72      18   D   0.65   0.75
#> 73      19   A   0.95   0.95
#> 74      19   B   0.95   0.95
#> 75      19   C   0.95   0.95
#> 76      19   D   0.95   0.95
#> 77      20   A   0.45   0.55
#> 78      20   B   0.50   0.60
#> 79      20   C   0.55   0.65
#> 80      20   D   0.60   0.70
#> 81      21   A   0.00   0.00
#> 82      21   B   0.00   0.00
#> 83      21   C   0.00   0.00
#> 84      21   D   0.00   0.00
#> 85      22   A   0.00   0.00
#> 86      22   B   0.00   0.00
#> 87      22   C   0.00   0.00
#> 88      22   D   0.00   0.00
```
