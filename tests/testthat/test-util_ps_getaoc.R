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

test_that("util_ps_getaoc skips a month and warns when download fails", {
  skip_if(!nzchar(aoc_xlsx), "aoc2024search.xlsx fixture not installed")

  # Make download fail for January (first doc) only; all others succeed.
  call_n <- 0L
  stub(util_ps_getaoc, ".aoc_oculus_login", function() NULL)
  stub(util_ps_getaoc, ".aoc_download_pdf", function(guid, dest_path, session_handle) {
    call_n <<- call_n + 1L
    call_n > 1L   # FALSE (fail) for the first call, TRUE (ok) for the rest
  })
  stub(util_ps_getaoc, ".aoc_parse_pdf", parse_pdf_from_filename)

  result <- suppressWarnings(
    util_ps_getaoc(yr = 2024, search_xlsx = aoc_xlsx, quiet = TRUE)
  )
  # One month was skipped; 11 rows expected
  expect_equal(nrow(result), 11L)
})

test_that("util_ps_getaoc skips a month and warns when parse fails", {
  skip_if(!nzchar(aoc_xlsx), "aoc2024search.xlsx fixture not installed")

  call_n <- 0L
  stub(util_ps_getaoc, ".aoc_oculus_login", function() NULL)
  stub(util_ps_getaoc, ".aoc_download_pdf",
       function(guid, dest_path, session_handle) TRUE)
  stub(util_ps_getaoc, ".aoc_parse_pdf", function(path) {
    call_n <<- call_n + 1L
    if (call_n == 1L) stop("simulated parse error")
    parse_pdf_from_filename(path)
  })

  expect_warning(
    result <- util_ps_getaoc(yr = 2024, search_xlsx = aoc_xlsx, quiet = TRUE),
    "simulated parse error"
  )
  expect_equal(nrow(result), 11L)
})

test_that("util_ps_getaoc retains PDFs when pdf_dir is supplied", {
  skip_if(!nzchar(aoc_xlsx), "aoc2024search.xlsx fixture not installed")

  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  stub(util_ps_getaoc, ".aoc_oculus_login", function() NULL)
  stub(util_ps_getaoc, ".aoc_download_pdf",
       function(guid, dest_path, session_handle) {
         writeBin(raw(1L), dest_path)
         TRUE
       })
  stub(util_ps_getaoc, ".aoc_parse_pdf", parse_pdf_from_filename)

  util_ps_getaoc(yr = 2024, search_xlsx = aoc_xlsx,
                 pdf_dir = tmp_dir, quiet = TRUE)

  expect_gt(length(list.files(tmp_dir, pattern = "\\.pdf$")), 0L)
})

test_that("util_ps_getaoc prints progress messages when quiet = FALSE", {
  skip_if(!nzchar(aoc_xlsx), "aoc2024search.xlsx fixture not installed")

  stub(util_ps_getaoc, ".aoc_oculus_login", function() NULL)
  stub(util_ps_getaoc, ".aoc_download_pdf",
       function(guid, dest_path, session_handle) TRUE)
  stub(util_ps_getaoc, ".aoc_parse_pdf", parse_pdf_from_filename)

  expect_output(
    util_ps_getaoc(yr = 2024, search_xlsx = aoc_xlsx, quiet = FALSE),
    "monthly Part A"
  )
})

test_that("util_ps_getaoc stops with an error when no documents match the requested year", {
  skip_if(!nzchar(aoc_xlsx), "aoc2024search.xlsx fixture not installed")

  expect_error(
    util_ps_getaoc(yr = 1999, search_xlsx = aoc_xlsx, quiet = TRUE),
    "No monthly Part A documents found for year"
  )
})

test_that("util_ps_getaoc prints a cached message and skips download for an existing valid PDF", {
  skip_if(!nzchar(aoc_xlsx), "aoc2024search.xlsx fixture not installed")

  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)
  # January's PDF already exists and is large enough to be treated as cached
  writeBin(raw(6000L), file.path(tmp_dir, "JAN.pdf"))

  download_called_for <- character(0)
  stub(util_ps_getaoc, ".aoc_oculus_login", function() NULL)
  stub(util_ps_getaoc, ".aoc_download_pdf", function(guid, dest_path, session_handle) {
    download_called_for <<- c(download_called_for, basename(dest_path))
    TRUE
  })
  stub(util_ps_getaoc, ".aoc_parse_pdf", parse_pdf_from_filename)

  expect_output(
    util_ps_getaoc(yr = 2024, search_xlsx = aoc_xlsx, pdf_dir = tmp_dir, quiet = FALSE),
    "(cached)", fixed = TRUE
  )
  expect_false("JAN.pdf" %in% download_called_for)
})

test_that("util_ps_getaoc prints a FAILED message when quiet = FALSE and download fails", {
  skip_if(!nzchar(aoc_xlsx), "aoc2024search.xlsx fixture not installed")

  call_n <- 0L
  stub(util_ps_getaoc, ".aoc_oculus_login", function() NULL)
  stub(util_ps_getaoc, ".aoc_download_pdf", function(guid, dest_path, session_handle) {
    call_n <<- call_n + 1L
    call_n > 1L   # fail only the first month; the rest succeed
  })
  stub(util_ps_getaoc, ".aoc_parse_pdf", parse_pdf_from_filename)

  suppressWarnings(
    expect_output(
      util_ps_getaoc(yr = 2024, search_xlsx = aoc_xlsx, quiet = FALSE),
      "FAILED"
    )
  )
})

test_that("util_ps_getaoc prints a note listing missing months when quiet = FALSE", {
  skip_if(!nzchar(aoc_xlsx), "aoc2024search.xlsx fixture not installed")

  call_n <- 0L
  stub(util_ps_getaoc, ".aoc_oculus_login", function() NULL)
  stub(util_ps_getaoc, ".aoc_download_pdf",
       function(guid, dest_path, session_handle) TRUE)
  stub(util_ps_getaoc, ".aoc_parse_pdf", function(path) {
    call_n <<- call_n + 1L
    if (call_n == 1L) stop("simulated parse error")
    parse_pdf_from_filename(path)
  })

  expect_warning(
    expect_output(
      result <- util_ps_getaoc(yr = 2024, search_xlsx = aoc_xlsx, quiet = FALSE),
      "no Part A document found for month"
    ),
    "simulated parse error"
  )
  expect_equal(nrow(result), 11L)
})

test_that("util_ps_getaoc prints a message when writing the out_file", {
  skip_if(!nzchar(aoc_xlsx), "aoc2024search.xlsx fixture not installed")

  out <- tempfile(fileext = ".xlsx")
  on.exit(unlink(out), add = TRUE)

  stub(util_ps_getaoc, ".aoc_oculus_login",  function() NULL)
  stub(util_ps_getaoc, ".aoc_download_pdf",
       function(guid, dest_path, session_handle) TRUE)
  stub(util_ps_getaoc, ".aoc_parse_pdf", parse_pdf_from_filename)

  expect_output(
    util_ps_getaoc(yr = 2024, search_xlsx = aoc_xlsx, out_file = out, quiet = FALSE),
    "Writing results to"
  )
})

test_that("util_ps_getaoc prints a message when retaining PDFs in pdf_dir", {
  skip_if(!nzchar(aoc_xlsx), "aoc2024search.xlsx fixture not installed")

  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  stub(util_ps_getaoc, ".aoc_oculus_login", function() NULL)
  stub(util_ps_getaoc, ".aoc_download_pdf",
       function(guid, dest_path, session_handle) {
         writeBin(raw(1L), dest_path)
         TRUE
       })
  stub(util_ps_getaoc, ".aoc_parse_pdf", parse_pdf_from_filename)

  expect_output(
    util_ps_getaoc(yr = 2024, search_xlsx = aoc_xlsx, pdf_dir = tmp_dir, quiet = FALSE),
    "PDFs retained in"
  )
})

# ===========================================================================
# .aoc_extract_guids -- error handling and fallback row assignment
# ===========================================================================

# Builds a corrupted copy of `src_xlsx` whose HYPERLINK formulas have been
# moved out of column A (by rewriting every `r="A..."` cell reference in the
# worksheet XML to `r="Z..."`), forcing the primary column-A-anchored GUID
# regex to fail to match so `.xxx_extract_guids()` falls back to positional
# row assignment from document order.  The GUID text itself remains inline in
# the (relocated) formula, so the fallback's plain `guid=` scan still finds it.
make_relocated_guid_xlsx <- function(src_xlsx) {
  tmpdir <- tempfile()
  dir.create(tmpdir)
  utils::unzip(src_xlsx, exdir = tmpdir)

  sheet_path <- file.path(tmpdir, "xl", "worksheets", "sheet1.xml")
  txt <- paste(readLines(sheet_path, warn = FALSE), collapse = "")
  txt <- gsub('r="A', 'r="Z', txt, fixed = TRUE)
  writeLines(txt, sheet_path)

  out <- tempfile(fileext = ".xlsx")
  old_wd <- setwd(tmpdir)
  on.exit(setwd(old_wd), add = TRUE)
  all_files <- list.files(".", recursive = TRUE, all.files = TRUE, no.. = TRUE)
  utils::zip(out, files = all_files, flags = "-q")
  out
}

# Builds a corrupted copy of `src_xlsx` with no `xl/worksheets/sheet1.xml`
# entry at all, to exercise the "cannot locate worksheet XML" error path.
make_no_worksheet_xlsx <- function(src_xlsx) {
  tmpdir <- tempfile()
  dir.create(tmpdir)
  utils::unzip(src_xlsx, exdir = tmpdir)
  file.remove(file.path(tmpdir, "xl", "worksheets", "sheet1.xml"))

  out <- tempfile(fileext = ".xlsx")
  old_wd <- setwd(tmpdir)
  on.exit(setwd(old_wd), add = TRUE)
  all_files <- list.files(".", recursive = TRUE, all.files = TRUE, no.. = TRUE)
  utils::zip(out, files = all_files, flags = "-q")
  out
}

test_that(".aoc_extract_guids stops when the worksheet XML cannot be located", {
  skip_if(!nzchar(aoc_xlsx), "aoc2024search.xlsx fixture not installed")

  bad_xlsx <- make_no_worksheet_xlsx(aoc_xlsx)
  on.exit(unlink(bad_xlsx), add = TRUE)

  expect_error(
    tbeploads:::.aoc_extract_guids(bad_xlsx, 2024),
    "Cannot locate worksheet XML"
  )
})

test_that(".aoc_extract_guids falls back to positional row assignment when column A pattern is absent", {
  skip_if(!nzchar(aoc_xlsx), "aoc2024search.xlsx fixture not installed")

  fallback_xlsx <- make_relocated_guid_xlsx(aoc_xlsx)
  on.exit(unlink(fallback_xlsx), add = TRUE)

  result <- tbeploads:::.aoc_extract_guids(fallback_xlsx, 2024)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 12L)
  expect_equal(sort(result$month_num), 1:12)
})

# ===========================================================================
# .aoc_parse_pdf -- error branches
# ===========================================================================

test_that(".aoc_parse_pdf stops when no monitoring period line is present", {
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw(1L), tmp)

  local_mocked_bindings(
    pdf_text = function(pdf, ...) c("no period info here", "page 2"),
    .package = "pdftools"
  )

  expect_error(
    tbeploads:::.aoc_parse_pdf(tmp),
    "Cannot find monitoring period"
  )
})

test_that(".aoc_parse_pdf stops when no Flow measurement line is present", {
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw(1L), tmp)

  local_mocked_bindings(
    pdf_text = function(pdf, ...) c(
      "COUNTY: POLK    MONITORING PERIOD: From: 01/01/2025 To: 01/31/2025",
      "page 2, no Flow line here"
    ),
    .package = "pdftools"
  )

  expect_error(
    tbeploads:::.aoc_parse_pdf(tmp),
    "Cannot find Flow measurement line"
  )
})

test_that(".aoc_parse_pdf returns NA tn_mgl when no Nitrogen line is present", {
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw(1L), tmp)

  page1 <- paste(
    "COUNTY: POLK    MONITORING PERIOD: From: 01/01/2025 To: 01/31/2025",
    "Sample",
    "Flow          0.5    0.5    0  1 Continuous  Recording",
    "Measurement",
    "PARM Code 50050 P    Permit    Report    MGD",
    sep = "\n"
  )
  local_mocked_bindings(
    pdf_text = function(pdf, ...) c(page1, "page 2, no nitrogen data at all"),
    .package = "pdftools"
  )

  result <- tbeploads:::.aoc_parse_pdf(tmp)

  expect_true(is.na(result$tn_mgl))
})

# ===========================================================================
# .aoc_oculus_login
# ===========================================================================

test_that(".aoc_oculus_login performs a two-step login and returns a handle when no redirect occurs", {
  login_fn <- tbeploads:::.aoc_oculus_login
  urls_hit <- character(0)

  stub(login_fn, "httr::GET", function(url, ...) {
    urls_hit <<- c(urls_hit, url)
    structure(list(fake_body = "<html>logged in, no redirect</html>"), class = "response")
  })
  stub(login_fn, "httr::content", function(r, type) charToRaw(r$fake_body))

  h <- login_fn()

  expect_s3_class(h, "handle")
  expect_length(urls_hit, 2L)
  expect_true(grepl("action=doPublicLogin", urls_hit[2]))
})

test_that(".aoc_oculus_login follows a window.location redirect when present", {
  login_fn <- tbeploads:::.aoc_oculus_login
  urls_hit <- character(0)

  stub(login_fn, "httr::GET", function(url, ...) {
    urls_hit <<- c(urls_hit, url)
    if (length(urls_hit) == 2L)
      structure(list(fake_body = 'window.location = "/Oculus/servlet/redirected"'),
                class = "response")
    else
      structure(list(fake_body = "ok"), class = "response")
  })
  stub(login_fn, "httr::content", function(r, type) charToRaw(r$fake_body))

  h <- login_fn()

  expect_s3_class(h, "handle")
  expect_length(urls_hit, 3L)
  expect_true(grepl("/Oculus/servlet/redirected$", urls_hit[3]))
})

# ===========================================================================
# .aoc_download_pdf
# ===========================================================================

test_that(".aoc_download_pdf downloads and writes a valid PDF (primary filename pattern)", {
  dl_fn <- tbeploads:::.aoc_download_pdf
  dest  <- tempfile(fileext = ".pdf")
  on.exit(unlink(dest), add = TRUE)

  hitlist_body <- '<input name="_FILE_NAME_38.123.1" type="hidden" value="storedfile.pdf"/>'
  call_n <- 0L
  stub(dl_fn, "httr::GET", function(url, ...) {
    call_n <<- call_n + 1L
    if (call_n == 1L) structure(list(body = hitlist_body), class = "response")
    else structure(list(body = "PDFDATA"), class = "response")
  })
  stub(dl_fn, "httr::content", function(r, type) {
    if (identical(r$body, "PDFDATA"))
      c(as.raw(c(0x25, 0x50, 0x44, 0x46)), charToRaw("...rest of pdf..."))
    else
      charToRaw(r$body)
  })

  ok <- dl_fn("38.123.1", dest, NULL)

  expect_true(ok)
  expect_true(file.exists(dest))
})

test_that(".aoc_download_pdf uses the fallback filename pattern when the primary pattern fails", {
  dl_fn <- tbeploads:::.aoc_download_pdf
  dest  <- tempfile(fileext = ".pdf")
  on.exit(unlink(dest), add = TRUE)

  # No `type="hidden"` attribute so the primary lookbehind pattern cannot match,
  # but the fallback context + value="....pdf" pattern still can.
  hitlist_body <- '_FILE_NAME_38.123.1" value="storedfile.pdf"/>'
  call_n <- 0L
  stub(dl_fn, "httr::GET", function(url, ...) {
    call_n <<- call_n + 1L
    if (call_n == 1L) structure(list(body = hitlist_body), class = "response")
    else structure(list(body = "PDFDATA"), class = "response")
  })
  stub(dl_fn, "httr::content", function(r, type) {
    if (identical(r$body, "PDFDATA"))
      c(as.raw(c(0x25, 0x50, 0x44, 0x46)), charToRaw("...rest of pdf..."))
    else
      charToRaw(r$body)
  })

  ok <- dl_fn("38.123.1", dest, NULL)

  expect_true(ok)
  expect_true(file.exists(dest))
})

test_that(".aoc_download_pdf returns FALSE when no filename can be extracted", {
  dl_fn <- tbeploads:::.aoc_download_pdf
  dest  <- tempfile(fileext = ".pdf")

  stub(dl_fn, "httr::GET", function(url, ...)
    structure(list(body = "<html>no matching hidden field here</html>"), class = "response"))
  stub(dl_fn, "httr::content", function(r, type) charToRaw(r$body))

  ok <- dl_fn("38.123.1", dest, NULL)

  expect_false(ok)
  expect_false(file.exists(dest))
})

test_that(".aoc_download_pdf returns FALSE when the downloaded content is not a valid PDF", {
  dl_fn <- tbeploads:::.aoc_download_pdf
  dest  <- tempfile(fileext = ".pdf")

  hitlist_body <- '<input name="_FILE_NAME_38.123.1" type="hidden" value="storedfile.pdf"/>'
  call_n <- 0L
  stub(dl_fn, "httr::GET", function(url, ...) {
    call_n <<- call_n + 1L
    if (call_n == 1L) structure(list(body = hitlist_body), class = "response")
    else structure(list(body = "not a pdf"), class = "response")
  })
  stub(dl_fn, "httr::content", function(r, type) charToRaw(r$body))

  ok <- dl_fn("38.123.1", dest, NULL)

  expect_false(ok)
  expect_false(file.exists(dest))
})
