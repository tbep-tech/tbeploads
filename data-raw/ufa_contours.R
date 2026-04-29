library(devtools)
library(terra)

devtools::load_all()

# SpatRaster objects must be wrapped with terra::wrap() before save() so they
# serialise correctly as package data.  Functions that consume contdry/contwet
# (util_gw_grad, util_gw_showgrad) call terra::unwrap() automatically when
# they receive a PackedSpatRaster.

pot_dry <- util_gw_getcontour("dry", 2022)
contdry <- terra::wrap(pot_dry)
save(contdry, file = "data/contdry.RData", compress = "xz")

pot_wet <- util_gw_getcontour("wet", 2022)
contwet <- terra::wrap(pot_wet)
save(contwet, file = "data/contwet.RData", compress = "xz")
