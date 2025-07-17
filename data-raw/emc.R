emc <- haven::read_sas("./data-raw/JEI_PRIOR/npspol3.sas7bdat") |>
  dplyr::rename(
    clucsid = CLUCSID,
    mean_tn = MEAN_TN,
    mean_tp = MEAN_TP,
    mean_tss = MEAN_TSS,
    mean_bod = BOD
  )

usethis::use_data(emc, overwrite = TRUE)
