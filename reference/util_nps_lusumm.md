# Summarize non-point source (NPS) ungaged loads by land use

Summarize non-point source (NPS) ungaged loads by land use

## Usage

``` r
util_nps_lusumm(
  dat,
  summ = c("basin", "segment", "all"),
  summtime = c("month", "year")
)
```

## Arguments

- dat:

  Input data frame as an intermediate result from
  [`anlz_nps`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps.md)

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
dat <- data.frame(
  bay_seg = rep(1:2, each = 6),
  basin = rep(c("02304500", "02306647"), each = 6),
  yr = rep(2021:2022, each = 3, times = 2),
  mo = rep(1:3, times = 4),
  clucsid = rep(1:3, times = 4),
  tnload = c(150, 250, 50, 180, 300, 40, 160, 270, 45, 170, 280, 35),
  tpload = c(15, 35, 8, 18, 42, 6, 16, 38, 7, 17, 40, 5),
  tssload = c(1200, 3500, 400, 1400, 4000, 350, 1300, 3800, 380, 1350, 3900, 320),
  bodload = c(800, 1500, 200, 900, 1800, 180, 850, 1600, 190, 870, 1650, 170),
  h2oload = c(50000, 80000, 25000, 55000, 85000, 22000, 52000, 82000, 23000, 53000, 83000, 21000)
)

util_nps_lusumm(dat, summ = 'basin', summtime = 'month')
#>    Year Month source          segment    basin                         lu
#> 1  2021     3    NPS Hillsborough Bay 02304500   High Density Residential
#> 2  2022     3    NPS Hillsborough Bay 02304500   High Density Residential
#> 3  2021     1    NPS Hillsborough Bay 02304500    Low Density Residential
#> 4  2022     1    NPS Hillsborough Bay 02304500    Low Density Residential
#> 5  2021     2    NPS Hillsborough Bay 02304500 Medium Density Residential
#> 6  2022     2    NPS Hillsborough Bay 02304500 Medium Density Residential
#> 7  2021     3    NPS    Old Tampa Bay 02306647   High Density Residential
#> 8  2022     3    NPS    Old Tampa Bay 02306647   High Density Residential
#> 9  2021     1    NPS    Old Tampa Bay 02306647    Low Density Residential
#> 10 2022     1    NPS    Old Tampa Bay 02306647    Low Density Residential
#> 11 2021     2    NPS    Old Tampa Bay 02306647 Medium Density Residential
#> 12 2022     2    NPS    Old Tampa Bay 02306647 Medium Density Residential
#>       tn_load     tp_load  tss_load  bod_load hy_load
#> 1  0.05511464 0.008818342 0.4409171 0.2204586   25000
#> 2  0.04409171 0.006613757 0.3858025 0.1984127   22000
#> 3  0.16534392 0.016534392 1.3227513 0.8818342   50000
#> 4  0.19841270 0.019841270 1.5432099 0.9920635   55000
#> 5  0.27557319 0.038580247 3.8580247 1.6534392   80000
#> 6  0.33068783 0.046296296 4.4091711 1.9841270   85000
#> 7  0.04960317 0.007716049 0.4188713 0.2094356   23000
#> 8  0.03858025 0.005511464 0.3527337 0.1873898   21000
#> 9  0.17636684 0.017636684 1.4329806 0.9369489   52000
#> 10 0.18738977 0.018738977 1.4880952 0.9589947   53000
#> 11 0.29761905 0.041887125 4.1887125 1.7636684   82000
#> 12 0.30864198 0.044091711 4.2989418 1.8187831   83000
```
