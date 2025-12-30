# Helper function for union operation

Helper function for union operation

## Usage

``` r
util_nps_unionnochunk(sf1, sf2)
```

## Arguments

- sf1:

  First sf object

- sf2:

  Second sf object

## Value

An sf object containing the spatial intersection of sf1 and sf2, with
geometries unioned by unique combinations of all attributes from both
input objects.

## Details

Used internally by
[`util_nps_union`](https://tbep-tech.github.io/tbeploads/reference/util_nps_union.md).
See the help file for more details.

## Examples

``` r
if (FALSE) { # \dontrun{
data(tbjuris)
data(tbsubshed)
result <- util_nps_unionnochunk(tbsubshed, tbjuris)
} # }
```
