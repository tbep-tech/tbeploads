library(devtools)

devtools::load_all()

contdry <- util_gw_getcontour("dry", 2022)
save(contdry, file = "data/contdry.RData", compress = "xz")

contwet <- util_gw_getcontour("wet", 2022)
save(contwet, file = "data/contwet.RData", compress = "xz")
