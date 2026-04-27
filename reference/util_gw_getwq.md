# Get groundwater quality concentrations for Floridan aquifer segments

Get groundwater quality concentrations for Floridan aquifer segments

## Usage

``` r
util_gw_getwq(sta_ids = NULL, yrrng = NULL, verbose = TRUE)
```

## Arguments

- sta_ids:

  character vector of SWFWMD station IDs to query. When `NULL`
  (default), uses stations 18340 (CR 581 North Fldn) and 18965 (SR 52
  and CR 581 Deep), the two Pasco County Floridan aquifer monitoring
  wells used in the 2022-2024 Tampa Bay groundwater loading analysis.

- yrrng:

  integer vector of length 2 specifying the start and end year for
  computing concentration means, e.g. `c(2020, 2024)`. When `NULL`
  (default), all available observations are used.

- verbose:

  logical, if `TRUE` (default) a progress message is printed.

## Value

A data frame with one row per bay segment (1-7) and columns:

- `bay_seg`: integer, bay segment number

- `tn_mgl`: numeric, mean total nitrogen concentration (mg/L)

- `tp_mgl`: numeric, mean total phosphorus concentration (mg/L)

## Details

Retrieves TN and TP concentrations (mg/L) from the [Water Atlas
API](https://dev.api.wateratlas.org) (`GET /api/samplingdata/stream`)
for Upper Floridan Aquifer monitoring stations and computes grand-mean
concentrations per station. Station means are then mapped to bay
segments:

- **OTB (segment 1):** mean of `sta_ids[1]` only (default: CR 581 North
  Fldn, station 18340).

- **HB (segment 2):** arithmetic mean of the per-station means across
  all `sta_ids` (default: mean of stations 18340 and 18965, SR 52 and CR
  581 Deep).

- **Segments 3-7:** fixed constants carried forward from
  `gwupdate95-98_final.xls` (the original 1995-1998 SWFWMD monitoring
  analysis). These values were used unchanged in every loading script
  from 2012 through 2021 and are not updated from the API.

**History:** Through the 2021 loading cycle, all seven segments used
hardcoded Floridan concentrations sourced from the 1995-1998 spreadsheet
(TN: 0.010-0.025 mg/L, TP: 0.097-0.137 mg/L). For the 2022-2024 update,
new SWFWMD well data showed substantially higher TN in the Pasco County
Floridan aquifer, so segments 1 and 2 were revised using stations 18340
and 18965. Segments 3-7 retained the original values.

TN is taken from the `TN_mgl` parameter and TP from `TP_mgl` in the
Water Atlas API response.

## Examples

``` r
if (FALSE) { # \dontrun{
# default stations, all available data
conc <- util_gw_getwq()

# restrict to a specific period
conc <- util_gw_getwq(yrrng = c(2020, 2024))
} # }
```
