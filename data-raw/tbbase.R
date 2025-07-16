data(tblu2023)
data(tbsoil)
tbbase <- util_nps_tbbase(tblu2023, tbsoil, gdal_path = "C:/OSGeo4W/bin", chunk_size = 1000)

save(tbbase, file = "data/tbbase.RData")
