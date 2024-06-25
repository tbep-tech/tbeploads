library(haven)
library(dplyr)
library(tibble)
library(here)

# original T:/03_BOARDS_COMMITTEES/05_TBNMC/2022_RA_Update/01_FUNDING_OUT/DELIVERABLES/TO-9/datastick_deliverables/2017-2021LUEntityLoads/2017-2021IPSMonthlyEntityBasin/ips1721monthentbas.sas7bdat
ipsfac <- read_sas(here('data-raw/ips1721monthentbas.sas7bdat')) |>
  select(bayseg, basin = BASIN, entity, facname, source = source2) |>
  distinct() |>
  mutate(
    entity = case_when(
      entity == 'Cytech Brewster' ~ 'Brewster Phosphogypsum', # entity is same as facility elsewhere
      entity == 'HRK' ~ 'Piney Point Facility', # to match allocation tables
      T ~ entity
    )
  ) |>
  mutate(
    entityshr = case_when(
      entity == 'Alpha/Owens Corning' ~ 'aoc' ,
      entity == 'Brewster Phosphogypsum' ~ 'brewster',
      entity == 'Busch Gardens' ~ 'busch' ,
      entity == 'CSX' ~ 'csx',
      entity == 'Coronet' ~ 'coronet',
      entity == 'Duke Energy' ~ 'duke' ,
      entity == 'Estech Agricola' ~ 'estech',
      entity == 'Piney Point Facility' ~ 'pineypoint',
      entity == 'Kerry' ~ 'kerry',
      entity == 'Kinder Morgan' ~ 'kinder',
      entity == 'Lowry Park Zoo' ~ 'lowry',
      entity == 'Mosaic' ~ 'mosaic',
      entity == 'TECO' ~ 'teco',
      entity == 'Trademark Nitrogen' ~ 'trademark',
      entity == 'Yara' ~ 'yara'
    )
  ) |>
  mutate(
    facnameshr = case_when(
      facname == 'CSX - Rockport Newport' ~ 'rocknewp' ,
      facname == 'CSX Winston Yard' ~ 'winston',
      facname == 'Kinder Morgan Port Sutton' ~ 'portsutt',
      facname == 'Kinder Morgan Tampaplex' ~ 'tampaplex',
      facname == 'Mosaic - Bartow' ~ 'bartow',
      facname == 'Mosaic - Bonnie' ~ 'bonnie',
      facname == 'Mosaic - Four Corners' ~ 'fourcorners',
      facname == 'Mosaic - Ft. Lonesome' ~ 'ftlone',
      facname == 'Mosaic - Green Bay' ~ 'greenbay',
      facname == 'Mosaic - Hookers Prairie' ~ 'hookers',
      facname == 'Mosaic - Kingsford' ~ 'kingsford',
      facname == 'Mosaic - Mulberry Phospho Stack' ~ 'mulbphosph',
      facname == 'Mosaic - Mulberry Plant' ~ 'mulbplant',
      facname == 'Mosaic - New Wales Chemical Plant' ~ 'newwales',
      facname == 'Mosaic - Nichols Mine' ~ 'nichols',
      facname == 'Mosaic - Plant City' ~ 'plantcity',
      facname == 'Mosaic - Port Sutton' ~ 'portsutt',
      facname == 'Mosaic - Riverview' ~ 'riverview',
      facname == 'Mosaic - Riverview Stack Closure' ~ 'riverviewstack',
      facname == 'Mosaic - South Pierce' ~ 'spierce',
      facname == 'Mosaic - Tampa Ammonia Terminal' ~ 'tampaamm',
      facname == 'Mosaic - Tampa Marine Terminal' ~ 'tampamar',
      facname == 'TECO - Bayside (fka Gannon)' ~ 'bayside',
      facname == 'TECO - Big Bend' ~ 'bigbend',
      facname == 'HRK Piney Point' ~ 'pineypoint',
      T ~ entityshr
    )
  ) |>
  mutate(
    permit = case_when(
      facname == 'Alpha/Owens Corning' ~ 'FL0029653',
      facname == 'Brewster Phosphogypsum' ~ 'FL0132381',
      facname == 'Busch Gardens' ~ 'FL0185833',
      facname == 'Coronet Industries' ~ 'FL0034657',
      facname == 'CSX - Rockport Newport' ~ 'FL0450600',
      facname == 'CSX Winston Yard' ~ 'FL0032581',
      facname == 'Duke Energy-Bartow Plant' ~ 'FL0000132',
      facname == 'Estech Agricola' ~ 'FL0160083',
      facname == 'HRK Piney Point' ~ 'FL0000124',
      facname == 'Kerry I and F' ~ 'FL0037389',
      facname == 'Kinder Morgan Port Sutton' ~ 'FL0122904',
      facname == 'Kinder Morgan Tampaplex' ~ 'FL0321486',
      facname == 'Lowry Park Zoo' ~ 'FL0188651',
      facname == 'Mosaic - Bartow' ~ 'FL0001589',
      facname == 'Mosaic - Bonnie' ~ 'FL0000523',
      facname == 'Mosaic - Four Corners' ~ 'FL0036412',
      facname == 'Mosaic - Ft. Lonesome' ~ 'FL0033332',
      facname == 'Mosaic - Green Bay' ~ 'FL0000752',
      facname == 'Mosaic - Hookers Prairie' ~ 'FL0033294',
      facname == 'Mosaic - Kingsford' ~ 'FL0000256',
      facname == 'Mosaic - Mulberry Phospho Stack' ~ 'FL0334944',
      facname == 'Mosaic - Mulberry Plant' ~ 'FL0000671',
      facname == 'Mosaic - New Wales Chemical Plant' ~ 'FL0036421',
      facname == 'Mosaic - Nichols Mine' ~ 'FL0030139',
      facname == 'Mosaic - Plant City' ~ 'FL0000078',
      facname == 'Mosaic - Port Sutton' ~ 'FL0000264',
      facname == 'Mosaic - Riverview' ~ 'FL0000761',
      facname == 'Mosaic - Riverview Stack Closure' ~ 'FL0177130',
      facname == 'Mosaic - South Pierce' ~ 'FL0000370',
      facname == 'Mosaic - Tampa Ammonia Terminal' ~ 'FL0187313',
      facname == 'Mosaic - Tampa Marine Terminal' ~ 'FL0166057',
      facname == 'TECO - Bayside (fka Gannon)' ~ 'FL0000809',
      facname == 'TECO - Big Bend' ~ 'FL0000817',
      facname == 'Trademark Nitrogen Corporation' ~ 'FL0000647',
      facname == 'Yara North America, Inc.' ~ 'FL0038652'
    )
  ) |>
  mutate(
    facid = case_when(
      permit == 'FL0000078' ~ '4029P20023',
      permit == 'FL0000124' ~ '4041P20001',
      permit == 'FL0000132' ~ 'FL0000132',
      permit == 'FL0000256' ~ 'FL0000256',
      permit == 'FL0000264' ~ '4029P20045',
      permit == 'FL0000370' ~ 'FL0000370',
      permit == 'FL0000523' ~ 'FL0000523',
      permit == 'FL0000647' ~ '4029P20048',
      permit == 'FL0000671' ~ '4053P20111',
      permit == 'FL0000752' ~ '4053P20061',
      permit == 'FL0000761' ~ '4029P20038',
      permit == 'FL0000809' ~ '4029P20086',
      permit == 'FL0000817' ~ 'FL0000817',
      permit == 'FL0001589' ~ 'FL0001589',
      permit == 'FL0029653' ~ 'FL0029653',
      permit == 'FL0030139' ~ '4053P20098',
      permit == 'FL0032581' ~ '4053P20113',
      permit == 'FL0033294' ~ 'FL0033294 ',
      permit == 'FL0033332' ~ '4029P02755',
      permit == 'FL0034657' ~ '4029P20001',
      permit == 'FL0036412' ~ '4041P20020',
      permit == 'FL0036421' ~ 'FL0036421',
      permit == 'FL0037389' ~ '4029P20030',
      permit == 'FL0038652' ~ '4029P20069',
      permit == 'FL0122904' ~ 'FL0122904',
      permit == 'FL0132381' ~ 'FL0132381',
      permit == 'FL0160083' ~ '4053P20049',
      permit == 'FL0166057' ~ 'FL0166057',
      permit == 'FL0177130' ~ 'FL0177130',
      permit == 'FL0185833' ~ 'FL0185833',
      permit == 'FL0187313' ~ 'FL0187313',
      permit == 'FL0188651' ~ 'FL0188651',
      permit == 'FL0321486' ~ 'FL0321486',
      permit == 'FL0334944' ~ 'FL0334944',
      permit == 'FL0450600' ~ 'FL0450600'
    )
  ) |>
  mutate(
    coastco = case_when(
      permit == 'FL0000078' ~ '238',
      permit == 'FL0000124' ~ '687a',
      permit == 'FL0000132' ~ '543',
      permit == 'FL0000256' ~ '593',
      permit == 'FL0000264' ~ '528',
      permit == 'FL0000370' ~ '568',
      permit == 'FL0000523' ~ '515b',
      permit == 'FL0000647' ~ '381',
      permit == 'FL0000671' ~ '515b',
      permit == 'FL0000752' ~ '515b',
      permit == 'FL0000761' ~ '515',
      permit == 'FL0000809' ~ '495',
      permit == 'FL0000817' ~ '585a',
      permit == 'FL0001589' ~ '515b',
      permit == 'FL0029653' ~ '327',
      permit == 'FL0030139' ~ '533',
      permit == 'FL0032581' ~ '423',
      permit == 'FL0033294' ~ '568',
      permit == 'FL0033332' ~ '549a',
      permit == 'FL0034657' ~ '431',
      permit == 'FL0036412' ~ '660',
      permit == 'FL0036421' ~ '515b',
      permit == 'FL0037389' ~ '403',
      permit == 'FL0038652' ~ '528',
      permit == 'FL0122904' ~ '528',
      permit == 'FL0132381' ~ '549a',
      permit == 'FL0160083' ~ '565',
      permit == 'FL0166057' ~ '461',
      permit == 'FL0177130' ~ '539',
      permit == 'FL0185833' ~ '191a',
      permit == 'FL0187313' ~ '461',
      permit == 'FL0188651' ~ '191',
      permit == 'FL0321486' ~ '528',
      permit == 'FL0334944' ~ '515b',
      permit == 'FL0450600' ~ '504'
    )
  )

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

# add ips material loss
ipsmat <- tribble(
  ~bayseg, ~basin, ~entity, ~facname, ~source, ~entityshr, ~facnameshr, ~permit, ~facid,
  2, NA_character_, 'CSX',           'Rockport',                   'PS - Industrial - Material Losses',  'csx',     'rock',      NA_character_,  NA_character_,
  2, NA_character_, 'CSX',           'Newport',                    'PS - Industrial - Material Losses',  'csx',     'newp',      NA_character_,  NA_character_,
  2, NA_character_, 'Mosaic',        'Tampa Marine',               'PS - Industrial - Material Losses',  'mosaic',  'tampamar',  NA_character_,  NA_character_,
  2, NA_character_, 'Mosaic',        'Big Bend',                   'PS - Industrial - Material Losses',  'mosaic',  'bigbend',   NA_character_,  NA_character_,
  2, NA_character_, 'Mosaic',        'Riverview',                  'PS - Industrial - Material Losses',  'mosaic',  'riverview', NA_character_,  NA_character_,
  2, NA_character_, 'Kinder Morgan', 'Kinder Morgan Tampaplex',    'PS - Industrial - Material Losses',  'kinder',  'tampaplex', NA_character_,  NA_character_,
  2, NA_character_, 'Kinder Morgan', 'Kinder Morgan Port Sutton',  'PS - Industrial - Material Losses',  'kinder',  'portsutt',  NA_character_,  NA_character_,
  4, NA_character_, 'Kinder Morgan', 'Kinder Morgan Port Manatee', 'PS - Industrial - Material Losses',  'kinder',  'portmana',  NA_character_,  NA_character_,
)


# combine ips dps ipsmat
facilities <- bind_rows(ipsfac, dpsfac, ipsmat) |>
  arrange(entity, facname)

usethis::use_data(facilities, overwrite = TRUE)
