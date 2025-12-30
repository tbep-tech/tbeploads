# Light edits to the outfall ID column for point source data

Light edits to the outfall ID column for point source data

## Usage

``` r
util_ps_fixoutfall(dat)
```

## Arguments

- dat:

  data frame from raw entity data as `data.frame`

## Value

Input data frame as is, with any edits to the outfall ID column.

## Details

The outfall ID column is edited lightly to remove any leading or
trailing white space, a hyphen is added between letters and numbers if
missing, and "Outfall" prefix is removed if presenn.

## Examples

``` r
pth <- system.file('extdata/ps_ind_busch_busch_2020.txt', package = 'tbeploads')
dat <- read.table(pth, skip = 0, sep = '\t', header = TRUE)
util_ps_fixoutfall(dat)
#>    Permit.Number Facility.Name Outfall.ID Year Month
#> 1      FL0185833            NA      D-002 2020     1
#> 2      FL0185833            NA      D-002 2020     2
#> 3      FL0185833            NA      D-002 2020     3
#> 4      FL0185833            NA      D-002 2020     4
#> 5      FL0185833            NA      D-002 2020     5
#> 6      FL0185833            NA      D-002 2020     6
#> 7      FL0185833            NA      D-002 2020     7
#> 8      FL0185833            NA      D-002 2020     8
#> 9      FL0185833            NA      D-002 2020     9
#> 10     FL0185833            NA      D-002 2020    10
#> 11     FL0185833            NA      D-002 2020    11
#> 12     FL0185833            NA      D-002 2020    12
#>    Average.Daily.Flow..ADF...mgd. BOD BOD..Unit QBOD TSS TSS.Unit QTSS
#> 1                       0.6848788 9.6        NA   NA   5       NA   NA
#> 2                       0.8995476 9.6        NA   NA   5       NA   NA
#> 3                       2.1543988 9.6        NA   NA   5       NA   NA
#> 4                       0.8332776 9.6        NA   NA   5       NA   NA
#> 5                       0.7817292 9.6        NA   NA   5       NA   NA
#> 6                       0.5670208 9.6        NA   NA   5       NA   NA
#> 7                       0.7822282 9.6        NA   NA   5       NA   NA
#> 8                       0.3074771 9.6        NA   NA   5       NA   NA
#> 9                       0.5308474 9.6        NA   NA   5       NA   NA
#> 10                      0.5141270 9.6        NA   NA   5       NA   NA
#> 11                      1.1936574 9.6        NA   NA   5       NA   NA
#> 12                      0.3504020 9.6        NA   NA   5       NA   NA
#>      Total.N Total.N.Unit Q.Total.N NO2.NO3 NO2.NO3.Unit Q.NO2.NO3    NH4
#> 1  0.2204008         mg/L   Average    0.06         mg/L   Average < 0.02
#> 2  0.2813892         mg/L   Average    0.03         mg/L   Average < 0.02
#> 3  0.3489408         mg/L   Average  < 0.01         mg/L         < < 0.02
#> 4  0.3819353         mg/L   Average  < 0.01         mg/L         < < 0.02
#> 5  0.8109884         mg/L   Average    0.01         mg/L   Average < 0.02
#> 6  0.1572375         mg/L   Average    0.03         mg/L   Average < 0.02
#> 7  0.4244999         mg/L   Average    0.02         mg/L   Average   0.02
#> 8  0.4194150         mg/L   Average    0.01         mg/L   Average < 0.02
#> 9  0.3403008         mg/L   Average    0.03         mg/L   Average   0.03
#> 10 0.2815430         mg/L   Average    0.05         mg/L   Average < 0.02
#> 11 0.2988790         mg/L   Average    0.04         mg/L   Average   0.02
#> 12 0.2351985         mg/L   Average    0.04         mg/L   Average < 0.02
#>    NH4.Unit   Q.NH4        TKN TKN.Unit   Q.TKN Organic.N Organic.N.Unit
#> 1      mg/L       < 1.30944860     mg/L Average 0.4925218           mg/L
#> 2      mg/L       < 0.89908543     mg/L Average 0.5891946           mg/L
#> 3      mg/L       < 0.29085900     mg/L Average 0.2206317           mg/L
#> 4      mg/L       < 0.09556365     mg/L Average 0.3310810           mg/L
#> 5      mg/L       < 0.96329637     mg/L Average 0.1574862           mg/L
#> 6      mg/L       < 0.61896968     mg/L Average 0.2531943           mg/L
#> 7      mg/L Average 0.26853224     mg/L Average 0.5768289           mg/L
#> 8      mg/L       < 0.18103536     mg/L Average 0.1790604           mg/L
#> 9      mg/L Average 0.34294015     mg/L Average 1.0641605           mg/L
#> 10     mg/L       < 0.18163662     mg/L Average 0.4809258           mg/L
#> 11     mg/L Average 1.38306350     mg/L Average 0.2237535           mg/L
#> 12     mg/L       < 1.72258314     mg/L Average 0.2262897           mg/L
#>    Q.Organic.N    Total.P Total.P.Unit Q.Total.P         PO4 PO4.Unit   Q.PO4
#> 1      Average 0.02850913         mg/L   Average 0.009237403     mg/L Average
#> 2      Average 0.03016478         mg/L   Average 0.010793461     mg/L Average
#> 3      Average 0.03319054         mg/L   Average 0.016642425     mg/L Average
#> 4      Average 0.24775478         mg/L   Average 0.015256113     mg/L Average
#> 5      Average 0.05084121         mg/L   Average 0.025013119     mg/L Average
#> 6      Average 0.08361766         mg/L   Average 0.028480643     mg/L Average
#> 7      Average 0.04077107         mg/L   Average 0.030187843     mg/L Average
#> 8      Average 0.05660241         mg/L   Average 0.010750899     mg/L Average
#> 9      Average 0.04621517         mg/L   Average 0.035173580     mg/L Average
#> 10     Average 0.28005210         mg/L   Average 0.010734214     mg/L Average
#> 11     Average 0.01810051         mg/L   Average 0.103772391     mg/L Average
#> 12     Average 0.06628856         mg/L   Average 0.010485249     mg/L Average
#>    Other.N..species. Other.N.Unit Q.Other.N Other.P..species. Other.P.Unit
#> 1                 NA           NA        NA                NA           NA
#> 2                 NA           NA        NA                NA           NA
#> 3                 NA           NA        NA                NA           NA
#> 4                 NA           NA        NA                NA           NA
#> 5                 NA           NA        NA                NA           NA
#> 6                 NA           NA        NA                NA           NA
#> 7                 NA           NA        NA                NA           NA
#> 8                 NA           NA        NA                NA           NA
#> 9                 NA           NA        NA                NA           NA
#> 10                NA           NA        NA                NA           NA
#> 11                NA           NA        NA                NA           NA
#> 12                NA           NA        NA                NA           NA
#>    Q.Other.P
#> 1         NA
#> 2         NA
#> 3         NA
#> 4         NA
#> 5         NA
#> 6         NA
#> 7         NA
#> 8         NA
#> 9         NA
#> 10        NA
#> 11        NA
#> 12        NA
```
