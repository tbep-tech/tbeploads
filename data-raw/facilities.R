library(haven)
library(dplyr)

pth <- 'T:/03_BOARDS_COMMITTEES/05_TBNMC/2022_RA_Update/01_FUNDING_OUT/DELIVERABLES/TO-9/datastick_deliverables/2017-2021LUEntityLoads/'

ipsfac <- read_sas(paste0(pth, '2017-2021IPSMonthlyEntityBasin/ips1721monthentbas.sas7bdat')) %>%
  select(bayseg, basin = BASIN, entity, facname, source = source2) %>%
  distinct()

dpsfac <- read_sas(paste0(pth, '2017-2021DPSMonthlyEntityBasin/dps1721monthentbas.sas7bdat')) %>%
  select(bayseg, basin, entity, facname, source = source2) %>%
  distinct() %>%
  mutate(
    entityshr = case_when(
      entity == 'Bradenton' ~ 'bradenton',
      entity == 'Clearwater' ~ 'clearwater',
      entity == 'Hillsborough Co.' ~ 'hillsco',
      entity == 'Lakeland' ~ 'lakeland',
      entity == 'Largo' ~ 'largo',
      entity == 'MacDill' ~ 'macdill',
      entity == 'Manatee Co.' ~ 'manatee',
      entity == 'Mulberry' ~ 'mulberry',
      entity == 'Oldsmar' ~ 'oldsmar',
      entity == 'Palmetto' ~ 'palmetto',
      entity == 'Pasco Co.' ~ 'pasco',
      entity == 'Pinellas Co.' ~ 'pinco',
      entity == 'Plant City' ~ 'plantcity',
      entity == 'Polk Co.' ~ 'polk',
      entity == 'St. Petersburg' ~ 'stpete',
      entity == 'Tampa' ~ 'tampa', # as hfcurren in RP files
      entity == 'Zephyrhills' ~ 'zeph'
    ),
    facnameshr = case_when(
      facname == 'Bridgeway Acres' ~ 'bridgeway',
      facname == 'City of Bradenton WRF' ~ 'bradenton',
      facname == 'City of Clearwater East AWWTF' ~ 'east',
      facname == 'City of Clearwater Northeast AWWTF' ~ 'ne',
      facname == 'City of Lakeland' ~ 'lakeland',
      facname == 'City of Largo' ~ 'largo',
      facname == 'City of Mulberry' ~ 'mulberry',
      facname == 'City of Oldsmar WRF' ~ 'oldsmar',
      facname == 'City of Palmetto WWTF' ~ 'palmetto',
      facname == 'City of Zephyrhills WWTF' ~ 'zeph',
      facname == 'Dale Mabry AWTP' ~ 'dalemabry',
      facname == 'Falkenburg AWTP' ~ 'falkenburg',
      facname == 'Howard F. Curren' ~ 'hfcurren',
      facname == 'MacDill AFB WWTP' ~ 'macdill',
      facname == 'Manatee County North WRF' ~ 'north',
      facname == 'Manatee County Southeast WRF' ~ 'se',
      facname == 'Northwest Regional WRF' ~ 'northwest',
      facname == 'NW Regional WWTP' ~ 'nw',
      facname == 'On Top Of The World WWTP' ~ 'ototw',
      facname == 'Pasco Reuse' ~ 'pasco',
      facname == 'Pebble Creek AWTP' ~ 'pebblecrk',
      facname == 'Plant City WRF' ~ 'plantcity',
      facname == 'River Oaks AWWTP' ~ 'riveroaks',
      facname == 'South County Regional WWTP' ~ 'southco',
      facname == 'South Cross Bayou WRF' ~ 'scross',
      facname == 'Southwest Regional WWTF' ~ 'sw',
      facname == 'St Pete Facilities' ~ 'stpete', # not sure how this relates to ne, nw, sw files
      facname == 'Valrico AWTP' ~ 'valrico',
      facname == 'Van Dyke WWTP' ~ 'vandyke',
      facname == 'William E. Dunn WRF (Pinellas NW)' ~ 'dunn'
    )
  )

facilities <- bind_rows(ipsfac, dpsfac) %>%
  arrange(entity, facname)

usethis::use_data(facilities, overwrite = TRUE)
