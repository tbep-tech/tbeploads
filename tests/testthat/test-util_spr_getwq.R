# Helpers -------------------------------------------------------------------

# Build an NDJSON string from a list of named records
make_ndjson <- function(...) {
  recs <- list(...)
  lines <- vapply(recs, function(r) {
    jsonlite::toJSON(r, auto_unbox = TRUE)
  }, character(1))
  paste(lines, collapse = "\n")
}

# Default NDJSON for a single spring (one TN and TP observation per year)
default_ndjson <- function(yrs = 2022:2024) {
  recs <- unlist(lapply(yrs, function(y) {
    list(
      list(parameter = "TN_mgl",
           activityStartDate = paste0(y, "-03-15T00:00:00"),
           resultValue = 0.50),
      list(parameter = "TP_mgl",
           activityStartDate = paste0(y, "-03-15T00:00:00"),
           resultValue = 0.05)
    )
  }), recursive = FALSE)
  do.call(make_ndjson, recs)
}

# Mock EPC data for Sulphur Spring station 174
make_mock_epc <- function() {
  months <- seq.Date(as.Date("2022-01-15"), as.Date("2024-12-15"), by = "month")
  data.frame(
    StationNumber          = 174L,
    SampleTime             = as.POSIXct(months),
    Total_Nitrogen         = as.character(round(runif(length(months), 0.4, 0.8), 2)),
    Total_Phosphorus       = as.character(round(runif(length(months), 0.03, 0.08), 3)),
    Total_Suspended_Solids = as.character(round(runif(length(months), 2.0, 8.0), 1)),
    stringsAsFactors       = FALSE
  )
}

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

test_that("util_spr_getwq returns the expected structure", {

  # Lithia returns TN+TP, Buckhorn returns TN+TP only
  ndjson_lithia   <- default_ndjson(2022:2024)
  ndjson_buckhorn <- default_ndjson(2022:2024)
  call_n <- 0L

  mock_GET <- function(url, query = NULL, ...) {
    call_n <<- call_n + 1L
    list(station = query$stationIds)
  }
  mock_status_code <- function(x) 200L
  mock_content <- function(x, as = NULL, encoding = NULL) {
    if (identical(x$station, "17805")) ndjson_lithia else ndjson_buckhorn
  }
  mock_read_importepc <- function(tmpfl, download_latest = TRUE) make_mock_epc()

  local_mocked_bindings(
    GET          = mock_GET,
    status_code  = mock_status_code,
    content      = mock_content,
    .package     = "httr"
  )
  local_mocked_bindings(
    read_importepc = mock_read_importepc,
    .package       = "tbeptools"
  )

  result <- util_spr_getwq(c(2022, 2024), verbose = FALSE)

  expect_s3_class(result, "data.frame")

  expected_cols <- c("spring", "yr", "tn_mgl", "tp_mgl", "tss_mgl")
  expect_true(all(expected_cols %in% names(result)))

  # Three springs present
  expect_setequal(unique(result$spring), c("Lithia", "Buckhorn", "Sulphur"))

  # One row per spring per year (3 springs x 3 years = 9 rows)
  expect_equal(nrow(result), 9L)

})

test_that("util_spr_getwq returns NA for TSS when API has no TSS records", {

  ndjson_no_tss <- default_ndjson(2022:2024)  # only TN + TP

  mock_GET         <- function(...) list()
  mock_status_code <- function(x) 200L
  mock_content     <- function(x, as = NULL, encoding = NULL) ndjson_no_tss
  mock_read_importepc <- function(tmpfl, download_latest = TRUE) make_mock_epc()

  local_mocked_bindings(
    GET         = mock_GET,
    status_code = mock_status_code,
    content     = mock_content,
    .package    = "httr"
  )
  local_mocked_bindings(
    read_importepc = mock_read_importepc,
    .package       = "tbeptools"
  )

  result <- util_spr_getwq(c(2022, 2024), verbose = FALSE)

  # Lithia and Buckhorn TSS should be NA (no TSS in mock NDJSON)
  lithia_tss   <- result$tss_mgl[result$spring == "Lithia"]
  buckhorn_tss <- result$tss_mgl[result$spring == "Buckhorn"]
  expect_true(all(is.na(lithia_tss)))
  expect_true(all(is.na(buckhorn_tss)))

})

test_that("util_spr_getwq year range filters EPC (Sulphur) data correctly", {

  # API mock returns only data within the requested range (as the real API would)
  ndjson_in_range <- default_ndjson(2022:2024)

  # EPC raw data spans a wider range; the function should filter it client-side
  epc_wide <- data.frame(
    StationNumber          = 174L,
    SampleTime             = as.POSIXct(
      seq.Date(as.Date("2020-01-15"), as.Date("2026-12-15"), by = "month")
    ),
    Total_Nitrogen         = "0.60",
    Total_Phosphorus       = "0.06",
    Total_Suspended_Solids = "5.0",
    stringsAsFactors       = FALSE
  )

  local_mocked_bindings(
    GET         = function(...) list(),
    status_code = function(x) 200L,
    content     = function(x, as = NULL, encoding = NULL) ndjson_in_range,
    .package    = "httr"
  )
  local_mocked_bindings(
    read_importepc = function(tmpfl, download_latest = TRUE) epc_wide,
    .package       = "tbeptools"
  )

  result <- util_spr_getwq(c(2022, 2024), verbose = FALSE)

  # All years should be within the requested range
  expect_true(all(result$yr >= 2022 & result$yr <= 2024))

  # Sulphur should have exactly 3 rows (one per year), filtered from the wider EPC set
  expect_equal(sum(result$spring == "Sulphur"), 3L)

})

test_that("util_spr_getwq converts NaN TSS to NA", {

  # EPC data with no valid TSS values for one year
  epc_no_tss <- data.frame(
    StationNumber          = 174L,
    SampleTime             = as.POSIXct(c("2022-06-15", "2023-06-15")),
    Total_Nitrogen         = c("0.55", "0.60"),
    Total_Phosphorus       = c("0.05", "0.06"),
    Total_Suspended_Solids = c(NA_character_, "4.0"),
    stringsAsFactors       = FALSE
  )

  local_mocked_bindings(
    GET         = function(...) list(),
    status_code = function(x) 200L,
    content     = function(x, as = NULL, encoding = NULL) default_ndjson(2022:2024),
    .package    = "httr"
  )
  local_mocked_bindings(
    read_importepc = function(tmpfl, download_latest = TRUE) epc_no_tss,
    .package       = "tbeptools"
  )

  result <- util_spr_getwq(c(2022, 2024), verbose = FALSE)

  sulphur_rows <- result[result$spring == "Sulphur", ]

  # 2022 had NA TSS → mean(NA, na.rm=TRUE) = NaN → converted to NA
  tss_2022 <- sulphur_rows$tss_mgl[sulphur_rows$yr == 2022]
  expect_true(is.na(tss_2022))

  # 2023 had one valid TSS = 4.0
  tss_2023 <- sulphur_rows$tss_mgl[sulphur_rows$yr == 2023]
  expect_equal(tss_2023, 4.0)

})

test_that("util_spr_getwq stops on non-200 API response", {

  local_mocked_bindings(
    GET         = function(...) list(),
    status_code = function(x) 500L,
    .package    = "httr"
  )

  expect_error(
    util_spr_getwq(c(2022, 2024), verbose = FALSE),
    "Water Atlas API request failed"
  )

})

test_that("util_spr_getwq prints progress messages when verbose = TRUE", {

  local_mocked_bindings(
    GET         = function(...) list(),
    status_code = function(x) 200L,
    content     = function(x, as = NULL, encoding = NULL) default_ndjson(2022:2024),
    .package    = "httr"
  )
  local_mocked_bindings(
    read_importepc = function(tmpfl, download_latest = TRUE) make_mock_epc(),
    .package       = "tbeptools"
  )

  expect_output(
    util_spr_getwq(c(2022, 2024), verbose = TRUE),
    "Lithia and Buckhorn"
  )
  expect_output(
    util_spr_getwq(c(2022, 2024), verbose = TRUE),
    "Sulphur Spring"
  )

})
