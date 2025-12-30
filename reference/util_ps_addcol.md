# Add column names for point source data from raw entity data

Add column names for point source from raw entity data

## Usage

``` r
util_ps_addcol(dat)
```

## Arguments

- dat:

  data frame from raw entity data as `data.frame`

## Value

Input data frame from `pth` as is if column names are correct, otherwise
additional columns are added as needed.

## Details

The function checks for TN, TP, TSS, and BOD. If any of these are
missing, the columns are added with empty values including a column for
units. If BOD is missing but CBOD is present, the CBOD column is renamed
to BOD.

## Examples

``` r
pth <- system.file('extdata/ps_dom_hillsco_falkenburg_2019.txt', package = 'tbeploads')
dat <- read.table(pth, skip = 0, sep = '\t', header = TRUE)
util_ps_addcol(dat)
#>    Permit.Number         Facility.Name Outfall.ID Year Month
#> 1        FL00407 Falkenburg Road AWWTF      D-001 2019     1
#> 2        FL00407 Falkenburg Road AWWTF      D-001 2019     2
#> 3        FL00407 Falkenburg Road AWWTF      D-001 2019     3
#> 4        FL00407 Falkenburg Road AWWTF      D-001 2019     4
#> 5        FL00407 Falkenburg Road AWWTF      D-001 2019     5
#> 6        FL00407 Falkenburg Road AWWTF      D-001 2019     6
#> 7        FL00407 Falkenburg Road AWWTF      D-001 2019     7
#> 8        FL00407 Falkenburg Road AWWTF      D-001 2019     8
#> 9        FL00407 Falkenburg Road AWWTF      D-001 2019     9
#> 10       FL00407 Falkenburg Road AWWTF      D-001 2019    10
#> 11       FL00407 Falkenburg Road AWWTF      D-001 2019    11
#> 12       FL00407 Falkenburg Road AWWTF      D-001 2019    12
#> 13       FL00407 Falkenburg Road AWWTF      R-001 2019     1
#> 14       FL00407 Falkenburg Road AWWTF      R-001 2019     2
#> 15       FL00407 Falkenburg Road AWWTF      R-001 2019     3
#> 16       FL00407 Falkenburg Road AWWTF      R-001 2019     4
#> 17       FL00407 Falkenburg Road AWWTF      R-001 2019     5
#> 18       FL00407 Falkenburg Road AWWTF      R-001 2019     6
#> 19       FL00407 Falkenburg Road AWWTF      R-001 2019     7
#> 20       FL00407 Falkenburg Road AWWTF      R-001 2019     8
#> 21       FL00407 Falkenburg Road AWWTF      R-001 2019     9
#> 22       FL00407 Falkenburg Road AWWTF      R-001 2019    10
#> 23       FL00407 Falkenburg Road AWWTF      R-001 2019    11
#> 24       FL00407 Falkenburg Road AWWTF      R-001 2019    12
#>    Average.Daily.Flow..ADF...mgd.       BOD BOD..Unit QBOD       TSS TSS.Unit
#> 1                        5.296512 0.8280425      mg/l   NA 0.4167875     mg/l
#> 2                        2.696663 1.5441635      mg/l   NA 0.5553969     mg/l
#> 3                        5.689358 1.3241451      mg/l   NA 0.3740764     mg/l
#> 4                        4.749738 1.2910567      mg/l   NA 0.3821190     mg/l
#> 5                        4.396303 1.3266714      mg/l   NA 0.3274173     mg/l
#> 6                        5.838083 1.3973229      mg/l   NA 0.5313604     mg/l
#> 7                        5.194401 1.1665574      mg/l   NA 0.3039208     mg/l
#> 8                        3.346228 1.2809236      mg/l   NA 0.2890792     mg/l
#> 9                        4.748794 1.1685260      mg/l   NA 0.6515675     mg/l
#> 10                       6.461638 1.3609233      mg/l   NA 0.2632500     mg/l
#> 11                       4.240126 1.0848231      mg/l   NA 0.3768561     mg/l
#> 12                       4.010090 1.6361168      mg/l   NA 0.4708175     mg/l
#> 13                       3.698012 1.6188011      mg/l   NA 0.3704153     mg/l
#> 14                       3.180484 1.8374191      mg/l   NA 0.1775579     mg/l
#> 15                       2.761142 1.6904981      mg/l   NA 0.3195870     mg/l
#> 16                       5.189126 1.4536160      mg/l   NA 0.5491718     mg/l
#> 17                       4.454835 1.7107790      mg/l   NA 0.3321027     mg/l
#> 18                       6.892169 1.2470248      mg/l   NA 0.3735168     mg/l
#> 19                       4.239362 1.0699091      mg/l   NA 0.3679821     mg/l
#> 20                       6.473536 1.2001535      mg/l   NA 0.3191815     mg/l
#> 21                       4.167933 1.7882855      mg/l   NA 0.3823141     mg/l
#> 22                       3.516200 1.2712782      mg/l   NA 0.4136695     mg/l
#> 23                       5.407001 1.4497958      mg/l   NA 0.3610934     mg/l
#> 24                       5.236846 1.8571717      mg/l   NA 0.4747824     mg/l
#>    QTSS  Total.N Total.N.Unit Q.Total.N   NO2.NO3 NO2.NO3.Unit Q.NO2.NO3
#> 1    NA 1.756881         mg/l        NA 1.2736234         mg/l        NA
#> 2    NA 2.120932         mg/l        NA 1.0651873         mg/l        NA
#> 3    NA 2.158781         mg/l        NA 1.3470263         mg/l        NA
#> 4    NA 2.054544         mg/l        NA 1.1540464         mg/l        NA
#> 5    NA 2.105568         mg/l        NA 1.1843187         mg/l        NA
#> 6    NA 1.931209         mg/l        NA 0.9634303         mg/l        NA
#> 7    NA 2.164595         mg/l        NA 1.2040010         mg/l        NA
#> 8    NA 2.259220         mg/l        NA 1.2276714         mg/l        NA
#> 9    NA 1.974068         mg/l        NA 1.1297932         mg/l        NA
#> 10   NA 1.708387         mg/l        NA 1.0854644         mg/l        NA
#> 11   NA 1.692041         mg/l        NA 1.3363794         mg/l        NA
#> 12   NA 2.204548         mg/l        NA 1.1892235         mg/l        NA
#> 13   NA 2.310801         mg/l        NA 0.8309151         mg/l        NA
#> 14   NA 1.840923         mg/l        NA 1.4042577         mg/l        NA
#> 15   NA 2.143444         mg/l        NA 1.0829171         mg/l        NA
#> 16   NA 2.118240         mg/l        NA 0.9371350         mg/l        NA
#> 17   NA 1.455411         mg/l        NA 0.9332882         mg/l        NA
#> 18   NA 2.038263         mg/l        NA 1.2949067         mg/l        NA
#> 19   NA 1.645825         mg/l        NA 1.0476327         mg/l        NA
#> 20   NA 2.181010         mg/l        NA 0.9910153         mg/l        NA
#> 21   NA 2.063323         mg/l        NA 1.0307079         mg/l        NA
#> 22   NA 1.992785         mg/l        NA 1.0946685         mg/l        NA
#> 23   NA 2.210327         mg/l        NA 1.1364083         mg/l        NA
#> 24   NA 1.895703         mg/l        NA 1.0128204         mg/l        NA
#>           NH4 NH4.Unit Q.NH4       TKN TKN.Unit Q.TKN Organic.N Organic.N.Unit
#> 1  0.11553068     mg/l    NA 0.7742375     mg/l    NA 0.7049344           MG/L
#> 2  0.03912186     mg/l    NA 0.7869710     mg/l    NA 0.7668773           MG/L
#> 3  0.19565381     mg/l    NA 0.8098931     mg/l    NA 0.7287094           MG/L
#> 4  0.09815979     mg/l    NA 0.7747741     mg/l    NA 0.8967148           MG/L
#> 5  0.11194269     mg/l    NA 0.8167086     mg/l    NA 0.7485324           MG/L
#> 6  0.04721523     mg/l    NA 0.8931970     mg/l    NA 0.7459457           MG/L
#> 7  0.11906452     mg/l    NA 1.0307583     mg/l    NA 0.7810265           MG/L
#> 8  0.13881786     mg/l    NA 0.7775514     mg/l    NA 0.7048672           MG/L
#> 9  0.15333911     mg/l    NA 0.7508594     mg/l    NA 0.7120566           MG/L
#> 10 0.12768744     mg/l    NA 0.9278294     mg/l    NA 0.7656434           MG/L
#> 11 0.08552913     mg/l    NA 0.8660382     mg/l    NA 0.8690353           MG/L
#> 12 0.32052595     mg/l    NA 0.8456293     mg/l    NA 0.6801820           MG/L
#> 13 0.15372281     mg/l    NA 0.7408319     mg/l    NA 0.7400614           MG/L
#> 14 0.07045132     mg/l    NA 0.8288592     mg/l    NA 0.7640481           MG/L
#> 15 0.22996744     mg/l    NA 0.7046287     mg/l    NA 0.7211856           MG/L
#> 16 0.30068509     mg/l    NA 0.8699418     mg/l    NA 0.6769587           MG/L
#> 17 0.30932767     mg/l    NA 0.8829174     mg/l    NA 0.7061859           MG/L
#> 18 0.15977219     mg/l    NA 0.9521087     mg/l    NA 0.9172869           MG/L
#> 19 0.02565296     mg/l    NA 0.7663364     mg/l    NA 0.6839884           MG/L
#> 20 0.03573056     mg/l    NA 0.8442951     mg/l    NA 0.7791517           MG/L
#> 21 0.11093766     mg/l    NA 1.1056168     mg/l    NA 0.7305263           MG/L
#> 22 0.16229166     mg/l    NA 0.8282358     mg/l    NA 0.7924744           MG/L
#> 23 0.08832758     mg/l    NA 0.9484002     mg/l    NA 0.7511255           MG/L
#> 24 0.02465123     mg/l    NA 0.6856647     mg/l    NA 0.6855994           MG/L
#>    Q.Organic.N   Total.P Total.P.Unit Q.Total.P       PO4 PO4.Unit Q.PO4
#> 1           NA 0.2001634         mg/l        NA 0.2808993     mg/l    NA
#> 2           NA 0.2656919         mg/l        NA 0.1789608     mg/l    NA
#> 3           NA 0.2425811         mg/l        NA 0.2955749     mg/l    NA
#> 4           NA 0.3550630         mg/l        NA 0.2607356     mg/l    NA
#> 5           NA 0.2370389         mg/l        NA 0.3071010     mg/l    NA
#> 6           NA 0.2070870         mg/l        NA 0.2275418     mg/l    NA
#> 7           NA 0.3276313         mg/l        NA 0.1705112     mg/l    NA
#> 8           NA 0.2472752         mg/l        NA 0.4313626     mg/l    NA
#> 9           NA 0.1277325         mg/l        NA 0.1840042     mg/l    NA
#> 10          NA 0.1556450         mg/l        NA 0.2383781     mg/l    NA
#> 11          NA 0.2045273         mg/l        NA 0.1653526     mg/l    NA
#> 12          NA 0.1839178         mg/l        NA 0.2641616     mg/l    NA
#> 13          NA 0.2337734         mg/l        NA 0.3170760     mg/l    NA
#> 14          NA 0.2520314         mg/l        NA 0.2971009     mg/l    NA
#> 15          NA 0.1868349         mg/l        NA 0.2801180     mg/l    NA
#> 16          NA 0.2528620         mg/l        NA 0.4182292     mg/l    NA
#> 17          NA 0.2666154         mg/l        NA 0.3289632     mg/l    NA
#> 18          NA 0.3230197         mg/l        NA 0.3571105     mg/l    NA
#> 19          NA 0.2404983         mg/l        NA 0.2244889     mg/l    NA
#> 20          NA 0.2483830         mg/l        NA 0.4727917     mg/l    NA
#> 21          NA 0.1998192         mg/l        NA 0.2475436     mg/l    NA
#> 22          NA 0.2163667         mg/l        NA 0.2451613     mg/l    NA
#> 23          NA 0.2491462         mg/l        NA 0.2085887     mg/l    NA
#> 24          NA 0.1697065         mg/l        NA 0.2868269     mg/l    NA
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
#> 13                NA           NA        NA                NA           NA
#> 14                NA           NA        NA                NA           NA
#> 15                NA           NA        NA                NA           NA
#> 16                NA           NA        NA                NA           NA
#> 17                NA           NA        NA                NA           NA
#> 18                NA           NA        NA                NA           NA
#> 19                NA           NA        NA                NA           NA
#> 20                NA           NA        NA                NA           NA
#> 21                NA           NA        NA                NA           NA
#> 22                NA           NA        NA                NA           NA
#> 23                NA           NA        NA                NA           NA
#> 24                NA           NA        NA                NA           NA
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
#> 13        NA
#> 14        NA
#> 15        NA
#> 16        NA
#> 17        NA
#> 18        NA
#> 19        NA
#> 20        NA
#> 21        NA
#> 22        NA
#> 23        NA
#> 24        NA
```
