# Prep Verna Wellfield data for use in AD and NPS calculations

Prep Verna Wellfield data for use in AD and NPS calculations

## Usage

``` r
util_prepverna(fl, typ, fillmis = T)
```

## Arguments

- fl:

  text string for the file path to the Verna Wellfield data

- typ:

  character string for the type of data to prepare, either 'AD' for
  atmospheric deposition or 'NPS' for nonpoint source. Uses different TP
  calculation for each type.

- fillmis:

  logical indicating whether to fill missing data with monthly means,
  see details

## Value

A data frame with total nitrogen and phosphorus estimates as mg/l for
each year and month of the input data

## Details

Raw data can be obtained from
<https://nadp.slh.wisc.edu/sites/ntn-FL41/> as monthly observations.
Total nitrogen and phosphorus concentrations are estimated from ammonium
and nitrate concentrations (mg/L) using the following relationships:

\$\$TN = NH_4^+ \* 0.78 + NO_3^- \* 0.23\$\$ \$\$TP = 0.01262 \* TN +
0.00110\$\$

The first equation corrects for the % of ions in ammonium and nitrate
that is N, and the second is a regression relationship between TBADS TN
and TP, applied to Verna.

Missing data (-9 values) can be filled using monthly means from the
previous five years where data exist for that month. If there are less
than five previous years of data for that month, the missing value is
not filled.

Years with incomplete seasonal data will be filled with NA values if
`fillmis = FALSE` or filled with monthly means if `fillmis = TRUE`.

## Examples

``` r
fl <- system.file('extdata/verna-raw.csv', package = 'tbeploads')
util_prepverna(fl)
#> Error in util_prepverna(fl): argument "typ" is missing, with no default
```
