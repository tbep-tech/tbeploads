# Get point source entity information from file name

Get point source entity information from file name

## Usage

``` r
util_ps_facinfo(pth, asdf = FALSE)
```

## Arguments

- pth:

  path to raw entity data

- asdf:

  logical, if `TRUE` return as `data.frame`

## Value

A list or `data.frame` (if `asdf = TRUE`) with entity, facility, permit,
facility id, coastal id, and coastal subbasin code

## Details

Bay segment is an integer with values of 1, 2, 3, 4, 5, 6, 7, and 55 for
Old Tampa Bay, Hillsborough Bay, Middle Tampa Bay, Lower Tampa Bay, Boca
Ciega Bay, Terra Ceia Bay, Manatee River, and Boca Ciega Bay South,
respectively.

## Examples

``` r
pth <- system.file('extdata/ps_dom_hillsco_falkenburg_2019.txt', package = 'tbeploads')
util_ps_facinfo(pth)
#> $entity
#> [1] "Hillsborough Co."
#> 
#> $facname
#> [1] "Falkenburg AWTP"
#> 
#> $permit
#> [1] "FL0040614"
#> 
#> $facid
#> [1] "59"
#> 
#> $coastco
#> [1] "381"
#> 
#> $coastid
#> [1] "D_HC_3P"
#> 
```
