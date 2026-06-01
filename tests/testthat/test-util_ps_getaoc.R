library(testthat)
library(mockery)

# ---- Test fixture ----------------------------------------------------------
# 2024 AOC OCULUS search export.  Contains 20 data rows:
#   12 monthly Part A docs (one per calendar month, some with duplicate filings)
#   3  annual (YR) Part A docs  <- must be excluded
#   5  other docs (non-"PART A" labels, e.g. "MARCH2024", "APRIL2024")  <- must be excluded
aoc_xlsx <- system.file("extdata/aoc2024search.xlsx", package = "tbeploads")

# ---- Helper: synthetic two-page DMR text ----------------------------------
# Returns a character vector of length 2 (pages) that matches the text layout
# .aoc_parse_pdf expects when pdftools::pdf_text() is called.
#
# Page 1: header + monitoring period + Flow Sample Measurement line
# Page 2: Nitrogen, Total Sample Measurement line
make_dmr_pages <- function(month_num, year, flow_val = "NOD", tn_val = "NOD") {
  from_date <- sprintf("%02d/01/%d", as.integer(month_num), as.integer(year))
  last_day  <- c(31L, 28L, 31L, 30L, 31L, 30L, 31L, 31L, 30L, 31L, 30L, 31L)[month_num]
  to_date   <- sprintf("%02d/%02d/%d", as.integer(month_num), last_day, as.integer(year))

  page1 <- paste(
    "DEPARTMENT OF ENVIRONMENTAL PROTECTION DISCHARGE MONITORING REPORT - PART A",
    paste0("COUNTY: POLK    MONITORING PERIOD: From: ", from_date, " To: ", to_date),
    "Sample",
    # Token 1="Flow"  2=daily-max  3=monthly-avg  4=no-exceedances  5+= freq/type
    sprintf("Flow          %s    %s    0  1 Continuous  Recording", flow_val, flow_val),
    "Measurement",
    "PARM Code 50050 P    Permit    Report    MGD",
    sep = "\n"
  )

  page2 <- paste(
    # Token 1="Nitrogen,"  2="Total"  3=concentration  4=no-ex  5+= freq/type
    sprintf("Nitrogen, Total    %s    0  1 Per discharge   Grab", tn_val),
    "Measurement",
    sep = "\n"
  )

  c(page1, page2)
}

# ---- Helper: parse stub that infers month from the PDF filename ------------
# Used in integration tests where each PDF is saved as "<MON>.pdf".
parse_pdf_from_filename <- function(path) {
  month_lu <- setNames(
    1:12, c("JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC")
  )
  mo_str <- toupper(sub("\\.pdf$", "", basename(path)))
  mo     <- unname(month_lu[mo_str])
  data.frame(yr = 2024L, mo = mo, adf_mgd = 0, tn_mgl = NA_real_,
             stringsAsFactors = FALSE)
}

# ===========================================================================
# .aoc_extract_guids
# ===========================================================================

test_that(".aoc_extract_guids returns one row per monthly Part A document", {
  skip_if(!nzchar(aoc_xlsx), "aoc2024search.xlsx fixture not installed")

  result <- tbeploads:::.aoc_extract_guids(aoc_xlsx, 2024)

  expect_s3_class(result, "data.frame")
  # 2024 search has exactly one MO PART A doc per calendar month
  expect_equal(nrow(result), 12L)
  expect_equal(sort(result$month_num), 1:12)
  expect_true(all(c("guid", "month_str", "month_num", "subject") %in% names(result)))
})

test_that(".aoc_extract_guids excludes annual (YR) and non-Part-A documents", {
  skip_if(!nzchar(aoc_xlsx), "aoc2024search.xlsx fixture not installed")

  result <- tbeploads:::.aoc_extract_guids(aoc_xlsx, 2024)

  expect_true(all(grepl("\\bMO\\b",     result$subject, perl = TRUE)))
  expect_true(all(grepl("\\bPART A\\b", result$subject, perl = TRUE)))
  expect_false(any(grepl("\\bYR\\b",    result$subject, perl = TRUE)))
})

test_that(".aoc_extract_guids uses the most-recently filed doc when a month has duplicates", {
  skip_if(!nzchar(aoc_xlsx), "aoc2024search.xlsx fixture not installed")

  result <- tbeploads:::.aoc_extract_guids(aoc_xlsx, 2024)

  # January 2024 has one MO PART A row in the fixture (row 2, guid 38.1270870.1).
  # Rows 5/6/8 are JAN YR (annual) and must be excluded.
  jan <- result[result$month_num == 1L, ]
  expect_equal(nrow(jan), 1L)
  expect_equal(jan$guid, "38.1270870.1")
})

test_that(".aoc_extract_guids returns zero rows when year has no matching documents", {
  skip_if(!nzchar(aoc_xlsx), "aoc2024search.xlsx fixture not installed")

  result <- tbeploads:::.aoc_extract_guids(aoc_xlsx, 1999)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0L)
})

# ===========================================================================
# .aoc_parse_pdf
# ===========================================================================

test_that(".aoc_parse_pdf returns correct structure", {
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw(1L), tmp)

  local_mocked_bindings(
    pdf_text = function(pdf, ...) make_dmr_pages(1L, 2025L),
    .package = "pdftools"
  )

  result <- tbeploads:::.aoc_parse_pdf(tmp)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1L)
  expect_equal(names(result), c("yr", "mo", "adf_mgd", "tn_mgl"))
})

test_that(".aoc_parse_pdf sets adf_mgd = 0 and tn_mgl = NA for NOD month", {
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw(1L), tmp)

  local_mocked_bindings(
    pdf_text = function(pdf, ...) make_dmr_pages(1L, 2025L, "NOD", "NOD"),
    .package = "pdftools"
  )

  result <- tbeploads:::.aoc_parse_pdf(tmp)

  expect_equal(result$yr,      2025L)
  expect_equal(result$mo,      1L)
  expect_equal(result$adf_mgd, 0)
  expect_true(is.na(result$tn_mgl))
})

test_that(".aoc_parse_pdf correctly extracts numeric flow and TN values", {
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw(1L), tmp)

  local_mocked_bindings(
    pdf_text = function(pdf, ...) make_dmr_pages(5L, 2024L, "0.389", "3.8"),
    .package = "pdftools"
  )

  result <- tbeploads:::.aoc_parse_pdf(tmp)

  expect_equal(result$yr,      2024L)
  expect_equal(result$mo,      5L)
  expect_equal(result$adf_mgd, 0.389)
  expect_equal(result$tn_mgl,  3.8)
})

test_that(".aoc_parse_pdf derives month from monitoring period, not from filename", {
  # A file named "JAN.pdf" whose internal monitoring period is February —
  # the real-world case for AOC 2025 where the OCULUS 'JAN MO' label
  # corresponds to a February monitoring period.
  tmp <- file.path(tempdir(), "JAN.pdf")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw(1L), tmp)

  local_mocked_bindings(
    pdf_text = function(pdf, ...) make_dmr_pages(2L, 2025L, "0.586", "NOD"),
    .package = "pdftools"
  )

  result <- tbeploads:::.aoc_parse_pdf(tmp)

  expect_equal(result$mo, 2L)   # February from the PDF, not January from the filename
})

# ===========================================================================
# util_ps_getaoc (integration)
# ===========================================================================

test_that("util_ps_getaoc returns a data frame with correct columns and row count", {
  skip_if(!nzchar(aoc_xlsx), "aoc2024search.xlsx fixture not installed")

  stub(util_ps_getaoc, ".aoc_oculus_login",  function() NULL)
  stub(util_ps_getaoc, ".aoc_download_pdf",
       function(guid, dest_path, session_handle) TRUE)
  stub(util_ps_getaoc, ".aoc_parse_pdf", parse_pdf_from_filename)

  result <- util_ps_getaoc(yr = 2024, search_xlsx = aoc_xlsx, quiet = TRUE)

  expect_s3_class(result, "data.frame")
  expect_equal(names(result), c("yr", "mo", "adf_mgd", "tn_mgl"))
  expect_equal(nrow(result), 12L)
  expect_true(all(result$yr == 2024L))
})

test_that("util_ps_getaoc output is sorted by month", {
  skip_if(!nzchar(aoc_xlsx), "aoc2024search.xlsx fixture not installed")

  stub(util_ps_getaoc, ".aoc_oculus_login",  function() NULL)
  stub(util_ps_getaoc, ".aoc_download_pdf",
       function(guid, dest_path, session_handle) TRUE)
  stub(util_ps_getaoc, ".aoc_parse_pdf", parse_pdf_from_filename)

  result <- util_ps_getaoc(yr = 2024, search_xlsx = aoc_xlsx, quiet = TRUE)

  expect_equal(result$mo, 1:12)
})

test_that("util_ps_getaoc preserves discharge values from .aoc_parse_pdf", {
  skip_if(!nzchar(aoc_xlsx), "aoc2024search.xlsx fixture not installed")

  stub(util_ps_getaoc, ".aoc_oculus_login",  function() NULL)
  stub(util_ps_getaoc, ".aoc_download_pdf",
       function(guid, dest_path, session_handle) TRUE)
  stub(util_ps_getaoc, ".aoc_parse_pdf", function(path) {
    month_lu <- setNames(
      1:12, c("JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC")
    )
    mo <- unname(month_lu[toupper(sub("\\.pdf$", "", basename(path)))])
    # May has a real discharge; all others are NOD
    if (identical(mo, 5L))
      data.frame(yr = 2024L, mo = 5L, adf_mgd = 0.389, tn_mgl = 3.8,
                 stringsAsFactors = FALSE)
    else
      data.frame(yr = 2024L, mo = mo,  adf_mgd = 0,     tn_mgl = NA_real_,
                 stringsAsFactors = FALSE)
  })

  result <- util_ps_getaoc(yr = 2024, search_xlsx = aoc_xlsx, quiet = TRUE)

  may <- result[result$mo == 5L, ]
  expect_equal(may$adf_mgd, 0.389)
  expect_equal(may$tn_mgl,  3.8)

  other <- result[result$mo != 5L, ]
  expect_true(all(other$adf_mgd == 0))
  expect_true(all(is.na(other$tn_mgl)))
})

test_that("util_ps_getaoc writes an xlsx file when out_file is specified", {
  skip_if(!nzchar(aoc_xlsx), "aoc2024search.xlsx fixture not installed")

  out <- tempfile(fileext = ".xlsx")
  on.exit(unlink(out), add = TRUE)

  stub(util_ps_getaoc, ".aoc_oculus_login",  function() NULL)
  stub(util_ps_getaoc, ".aoc_download_pdf",
       function(guid, dest_path, session_handle) TRUE)
  stub(util_ps_getaoc, ".aoc_parse_pdf", parse_pdf_from_filename)

  util_ps_getaoc(yr = 2024, search_xlsx = aoc_xlsx, out_file = out, quiet = TRUE)

  expect_true(file.exists(out))
  written <- readxl::read_xlsx(out, sheet = "AOC_DMR")
  expect_equal(names(written), c("yr", "mo", "adf_mgd", "tn_mgl"))
  expect_equal(nrow(written), 12L)
})

test_that("util_ps_getaoc stops with an error for a missing search_xlsx path", {
  expect_error(
    util_ps_getaoc(yr = 2025, search_xlsx = "nonexistent_file.xlsx")
  )
})
