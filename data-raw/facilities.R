library(haven)
library(dplyr)
library(tibble)
library(here)

# original T:/03_BOARDS_COMMITTEES/05_TBNMC/2022_RA_Update/01_FUNDING_OUT/DELIVERABLES/TO-9/datastick_deliverables/2017-2021LUEntityLoads/2017-2021IPSMonthlyEntityBasin/ips1721monthentbas.sas7bdat
ipsfac <- read_sas(here('data-raw/ips1721monthentbas.sas7bdat')) |>
  select(bayseg, basin = BASIN, entity, facname, source = source2) |>
  distinct()

# original T:/03_BOARDS_COMMITTEES/05_TBNMC/2022_RA_Update/01_FUNDING_OUT/DELIVERABLES/TO-9/datastick_deliverables/2017-2021LUEntityLoads/2017-2021DPSMonthlyEntityBasin/dps1721monthentbas.sas7bdat
dpsfac <- read_sas(here('data-raw/dps1721monthentbas.sas7bdat')) |>
  select(bayseg, basin, entity, facname, source = source2) |>
  distinct() |>
  mutate( # make ototw its own entity
    entity = case_when(
      entity == 'Pinellas Co.' & facname == 'On Top Of The World WWTP' ~ 'On Top Of The World',
      T ~ entity
    ),
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
      entity == 'On Top Of The World' ~ 'ototw',
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
      facname == 'On Top Of The World WWTP' ~ 'ototw',
      facname == 'NW Regional WWTP' ~ 'nw',
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
      facname == 'South County Regional WWTP' & grepl('REUSE', source) ~ 'FL0028061LA', # assign separate permit id for reuse
      facname == 'South County Regional WWTP' & grepl('SW', source) ~ 'FL0028061SW', # assign separate permit id for SW
      facname == 'South Cross Bayou WRF' ~ 'FL0040436',
      facname == 'Southwest Regional WWTF' ~ 'FLA012954',
      facname == 'St Pete Facilities' ~ 'STPETE', # not sure how this relates to ne, nw, sw files
      facname == 'Valrico AWTP' ~ 'FL0040983',
      facname == 'Van Dyke WWTP' ~ 'FLA012234',
      facname == 'William E. Dunn WRF (Pinellas NW)' ~ 'FL0128775'
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
      facname == 'South County Regional WWTP' & grepl('REUSE', source) ~ '149b', # assign separate facid for reuse
      facname == 'South County Regional WWTP' & grepl('SW', source) ~ '149a', # assign separate facid for sw
      facname == 'South Cross Bayou WRF' ~ 'PC001',
      facname == 'Southwest Regional WWTF' ~ 'PK001',
      facname == 'St Pete Facilities' ~ 'STPET', # not sure how this relates to ne, nw, sw files
      facname == 'Valrico AWTP' ~ '176',
      facname == 'Van Dyke WWTP' ~ '2',
      facname == 'William E. Dunn WRF (Pinellas NW)' ~ 'PCNW'
    )
  )

# add dps st pete facilities
stpete <- tribble(
  ~bayseg, ~basin, ~entity, ~facname, ~source, ~entityshr, ~facnameshr, ~permit, ~facid,
  1,   '206-1',  'St. Petersburg',  'City of St. Petersburg Northeast WRF',  'PS - Domestic - REUSE',  'stpete',  'ne',  'FLA128856',  'PC159',
  5,   '207-5',  'St. Petersburg',  'City of St. Petersburg Northwest WRF',  'PS - Domestic - REUSE',  'stpete',  'nw',  'FLA128821',  'PC156',
  55,  '207-5',  'St. Petersburg',  'City of St. Petersburg Southwest WRF',  'PS - Domestic - REUSE',  'stpete',  'sw',  'FLA128848',  'PC158'
)

# combine dps
dpsfac <- dpsfac |>
  bind_rows(stpete)

# add coast id to dps
dpsfac <- dpsfac |>
  mutate(
    coastid = case_when(
      permit == "FL0036820"   ~  "D_HC_14",
      permit == "FL0039896"   ~  "D_HC_15",
      permit == "FL0027821"   ~  "D_HC_2",
      permit == "FL0020338"   ~ "D_PK_3",
      permit == "FL0020401"   ~ "D_MC_2",
      permit == "FL0020940"   ~ "D_HC_5D",
      permit == "FL0021369"   ~ "D_MC_3",
      permit == "FL0021865"   ~ "D_PC_8",
      permit == "FL0026557"   ~ "D_HC_17",
      permit == "FL0026603"   ~ "D_PC_9",
      permit == "FL0027651"   ~ "D_PC_5",
      permit == "FL0028061SW" ~ "D_HC18D1",
      permit == "FL0028061LA" ~ "D_HC18D2",
      permit == "FL0039772"   ~ "D_PK_2",
      permit == "FL0040614"   ~ "D_HC_3P",
      permit == "FL0040983"   ~ "D_HC_16",
      permit == "FL0041670"   ~ "D_HC_1P",
      permit == "FL0128775"   ~ "PINNW",
      permit == "FL0128937"   ~ "D_PC_6",
      permit == "FLA012124"   ~ "D_HC_12",
      permit == "FLA012234"   ~ "D_HC_002",
      permit == "FLA012617"   ~ "D_MC_1",
      permit == "FLA012618"   ~ "D_MC_4",
      permit == "FLA012744"   ~ "D_PA_001",
      permit == "FLA012905"   ~ "D_PC_7",
      permit == "FLA012954"   ~ "D_PK_001",
      permit == "FLA128821"   ~ "D_PC_11",
      permit == "FLA128848"   ~ "D_PC_13",
      permit == "FLA128856"   ~ "D_PC_10",
      permit == "FLA178667"   ~ "D_PK_002",
      permit == "FL0168505"   ~ "BridgeAc",
      permit == "FL0040436"   ~ "SCROSSB",
      permit == "FLA128830"   ~ "D_PC_12",
      T ~ NA_character_ # only pasco reuse and st pete facilities have no coast id, which is fine
    )
  )

# add coast co to dps
dpsfac <- dpsfac |>
  mutate(
    coastco = case_when(
      coastid == "D_HC_14"  ~ "461",
      coastid == "D_HC_15"  ~ "204",
      coastid == "D_HC_2"   ~ "421",
      coastid == "D_PK_3"   ~ "515b",
      coastid == "D_MC_2"   ~ "687",
      coastid == "D_HC_5D"  ~ "411b",
      coastid == "D_MC_3"   ~ "736",
      coastid == "D_PC_8"   ~ "480",
      coastid == "D_HC_17"  ~ "403",
      coastid == "D_PC_9"   ~ "509",
      coastid == "D_PC_5"   ~ "392",
      coastid == "D_HC18D1" ~ "583",
      coastid == "D_HC18D2" ~ "625a",
      coastid == "D_PK_2"   ~ "502",
      coastid == "D_HC_3P"  ~ "381",
      coastid == "D_HC_16"  ~ "463",
      coastid == "D_HC_1P"  ~ "319", # if D-005 is outfall id, then coast_co changed to 292, done in functions
      coastid == "PINNW"    ~ "257",
      coastid == "D_PC_6"   ~ "387",
      coastid == "D_HC_12"  ~ "497",
      coastid == "D_HC_002" ~ "245",
      coastid == "D_MC_1"   ~ "711",
      coastid == "D_MC_4"   ~ "767",
      coastid == "D_PA_001" ~ "197",
      coastid == "D_PC_7"   ~ "451",
      coastid == "D_PK_001" ~ "502",
      coastid == "D_PC_11"  ~ "501",
      coastid == "D_PC_13"  ~ "594a",
      coastid == "D_PC_10"  ~ "566",
      coastid == "D_PK_002" ~ "244",
      coastid == "D_PC_12"  ~ "594",
      coastid == "SCROSSB"  ~ "556",
      coastid == "BridgeAc" ~ "508",
      T ~ NA_character_ # only pasco reuse and st pete facilities have no coast id, which is fine
    )
  )

# combine ips dps
facilities <- bind_rows(ipsfac, dpsfac) |>
  arrange(entity, facname)

usethis::use_data(facilities, overwrite = TRUE)
