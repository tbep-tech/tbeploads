# Get rainfall data at NOAA NCDC sites for atmospheric deposition and non-point source ungaged calculations

Get rainfall data at NOAA NCDC sites for atmospheric deposition and
non-point source ungaged calculations

## Usage

``` r
util_getrain(yrs, station = NULL, noaa_key, ntry = 5, quiet = FALSE)
```

## Arguments

- yrs:

  numeric vector for the years of data to retrieve

- station:

  numeric vector of station numbers to retrieve, see details

- noaa_key:

  character for the NOAA API key

- ntry:

  numeric for the number of times to try to download the data

- quiet:

  logical to print progress in the console

## Value

a data frame with the following columns:

- `station`: numeric, the station id

- `date`: Date, the date of the observation

- `Year`: numeric, the year of the observation

- `Month`: numeric, the month of the observation

- `Day`: numeric, the day of the observation

- `rainfall`: numeric, the amount of rainfall in inches

## Details

This function is used to retrieve a long-term record of rainfall for
estimating AD and NPS ungaged loads. It is used to create an input data
file for load calculations and it is not used directly by any other
functions due to download time. A NOAA API key is required to use the
function.

By default, rainfall data is retrieved for the following stations:

- `228`: ARCADIA

- `478`: BARTOW

- `520`: BAY LAKE

- `940`: BRADENTON EXPERIMENT

- `945`: BRADENTON 5 ESE

- `1046`: BROOKSVILLE CHIN HIL

- `1163`: BUSHNELL 2 E

- `1632`: CLEARWATER

- `1641`: CLERMONT 7 S

- `2806`: ST PETERSBURG WHITTD

- `3153`: FORT GREEN 12 WSW

- `3986`: HILLSBOROUGH RVR SP

- `4707`: LAKE ALFRED EXP STN

- `5973`: MOUNTAIN LAKE

- `6065`: MYAKKA RIVER STATE P

- `6880`: PARRISH

- `7205`: PLANT CITY

- `7851`: ST LEO

- `7886`: ST PETERSBURG WHITTD

- `8788`: TAMPA INTL ARPT

- `8824`: TARPON SPNGS SWG PLT

- `9176`: VENICE

- `9401`: WAUCHULA 2 N

## See also

[`rain`](https://tbep-tech.github.io/tbeploads/reference/rain.md)

## Examples

``` r
if (FALSE) { # \dontrun{
noaa_key <- Sys.getenv('NOAA_KEY')
util_getrain(2021, 228, noaa_key)
} # }
```
