library(testthat)
library(mockery)

# ---- Fixtures --------------------------------------------------------------
macdill_xlsx <- system.file("extdata/macdill2025search.xlsx", package = "tbeploads")

# ---- Helpers: synthetic PDF text ------------------------------------------

# Builds a minimal multi-page Part A text string mimicking the MacDill layout.
# Each "page" is one monitoring group section (R-001, R-002, R-003).
# flow_val / bod_val / tss_val may be "NOD", "ANC", "<2", or a number.
# tn_val is for R-003 only.
make_part_a_pages <- function(month_num, year,
                               r1_flow = "NOD", r2_flow = "NOD", r3_flow = "NOD",
                               r1_bod  = "NOD", r2_bod  = "NOD", r3_bod  = "NOD",
                               r1_tss  = "NOD", r2_tss  = "NOD", r3_tss  = "NOD",
                               r3_tn   = "NOD") {
  from_date <- sprintf("%02d/01/%d", as.integer(month_num), as.integer(year))
  to_date   <- sprintf("%02d/28/%d", as.integer(month_num), as.integer(year))

  make_section <- function(group, flow_val, bod_val, tss_val, tn_val = NULL) {
    # Flow block: Case A (Sample on previous line, values on Flow line)
    flow_block <- paste(
      sprintf("MONITORING GROUP:     %s", group),
      paste0("COUNTY: HILLSBOROUGH    MONITORING PERIOD: From: ", from_date, " To: ", to_date),
      "Sample",
      sprintf("Flow          %s    %s    0  1 Continuous  Meter", flow_val, flow_val),
      "Measurement",
      "PARM Code 50050 1    Permit    Report    MGD",
      "Mon. Site: FLW-01    Requirement    (Mo Avg)",
      sep = "\n"
    )

    # BOD block: Case B (parameter + "Sample" on same line, values on next)
    bod_block <- paste(
      "BOD, Carbonaceous 5 day,          Sample",
      sprintf("%s    %s    %s    0  1 Weekly  Composite", bod_val, bod_val, bod_val),
      "20C                               Measurement",
      "PARM Code 80082 A    Permit    60.0    45.0    30.0    mg/L",
      "Mon. Site: EFA-01    Requirement    (Maximum)   (Wkly Avg)   (Mo Avg)",
      sep = "\n"
    )

    # TSS block: Maximum for R-001/R-003; Mo Avg (triple) for R-002
    tss_block <- if (group == "R-002") {
      paste(
        "Sample",
        sprintf("Solids, Total Suspended    %s    %s    %s    0  2 weeks  Grab",
                tss_val, tss_val, tss_val),
        "Measurement",
        "PARM Code 00530 A    Permit    60.0    45.0    30.0    mg/L",
        "Mon. Site: EFA-02    Requirement    (Maximum)   (Wkly Avg)   (Mo Avg)",
        sep = "\n"
      )
    } else {
      paste(
        "Sample",
        sprintf("Solids, Total Suspended    %s    0  4 Days/Week  Grab", tss_val),
        "Measurement",
        "PARM Code 00530 B    Permit    5.0    mg/L",
        "Mon. Site: EFB-01    Requirement    (Maximum)",
        sep = "\n"
      )
    }

    # TN block (R-003 only)
    tn_block <- if (!is.null(tn_val)) {
      paste(
        "Sample",
        sprintf("Nitrogen, Nitrate, Total (as N)    %s    0  1 Bi-weekly  Grab", tn_val),
        "Measurement",
        "PARM Code 00620 A    Permit    12.0    mg/L",
        "Mon. Site: EFA-03    Requirement    (Maximum)",
        sep = "\n"
      )
    } else ""

    paste(flow_block, bod_block, tss_block, tn_block, sep = "\n")
  }

  c(make_section("R-001", r1_flow, r1_bod, r1_tss),
    make_section("R-002", r2_flow, r2_bod, r2_tss),
    make_section("R-003", r3_flow, r3_bod, r3_tss, r3_tn))
}

# Builds a mock two-page pdf_data() list for a Part B PDF.
# Page 1: "Mon. Site" header with flow/BOD/TSS columns.
# Page 2: "Code" header with TN (00620) column (biweekly, so most days NA).
# `daily` fields: day, r1_flow, r2_flow, r3_flow, bod_r1, bod_r23, tss_r13,
#   tss_r2, tn_r3 (NA = not measured that day).
make_part_b_page <- function(daily_data) {
  make_word <- function(text, x, y)
    data.frame(text = as.character(text), x = as.integer(x), y = as.integer(y),
               space = FALSE, width = 10L, height = 9L, stringsAsFactors = FALSE)

  # Page 1 x-positions (Mon. Site row)
  X1 <- list(site = 82L, flw01 = 108L, cal01 = 153L, flw02 = 194L, flw03 = 235L,
              efa01 = 280L, efa02 = 327L, efb01a = 376L, efb01b = 425L,
              efa02b = 473L, efa01b = 521L)
  # Page 2 x-position for TN (00620) from Code row
  TN_X <- 420L

  # ---- Page 1 ---------------------------------------------------------------
  hdr1 <- do.call(rbind, list(
    make_word("DAILY SAMPLE RESULTS - PART B", 200L, 50L),
    make_word("Site",   X1$site,   172L),
    make_word("FLW-01", X1$flw01,  172L), make_word("CAL-01", X1$cal01,  172L),
    make_word("FLW-02", X1$flw02,  172L), make_word("FLW-03", X1$flw03,  172L),
    make_word("EFA-01", X1$efa01,  172L), make_word("EFA-02", X1$efa02,  172L),
    make_word("EFB-01", X1$efb01a, 172L), make_word("EFB-01", X1$efb01b, 172L),
    make_word("EFA-02", X1$efa02b, 172L), make_word("EFA-01", X1$efa01b, 172L)
  ))
  p1_rows <- do.call(rbind, lapply(seq_along(daily_data$day), function(i) {
    dy    <- daily_data$day[i]
    row_y <- 183L + (i - 1L) * 11L
    w <- make_word(dy, 72L, row_y)
    add <- function(val, x) if (!is.na(val)) rbind(w, make_word(val, x+1L, row_y)) else w
    w <- add(daily_data$r1_flow[i], X1$cal01)
    w <- add(daily_data$r2_flow[i], X1$flw02)
    w <- add(daily_data$r3_flow[i], X1$flw03)
    if (!is.null(daily_data$bod_r1)  && !is.na(daily_data$bod_r1[i]))
      w <- rbind(w, make_word(daily_data$bod_r1[i],  X1$efa01  + 1L, row_y))
    if (!is.null(daily_data$bod_r23) && !is.na(daily_data$bod_r23[i]))
      w <- rbind(w, make_word(daily_data$bod_r23[i], X1$efa02  + 1L, row_y))
    if (!is.null(daily_data$tss_r13) && !is.na(daily_data$tss_r13[i]))
      w <- rbind(w, make_word(daily_data$tss_r13[i], X1$efb01b + 1L, row_y))
    if (!is.null(daily_data$tss_r2)  && !is.na(daily_data$tss_r2[i]))
      w <- rbind(w, make_word(daily_data$tss_r2[i],  X1$efa02b + 1L, row_y))
    w
  }))
  page1 <- rbind(hdr1, p1_rows)

  # ---- Page 2 (TN column at x=420) ----------------------------------------
  hdr2 <- make_word("Code",  77L, 175L)
  hdr2 <- rbind(hdr2, make_word("00620", TN_X, 175L))
  p2_rows <- do.call(rbind, lapply(seq_along(daily_data$day), function(i) {
    dy    <- daily_data$day[i]
    row_y <- 183L + (i - 1L) * 11L
    w <- make_word(dy, 72L, row_y)
    tn_val <- if (!is.null(daily_data$tn_r3) && !is.na(daily_data$tn_r3[i]))
                daily_data$tn_r3[i] else NA
    if (!is.na(tn_val)) w <- rbind(w, make_word(tn_val, TN_X + 1L, row_y))
    w
  }))
  page2 <- rbind(hdr2, p2_rows)

  list(page1, page2)
}

# ---- Helper: integration-test parse stub -----------------------------------
parse_parta_from_guid <- function(path) {
  # Returns a predictable 3-row Part A data frame; month inferred from filename.
  data.frame(outfall  = c("R-001","R-002","R-003"),
             flow_mgd = c(0.3, 0.01, 0.5),
             bod_mgl  = c(2.0, 3.0, 2.5),
             tss_mgl  = c(1.5, NA,  2.0),
             tn_mgl   = c(NA,  NA,  4.5),
             stringsAsFactors = FALSE)
}

parse_partb_from_guid <- function(path) {
  data.frame(outfall  = c("R-001","R-002","R-003"),
             flow_mgd = c(0.25, 0.015, 0.55),
             bod_mgl  = c(1.8,  2.5,   2.5),
             tss_mgl  = c(1.2,  1.0,   1.2),
             tn_mgl   = NA_real_,
             stringsAsFactors = FALSE)
}

# Part B fixture that includes a non-NA TN for R-003 (biweekly average).
parse_partb_with_tn_from_guid <- function(path) {
  data.frame(outfall  = c("R-001","R-002","R-003"),
             flow_mgd = c(0.25, 0.015, 0.55),
             bod_mgl  = c(1.8,  2.5,   2.5),
             tss_mgl  = c(1.2,  1.0,   1.2),
             tn_mgl   = c(NA_real_, NA_real_, 2.7),
             stringsAsFactors = FALSE)
}

# ===========================================================================
# .macdill_extract_guids
# ===========================================================================

test_that(".macdill_extract_guids returns only MO (non-YR) documents", {
  skip_if(!nzchar(macdill_xlsx), "macdill2025search.xlsx fixture not installed")

  result <- tbeploads:::.macdill_extract_guids(macdill_xlsx, 2025)

  expect_s3_class(result, "data.frame")
  expect_true(nrow(result) > 0L)
  expect_true(all(c("guid","subject","row") %in% names(result)))
  expect_false(any(grepl("\\bYR\\b", result$subject, perl = TRUE)))
  expect_true(all(grepl("\\bMO\\b", result$subject, perl = TRUE)))
})

test_that(".macdill_extract_guids returns both Part A and Part B labelled docs", {
  skip_if(!nzchar(macdill_xlsx), "macdill2025search.xlsx fixture not installed")

  result <- tbeploads:::.macdill_extract_guids(macdill_xlsx, 2025)

  # The 2025 XLSX contains docs labelled as both "PART A" and "PART B"
  has_parta <- any(grepl("PART A", result$subject, fixed = TRUE))
  has_partb <- any(grepl("PART B", result$subject, fixed = TRUE))
  expect_true(has_parta)
  expect_true(has_partb)
})

test_that(".macdill_extract_guids returns no duplicate GUIDs", {
  skip_if(!nzchar(macdill_xlsx), "macdill2025search.xlsx fixture not installed")

  result <- tbeploads:::.macdill_extract_guids(macdill_xlsx, 2025)

  expect_equal(length(unique(result$guid)), nrow(result))
})

test_that(".macdill_extract_guids returns zero rows for a year with no data", {
  skip_if(!nzchar(macdill_xlsx), "macdill2025search.xlsx fixture not installed")

  result <- tbeploads:::.macdill_extract_guids(macdill_xlsx, 1999)

  expect_equal(nrow(result), 0L)
})

# ===========================================================================
# .macdill_classify_pdf
# ===========================================================================

test_that(".macdill_classify_pdf detects Part A content and monitoring period", {
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw(1L), tmp)

  local_mocked_bindings(
    pdf_text = function(pdf, ...) {
      c(paste(
        "DEPARTMENT OF ENVIRONMENTAL PROTECTION DISCHARGE MONITORING REPORT - PART A",
        "COUNTY: HILLSBOROUGH    MONITORING PERIOD: From: 06/01/2025 To: 06/30/2025",
        sep = "\n"
      ))
    },
    .package = "pdftools"
  )

  info <- tbeploads:::.macdill_classify_pdf(tmp)

  expect_equal(info$type,  "partA")
  expect_equal(info$month, 6L)
  expect_equal(info$year,  2025L)
})

test_that(".macdill_classify_pdf detects Part B content and monitoring period", {
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw(1L), tmp)

  local_mocked_bindings(
    pdf_text = function(pdf, ...) {
      c(paste(
        "DAILY SAMPLE RESULTS - PART B",
        "Permit Number: FLA012124    Facility: MacDill AFB WWTP",
        "Monitoring Period    From:    8/1/2025    To:    8/31/2025",
        sep = "\n"
      ))
    },
    .package = "pdftools"
  )

  info <- tbeploads:::.macdill_classify_pdf(tmp)

  expect_equal(info$type,  "partB")
  expect_equal(info$month, 8L)
  expect_equal(info$year,  2025L)
})

test_that(".macdill_classify_pdf correctly extracts two-digit month (regression: greedy sub bug)", {
  # Month 11 (November) was previously parsed as month 1 because greedy .*
  # in sub() consumed the leading '1' of '11', leaving '1/01/2022'.
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw(1L), tmp)

  local_mocked_bindings(
    pdf_text = function(pdf, ...) {
      c(paste(
        "DEPARTMENT OF ENVIRONMENTAL PROTECTION DISCHARGE MONITORING REPORT - PART A",
        "COUNTY: HILLSBOROUGH    MONITORING PERIOD: From: 11/01/2022 To: 11/30/2022",
        sep = "\n"
      ))
    },
    .package = "pdftools"
  )

  info <- tbeploads:::.macdill_classify_pdf(tmp)

  expect_equal(info$type,  "partA")
  expect_equal(info$month, 11L)   # must be 11 (November), not 1 (January)
  expect_equal(info$year,  2022L)
})

test_that(".macdill_classify_pdf returns NULL for unrecognised content", {
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw(1L), tmp)

  local_mocked_bindings(
    pdf_text = function(pdf, ...) c("Something completely different"),
    .package = "pdftools"
  )

  expect_null(tbeploads:::.macdill_classify_pdf(tmp))
})

# ===========================================================================
# .macdill_parse_part_a
# ===========================================================================

test_that(".macdill_parse_part_a returns 3 rows with correct columns", {
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw(1L), tmp)

  local_mocked_bindings(
    pdf_text = function(pdf, ...) make_part_a_pages(2L, 2025L),
    .package = "pdftools"
  )

  result <- tbeploads:::.macdill_parse_part_a(tmp)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 3L)
  expect_equal(sort(result$outfall), c("R-001","R-002","R-003"))
  expect_true(all(c("flow_mgd","bod_mgl","tss_mgl","tn_mgl") %in% names(result)))
})

test_that(".macdill_parse_part_a sets flow_mgd = 0 for NOD outfalls", {
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw(1L), tmp)

  local_mocked_bindings(
    pdf_text = function(pdf, ...) make_part_a_pages(1L, 2025L),
    .package = "pdftools"
  )

  result <- tbeploads:::.macdill_parse_part_a(tmp)

  expect_true(all(result$flow_mgd == 0))
})

test_that(".macdill_parse_part_a extracts numeric values correctly", {
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw(1L), tmp)

  local_mocked_bindings(
    pdf_text = function(pdf, ...) make_part_a_pages(
      5L, 2025L,
      r1_flow = "0.300", r2_flow = "0.025", r3_flow = "0.640",
      r1_bod  = "6.1",   r2_bod  = "2.2",   r3_bod  = "2.2",
      r1_tss  = "5.6",   r2_tss  = "4.0",   r3_tss  = "5.2",
      r3_tn   = "2.0"
    ),
    .package = "pdftools"
  )

  result <- tbeploads:::.macdill_parse_part_a(tmp)

  r1 <- result[result$outfall == "R-001", ]
  r3 <- result[result$outfall == "R-003", ]

  expect_equal(r1$flow_mgd, 0.300)
  expect_equal(r1$bod_mgl,  6.1)
  expect_equal(r3$tn_mgl,   2.0)
  # TN is NA for R-001 and R-002
  expect_true(is.na(result[result$outfall == "R-002", "tn_mgl"]))
  expect_true(is.na(r1$tn_mgl))
})

# ===========================================================================
# .macdill_apply_sub
# ===========================================================================

test_that(".macdill_apply_sub applies <1 and <2 substitution rules", {
  expect_equal(tbeploads:::.macdill_apply_sub(c("<1", "<2", "3.5")), c(0.5, 1.0, 3.5))
})

test_that(".macdill_apply_sub treats NOD and ANC as NA", {
  result <- tbeploads:::.macdill_apply_sub(c("NOD", "ANC", NA))
  expect_true(all(is.na(result)))
})

test_that(".macdill_apply_sub handles decimal variants <1.0 and <2.0", {
  expect_equal(tbeploads:::.macdill_apply_sub(c("<1.0", "<2.0")), c(0.5, 1.0))
})

test_that(".macdill_apply_sub applies half-MDL for arbitrary <X values", {
  expect_equal(tbeploads:::.macdill_apply_sub(c("<4", "<0.5")), c(2.0, 0.25))
})

# ===========================================================================
# .macdill_parse_part_b
# ===========================================================================

test_that(".macdill_parse_part_b computes daily averages with substitution", {
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw(1L), tmp)

  # Two days of data
  daily <- list(
    day     = c(1L, 2L),
    r1_flow = c("0.3", "0.1"),
    r2_flow = c("0.0", "0.02"),
    r3_flow = c("0.5", "0.6"),
    bod_r1  = c("<2", "1.5"),    # <2→1.0; mean(1.0, 1.5) = 1.25
    bod_r23 = c("3.5", "<1"),    # <1→0.5; mean(3.5, 0.5) = 2.0
    tss_r13 = c("<1", "1.0"),    # <1→0.5; mean(0.5, 1.0) = 0.75
    tss_r2  = c("2.0", "<2")    # <2→1.0; mean(2.0, 1.0) = 1.5
  )

  local_mocked_bindings(
    pdf_data = function(pdf, ...) make_part_b_page(daily),
    .package = "pdftools"
  )

  result <- tbeploads:::.macdill_parse_part_b(tmp)

  expect_equal(nrow(result), 3L)
  expect_equal(sort(result$outfall), c("R-001","R-002","R-003"))
  expect_true(all(is.na(result$tn_mgl)))   # TN always NA from Part B

  r1 <- result[result$outfall == "R-001", ]
  r2 <- result[result$outfall == "R-002", ]
  r3 <- result[result$outfall == "R-003", ]

  expect_equal(r1$flow_mgd, 0.2)    # mean(0.3, 0.1)
  expect_equal(r1$bod_mgl,  1.25)   # mean(<2→1, 1.5)
  expect_equal(r1$tss_mgl,  0.75)   # mean(<1→0.5, 1.0)  [shared with R-003]

  expect_equal(r2$flow_mgd, 0.01)   # mean(0.0, 0.02)
  expect_equal(r2$bod_mgl,  2.0)    # mean(3.5, <1→0.5)  [shared with R-003]
  expect_equal(r2$tss_mgl,  1.5)    # mean(2.0, <2→1.0)

  expect_equal(r3$flow_mgd, 0.55)   # mean(0.5, 0.6)
  expect_equal(r3$bod_mgl,  2.0)    # same column as R-002
  expect_equal(r3$tss_mgl,  0.75)   # same column as R-001
  # TN is NA when no tn_r3 data supplied (no page-2 TN column in daily)
  expect_true(all(is.na(result$tn_mgl)))
})

test_that(".macdill_parse_part_b extracts TN from page 2 for R-003", {
  # TN (00620) is on page 2 of the Part B, measured biweekly.
  # Days without a measurement have NA; the monthly average covers observed days only.
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw(1L), tmp)

  daily <- list(
    day     = c(1L, 7L, 14L, 21L),
    r1_flow = c("0.3", "0.3", "0.3", "0.3"),
    r2_flow = c("0.02","0.02","0.02","0.02"),
    r3_flow = c("0.5", "0.5", "0.5", "0.5"),
    tss_r13 = c("1.0", NA,   "1.2", NA),
    tss_r2  = c(NA,    NA,   NA,    NA),
    # TN measured only on days 7 and 21 (biweekly); days 1 and 14 have no TN
    tn_r3   = c(NA,   "1.8", NA,   "8.0")   # mean(1.8, 8.0) = 4.9
  )

  local_mocked_bindings(
    pdf_data = function(pdf, ...) make_part_b_page(daily),
    .package = "pdftools"
  )

  result <- tbeploads:::.macdill_parse_part_b(tmp)

  r3 <- result[result$outfall == "R-003", ]
  expect_equal(r3$tn_mgl, 4.9)   # mean(1.8, 8.0) = 4.9

  # TN is NA for R-001 and R-002 (they do not report TN)
  expect_true(is.na(result[result$outfall == "R-001", "tn_mgl"]))
  expect_true(is.na(result[result$outfall == "R-002", "tn_mgl"]))
})

test_that(".macdill_parse_part_b ignores PLANT STAFFING certification numbers in TN column", {
  # Regression: certification numbers (23476, 24878, etc.) in the PLANT STAFFING
  # section at the bottom of page 2 can fall within the 00620 TN column's
  # Voronoi x-range and were incorrectly averaged as TN values.
  # Fixed by restricting the candidate search to rows at or above the last
  # day-number row on page 2.
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw(1L), tmp)

  make_word <- function(text, x, y)
    data.frame(text = as.character(text), x = as.integer(x), y = as.integer(y),
               space = FALSE, width = 10L, height = 9L, stringsAsFactors = FALSE)

  TN_X <- 329L

  # Page 1: minimal with flow only
  hdr1 <- rbind(
    make_word("DAILY SAMPLE RESULTS - PART B", 200L, 50L),
    make_word("Site",   82L, 172L), make_word("CAL-01", 153L, 172L),
    make_word("FLW-02", 194L, 172L), make_word("FLW-03", 235L, 172L),
    make_word("EFA-01", 280L, 172L), make_word("EFA-02", 327L, 172L),
    make_word("EFB-01", 376L, 172L), make_word("EFB-01", 425L, 172L),
    make_word("EFA-02", 473L, 172L)
  )
  p1_rows <- rbind(
    make_word(1L, 72L, 184L), make_word("0.3", 154L, 184L),
    make_word(2L, 72L, 195L), make_word("0.3", 154L, 195L)
  )
  page1 <- rbind(hdr1, p1_rows)

  # Page 2: TN (00620) column at x=329; real TN value only on day 19 (2.0).
  # Certification numbers in the PLANT STAFFING block appear below day 30.
  hdr2 <- rbind(
    make_word("Code",  77L, 174L),
    make_word("00620", TN_X, 174L)
  )
  day_rows <- do.call(rbind, lapply(1:30, function(d) {
    row_y <- 190L + d * 10L
    w <- make_word(d, 72L, row_y)
    if (d == 19L) rbind(w, make_word("2.0", TN_X + 2L, row_y)) else w
  }))
  staffing_y0 <- 190L + 30L * 10L + 30L
  staffing <- rbind(
    make_word("23476", TN_X + 1L, staffing_y0),
    make_word("24878", TN_X + 1L, staffing_y0 + 12L),
    make_word("8426",  TN_X + 1L, staffing_y0 + 24L),
    make_word("28101", TN_X + 1L, staffing_y0 + 36L)
  )
  page2 <- rbind(hdr2, day_rows, staffing)

  local_mocked_bindings(
    pdf_data = function(pdf, ...) list(page1, page2),
    .package = "pdftools"
  )

  result <- tbeploads:::.macdill_parse_part_b(tmp)

  r3 <- result[result$outfall == "R-003", ]
  # Only day 19's value (2.0) averaged; certification numbers must be excluded
  expect_equal(r3$tn_mgl, 2.0)
})

test_that(".macdill_parse_part_b captures TN values without a leading zero (.10 style)", {
  # Regression: values like '.10' were excluded by the '^[<>]?[0-9]' filter
  # because they start with '.' not a digit.  Fixed to '^[<>]?\\.?[0-9]'.
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw(1L), tmp)

  daily <- list(
    day     = c(1L, 2L, 7L, 14L),
    r1_flow = c("0.3","0.3","0.3","0.3"),
    r2_flow = c("0.02","0.02","0.02","0.02"),
    r3_flow = c("0.5","0.5","0.5","0.5"),
    tn_r3   = c(NA, NA, ".10", "1.8")   # mean(0.10, 1.80) = 0.95
  )

  local_mocked_bindings(
    pdf_data = function(pdf, ...) make_part_b_page(daily),
    .package = "pdftools"
  )

  result <- tbeploads:::.macdill_parse_part_b(tmp)

  expect_equal(result[result$outfall == "R-003", "tn_mgl"], 0.95)
})

test_that(".macdill_parse_part_b page-2 Site keyword without CAL-01 does not corrupt page-1 values", {
  # Regression: page 2 of the Part B PDF contains 'Site' as a column label,
  # causing the Mon. Site parser to run on page 2 with wrong x-positions
  # (monitoring-site row labels misread as column headers).  Days present only
  # on page 2 received spurious values from those wrong positions.
  # Fixed by requiring CAL-01 in the Site header row before processing.
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw(1L), tmp)

  make_word <- function(text, x, y)
    data.frame(text = as.character(text), x = as.integer(x), y = as.integer(y),
               space = FALSE, width = 10L, height = 9L, stringsAsFactors = FALSE)

  # Page 1: days 1-2 with known BOD R-001 = 2.0
  hdr1 <- rbind(
    make_word("DAILY SAMPLE RESULTS - PART B", 200L, 50L),
    make_word("Site",   82L, 172L), make_word("CAL-01", 153L, 172L),
    make_word("FLW-02", 194L, 172L), make_word("FLW-03", 235L, 172L),
    make_word("EFA-01", 280L, 172L), make_word("EFA-02", 327L, 172L),
    make_word("EFB-01", 376L, 172L), make_word("EFB-01", 425L, 172L),
    make_word("EFA-02", 473L, 172L)
  )
  p1_rows <- rbind(
    make_word(1L, 72L, 184L), make_word("0.3", 154L, 184L), make_word("2.0", 281L, 184L),
    make_word(2L, 72L, 195L), make_word("0.3", 154L, 195L), make_word("2.0", 281L, 195L)
  )
  page1 <- rbind(hdr1, p1_rows)

  # Page 2: has "Site" + "EFA-01" at wrong x but no "CAL-01".
  # Day 3 appears ONLY here with a spurious value (9.9) at the wrong EFA-01 position.
  # Without the CAL-01 guard this day would be added to p1_rows with bod_r1=9.9,
  # corrupting the mean from 2.0 to mean(2.0, 2.0, 9.9) = 4.63.
  hdr2 <- rbind(
    make_word("Code",  77L, 173L), make_word("00620", 420L, 173L),
    make_word("Site",  82L, 184L), make_word("EFA-01", 197L, 184L),
    make_word("EFA-02", 110L, 184L)
  )
  p2_rows <- rbind(
    make_word(3L,    72L, 206L),
    make_word("9.9", 198L, 206L),   # near wrong EFA-01 x=197; corrupts if guard fails
    make_word("1.5", 421L, 206L)    # TN value in 00620 column
  )
  page2 <- rbind(hdr2, p2_rows)

  local_mocked_bindings(
    pdf_data = function(pdf, ...) list(page1, page2),
    .package = "pdftools"
  )

  result <- tbeploads:::.macdill_parse_part_b(tmp)

  r1 <- result[result$outfall == "R-001", ]
  # BOD R-001 must be 2.0 (days 1-2 only); 9.9 from page 2 must be ignored
  expect_equal(r1$bod_mgl, 2.0)
  # TN is still extracted from page 2 Code block (independent of Site guard)
  expect_equal(result[result$outfall == "R-003", "tn_mgl"], 1.5)
})

# ===========================================================================
# util_ps_getmacdill (integration)
# ===========================================================================

test_that("util_ps_getmacdill returns correctly-structured data frame", {
  skip_if(!nzchar(macdill_xlsx), "macdill2025search.xlsx fixture not installed")

  call_n   <- 0L
  classify_mock <- function(path) {
    call_n <<- call_n + 1L
    list(type = "partA", month = call_n, year = 2025L)
  }

  stub(util_ps_getmacdill, ".macdill_oculus_login",  function() NULL)
  stub(util_ps_getmacdill, ".macdill_download_pdf",
       function(guid, dest_path, session_handle) TRUE)
  stub(util_ps_getmacdill, ".macdill_classify_pdf",  classify_mock)
  stub(util_ps_getmacdill, ".macdill_parse_part_a",  parse_parta_from_guid)

  result <- util_ps_getmacdill(yr = 2025, search_xlsx = macdill_xlsx, quiet = TRUE)

  expect_s3_class(result, "data.frame")
  expect_equal(names(result), c("yr","mo","outfall","flow_mgd","bod_mgl","tss_mgl","tn_mgl","verify"))
  expect_true(nrow(result) > 0L)
  expect_equal(nrow(result) %% 3L, 0L)           # always a multiple of 3
  expect_true(all(result$yr == 2025L))
  expect_true(all(result$outfall %in% c("R-001","R-002","R-003")))
})

test_that("util_ps_getmacdill Part B overrides Part A BOD, TSS, and flow when both exist", {
  skip_if(!nzchar(macdill_xlsx), "macdill2025search.xlsx fixture not installed")

  doc_list <- data.frame(guid = c("guid_a","guid_b"), row = c(1L, 2L),
                          subject = c("DMR 2025 JUN MO PART A","DMR 2025 JUN MO PART B"),
                          stringsAsFactors = FALSE)

  classify_mock <- function(path) {
    if (grepl("guid_a", path)) list(type="partA", month=6L, year=2025L)
    else                        list(type="partB", month=6L, year=2025L)
  }

  stub(util_ps_getmacdill, ".macdill_extract_guids", function(...) doc_list)
  stub(util_ps_getmacdill, ".macdill_oculus_login",  function() NULL)
  stub(util_ps_getmacdill, ".macdill_download_pdf",
       function(guid, dest_path, session_handle) TRUE)
  stub(util_ps_getmacdill, ".macdill_classify_pdf",  classify_mock)
  stub(util_ps_getmacdill, ".macdill_parse_part_a",  parse_parta_from_guid)
  stub(util_ps_getmacdill, ".macdill_parse_part_b",  parse_partb_from_guid)

  result <- util_ps_getmacdill(yr = 2025, search_xlsx = macdill_xlsx, quiet = TRUE)

  expect_equal(nrow(result), 3L)
  r1 <- result[result$outfall == "R-001", ]
  r3 <- result[result$outfall == "R-003", ]
  # Part B daily averages override Part A for BOD, TSS, flow
  expect_equal(r1$bod_mgl,  parse_partb_from_guid(NULL)$bod_mgl[1])
  expect_equal(r1$tss_mgl,  parse_partb_from_guid(NULL)$tss_mgl[1])
  expect_equal(r1$flow_mgd, parse_partb_from_guid(NULL)$flow_mgd[1])
  # Part B fixture has NA TN; Part A TN is used as fallback for R-003
  expect_equal(r3$tn_mgl, parse_parta_from_guid(NULL)$tn_mgl[3])   # 4.5
  # R-001: TSS from Part B → verify = FALSE
  expect_false(result[result$outfall == "R-001", "verify"])
  # R-003: TSS from Part B but TN falls back to Part A maximum → verify = TRUE
  expect_true(result[result$outfall == "R-003", "verify"])
})

test_that("util_ps_getmacdill sets verify = TRUE when only Part A available for R-001/R-003", {
  skip_if(!nzchar(macdill_xlsx), "macdill2025search.xlsx fixture not installed")

  # Only Part A for one month — TSS R-001/R-003 comes from Part A Maximum
  doc_list <- data.frame(guid = "guid_a", row = 1L,
                          subject = "DMR 2025 JUN MO PART A",
                          stringsAsFactors = FALSE)

  stub(util_ps_getmacdill, ".macdill_extract_guids", function(...) doc_list)
  stub(util_ps_getmacdill, ".macdill_oculus_login",  function() NULL)
  stub(util_ps_getmacdill, ".macdill_download_pdf",
       function(guid, dest_path, session_handle) TRUE)
  stub(util_ps_getmacdill, ".macdill_classify_pdf",
       function(path) list(type="partA", month=6L, year=2025L))
  stub(util_ps_getmacdill, ".macdill_parse_part_a",  parse_parta_from_guid)

  result <- util_ps_getmacdill(yr = 2025, search_xlsx = macdill_xlsx, quiet = TRUE)

  # R-001 and R-003 have non-NA TSS from Part A Maximum → verify = TRUE
  expect_true(result[result$outfall == "R-001", "verify"])
  expect_true(result[result$outfall == "R-003", "verify"])
  # R-002 TSS is Part A Monthly Average → verify = FALSE
  expect_false(result[result$outfall == "R-002", "verify"])
})

test_that("util_ps_getmacdill renames unclassifiable PDFs using document subject", {
  skip_if(!nzchar(macdill_xlsx), "macdill2025search.xlsx fixture not installed")

  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  # Two docs: one classifiable Part A, one unclassifiable (scanned)
  doc_list <- data.frame(
    guid    = c("38.111.1","38.999.1"),
    row     = c(1L, 2L),
    subject = c("DMR 2025 JUN MO PART A", "DMR 2022 JAN MO PART B (761028)"),
    stringsAsFactors = FALSE
  )

  stub(util_ps_getmacdill, ".macdill_extract_guids", function(...) doc_list)
  stub(util_ps_getmacdill, ".macdill_oculus_login",  function() NULL)
  stub(util_ps_getmacdill, ".macdill_download_pdf",
       function(guid, dest_path, session_handle) { writeBin(raw(1L), dest_path); TRUE })
  stub(util_ps_getmacdill, ".macdill_classify_pdf", function(path) {
    if (grepl("38\\.111\\.1", path)) list(type="partA", month=6L, year=2025L)
    else                              NULL   # unclassifiable
  })
  stub(util_ps_getmacdill, ".macdill_parse_part_a", parse_parta_from_guid)

  util_ps_getmacdill(yr = 2025, search_xlsx = macdill_xlsx,
                     pdf_dir = tmp_dir, quiet = TRUE)

  files <- list.files(tmp_dir, pattern = "\\.pdf$")
  # Unclassifiable file should be saved with subject-derived name
  expect_true(any(grepl("macdill_unclassified_", files)))
  expect_true(any(grepl("761028", files)))         # subject text in filename
  expect_false(any(grepl("^38\\.999\\.1", files))) # GUID name should be gone
})

test_that("util_ps_getmacdill falls back to Part B when no Part A exists", {
  skip_if(!nzchar(macdill_xlsx), "macdill2025search.xlsx fixture not installed")

  doc_list <- data.frame(guid = "guid_b", row = 1L,
                          subject = "DMR 2025 JUN MO PART B",
                          stringsAsFactors = FALSE)

  stub(util_ps_getmacdill, ".macdill_extract_guids", function(...) doc_list)
  stub(util_ps_getmacdill, ".macdill_oculus_login",  function() NULL)
  stub(util_ps_getmacdill, ".macdill_download_pdf",
       function(guid, dest_path, session_handle) TRUE)
  stub(util_ps_getmacdill, ".macdill_classify_pdf",
       function(path) list(type="partB", month=6L, year=2025L))
  stub(util_ps_getmacdill, ".macdill_parse_part_b",  parse_partb_from_guid)

  result <- util_ps_getmacdill(yr = 2025, search_xlsx = macdill_xlsx, quiet = TRUE)

  expect_equal(nrow(result), 3L)
  r1 <- result[result$outfall == "R-001", ]
  expect_equal(r1$bod_mgl, parse_partb_from_guid(NULL)$bod_mgl[1])
  expect_true(is.na(r1$tn_mgl))   # TN always NA from Part B
})

test_that("util_ps_getmacdill Part B TN overrides Part A TN when Part B provides TN", {
  skip_if(!nzchar(macdill_xlsx), "macdill2025search.xlsx fixture not installed")

  doc_list <- data.frame(guid    = c("guid_a","guid_b"), row = c(1L, 2L),
                          subject = c("DMR 2025 JUN MO PART A","DMR 2025 JUN MO PART B"),
                          stringsAsFactors = FALSE)

  classify_mock <- function(path) {
    if (grepl("guid_a", path)) list(type="partA", month=6L, year=2025L)
    else                        list(type="partB", month=6L, year=2025L)
  }

  stub(util_ps_getmacdill, ".macdill_extract_guids", function(...) doc_list)
  stub(util_ps_getmacdill, ".macdill_oculus_login",  function() NULL)
  stub(util_ps_getmacdill, ".macdill_download_pdf",
       function(guid, dest_path, session_handle) TRUE)
  stub(util_ps_getmacdill, ".macdill_classify_pdf",  classify_mock)
  stub(util_ps_getmacdill, ".macdill_parse_part_a",  parse_parta_from_guid)
  stub(util_ps_getmacdill, ".macdill_parse_part_b",  parse_partb_with_tn_from_guid)

  result <- util_ps_getmacdill(yr = 2025, search_xlsx = macdill_xlsx, quiet = TRUE)

  r3 <- result[result$outfall == "R-003", ]
  # Part B biweekly average (2.7) must take precedence over Part A maximum (4.5)
  expect_equal(r3$tn_mgl, parse_partb_with_tn_from_guid(NULL)$tn_mgl[3])
  expect_false(r3$tn_mgl == parse_parta_from_guid(NULL)$tn_mgl[3])
  # Both TSS and TN came from Part B → verify = FALSE
  expect_false(r3$verify)
})

test_that("util_ps_getmacdill retains sensibly-named PDFs when pdf_dir is supplied", {
  skip_if(!nzchar(macdill_xlsx), "macdill2025search.xlsx fixture not installed")

  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  doc_list <- data.frame(guid    = c("38.111.1","38.222.1"), row = c(1L, 2L),
                          subject = c("DMR 2025 JUN MO PART A","DMR 2025 JUN MO PART B"),
                          stringsAsFactors = FALSE)

  classify_mock <- function(path) {
    if (grepl("38\\.111\\.1", path)) list(type="partA", month=6L, year=2025L)
    else                              list(type="partB", month=6L, year=2025L)
  }

  stub(util_ps_getmacdill, ".macdill_extract_guids", function(...) doc_list)
  stub(util_ps_getmacdill, ".macdill_oculus_login",  function() NULL)
  # Create real dummy files so rename_to_sensible has something to work with
  stub(util_ps_getmacdill, ".macdill_download_pdf",
       function(guid, dest_path, session_handle) {
         writeBin(raw(1L), dest_path); TRUE
       })
  stub(util_ps_getmacdill, ".macdill_classify_pdf",  classify_mock)
  stub(util_ps_getmacdill, ".macdill_parse_part_a",  parse_parta_from_guid)
  stub(util_ps_getmacdill, ".macdill_parse_part_b",  parse_partb_from_guid)

  util_ps_getmacdill(yr = 2025, search_xlsx = macdill_xlsx,
                     pdf_dir = tmp_dir, quiet = TRUE)

  retained <- list.files(tmp_dir, pattern = "\\.pdf$")
  # Only macdill_YYYY_MM_part*.pdf files should remain; raw GUID files removed
  expect_true(all(grepl("^macdill_", retained)))
  expect_true(any(grepl("_partA\\.pdf$", retained)))
  expect_true(any(grepl("_partB\\.pdf$", retained)))
  expect_true(any(grepl("_2025_06_", retained)))
})

test_that("util_ps_getmacdill writes xlsx when out_file is specified", {
  skip_if(!nzchar(macdill_xlsx), "macdill2025search.xlsx fixture not installed")

  out   <- tempfile(fileext = ".xlsx")
  on.exit(unlink(out), add = TRUE)
  call_n <- 0L

  stub(util_ps_getmacdill, ".macdill_oculus_login", function() NULL)
  stub(util_ps_getmacdill, ".macdill_download_pdf",
       function(guid, dest_path, session_handle) TRUE)
  stub(util_ps_getmacdill, ".macdill_classify_pdf", function(path) {
    call_n <<- call_n + 1L
    list(type="partA", month=call_n, year=2025L)
  })
  stub(util_ps_getmacdill, ".macdill_parse_part_a", parse_parta_from_guid)

  util_ps_getmacdill(yr = 2025, search_xlsx = macdill_xlsx,
                     out_file = out, quiet = TRUE)

  expect_true(file.exists(out))
  written <- readxl::read_xlsx(out, sheet = "MacDill_DMR")
  expect_equal(names(written), c("yr","mo","outfall","flow_mgd","bod_mgl","tss_mgl","tn_mgl","verify"))
})

test_that("util_ps_getmacdill stops with error for missing search_xlsx", {
  expect_error(
    util_ps_getmacdill(yr = 2025, search_xlsx = "nonexistent.xlsx")
  )
})

test_that("util_ps_getmacdill returns empty data frame when no PDFs download successfully", {
  skip_if(!nzchar(macdill_xlsx), "macdill2025search.xlsx fixture not installed")

  stub(util_ps_getmacdill, ".macdill_oculus_login", function() NULL)
  stub(util_ps_getmacdill, ".macdill_download_pdf",
       function(guid, dest_path, session_handle) FALSE)   # all downloads fail

  result <- util_ps_getmacdill(yr = 2025, search_xlsx = macdill_xlsx, quiet = TRUE)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0L)
  expect_equal(names(result), c("yr","mo","outfall","flow_mgd","bod_mgl","tss_mgl","tn_mgl","verify"))
})

test_that("util_ps_getmacdill skips PDFs whose year does not match requested year", {
  skip_if(!nzchar(macdill_xlsx), "macdill2025search.xlsx fixture not installed")

  # Two docs in the index: one matches 2025, one is classified as 2024 (wrong year).
  doc_list <- data.frame(
    guid    = c("guid_a", "guid_b"), row = c(1L, 2L),
    subject = c("DMR 2025 JUN MO PART A", "DMR 2025 JUL MO PART A"),
    stringsAsFactors = FALSE
  )

  call_n <- 0L
  classify_mock <- function(path) {
    call_n <<- call_n + 1L
    if (call_n == 1L) list(type = "partA", month = 6L, year = 2025L)
    else              list(type = "partA", month = 7L, year = 2024L)  # wrong year
  }

  stub(util_ps_getmacdill, ".macdill_extract_guids", function(...) doc_list)
  stub(util_ps_getmacdill, ".macdill_oculus_login",  function() NULL)
  stub(util_ps_getmacdill, ".macdill_download_pdf",
       function(guid, dest_path, session_handle) TRUE)
  stub(util_ps_getmacdill, ".macdill_classify_pdf",  classify_mock)
  stub(util_ps_getmacdill, ".macdill_parse_part_a",  parse_parta_from_guid)

  result <- util_ps_getmacdill(yr = 2025, search_xlsx = macdill_xlsx, quiet = TRUE)

  # Only June (year 2025) should be in the output; July (year 2024) skipped
  expect_equal(sort(unique(result$mo)), 6L)
  expect_equal(nrow(result), 3L)
})

test_that("util_ps_getmacdill skips a month and continues when download fails", {
  skip_if(!nzchar(macdill_xlsx), "macdill2025search.xlsx fixture not installed")

  doc_list <- data.frame(
    guid    = c("guid_a", "guid_b"), row = c(1L, 2L),
    subject = c("DMR 2025 JUN MO PART A", "DMR 2025 JUL MO PART A"),
    stringsAsFactors = FALSE
  )

  call_n <- 0L
  stub(util_ps_getmacdill, ".macdill_extract_guids", function(...) doc_list)
  stub(util_ps_getmacdill, ".macdill_oculus_login",  function() NULL)
  stub(util_ps_getmacdill, ".macdill_download_pdf",
       function(guid, dest_path, session_handle) {
         call_n <<- call_n + 1L
         call_n > 1L   # first download fails, second succeeds
       })
  stub(util_ps_getmacdill, ".macdill_classify_pdf",
       function(path) list(type = "partA", month = 7L, year = 2025L))
  stub(util_ps_getmacdill, ".macdill_parse_part_a", parse_parta_from_guid)

  result <- util_ps_getmacdill(yr = 2025, search_xlsx = macdill_xlsx, quiet = TRUE)

  # Only July (second download, which succeeded) should appear
  expect_equal(sort(unique(result$mo)), 7L)
  expect_equal(nrow(result), 3L)
})

test_that("util_ps_getmacdill prints progress messages when quiet = FALSE", {
  skip_if(!nzchar(macdill_xlsx), "macdill2025search.xlsx fixture not installed")

  call_n <- 0L
  stub(util_ps_getmacdill, ".macdill_oculus_login", function() NULL)
  stub(util_ps_getmacdill, ".macdill_download_pdf",
       function(guid, dest_path, session_handle) TRUE)
  stub(util_ps_getmacdill, ".macdill_classify_pdf", function(path) {
    call_n <<- call_n + 1L
    list(type = "partA", month = call_n, year = 2025L)
  })
  stub(util_ps_getmacdill, ".macdill_parse_part_a", parse_parta_from_guid)

  expect_output(
    util_ps_getmacdill(yr = 2025, search_xlsx = macdill_xlsx, quiet = FALSE),
    "candidate monthly"
  )
})

test_that("util_ps_getmacdill stops with an error when no documents match the requested year", {
  skip_if(!nzchar(macdill_xlsx), "macdill2025search.xlsx fixture not installed")

  expect_error(
    util_ps_getmacdill(yr = 1999, search_xlsx = macdill_xlsx, quiet = TRUE),
    "No monthly documents found for year"
  )
})

test_that("util_ps_getmacdill prints a cached message and skips download for an existing valid PDF", {
  doc_list <- data.frame(guid = "38.111.1", row = 1L,
                          subject = "DMR 2025 JUN MO PART A",
                          stringsAsFactors = FALSE)

  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)
  writeBin(raw(6000L), file.path(tmp_dir, "38.111.1.pdf"))

  download_called <- FALSE
  stub(util_ps_getmacdill, ".macdill_extract_guids", function(...) doc_list)
  stub(util_ps_getmacdill, ".macdill_oculus_login",  function() NULL)
  stub(util_ps_getmacdill, ".macdill_download_pdf", function(guid, dest_path, session_handle) {
    download_called <<- TRUE
    TRUE
  })
  stub(util_ps_getmacdill, ".macdill_classify_pdf",
       function(path) list(type = "partA", month = 6L, year = 2025L))
  stub(util_ps_getmacdill, ".macdill_parse_part_a", parse_parta_from_guid)

  expect_output(
    util_ps_getmacdill(yr = 2025, search_xlsx = macdill_xlsx, pdf_dir = tmp_dir, quiet = FALSE)
  )
  expect_false(download_called)
})

test_that("util_ps_getmacdill prints a FAILED message when quiet = FALSE and download fails", {
  doc_list <- data.frame(guid = c("guid_a","guid_b"), row = c(1L, 2L),
                          subject = c("DMR 2025 JUN MO PART A","DMR 2025 JUL MO PART A"),
                          stringsAsFactors = FALSE)

  call_n <- 0L
  stub(util_ps_getmacdill, ".macdill_extract_guids", function(...) doc_list)
  stub(util_ps_getmacdill, ".macdill_oculus_login",  function() NULL)
  stub(util_ps_getmacdill, ".macdill_download_pdf", function(guid, dest_path, session_handle) {
    call_n <<- call_n + 1L
    call_n > 1L   # first download fails, second succeeds
  })
  stub(util_ps_getmacdill, ".macdill_classify_pdf",
       function(path) list(type = "partA", month = 7L, year = 2025L))
  stub(util_ps_getmacdill, ".macdill_parse_part_a", parse_parta_from_guid)

  expect_output(
    util_ps_getmacdill(yr = 2025, search_xlsx = macdill_xlsx, quiet = FALSE),
    "FAILED"
  )
})

test_that("util_ps_getmacdill prints an unclassifiable message with the derived filename", {
  doc_list <- data.frame(guid = "38.999.1", row = 1L,
                          subject = "DMR 2022 JAN MO PART B (761028)",
                          stringsAsFactors = FALSE)

  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  stub(util_ps_getmacdill, ".macdill_extract_guids", function(...) doc_list)
  stub(util_ps_getmacdill, ".macdill_oculus_login",  function() NULL)
  stub(util_ps_getmacdill, ".macdill_download_pdf",
       function(guid, dest_path, session_handle) { writeBin(raw(1L), dest_path); TRUE })
  stub(util_ps_getmacdill, ".macdill_classify_pdf", function(path) NULL)

  expect_output(
    util_ps_getmacdill(yr = 2025, search_xlsx = macdill_xlsx, pdf_dir = tmp_dir, quiet = FALSE),
    "unclassifiable"
  )
})

test_that("util_ps_getmacdill prints a skip message for a PDF classified to a different year", {
  doc_list <- data.frame(guid = "guid_a", row = 1L,
                          subject = "DMR 2025 JUL MO PART A",
                          stringsAsFactors = FALSE)

  stub(util_ps_getmacdill, ".macdill_extract_guids", function(...) doc_list)
  stub(util_ps_getmacdill, ".macdill_oculus_login",  function() NULL)
  stub(util_ps_getmacdill, ".macdill_download_pdf",
       function(guid, dest_path, session_handle) TRUE)
  stub(util_ps_getmacdill, ".macdill_classify_pdf",
       function(path) list(type = "partA", month = 7L, year = 2024L))

  expect_output(
    util_ps_getmacdill(yr = 2025, search_xlsx = macdill_xlsx, quiet = FALSE),
    "skipping"
  )
})

test_that("util_ps_getmacdill prints 'No usable PDFs found' and returns an empty data frame when every document is unclassifiable", {
  doc_list <- data.frame(guid = c("38.1.1","38.2.1"), row = c(1L, 2L),
                          subject = c("DMR 2022 JAN MO PART A (1)", "DMR 2022 FEB MO PART A (2)"),
                          stringsAsFactors = FALSE)

  stub(util_ps_getmacdill, ".macdill_extract_guids", function(...) doc_list)
  stub(util_ps_getmacdill, ".macdill_oculus_login",  function() NULL)
  stub(util_ps_getmacdill, ".macdill_download_pdf",
       function(guid, dest_path, session_handle) { writeBin(raw(1L), dest_path); TRUE })
  stub(util_ps_getmacdill, ".macdill_classify_pdf", function(path) NULL)

  result <- expect_output(
    util_ps_getmacdill(yr = 2025, search_xlsx = macdill_xlsx, quiet = FALSE),
    "No usable PDFs found"
  )
})

test_that("util_ps_getmacdill keeps Part A values for an outfall missing from Part B", {
  skip_if(!nzchar(macdill_xlsx), "macdill2025search.xlsx fixture not installed")

  doc_list <- data.frame(guid = c("guid_a","guid_b"), row = c(1L, 2L),
                          subject = c("DMR 2025 JUN MO PART A","DMR 2025 JUN MO PART B"),
                          stringsAsFactors = FALSE)

  classify_mock <- function(path) {
    if (grepl("guid_a", path)) list(type="partA", month=6L, year=2025L)
    else                        list(type="partB", month=6L, year=2025L)
  }
  # Part B is missing an R-002 row entirely
  partb_missing_r2 <- function(path) {
    data.frame(outfall  = c("R-001","R-003"),
               flow_mgd = c(0.25, 0.55),
               bod_mgl  = c(1.8,  2.5),
               tss_mgl  = c(1.2,  1.2),
               tn_mgl   = NA_real_,
               stringsAsFactors = FALSE)
  }

  stub(util_ps_getmacdill, ".macdill_extract_guids", function(...) doc_list)
  stub(util_ps_getmacdill, ".macdill_oculus_login",  function() NULL)
  stub(util_ps_getmacdill, ".macdill_download_pdf",
       function(guid, dest_path, session_handle) TRUE)
  stub(util_ps_getmacdill, ".macdill_classify_pdf",  classify_mock)
  stub(util_ps_getmacdill, ".macdill_parse_part_a",  parse_parta_from_guid)
  stub(util_ps_getmacdill, ".macdill_parse_part_b",  partb_missing_r2)

  result <- util_ps_getmacdill(yr = 2025, search_xlsx = macdill_xlsx, quiet = TRUE)

  r2 <- result[result$outfall == "R-002", ]
  parta <- parse_parta_from_guid(NULL)
  parta_r2 <- parta[parta$outfall == "R-002", ]
  # R-002 has no Part B row, so its Part A values must be untouched
  expect_equal(r2$flow_mgd, parta_r2$flow_mgd)
  expect_equal(r2$bod_mgl,  parta_r2$bod_mgl)
  expect_equal(r2$tss_mgl,  parta_r2$tss_mgl)
})

test_that("util_ps_getmacdill skips a month entirely when both Part A and Part B fail to parse", {
  skip_if(!nzchar(macdill_xlsx), "macdill2025search.xlsx fixture not installed")

  # Two months: June has only a Part A doc whose parse fails (no Part B at all,
  # so both parta_data and partb_data are NULL); July parses normally.
  doc_list <- data.frame(
    guid    = c("guid_jun", "guid_jul"), row = c(1L, 2L),
    subject = c("DMR 2025 JUN MO PART A", "DMR 2025 JUL MO PART A"),
    stringsAsFactors = FALSE
  )

  classify_mock <- function(path) {
    if (grepl("guid_jun", path)) list(type = "partA", month = 6L, year = 2025L)
    else                          list(type = "partA", month = 7L, year = 2025L)
  }

  stub(util_ps_getmacdill, ".macdill_extract_guids", function(...) doc_list)
  stub(util_ps_getmacdill, ".macdill_oculus_login",  function() NULL)
  stub(util_ps_getmacdill, ".macdill_download_pdf",
       function(guid, dest_path, session_handle) TRUE)
  stub(util_ps_getmacdill, ".macdill_classify_pdf",  classify_mock)
  stub(util_ps_getmacdill, ".macdill_parse_part_a", function(path) {
    # PDFs are renamed to "macdill_<yr>_<mo>_partA.pdf" before parsing, so key
    # off the month embedded in the renamed path rather than the original guid.
    if (grepl("_06_", path, fixed = TRUE)) stop("simulated parse error")
    parse_parta_from_guid(path)
  })

  result <- suppressWarnings(
    util_ps_getmacdill(yr = 2025, search_xlsx = macdill_xlsx, quiet = TRUE)
  )

  expect_equal(sort(unique(result$mo)), 7L)
  expect_equal(nrow(result), 3L)
})

test_that("util_ps_getmacdill prints a note listing missing months when quiet = FALSE", {
  skip_if(!nzchar(macdill_xlsx), "macdill2025search.xlsx fixture not installed")

  doc_list <- data.frame(guid = "guid_a", row = 1L,
                          subject = "DMR 2025 JUN MO PART A",
                          stringsAsFactors = FALSE)

  stub(util_ps_getmacdill, ".macdill_extract_guids", function(...) doc_list)
  stub(util_ps_getmacdill, ".macdill_oculus_login",  function() NULL)
  stub(util_ps_getmacdill, ".macdill_download_pdf",
       function(guid, dest_path, session_handle) TRUE)
  stub(util_ps_getmacdill, ".macdill_classify_pdf",
       function(path) list(type = "partA", month = 6L, year = 2025L))
  stub(util_ps_getmacdill, ".macdill_parse_part_a", parse_parta_from_guid)

  expect_output(
    util_ps_getmacdill(yr = 2025, search_xlsx = macdill_xlsx, quiet = FALSE),
    "no usable document found for month"
  )
})

test_that("util_ps_getmacdill prints a message when writing the out_file", {
  skip_if(!nzchar(macdill_xlsx), "macdill2025search.xlsx fixture not installed")

  out <- tempfile(fileext = ".xlsx")
  on.exit(unlink(out), add = TRUE)
  call_n <- 0L

  stub(util_ps_getmacdill, ".macdill_oculus_login", function() NULL)
  stub(util_ps_getmacdill, ".macdill_download_pdf",
       function(guid, dest_path, session_handle) TRUE)
  stub(util_ps_getmacdill, ".macdill_classify_pdf", function(path) {
    call_n <<- call_n + 1L
    list(type = "partA", month = call_n, year = 2025L)
  })
  stub(util_ps_getmacdill, ".macdill_parse_part_a", parse_parta_from_guid)

  expect_output(
    util_ps_getmacdill(yr = 2025, search_xlsx = macdill_xlsx, out_file = out, quiet = FALSE),
    "Writing results to"
  )
})

test_that("util_ps_getmacdill prints a retained-PDFs message and removes leftover raw GUID files", {
  skip_if(!nzchar(macdill_xlsx), "macdill2025search.xlsx fixture not installed")

  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  # Three docs for the same month: an older, non-selected Part A revision
  # (guid_old) that is never renamed and must be cleaned up as a leftover raw
  # GUID file, plus the selected Part A (guid_new, higher row) and Part B.
  doc_list <- data.frame(
    guid    = c("38.100.1", "38.200.1", "38.300.1"),
    row     = c(1L, 2L, 3L),
    subject = c("DMR 2025 JUN MO PART A", "DMR 2025 JUN MO PART A", "DMR 2025 JUN MO PART B"),
    stringsAsFactors = FALSE
  )

  classify_mock <- function(path) {
    if (grepl("38\\.300\\.1", path)) list(type = "partB", month = 6L, year = 2025L)
    else                              list(type = "partA", month = 6L, year = 2025L)
  }

  stub(util_ps_getmacdill, ".macdill_extract_guids", function(...) doc_list)
  stub(util_ps_getmacdill, ".macdill_oculus_login",  function() NULL)
  stub(util_ps_getmacdill, ".macdill_download_pdf",
       function(guid, dest_path, session_handle) { writeBin(raw(1L), dest_path); TRUE })
  stub(util_ps_getmacdill, ".macdill_classify_pdf",  classify_mock)
  stub(util_ps_getmacdill, ".macdill_parse_part_a",  parse_parta_from_guid)
  stub(util_ps_getmacdill, ".macdill_parse_part_b",  parse_partb_from_guid)

  expect_output(
    util_ps_getmacdill(yr = 2025, search_xlsx = macdill_xlsx, pdf_dir = tmp_dir, quiet = FALSE),
    "PDFs retained in"
  )

  retained <- list.files(tmp_dir, pattern = "\\.pdf$")
  # The lower-row Part A revision (38.100.1) was never selected as best_a, so
  # it should remain un-renamed and then be removed as a leftover raw GUID file.
  expect_false(any(grepl("^38\\.100\\.1\\.pdf$", retained)))
  expect_true(all(grepl("^macdill_", retained)))
})

# ===========================================================================
# .macdill_extract_guids -- error handling and fallback row assignment
# ===========================================================================

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

test_that(".macdill_extract_guids stops when the worksheet XML cannot be located", {
  skip_if(!nzchar(macdill_xlsx), "macdill2025search.xlsx fixture not installed")

  bad_xlsx <- make_no_worksheet_xlsx(macdill_xlsx)
  on.exit(unlink(bad_xlsx), add = TRUE)

  expect_error(
    tbeploads:::.macdill_extract_guids(bad_xlsx, 2025),
    "Cannot locate worksheet XML"
  )
})

test_that(".macdill_extract_guids falls back to positional row assignment when column A pattern is absent", {
  skip_if(!nzchar(macdill_xlsx), "macdill2025search.xlsx fixture not installed")

  fallback_xlsx <- make_relocated_guid_xlsx(macdill_xlsx)
  on.exit(unlink(fallback_xlsx), add = TRUE)

  result <- tbeploads:::.macdill_extract_guids(fallback_xlsx, 2025)

  expect_s3_class(result, "data.frame")
  expect_true(nrow(result) > 0L)
})

# ===========================================================================
# .macdill_classify_pdf -- additional branches
# ===========================================================================

test_that(".macdill_classify_pdf returns NULL when the monitoring period pattern is absent", {
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw(1L), tmp)

  local_mocked_bindings(
    pdf_text = function(pdf, ...) "DISCHARGE MONITORING REPORT with no period info at all",
    .package = "pdftools"
  )

  expect_null(tbeploads:::.macdill_classify_pdf(tmp))
})

test_that(".macdill_classify_pdf returns NULL when the monitoring period date is invalid", {
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw(1L), tmp)

  local_mocked_bindings(
    pdf_text = function(pdf, ...) paste(
      "DEPARTMENT OF ENVIRONMENTAL PROTECTION DISCHARGE MONITORING REPORT - PART A",
      "COUNTY: HILLSBOROUGH    MONITORING PERIOD: From: 02/30/2025 To: 02/28/2025",
      sep = "\n"
    ),
    .package = "pdftools"
  )

  expect_null(tbeploads:::.macdill_classify_pdf(tmp))
})

# ===========================================================================
# .macdill_parse_part_a -- no monitoring groups found
# ===========================================================================

test_that(".macdill_parse_part_a returns an all-NA 3-row frame when no monitoring groups are found", {
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw(1L), tmp)

  local_mocked_bindings(
    pdf_text = function(pdf, ...) "no monitoring groups mentioned anywhere here",
    .package = "pdftools"
  )

  result <- tbeploads:::.macdill_parse_part_a(tmp)

  expect_equal(sort(result$outfall), c("R-001","R-002","R-003"))
  expect_true(all(is.na(result$flow_mgd)))
  expect_true(all(is.na(result$bod_mgl)))
  expect_true(all(is.na(result$tss_mgl)))
  expect_true(all(is.na(result$tn_mgl)))
})

# ===========================================================================
# .macdill_extract_val -- direct unit tests
# ===========================================================================

test_that(".macdill_extract_val returns NA when no Requirement line matches the timing pattern", {
  lines <- c("Flow  1.0  2.0  extra", "totally unrelated line")
  result <- tbeploads:::.macdill_extract_val(lines, "^Flow\\s", "Mo Avg", 1L)
  expect_true(is.na(result))
})

test_that(".macdill_extract_val skips a candidate line that itself matches Permit/Requirement/Mon.", {
  lines <- c(
    "Mon. Site: BOD, Carbonaceous 5 day, 20C  something",
    "Mon. Site: EFA-01    Requirement    (Mo Avg)"
  )
  result <- tbeploads:::.macdill_extract_val(lines, "BOD.*Carbon", "Mo Avg", 1L)
  expect_true(is.na(result))
})

test_that(".macdill_extract_val continues past a Sample line whose next line has no value tokens", {
  lines <- c(
    "BOD, Carbonaceous 5 day,          Sample",
    "Mon. Site: EFA-01    Requirement    (Mo Avg)"
  )
  result <- tbeploads:::.macdill_extract_val(lines, "BOD.*Carbon", "Mo Avg", 1L)
  expect_true(is.na(result))
})

# ===========================================================================
# .macdill_parse_tok -- direct unit tests
# ===========================================================================

test_that(".macdill_parse_tok returns NA (not NOD) for an empty or ANC token", {
  r1 <- tbeploads:::.macdill_parse_tok(NA_character_)
  r2 <- tbeploads:::.macdill_parse_tok("ANC")
  expect_true(is.na(r1$val)); expect_false(r1$nod)
  expect_true(is.na(r2$val)); expect_false(r2$nod)
})

test_that(".macdill_parse_tok flags NOD without halving", {
  r <- tbeploads:::.macdill_parse_tok("NOD")
  expect_true(is.na(r$val))
  expect_true(r$nod)
})

test_that(".macdill_parse_tok halves below-detection '<X' tokens", {
  r <- tbeploads:::.macdill_parse_tok("<4")
  expect_equal(r$val, 4)
  expect_false(r$nod)
})

# ===========================================================================
# .macdill_parse_part_b -- additional branches
# ===========================================================================

test_that(".macdill_parse_part_b returns NA for a column whose header token was not found", {
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw(1L), tmp)

  make_word <- function(text, x, y)
    data.frame(text = as.character(text), x = as.integer(x), y = as.integer(y),
               space = FALSE, width = 10L, height = 9L, stringsAsFactors = FALSE)

  # Site header omits the second "EFA-02" token, so tss_r2_x resolves to NA
  hdr1 <- rbind(
    make_word("DAILY SAMPLE RESULTS - PART B", 200L, 50L),
    make_word("Site",   82L, 172L), make_word("CAL-01", 153L, 172L),
    make_word("FLW-02", 194L, 172L), make_word("FLW-03", 235L, 172L),
    make_word("EFA-01", 280L, 172L), make_word("EFA-02", 327L, 172L),
    make_word("EFB-01", 376L, 172L), make_word("EFB-01", 425L, 172L)
    # note: no second "EFA-02" token here
  )
  p1_rows <- rbind(
    make_word(1L, 72L, 184L), make_word("0.3", 154L, 184L),
    make_word(2L, 72L, 195L), make_word("0.3", 154L, 195L)
  )
  page1 <- rbind(hdr1, p1_rows)

  local_mocked_bindings(
    pdf_data = function(pdf, ...) list(page1),
    .package = "pdftools"
  )

  result <- tbeploads:::.macdill_parse_part_b(tmp)

  r2 <- result[result$outfall == "R-002", ]
  expect_true(is.na(r2$tss_mgl))
})

test_that(".macdill_parse_part_b returns an all-NA 3-row frame when no Mon. Site rows are found", {
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw(1L), tmp)

  local_mocked_bindings(
    pdf_data = function(pdf, ...) list(data.frame(
      text = "nothing relevant here", x = 10L, y = 10L,
      space = FALSE, width = 1L, height = 1L, stringsAsFactors = FALSE
    )),
    .package = "pdftools"
  )

  result <- tbeploads:::.macdill_parse_part_b(tmp)

  expect_equal(sort(result$outfall), c("R-001","R-002","R-003"))
  expect_true(all(is.na(result$flow_mgd)))
  expect_true(all(is.na(result$tn_mgl)))
})

test_that(".macdill_parse_part_b debug = TRUE prints diagnostic output without altering results", {
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw(1L), tmp)

  daily <- list(
    day     = c(1L, 7L),
    r1_flow = c("0.3", "0.3"),
    r2_flow = c("0.02","0.02"),
    r3_flow = c("0.5", "0.5"),
    bod_r1  = c("2.0", "2.0"),
    bod_r23 = c("3.0", "3.0"),
    tss_r13 = c("1.0", "1.0"),
    tss_r2  = c("1.5", "1.5"),
    tn_r3   = c(NA,   "1.8")
  )

  local_mocked_bindings(
    pdf_data = function(pdf, ...) make_part_b_page(daily),
    .package = "pdftools"
  )

  expect_output(
    result <- tbeploads:::.macdill_parse_part_b(tmp, debug = TRUE)
  )
  expect_equal(nrow(result), 3L)
})

# ===========================================================================
# .macdill_oculus_login
# ===========================================================================

test_that(".macdill_oculus_login performs a two-step login and returns a handle when no redirect occurs", {
  login_fn <- tbeploads:::.macdill_oculus_login
  urls_hit <- character(0)

  stub(login_fn, "httr::GET", function(url, ...) {
    urls_hit <<- c(urls_hit, url)
    structure(list(fake_body = "<html>logged in, no redirect</html>"), class = "response")
  })
  stub(login_fn, "httr::content", function(r, type) charToRaw(r$fake_body))

  h <- login_fn()

  expect_s3_class(h, "handle")
  expect_length(urls_hit, 2L)
})

test_that(".macdill_oculus_login follows a window.location redirect when present", {
  login_fn <- tbeploads:::.macdill_oculus_login
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
# .macdill_download_pdf
# ===========================================================================

test_that(".macdill_download_pdf downloads and writes a valid PDF (primary filename pattern)", {
  dl_fn <- tbeploads:::.macdill_download_pdf
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

test_that(".macdill_download_pdf uses the fallback filename pattern when the primary pattern fails", {
  dl_fn <- tbeploads:::.macdill_download_pdf
  dest  <- tempfile(fileext = ".pdf")
  on.exit(unlink(dest), add = TRUE)

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

test_that(".macdill_download_pdf returns FALSE when no filename can be extracted", {
  dl_fn <- tbeploads:::.macdill_download_pdf
  dest  <- tempfile(fileext = ".pdf")

  stub(dl_fn, "httr::GET", function(url, ...)
    structure(list(body = "<html>no matching hidden field here</html>"), class = "response"))
  stub(dl_fn, "httr::content", function(r, type) charToRaw(r$body))

  ok <- dl_fn("38.123.1", dest, NULL)

  expect_false(ok)
  expect_false(file.exists(dest))
})

test_that(".macdill_download_pdf returns FALSE when the downloaded content is not a valid PDF", {
  dl_fn <- tbeploads:::.macdill_download_pdf
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
