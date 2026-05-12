# Download and clip an FNAI FLMA zipped GDB to the Tampa Bay watershed

Downloads a zipped File Geodatabase from the FNAI website (or any
compatible URL), extracts it, reads the first layer, reprojects, fixes
geometries, and clips to the study area boundary. The downloaded zip is
deleted on function exit.

## Usage

``` r
util_nps_getflma(url, clp = tbfullshed, crs = 6443L, verbose = TRUE)
```

## Arguments

- url:

  Character. Direct URL to the FNAI zip file.

- clp:

  An `sf` polygon used to clip the output. Defaults to the Tampa Bay
  watershed
  ([`tbfullshed`](https://tbep-tech.github.io/tbeploads/reference/tbfullshed.md)).

- crs:

  Integer EPSG code for the output CRS. Default `6443L`.

- verbose:

  Logical. Print progress messages. Default `TRUE`.

## Value

An `sf` object clipped to `clp` in `crs`.

## Details

The zip archive may contain either a File Geodatabase (`.gdb`) or a
shapefile (`.shp`). A GDB is preferred; if none is found the first
shapefile in the archive is used. When a GDB is present,
`sf::gdal_utils("vectortranslate")` converts it to a temporary
GeoPackage before reading to avoid GDAL driver limitations with curved
geometries.

## Examples

``` r
if (FALSE) { # \dontrun{
flma <- util_nps_getflma(
  url = "https://www.fnai.org/shapefiles/flma_202503.zip"
)
} # }
```
