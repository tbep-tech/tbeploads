create_mock_epc_data <- function() {
  data.frame(
    StationNumber = c(105, 113, 114, 132, 141, 138, 142, 147),
    SampleTime = as.POSIXct(c("2021-01-15 10:00:00", "2021-01-20 11:00:00",
                              "2021-02-15 09:30:00", "2021-02-20 14:00:00",
                              "2021-03-15 08:00:00", "2021-03-20 13:00:00",
                              "2021-04-15 11:30:00", "2021-04-20 16:00:00")),
    Total_Nitrogen = c("2.5", "3.0", "2.8", "3.2", "2.1", "2.9", "3.1", "2.6"),
    Total_Phosphorus = c("0.20", "0.25", "0.18", "0.22", "0.16", "0.24", "0.21", "0.19"),
    Total_Suspended_Solids = c("30", "35", "28", "32", "26", "34", "31", "29"),
    BOD = c("4.5", "5.0", "4.2", "4.8", "4.1", "4.9", "5.1", "4.6"),
    stringsAsFactors = FALSE
  )
}

mock_read_importepc <- function(tmpfl, download_latest = TRUE) {
  return(create_mock_epc_data())
}

test_that("util_nps_fillwq returns correct data", {

  mancopth <- system.file("extdata", "nps_wq_manco.txt", package = "tbeploads")
  pincopth <- system.file("extdata", "nps_wq_pinco.txt", package = "tbeploads")

  mock_read_importepc <- mock(create_mock_epc_data())

  local_mocked_bindings(
    read_importepc = mock_read_importepc,
    .package = "tbeptools"
  )

  wq <- util_nps_getwq(
    mancopth = mancopth,
    pincopth = pincopth,
    verbose = FALSE
  )

  result <- util_nps_fillmiswq(wq)

  expect_type(result, "list")
  expect_true(all(c("basin", "yr", "mo", "tn_mgl", "tp_mgl", "tss_mgl", "bod_mgl") %in% names(result)))

})
