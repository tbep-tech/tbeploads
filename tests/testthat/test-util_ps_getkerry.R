library(testthat)
library(mockery)

# ---- Test fixture ----------------------------------------------------------
# 2025 Kerry I&F OCULUS search export.  Contains 15 data rows:
#   12 monthly Part A docs (one per calendar month)
#   1  revision of the April Part A doc (must be preferred over the original)
#   2  annual (YR) Part A docs  <- must be excluded
kerry_xlsx <- system.file("extdata/kerry2025search.xlsx", package = "tbeploads")

# ---- Helper: synthetic Part A DMR text ------------------------------------
# Returns a character vector of length 1 (single page of concatenated text)
# matching the layout .kerry_parse_pdf expects from pdftools::pdf_text().
make_kerry_page <- function(month_num, year,
                             flow_moavg = "1.7", flow_dlymx = "1.3",
                             bod_val = "<2", tn_val = "0.59", tp_val = "0.15") {
  from_date <- sprintf("%02d/01/%d", as.integer(month_num), as.integer(year))
  last_day  <- c(31L, 28L, 31L, 30L, 31L, 30L, 31L, 31L, 30L, 31L, 30L, 31L)[month_num]
  to_date   <- sprintf("%02d/%02d/%d", as.integer(month_num), last_day, as.integer(year))

  paste(
    "DEPARTMENT OF ENVIRONMENTAL PROTECTION DISCHARGE MONITORING REPORT - PART A",
    paste0("COUNTY: HILLSBOROUGH    MONITORING PERIOD: From: ", from_date, " To: ", to_date),
    sprintf("Flow          0.9    0.7    0  1 Continuous  Meter"),
    "Measurement",
    "PARM Code 50050 1    Permit    Report    Report    MGD",
    "Mon. Site: FLW-1    Requirement    (Mo Avg)   (Daily Mx)",
    sprintf("Flow          0.9    0.5    0  1 Continuous  Meter"),
    "Measurement",
    "PARM Code 50050 P    Permit    Report    Report    MGD",
    "Mon. Site: FLW-2    Requirement    (Mo Avg)   (Daily Mx)",
    sprintf("Flow          %s    %s    0  1 Continuous  Calculated", flow_moavg, flow_dlymx),
    "Measurement",
    "PARM Code 50050 Q    Permit    Report    Report    MGD",
    "Mon. Site: FLW-3    Requirement    (Mo Avg)   (Daily Mx)",
    sprintf("Nitrogen, Total          %s    0  1 Monthly  Grab", tn_val),
    "Measurement",
    "PARM Code 00600 1    Permit    Report    mg/L",
    "Mon. Site: EFF-1    Requirement    (Daily Mx)",
    # Second "Nitrogen, Total" block (calculated load, ton/yr) -- must be ignored
    "Nitrogen, Total          0.09    0.79    0  1 Monthly  Calculated",
    "Measurement",
    "PARM Code 00600 P    Permit    1.95    1.3    ton/yr",
    "Mon. Site: EFF-1    Requirement   (Annl Tot)   (5 Yr Avg)",
    sprintf("BOD, Carbonaceous 5 day, 20C          %s    0  1 Monthly  Grab", bod_val),
    "Measurement",
    "PARM Code 80082 1    Permit    Report    mg/L",
    "Mon. Site: EFF-1    Requirement    (Daily Mx)",
    sprintf("Phosphorus, Total (as P)          %s    0  1 Monthly  Grab", tp_val),
    "Measurement",
    "PARM Code 00665 1    Permit    Report    mg/L",
    "Mon. Site: EFF-1    Requirement    (Daily Mx)",
    sep = "\n"
  )
}

# ---- Helper: parse stub that infers month from the PDF filename ------------
parse_pdf_from_filename <- function(path) {
  month_lu <- setNames(
    1:12, c("JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC")
  )
  mo_str <- toupper(sub("\\.pdf$", "", basename(path)))
  mo     <- unname(month_lu[mo_str])
  data.frame(yr = 2025L, mo = mo, outfall = "FLW-3", flow_mgd = 0,
             bod_mgl = NA_real_, tss_mgl = NA_real_, tn_mgl = NA_real_,
             tp_mgl = NA_real_, stringsAsFactors = FALSE)
}

# ===========================================================================
# .kerry_extract_guids
# ===========================================================================

test_that(".kerry_extract_guids returns one row per monthly Part A document", {
  skip_if(!nzchar(kerry_xlsx), "kerry2025search.xlsx fixture not installed")

  result <- tbeploads:::.kerry_extract_guids(kerry_xlsx, 2025)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 12L)
  expect_equal(sort(result$month_num), 1:12)
  expect_true(all(c("guid", "month_str", "month_num", "subject") %in% names(result)))
})

test_that(".kerry_extract_guids excludes annual (YR) documents", {
  skip_if(!nzchar(kerry_xlsx), "kerry2025search.xlsx fixture not installed")

  result <- tbeploads:::.kerry_extract_guids(kerry_xlsx, 2025)

  expect_true(all(grepl("\\bMO\\b",     result$subject, perl = TRUE)))
  expect_true(all(grepl("\\bPART A\\b", result$subject, perl = TRUE)))
  expect_false(any(grepl("\\bYR\\b",    result$subject, perl = TRUE)))
})

test_that(".kerry_extract_guids prefers a revision-prefixed subject over the original", {
  skip_if(!nzchar(kerry_xlsx), "kerry2025search.xlsx fixture not installed")

  result <- tbeploads:::.kerry_extract_guids(kerry_xlsx, 2025)

  apr <- result[result$month_num == 4L, ]
  expect_equal(nrow(apr), 1L)
  expect_true(grepl("^DMR \\(R\\)", apr$subject))
})

test_that(".kerry_extract_guids returns zero rows when year has no matching documents", {
  skip_if(!nzchar(kerry_xlsx), "kerry2025search.xlsx fixture not installed")

  result <- tbeploads:::.kerry_extract_guids(kerry_xlsx, 1999)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0L)
})

# ===========================================================================
# .kerry_parse_pdf
# ===========================================================================

test_that(".kerry_parse_pdf returns correct structure", {
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw(1L), tmp)

  local_mocked_bindings(
    pdf_text = function(pdf, ...) make_kerry_page(1L, 2025L),
    .package = "pdftools"
  )

  result <- tbeploads:::.kerry_parse_pdf(tmp)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1L)
  expect_equal(names(result),
               c("yr", "mo", "outfall", "flow_mgd", "bod_mgl", "tss_mgl", "tn_mgl", "tp_mgl"))
})

test_that(".kerry_parse_pdf extracts FLW-3 Mo Avg flow, not FLW-1/FLW-2", {
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw(1L), tmp)

  local_mocked_bindings(
    pdf_text = function(pdf, ...) make_kerry_page(1L, 2025L, flow_moavg = "1.7", flow_dlymx = "1.3"),
    .package = "pdftools"
  )

  result <- tbeploads:::.kerry_parse_pdf(tmp)

  expect_equal(result$outfall,  "FLW-3")
  expect_equal(result$flow_mgd, 1.7)   # Mo Avg, not the 0.9 values from FLW-1/FLW-2
})

test_that(".kerry_parse_pdf strips '<' from below-detection BOD without halving", {
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw(1L), tmp)

  local_mocked_bindings(
    pdf_text = function(pdf, ...) make_kerry_page(1L, 2025L, bod_val = "<2"),
    .package = "pdftools"
  )

  result <- tbeploads:::.kerry_parse_pdf(tmp)

  expect_equal(result$bod_mgl, 2)
})

test_that(".kerry_parse_pdf extracts the TN concentration block, not the TN load block", {
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw(1L), tmp)

  local_mocked_bindings(
    pdf_text = function(pdf, ...) make_kerry_page(1L, 2025L, tn_val = "0.59"),
    .package = "pdftools"
  )

  result <- tbeploads:::.kerry_parse_pdf(tmp)

  # 0.59 (concentration, mg/L) not 0.09 or 0.79 (the ton/yr load block values)
  expect_equal(result$tn_mgl, 0.59)
})

test_that(".kerry_parse_pdf always returns NA for tss_mgl", {
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw(1L), tmp)

  local_mocked_bindings(
    pdf_text = function(pdf, ...) make_kerry_page(1L, 2025L),
    .package = "pdftools"
  )

  result <- tbeploads:::.kerry_parse_pdf(tmp)

  expect_true(is.na(result$tss_mgl))
})

test_that(".kerry_parse_pdf derives month and year from the monitoring period", {
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw(1L), tmp)

  local_mocked_bindings(
    pdf_text = function(pdf, ...) make_kerry_page(9L, 2025L),
    .package = "pdftools"
  )

  result <- tbeploads:::.kerry_parse_pdf(tmp)

  expect_equal(result$yr, 2025L)
  expect_equal(result$mo, 9L)
})

# ===========================================================================
# util_ps_getkerry (integration)
# ===========================================================================

test_that("util_ps_getkerry returns a data frame with correct columns and row count", {
  skip_if(!nzchar(kerry_xlsx), "kerry2025search.xlsx fixture not installed")

  stub(util_ps_getkerry, ".kerry_oculus_login",  function() NULL)
  stub(util_ps_getkerry, ".kerry_download_pdf",
       function(guid, dest_path, session_handle) TRUE)
  stub(util_ps_getkerry, ".kerry_parse_pdf", parse_pdf_from_filename)

  result <- util_ps_getkerry(yr = 2025, search_xlsx = kerry_xlsx, quiet = TRUE)

  expect_s3_class(result, "data.frame")
  expect_equal(names(result),
               c("yr", "mo", "outfall", "flow_mgd", "bod_mgl", "tss_mgl", "tn_mgl", "tp_mgl"))
  expect_equal(nrow(result), 12L)
  expect_true(all(result$yr == 2025L))
})

test_that("util_ps_getkerry output is sorted by month", {
  skip_if(!nzchar(kerry_xlsx), "kerry2025search.xlsx fixture not installed")

  stub(util_ps_getkerry, ".kerry_oculus_login",  function() NULL)
  stub(util_ps_getkerry, ".kerry_download_pdf",
       function(guid, dest_path, session_handle) TRUE)
  stub(util_ps_getkerry, ".kerry_parse_pdf", parse_pdf_from_filename)

  result <- util_ps_getkerry(yr = 2025, search_xlsx = kerry_xlsx, quiet = TRUE)

  expect_equal(result$mo, 1:12)
})

test_that("util_ps_getkerry writes an xlsx file when out_file is specified", {
  skip_if(!nzchar(kerry_xlsx), "kerry2025search.xlsx fixture not installed")

  out <- tempfile(fileext = ".xlsx")
  on.exit(unlink(out), add = TRUE)

  stub(util_ps_getkerry, ".kerry_oculus_login",  function() NULL)
  stub(util_ps_getkerry, ".kerry_download_pdf",
       function(guid, dest_path, session_handle) TRUE)
  stub(util_ps_getkerry, ".kerry_parse_pdf", parse_pdf_from_filename)

  util_ps_getkerry(yr = 2025, search_xlsx = kerry_xlsx, out_file = out, quiet = TRUE)

  expect_true(file.exists(out))
  written <- readxl::read_xlsx(out, sheet = "Kerry_DMR")
  expect_equal(nrow(written), 12L)
})

test_that("util_ps_getkerry stops with an error for a missing search_xlsx path", {
  expect_error(
    util_ps_getkerry(yr = 2025, search_xlsx = "nonexistent_file.xlsx")
  )
})

test_that("util_ps_getkerry skips a month and warns when download fails", {
  skip_if(!nzchar(kerry_xlsx), "kerry2025search.xlsx fixture not installed")

  call_n <- 0L
  stub(util_ps_getkerry, ".kerry_oculus_login", function() NULL)
  stub(util_ps_getkerry, ".kerry_download_pdf", function(guid, dest_path, session_handle) {
    call_n <<- call_n + 1L
    call_n > 1L
  })
  stub(util_ps_getkerry, ".kerry_parse_pdf", parse_pdf_from_filename)

  result <- suppressWarnings(
    util_ps_getkerry(yr = 2025, search_xlsx = kerry_xlsx, quiet = TRUE)
  )
  expect_equal(nrow(result), 11L)
})

test_that("util_ps_getkerry retains PDFs when pdf_dir is supplied", {
  skip_if(!nzchar(kerry_xlsx), "kerry2025search.xlsx fixture not installed")

  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  stub(util_ps_getkerry, ".kerry_oculus_login", function() NULL)
  stub(util_ps_getkerry, ".kerry_download_pdf",
       function(guid, dest_path, session_handle) {
         writeBin(raw(1L), dest_path)
         TRUE
       })
  stub(util_ps_getkerry, ".kerry_parse_pdf", parse_pdf_from_filename)

  util_ps_getkerry(yr = 2025, search_xlsx = kerry_xlsx,
                    pdf_dir = tmp_dir, quiet = TRUE)

  expect_gt(length(list.files(tmp_dir, pattern = "\\.pdf$")), 0L)
})
