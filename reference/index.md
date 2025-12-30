# Package index

## Analyze data

Functions for analyzing data.

- [`anlz_ad()`](https://tbep-tech.github.io/tbeploads/reference/anlz_ad.md)
  : Calculate AD loads and summarize
- [`anlz_dps()`](https://tbep-tech.github.io/tbeploads/reference/anlz_dps.md)
  : Calculate DPS reuse and end of pipe loads and summarize
- [`anlz_dps_facility()`](https://tbep-tech.github.io/tbeploads/reference/anlz_dps_facility.md)
  : Calculate DPS reuse and end of pipe loads from raw facility data
- [`anlz_ips()`](https://tbep-tech.github.io/tbeploads/reference/anlz_ips.md)
  : Calculate IPS loads and summarize
- [`anlz_ips_facility()`](https://tbep-tech.github.io/tbeploads/reference/anlz_ips_facility.md)
  : Calculate IPS loads from raw facility data
- [`anlz_ml()`](https://tbep-tech.github.io/tbeploads/reference/anlz_ml.md)
  : Calculate material loss (ML) loads and summarize
- [`anlz_ml_facility()`](https://tbep-tech.github.io/tbeploads/reference/anlz_ml_facility.md)
  : Calculate material loss (ML) loads from raw facility data
- [`anlz_nps()`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps.md)
  : Calculate non-point source (NPS) loads for Tampa Bay
- [`anlz_nps_gaged()`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps_gaged.md)
  : Calculate non-point source (NPS) loads for gaged basins
- [`anlz_nps_ungaged()`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps_ungaged.md)
  : Estimated non-point source (NPS) ungaged loads

## Internal datasets

Supporting datasets used by the other functions.

- [`ad_distance`](https://tbep-tech.github.io/tbeploads/reference/ad_distance.md)
  : Data frame of distances of segment locations to National Weather
  Service (NWS) sites

- [`allflo`](https://tbep-tech.github.io/tbeploads/reference/allflo.md)
  :

  Data frame of all flow data used in `anlz_nps_gaged` and
  `anlz_nps_ungaged`

- [`allwq`](https://tbep-tech.github.io/tbeploads/reference/allwq.md) :

  Data frame of all water quality data used in `anlz_nps_gaged`

- [`clucsid`](https://tbep-tech.github.io/tbeploads/reference/clucsid.md)
  : Lookup table for FLUCCSCODE conversion to CLUCSID and IMPROVED

- [`dbasing`](https://tbep-tech.github.io/tbeploads/reference/dbasing.md)
  : Basin information for coastal subbasin codes

- [`emc`](https://tbep-tech.github.io/tbeploads/reference/emc.md) :
  Event Mean Concentration (EMC) data for CLUCSID in Tampa Bay

- [`facilities`](https://tbep-tech.github.io/tbeploads/reference/facilities.md)
  : Domestic and industrial point source facilities, including
  industrial with material losses

- [`nps_distance`](https://tbep-tech.github.io/tbeploads/reference/nps_distance.md)
  : Data frame of distances of drainage basin locations to National
  Weather Service (NWS) sites

- [`rain`](https://tbep-tech.github.io/tbeploads/reference/rain.md) :
  Data frame of daily rainfall data from NOAA NCDC National Weather
  Service (NWS) sites from 2017 to 2023

- [`rain_historic`](https://tbep-tech.github.io/tbeploads/reference/rain_historic.md)
  : Data frame of historical daily rainfall datas

- [`rcclucsid`](https://tbep-tech.github.io/tbeploads/reference/rcclucsid.md)
  : Lookup table for CLUCSID runoff coefficients

- [`tbbase`](https://tbep-tech.github.io/tbeploads/reference/tbbase.md)
  : Combined spatial data required for non-point source (NPS) ungaged
  estimate

- [`tbdbasin`](https://tbep-tech.github.io/tbeploads/reference/tbdbasin.md)
  : Simple feature polygons major drainage basins in the Tampa Bay
  Estuary Program boundary

- [`tbfullshed`](https://tbep-tech.github.io/tbeploads/reference/tbfullshed.md)
  : Simple features polygon for the Tampa Bay Estuary Program boundary

- [`tbjuris`](https://tbep-tech.github.io/tbeploads/reference/tbjuris.md)
  : Simple feature polygons of jurisdictional boundaries in the Tampa
  Bay Estuary Program boundary

- [`tblu2023`](https://tbep-tech.github.io/tbeploads/reference/tblu2023.md)
  : Simple feature polygons of 2023 land use in the Tampa Bay Estuary
  Program boundary

- [`tbsoil`](https://tbep-tech.github.io/tbeploads/reference/tbsoil.md)
  : Simple feature polygons of soil data in the Tampa Bay Estuary
  Program boundary

- [`tbsubshed`](https://tbep-tech.github.io/tbeploads/reference/tbsubshed.md)
  : Simple feature polygons of sub-watersheds in the Tampa Bay Estuary
  Program boundary

- [`usgsflow`](https://tbep-tech.github.io/tbeploads/reference/usgsflow.md)
  : Data frame of USGS stream flow data from the USGS NWIS database for
  2021 to 2023

## Utility functions

Utility functions used by other functions.

- [`util_getrain()`](https://tbep-tech.github.io/tbeploads/reference/util_getrain.md)
  : Get rainfall data at NOAA NCDC sites for atmospheric deposition and
  non-point source ungaged calculations
- [`util_nps_fillmiswq()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_fillmiswq.md)
  : Fill in missing water quality values for non-point source (NPS) data
- [`util_nps_getextflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getextflow.md)
  : Get external flow data not from USGS for NPS calculations
- [`util_nps_getflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getflow.md)
  : Get flow data from for NPS calculations at gaged sites
- [`util_nps_getswfwmd()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getswfwmd.md)
  : Retrieve non-point source (NPS) supporting data from SWFWMD web
  services
- [`util_nps_getusgsflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getusgsflow.md)
  : Get flow data from USGS for NPS calculations
- [`util_nps_getwq()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getwq.md)
  : Get water quality data for NPS gaged flows
- [`util_nps_landsoil()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_landsoil.md)
  : Utility function for non-point source (NPS) ungaged workflow to
  create land use and soil data
- [`util_nps_landsoilrc()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_landsoilrc.md)
  : Utility function to create non-point source (NPS) ungaged land use
  and soil runoff coefficients
- [`util_nps_lusumm()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_lusumm.md)
  : Summarize non-point source (NPS) ungaged loads by land use
- [`util_nps_preplog()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_preplog.md)
  : Utility function for non-point source (NPS) ungaged workflow to
  prepare land use and soil data for logistic regression
- [`util_nps_preprain()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_preprain.md)
  : Prep rain data for non-point source (NPS) ungaged load estimates
- [`util_nps_segment()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_segment.md)
  : Create bay segment column for non-point source (NPS) load data
- [`util_nps_tbbase()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_tbbase.md)
  : Create unioned base layer for non-point source (NPS) ungaged load
  estimation in the Tampa Bay watershed
- [`util_nps_union()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_union.md)
  : Fast Spatial Intersection and Union Using GDAL
- [`util_nps_unionchunk()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_unionchunk.md)
  : Helper function for union operation
- [`util_nps_unionnochunk()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_unionnochunk.md)
  : Helper function for union operation
- [`util_prepverna()`](https://tbep-tech.github.io/tbeploads/reference/util_prepverna.md)
  : Prep Verna Wellfield data for use in AD and NPS calculations
- [`util_ps_addcol()`](https://tbep-tech.github.io/tbeploads/reference/util_ps_addcol.md)
  : Add column names for point source data from raw entity data
- [`util_ps_checkfls()`](https://tbep-tech.github.io/tbeploads/reference/util_ps_checkfls.md)
  : Create a data frame of formatting issues with point source input
  files
- [`util_ps_checkuni()`](https://tbep-tech.github.io/tbeploads/reference/util_ps_checkuni.md)
  : Check units for point source from raw entity data
- [`util_ps_facinfo()`](https://tbep-tech.github.io/tbeploads/reference/util_ps_facinfo.md)
  : Get point source entity information from file name
- [`util_ps_fillmis()`](https://tbep-tech.github.io/tbeploads/reference/util_ps_fillmis.md)
  : Fill missing point source data with annual average
- [`util_ps_fixoutfall()`](https://tbep-tech.github.io/tbeploads/reference/util_ps_fixoutfall.md)
  : Light edits to the outfall ID column for point source data
- [`util_summ()`](https://tbep-tech.github.io/tbeploads/reference/util_summ.md)
  : Summarize load estimates
