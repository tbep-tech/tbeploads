# Get groundwater quality concentrations for Floridan aquifer segments

Get groundwater quality concentrations for Floridan aquifer segments

## Usage

``` r
util_gw_getwq(path)
```

## Arguments

- path:

  character string, path to a folder containing one or more water
  quality CSV files downloaded from the SWFMD District database (see
  Details).

## Value

A data frame with one row per bay segment (1-7) and columns:

- `bay_seg`: integer, bay segment number

- `tn_mgl`: numeric, mean total nitrogen concentration (mg/L)

- `tp_mgl`: numeric, mean total phosphorus concentration (mg/L)

## Details

Reads SWFMD District water quality CSV files for Upper Floridan Aquifer
monitoring stations and computes mean TN and TP concentrations (mg/L)
per station. Station means are then mapped to bay segments following the
methodology in Zarbock et al. (1994) as applied in the 2022-2024 Tampa
Bay groundwater loading analysis:

- **OTB (segment 1):** CR 581 North Fldn well (Pasco County, 77 ft
  depth; SWFMD station 18340).

- **HB (segment 2):** arithmetic mean of CR 581 North Fldn and SR 52 and
  CR 581 Deep (Pasco County, 83 ft depth) stations.

- **Segments 3-7:** fixed historical concentrations from earlier
  monitoring periods (late 1990s to early 2000s). These values are
  returned as constants and are not updated from the CSV files.

TN is taken from `"Nitrogen- Total (Total)"` and TP from
`"Phosphorus- Total (Total)"`. All qualifying flags are retained;
non-detect values (`qualifier = "U"`) are included at the reported
instrument value.

CSV files must match the format produced by the SWFMD Water Management
Information System (WMIS) data download tool, with columns: SID, Station
Name, Parameter Name, Sample Date and Time, Timezone, Sample Result,
Measuring Unit, Remark, Method Name, Medium, Value Qualifier, Analysis
Date and Time, Measuring program Name, Activity Depth, Activity Depth
Unit, Sampling Agency.

## Examples

``` r
if (FALSE) { # \dontrun{
conc <- util_gw_getwq("path/to/GW_DistrictWQData")
} # }
```
