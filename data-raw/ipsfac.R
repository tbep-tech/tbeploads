library(haven)
library(dplyr)
library(here)

pth <- 'T:/03_BOARDS_COMMITTEES/05_TBNMC/2022_RA_Update/01_FUNDING_OUT/DELIVERABLES/TO-9/datastick_deliverables/2017-2021LUEntityLoads/'

ipsfac <- read_sas(paste0(pth, '2017-2021IPSMonthlyEntityBasin/ips1721monthentbas.sas7bdat')) %>%
  select(bayseg, basin = BASIN, entity, facname, source = source2) %>%
  distinct() %>%
  arrange(entity, facname)

usethis::use_data(ipsfac, overwrite = TRUE)
