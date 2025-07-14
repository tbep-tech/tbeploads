library(tidyverse)
# # get combined subwatershed, drainage basin, jurisdiction, land use, and soils data
# data(tblu2023)
# data(tbsoil)
# tbbase <- util_nps_tbbase(tbsubshed, tbjuris, tblu2023, tbsoil, gdal_path = "C:/OSGeo4W/bin", chunk_size = 1000)

# ungaged
data(tbbase)
data(rain)
mancopth <- system.file('extdata/nps_wq_manco.txt', package = 'tbeploads')
pincopth <- system.file('extdata/nps_wq_pinco.txt', package = 'tbeploads')
lakemanpth <- system.file('extdata/nps_extflow_lakemanatee.xlsx', package = 'tbeploads')
tampabypth <- system.file('extdata/nps_extflow_tampabypass.xlsx', package = 'tbeploads')
bellshlpth <- system.file('extdata/nps_extflow_bellshoals.xls', package = 'tbeploads')

nps_ungaged <- anlz_nps_ungaged(yrrng = c('2021-01-01', '2023-12-31'),
                                tbbase, rain, lakemanpth, tampabypth, bellshlpth, verbose = T)

nps_gaged <- anlz_nps_gaged(yrrng = c('2021-01-01', '2023-12-31'), mancopth = mancopth,
                          pincopth = pincopth, lakemanpth = lakemanpth, tampabypth = tampabypth,
                          bellshlpth = bellshlpth, verbose = T) |>
  dplyr::select(
    basin,
    yr,
    mo,
    oh2oload = h20load,
    otnload = tnload,
    otpload = tpload,
    otssload = tssload,
    obodload = bodload
  )

# get verna data, fill missing w/ five-year avg
fl <- system.file('extdata/verna-raw.csv', package = 'tbeploads')
verna <- util_prepverna(fl)

nps2 <- nps_ungaged |>
  dplyr::left_join(verna, by = c("yr", "mo")) |>
  dplyr::mutate(
    tnload_a = tnload,
    tnload_b = tnload,
    tpload_a = tpload,
    tpload_b = tpload,
    h2oload2 = h2oload * 1000
  ) |>
  dplyr::mutate(
    tnload_a = dplyr::case_when(
      clucsid %in% c(18, 20) ~ 0,
      TRUE ~ tnload_a
    ),
    tnload_b = dplyr::case_when(
      clucsid %in% c(18, 20) ~ h2oload2 * tn_ppt * 3.04 * 0.001 * 0.001,
      TRUE ~ tnload_b
    ),
    tpload_a = dplyr::case_when(
      clucsid %in% c(18, 20) ~ 0,
      TRUE ~ tpload_a
    ),
    tpload_b = dplyr::case_when(
      clucsid %in% c(18, 20) ~ h2oload2 * tp_ppt * 3.04 * 0.001 * 0.001,
      TRUE ~ tpload_b
    )
  ) |>
  dplyr::group_by(yr, mo, bay_seg, basin) |>
  dplyr::summarise(
    h2oload = sum(h2oload, na.rm=TRUE),
    tnload = sum(tnload, na.rm=TRUE),
    tpload = sum(tpload, na.rm=TRUE),
    tssload = sum(tssload, na.rm=TRUE),
    bodload = sum(bodload, na.rm=TRUE),
    tnload_a = sum(tnload_a, na.rm = TRUE),
    tnload_b = sum(tnload_b, na.rm = TRUE),
    tpload_a = sum(tpload_a, na.rm = TRUE),
    tpload_b = sum(tpload_b, na.rm = TRUE),
    area = sum(area, na.rm=TRUE),
    bas_area = dplyr::first(bas_area),
    .groups = 'drop'
  )

nps <- nps2 |>
  dplyr::filter(!basin %in% c("02303000", "02303330", "02301000", "02301300")) |> # Remove nested basins
  dplyr::mutate(basin = ifelse(basin == "02299950", "LMANATEE", basin)) |>  # Rename basin
  dplyr::group_by(yr, mo, bay_seg, basin) |>
  dplyr::summarise(
    h2oload = sum(h2oload, na.rm=TRUE),
    tnload = sum(tnload, na.rm=TRUE),
    tpload = sum(tpload, na.rm=TRUE),
    tssload = sum(tssload, na.rm=TRUE),
    bodload = sum(bodload, na.rm=TRUE),
    tnload_a = sum(tnload_a, na.rm = TRUE),
    tnload_b = sum(tnload_b, na.rm = TRUE),
    tpload_a = sum(tpload_a, na.rm = TRUE),
    tpload_b = sum(tpload_b, na.rm = TRUE),
    area = sum(area, na.rm=TRUE),
    bas_area = dplyr::first(bas_area),
    .groups = 'drop'
    )

estloads <- nps |>
  dplyr::mutate(
    eh2oload = h2oload,
    etnload = tnload,
    etpload = tpload,
    etnloada = tnload_a,
    etploada = tpload_a,
    etnloadb = tnload_b,
    etploadb = tpload_b,
    etssload = tssload,
    ebodload = bodload
  ) |>
  dplyr::select(
    yr, mo, basin, bay_seg, bas_area,
    eh2oload, etnload, etpload, etssload, ebodload,
    etnloada, etploada, etnloadb, etploadb
  )

npsfinal <- estloads |>
  dplyr::full_join(nps_gaged, by = c("yr", "mo", "basin")) |>
  dplyr::mutate(
    h2oload = ifelse(is.na(oh2oload), eh2oload, oh2oload),
    tnload = ifelse(is.na(otnload), etnload, otnload),
    tpload = ifelse(is.na(otpload), etpload, otpload),
    tssload = ifelse(is.na(otssload), etssload, otssload),
    bodload = ifelse(is.na(obodload), ebodload, obodload),
    tnload_a = ifelse(is.na(otnload), etnloada, otnload),
    tpload_a = ifelse(is.na(otpload), etploada, otpload),
    tnload_b = ifelse(is.na(otnload), etnloadb, otnload),
    tpload_b = ifelse(is.na(otpload), etploadb, otpload),
    source = "NPS"
  ) |>
  dplyr::mutate(
    segment = dplyr::case_when(
      basin %in% c("LTARPON", "02306647", "02307000", "02307359", "206-1") ~ 1,
      basin %in% c("TBYPASS", "02301750", "206-2", "02300700") ~ 2,
      basin %in% c("02301000", "02301300", "02303000", "02303330") ~ 2,
      basin %in% c("02301500", "02301695", "204-2") ~ 2,
      basin %in% c("02304500", "205-2") ~ 2,
      basin %in% c("02300500", "02300530", "203-3") ~ 3,
      basin %in% c("206-3C", "206-3E", "206-3W") ~ 3,
      basin == "206-4" ~ 4,
      basin == "206-5" | basin == "207-5" & bay_seg == 55 ~ 55,
      basin == "207-5" & bay_seg == 5 ~ 5,
      basin == "206-6" ~ 6,
      basin %in% c("EVERSRES", "LMANATEE", "202-7", "02299950") ~ 7,
      TRUE ~ NA
    ),
    majbasin = dplyr::case_when(
      basin %in% c("LTARPON", "02306647", "02307000", "02307359", "206-1") ~ "Coastal Old Tampa Bay",
      basin %in% c("TBYPASS", "02301750", "206-2", "02300700") ~ "Coastal Hillsborough Bay",
      basin %in% c("02301000", "02301300", "02303000", "02303330") ~ "Error!!!",
      basin %in% c("02301500", "02301695", "204-2") ~ "Alafia River",
      basin %in% c("02304500", "205-2") ~ "Hillsborough River",
      basin %in% c("02300500", "02300530", "203-3") ~ "Little Manatee River",
      basin %in% c("206-3C", "206-3E", "206-3W") ~ "Coastal Middle Tampa Bay",
      basin == "206-4" ~ "Coastal Lower Tampa Bay",
      basin == "206-5" | basin == "207-5" & bay_seg == 55 ~ "Boca Ciega Bay South",
      basin == "207-5" & bay_seg == 5 ~ "Boca Ciega Bay North",
      basin == "206-6" ~ "Terra Ceia Bay",
      basin %in% c("EVERSRES", "LMANATEE", "202-7", "02299950") ~ "Manatee River",
      TRUE ~ NA
    )
  ) |>
  dplyr::select(
    yr, mo, segment, majbasin, bay_seg, basin, bas_area, source,
    h2oload, tnload, tpload, tssload, bodload,
    tnload_a, tpload_a, tnload_b, tpload_b
  )

out <- npsfinal |>
  dplyr::group_by(yr, mo, bay_seg, basin) |>
  dplyr::summarise(
    h2oload = sum(h2oload, na.rm=TRUE),
    tnload = sum(tnload, na.rm=TRUE),
    tpload = sum(tpload, na.rm=TRUE),
    tssload = sum(tssload, na.rm=TRUE),
    bodload = sum(bodload, na.rm=TRUE),
    bas_area = sum(bas_area, na.rm=TRUE),
    segment = dplyr::first(segment),
    majbasin = dplyr::first(majbasin),
    source = dplyr::first(source)
  ) |>
  dplyr::arrange(segment, basin, yr)
