# Simple features polygons of FNAI Florida Conservation Lands clipped to the Tampa Bay watershed

Simple features polygons of FNAI Florida Conservation Lands clipped to
the Tampa Bay watershed

## Usage

``` r
flma
```

## Format

A [`sf`](https://r-spatial.github.io/sf/reference/sf.html) object

## Details

Used to identify conservation lands for the non-point source (NPS) load
allocation assessment. When passed as the `tbconserv` argument to
[`util_nps_tbbase`](https://tbep-tech.github.io/tbeploads/reference/util_nps_tbbase.md),
conservation areas receive a `conservation = TRUE` flag in the output
[`tbbase`](https://tbep-tech.github.io/tbeploads/reference/tbbase.md)
dataset, which routes their load to the aggregate `"Conserv"` entity in
[`anlz_aa`](https://tbep-tech.github.io/tbeploads/reference/anlz_aa.md).

Source: Florida Natural Areas Inventory (FNAI) Florida Managed Areas
(FLMA) / Florida Conservation Lands database. Downloaded via
[`util_nps_getflma`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getflma.md)
and clipped to
[`tbfullshed`](https://tbep-tech.github.io/tbeploads/reference/tbfullshed.md).

Projection is NAD83(2011) / Florida West (ftUS), CRS 6443.

## Examples

``` r
if (FALSE) { # \dontrun{
url <- "https://www.fnai.org/shapefiles/flma_202503.zip"

flma <- util_nps_getflma(url = url)

save(flma, file = "data/flma.RData", compress = "xz")
} # }
```
