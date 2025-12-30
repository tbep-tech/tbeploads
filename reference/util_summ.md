# Summarize load estimates

Summarize load estimates

## Usage

``` r
util_summ(
  dat,
  summ = c("entity", "facility", "basin", "segment", "all"),
  summtime = c("month", "year")
)
```

## Arguments

- dat:

  Pre-processed data frame of load estimates, see examples

- summ:

  chr string indicating how the returned data are summarized, see
  details

- summtime:

  chr string indicating how the returned data are summarized temporally
  (month or year), see details

## Value

Data frame with summarized loading data based on user-supplied arguments

## Details

The data are summarized differently based on the `summ` and `summtime`
arguments. All loading data are summed based on these arguments, e.g.,
by bay segment (`summ = 'segment'`) and year (`summtime = 'year'`).

## Examples

``` r
fls <- list.files(system.file('extdata/', package = 'tbeploads'),
  pattern = 'ps_ind_', full.names = TRUE)

ipsbyfac <- anlz_ips_facility(fls)

# add bay segment and source
# there should only be loads to Hillsborough, Middle, and Lower Tampa Bay
ipsld <- ipsbyfac  |>
  dplyr::arrange(coastco) |>
  dplyr::left_join(dbasing, by = "coastco") |>
  dplyr::mutate(
    segment = dplyr::case_when(
      bayseg == 1 ~ "Old Tampa Bay",
      bayseg == 2 ~ "Hillsborough Bay",
      bayseg == 3 ~ "Middle Tampa Bay",
      bayseg == 4 ~ "Lower Tampa Bay",
      TRUE ~ NA_character_
    ),
    source = 'IPS'
  ) |>
  dplyr::select(-basin, -hectare, -coastco, -name, -bayseg)

util_summ(ipsld, summ = 'entity', summtime = 'year')
#> # A tibble: 5 × 9
#>    Year source entity         segment  tn_load tp_load tss_load bod_load hy_load
#>   <int> <chr>  <chr>          <chr>      <dbl>   <dbl>    <dbl>    <dbl>   <dbl>
#> 1  2020 IPS    Busch Gardens  Hillsbo…  0.437   0.0858   6.11       11.7  1.11  
#> 2  2021 IPS    Coronet        Hillsbo…  0.0305  0.0515   0.0662      0    0.0184
#> 3  2017 IPS    Lowry Park Zoo Hillsbo…  0.215   0.0612   0           0    0.188 
#> 4  2018 IPS    Lowry Park Zoo Hillsbo…  0.168   0.0456   0           0    0.140 
#> 5  2019 IPS    Lowry Park Zoo Hillsbo…  0.0950  0.0226   0           0    0.0763
```
