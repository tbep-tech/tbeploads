# Fast Spatial Intersection and Union Using GDAL

Performs a spatial intersection and union of two sf objects using GDAL's
optimized spatial operations. This function is significantly faster than
native sf operations for large datasets.

## Usage

``` r
util_nps_union(
  sf1,
  sf2,
  gdal_path = NULL,
  chunk_size = NULL,
  cast = FALSE,
  verbose = TRUE
)
```

## Arguments

- sf1:

  An sf object containing polygons. All non-geometry columns will be
  preserved in the output

- sf2:

  An sf object containing polygons. All non-geometry columns will be
  preserved in the output

- gdal_path:

  Character string specifying the path to GDAL binaries (e.g.,
  "C:/OSGeo4W/bin"). If NULL (default), assumes GDAL is in system PATH

- chunk_size:

  Integer. For large datasets, process in chunks of this many features
  from sf1. Set to NULL (default) to process all at once

- cast:

  Logical. If TRUE, will cast multipolygon geometries to polygons before
  processing. Default is FALSE, which keeps multipolygons as is (usually
  faster).

- verbose:

  Logical. If TRUE, will print progress messages. Default is TRUE.

## Value

An sf object containing the spatial intersection of sf1 and sf2, with
geometries unioned by unique combinations of all attributes from both
input objects

This function uses GDAL's ogr2ogr utility to perform spatial
intersection operations, which can be much faster than sf's native
functions for large datasets. The process:

1.  Exports both sf objects to temporary GeoPackage files

2.  Combines them into a single file

3.  Dynamically builds SQL query based on actual column names

4.  Uses SQL with spatial functions to find intersections

5.  Groups and unions results by all attribute combinations

For very large datasets that cause memory issues, the function can
process data in chunks.

The function automatically detects all non-geometry columns from both
input objects and includes them in the intersection operation.

## Note

Requires GDAL/OGR to be installed and accessible. On Windows, this is
typically provided by OSGeo4W or QGIS installations, downloadable at
<https://trac.osgeo.org/osgeo4w/>.

## Examples

``` r
if (FALSE) { # \dontrun{
data(tbsubshed)
data(tbjuris)
result <- util_nps_union(
  sf1 = tbsubshed,
  sf2 = tbjuris,
  "C:/OSGeo4W/bin"
  )
} # }
```
