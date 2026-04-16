# Retrieve spring water quality data from APIs

Retrieve spring water quality data from APIs

## Usage

``` r
util_spr_getwq(yrrng, verbose = TRUE)
```

## Arguments

- yrrng:

  integer vector of length 2, start and end year, e.g. `c(2022, 2024)`.

- verbose:

  logical, if `TRUE` progress messages are printed.

## Value

A data frame with columns `spring`, `yr`, `tn_mgl`, `tp_mgl`, and
`tss_mgl` (one row per spring per year).

## Details

Fetches annual mean TN, TP, and TSS concentrations (mg/L) for Lithia,
Buckhorn, and Sulphur springs from two external sources.

**Lithia and Buckhorn springs** are retrieved from the [Water Atlas
API](https://dev.api.wateratlas.org) (`GET /api/samplingdata/stream`),
using Southwest Florida Water Management District (SWFWMD) monitoring
stations 17805 (Lithia Main Spring) and 18276 (Buckhorn Main Spring)
from the `WIN_21FLSWFD` data source. This is the same underlying dataset
as FDEP's Impaired Waters Rule file but accessed directly via API. TSS
is not routinely measured at these stations and will typically be `NA`,
in which case
[`anlz_spr`](https://tbep-tech.github.io/tbeploads/reference/anlz_spr.md)
substitutes fixed historical values.

**Sulphur Spring** data are retrieved via
[`read_importepc`](https://tbep-tech.github.io/tbeptools/reference/read_importepc.html),
which downloads the Environmental Protection Commission of Hillsborough
County (EPC) monitoring spreadsheet. Station 174 corresponds to the
Sulphur Spring sampling location and provides monthly TN, TP, and TSS
observations.

Annual means are computed across all observations within each calendar
year. TSS values that are `NaN` (i.e., no valid observations in a year)
are converted to `NA` so that
[`anlz_spr`](https://tbep-tech.github.io/tbeploads/reference/anlz_spr.md)
can apply the fixed fallback concentrations.

## See also

[`anlz_spr`](https://tbep-tech.github.io/tbeploads/reference/anlz_spr.md)

## Examples

``` r
if (FALSE) { # \dontrun{
wqdat <- util_spr_getwq(c(2022, 2024))
} # }
```
