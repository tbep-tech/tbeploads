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
    ),
    permit = case_when(
      facname == 'Bridgeway Acres' ~ 'FL0168505',
      facname == 'City of Bradenton WRF' ~ 'FL0021369',
      facname == 'City of Clearwater East AWWTF' ~ 'FL0021865',
      facname == 'City of Clearwater Northeast AWWTF' ~ 'FL0128937',
      facname == 'City of Lakeland' ~ 'FL0039772',
      facname == 'City of Largo' ~ 'FL0026603',
      facname == 'City of Mulberry' ~ 'FL0020338',
      facname == 'City of Oldsmar WRF' ~ 'FL0027651',
      facname == 'City of Palmetto WWTF' ~ 'FL0020401',
      facname == 'City of Zephyrhills WWTF' ~ 'FLA012744',
      facname == 'Dale Mabry AWTP' ~ 'FL0036820',
      facname == 'Falkenburg AWTP' ~ 'FL0040614',
      facname == 'Howard F. Curren' ~ 'FL0020940',
      facname == 'MacDill AFB WWTP' ~ 'FLA012124',
      facname == 'Manatee County North WRF' ~ 'FLA012617',
      facname == 'Manatee County Southeast WRF' ~ 'FLA012618',
      facname == 'Northwest Regional WRF' ~ 'FL0041670',
      facname == 'NW Regional WWTP' ~ 'FLA178667',
      facname == 'On Top Of The World WWTP' ~ 'FLA012905',
      facname == 'Pasco Reuse' ~ 'PascoReuse',
      facname == 'Pebble Creek AWTP' ~ 'FL0039896',
      facname == 'Plant City WRF' ~ 'FL0026557',
      facname == 'River Oaks AWWTP' ~ 'FL0027821',
      facname == 'South County Regional WWTP' ~ 'FL0028061',
      facname == 'South Cross Bayou WRF' ~ 'FL0040436',
      facname == 'Southwest Regional WWTF' ~ 'FLA012954',
      facname == 'St Pete Facilities' ~ 'STPETE', # not sure how this relates to ne, nw, sw files
      facname == 'Valrico AWTP' ~ 'FL0040983',
      facname == 'Van Dyke WWTP' ~ 'FLA012234',
      facname == 'William E. Dunn WRF (Pinellas NW)' ~ 'FLA012877'
    ),
    facid = case_when(
      facname == 'Bridgeway Acres' ~ 'FL0168505',
      facname == 'City of Bradenton WRF' ~ 'MC757',
      facname == 'City of Clearwater East AWWTF' ~ 'PC691',
      facname == 'City of Clearwater Northeast AWWTF' ~ 'PC963',
      facname == 'City of Lakeland' ~ 'PK852',
      facname == 'City of Largo' ~ 'PC750',
      facname == 'City of Mulberry' ~ 'PK246',
      facname == 'City of Oldsmar WRF' ~ 'PC520',
      facname == 'City of Palmetto WWTF' ~ 'MC077',
      facname == 'City of Zephyrhills WWTF' ~ 'PA001',
      facname == 'Dale Mabry AWTP' ~ '50',
      facname == 'Falkenburg AWTP' ~ '59',
      facname == 'Howard F. Curren' ~ '82',
      facname == 'MacDill AFB WWTP' ~ '98',
      facname == 'Manatee County North WRF' ~ 'MC009',
      facname == 'Manatee County Southeast WRF' ~ 'MC011',
      facname == 'Northwest Regional WRF' ~ '112',
      facname == 'NW Regional WWTP' ~ 'PK002',
      facname == 'On Top Of The World WWTP' ~ 'PC749',
      facname == 'Pasco Reuse' ~ 'Pasco',
      facname == 'Pebble Creek AWTP' ~ '118',
      facname == 'Plant City WRF' ~ '121',
      facname == 'River Oaks AWWTP' ~ '129',
      facname == 'South County Regional WWTP' ~ '149ab',
      facname == 'South Cross Bayou WRF' ~ 'PC001',
      facname == 'Southwest Regional WWTF' ~ 'PK001',
      facname == 'St Pete Facilities' ~ 'STPET', # not sure how this relates to ne, nw, sw files
      facname == 'Valrico AWTP' ~ '176',
      facname == 'Van Dyke WWTP' ~ '2',
      facname == 'William E. Dunn WRF (Pinellas NW)' ~ 'PCNW'
    )
  )

facilities <- bind_rows(ipsfac, dpsfac) %>%
  arrange(entity, facname)

usethis::use_data(facilities, overwrite = TRUE)
