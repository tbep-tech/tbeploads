# Simple feature polygons of soil data in the Tampa Bay Estuary Program boundary

Simple feature polygons of soil data in the Tampa Bay Estuary Program
boundary

## Usage

``` r
tbsoil
```

## Format

A [`sf`](https://r-spatial.github.io/sf/reference/sf.html) object

## Details

Used for estimating ungaged non-point source (NPS) loads. The data
includes the following columns.

- `FLUCCSCODE`: Numeric value for the Florida Land Use, Cover and Forms
  Classification System (FLUCCS) code

- `FLUCCSDESC`: Character describing the FLUCCS description

- `geometry`: The geometry column

Projection is NAD83(2011) / Florida West (ftUS), CRS 6443.

## Examples

``` r
if (FALSE) { # \dontrun{
# use SWFWMD API
tbsoil <- util_nps_getswfwmd('soil')

save(tbsoil, file = 'data/tbsoil.RData', compress = 'xz')
} # }
```
