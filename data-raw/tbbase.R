library(dplyr)
library(sf)

data(tblu2023)
data(tbsoil)

tbbase <- util_nps_tbbase(tblu2023, tbsoil, gdal_path = "C:/OSGeo4W/bin", chunk_size = 1000)

save(tbbase, file = "data/tbbase.RData")

# ed <- readRDS(file = '~/Desktop/tbeploads/data/tb_base.rds')
# edsum <- ed |>
#   group_by(bay_seg, basin, drnfeat, entity, FLUCCSCODE, CLUCSID, IMPROVED, hydrgrp) |>
#   summarise(
#      area_ha = sum(area_ha, na.rm = T),
#     .groups = 'drop'
#   )
# toplo <- inner_join(tbbase, ed, by = c('bay_seg', 'basin', 'drnfeat', 'entity', 'FLUCCSCODE', 'CLUCSID', 'IMPROVED', 'hydgrp' = 'hydrgrp'))
