# Get external flow data not from USGS for NPS calculations

Get external flow data not from USGS for NPS calculations

## Usage

``` r
util_nps_getextflow(pth, loc, yrrng = c(2021, 2023))
```

## Arguments

- pth:

  Path to the external Excel file

- loc:

  Location of the external flow data. Options are 'LMANATEE', 'TBYPASS',
  or '02301500'.

- yrrng:

  Numeric vector of length 2 indicating the year range to filter the
  data. Default is c(2021, 2023).

## Value

A data frame of flow data for the location in `loc`

## Details

This function retrieves and formats external flow data that cannot be
obtained from the USGS API. The three required locations are Lake
Manatee, Tampa Bypass Canal (s160), and the Alafia River Bell Shoals
Bell Shoals.

External data can be obtained as follows:

- LMANATEE: Lake Manatee flow for the Manatee River dam, from Manatee
  County Utilities, input flow is cfs (Manatee County contact is Amanda
  ShawverKarnitz, <amanda.shawverkarnitz@mymanatee.org>).

- TBYPASS: Tampa Bypass Canal flow from Tampa Bay Water. Input flow is
  MGD and is converted to cfs (Tampa Bay Water contact is Cathleen
  Jonas, <cjonas@tampabaywater.org>, device ID 957).

- 02301500: Alafia River Bell Shoals flow data from SWFWMD WMIS Pumpage
  Reports for Permit 11794
  (<https://www18.swfwmd.state.fl.us/search/search/searchwupsimple.aspx>)
  or optionally from Tampa Bay Water reported withdrawals for Site 4626
  (Cathleen Jonas, <cjonas@tampabaywater.org>, device ID 4626). Input
  flow from latter is daily average converted to cfs.

System files are included in the package which can be updated annually.

## Examples

``` r
# lake manatee
pth <- system.file('extdata/nps_extflow_lakemanatee.xlsx', package = 'tbeploads')
extflo <- util_nps_getextflow(pth, loc = "LMANATEE")

# tampa bypass
pth <- system.file('extdata/nps_extflow_tampabypass.xlsx', package = 'tbeploads')
extflo <- util_nps_getextflow(pth, loc = "TBYPASS")

# bell shoals
pth <- system.file('extdata/nps_extflow_bellshoals.xls', package = 'tbeploads')
extflo <- util_nps_getextflow(pth, loc = "02301500")
```
