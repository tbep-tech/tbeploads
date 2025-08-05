data(tblu2023)
data(tbsoil)

usdasoil <- st_read('T:/05_GIS/TBEP/TBLOADS/USDA_SSURGO_CLIP_FIPS0902.shp')
tb_soil <- usdasoil |>
  select(hydgrp = SDV_Hydr_1) |>
  group_by(hydgrp) |>
  summarise() |>
  st_transform(crs = 6443)
tbbase <- util_nps_tbbase(tblu2023, tb_soil, gdal_path = "C:/OSGeo4W/bin", chunk_size = 1000)

save(tbbase, file = "data/tbbase.RData")

# ed <- readRDS(file = '~/Desktop/tbeploads/data/tb_base.rds')
# edsum <- ed |>
#   group_by(bay_seg, basin, drnfeat, entity, FLUCCSCODE, CLUCSID, IMPROVED, hydrgrp) |>
#   summarise(
#      area_ha = sum(area_ha, na.rm = T),
#     .groups = 'drop'
#   )
# toplo <- inner_join(tbbase, ed, by = c('bay_seg', 'basin', 'drnfeat', 'entity', 'FLUCCSCODE', 'CLUCSID', 'IMPROVED', 'hydgrp' = 'hydrgrp'))
