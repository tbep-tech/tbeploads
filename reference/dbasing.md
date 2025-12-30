# Basin information for coastal subbasin codes

Basin information for coastal subbasin codes

## Usage

``` r
dbasing
```

## Format

A `data.frame`

## Details

Used for domestic point source summaries, bay segments are as follows:

- 1: Old Tampa Bay

- 2: Hillsborough Bay

- 3: Middle Tampa Bay

- 4: Lower Tampa Bay

- 5: Upper Boca Ciega Bay

- 6: Terra Ceia Bay

- 7: Manatee River

- 55: Lower Boca Ciega Bay

See "data-raw/dbasing.R" for creation.

## Examples

``` r
dbasing
#> # A tibble: 435 × 6
#>    coastco gagetype basin    bayseg name          hectare
#>    <chr>   <chr>    <chr>     <dbl> <chr>           <dbl>
#>  1 697     Gaged    02299950      7 Manatee River    353.
#>  2 700a    Gaged    02299950      7 Manatee River   4647.
#>  3 707     Gaged    02299950      7 Manatee River   5642.
#>  4 724     Gaged    02299950      7 Manatee River    518 
#>  5 725     Gaged    02299950      7 Manatee River    289.
#>  6 727     Gaged    02299950      7 Manatee River    586.
#>  7 728     Gaged    02299950      7 Manatee River   2257.
#>  8 742     Gaged    02299950      7 Manatee River    936.
#>  9 747     Gaged    02299950      7 Manatee River    794.
#> 10 755     Gaged    02299950      7 Manatee River    914.
#> # ℹ 425 more rows
```
