devtools::load_all()

data(tbbase)
data(rcclucsid)
data(emc)

nps_factors <- util_aa_npsfactors(tbbase, rcclucsid, emc)

usethis::use_data(nps_factors, overwrite = TRUE)
