# Create a data frame of formatting issues with point source input files

Create a data frame of formatting issues with point source input files

## Usage

``` r
util_ps_checkfls(fls)
```

## Arguments

- fls:

  vector of file paths to raw facility data, one to many

## Value

A `data.frame` with three columns indicating `name` for the file name,
`chk` for the file issue, and `nms` for a concatenated string of column
names for the file

## Details

The `chk` column indicates the issue with the file and will indicate
`"ok"` if no issues are found, `"read error"` if the file cannot be
read, and `"check columns"` if the column names are not as expected. Any
file not showing `"ok"` should be checked for issues.

All files are checked with
[`util_ps_checkuni`](https://tbep-tech.github.io/tbeploads/reference/util_ps_checkuni.md)
if a file does not have a read error.

The function cannot be used with files for material losses.

## Examples

``` r
fls <- system.file('extdata/ps_dom_hillsco_falkenburg_2019.txt', package = 'tbeploads')
util_ps_checkfls(fls)
#> # A tibble: 1 × 3
#>   name                               chk   nms                                  
#>   <chr>                              <chr> <chr>                                
#> 1 ps_dom_hillsco_falkenburg_2019.txt ok    Permit.Number, Facility.Name, Outfal…
```
