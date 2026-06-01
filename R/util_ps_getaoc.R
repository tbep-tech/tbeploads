#' Get AOC LLC discharge monitoring report data from FDEP OCULUS
#'
#' Downloads and parses monthly Part A Discharge Monitoring Report (DMR) PDFs
#' for the AOC LLC industrial wastewater facility (NPDES permit FL0029653,
#' Polk County, FL) from the Florida Department of Environmental Protection
#' (FDEP) OCULUS public document management system.  Returns Average Daily Flow
#' and Total Nitrogen concentration for each available monitoring month.
#'
#' @param yr numeric (length 1), the monitoring year to retrieve (e.g., 2025).
#' @param search_xlsx character, path to an OCULUS search-results spreadsheet
#'   for facility FL0029653.  See Details for instructions on generating this
#'   file.
#' @param pdf_dir character or NULL.  Directory in which to save the downloaded
#'   PDFs.  If `NULL` (default), a temporary directory is used and all PDFs
#'   are deleted when the function exits.  If a path is supplied, PDFs are
#'   retained there.
#' @param out_file character or NULL.  If provided, the results data frame is
#'   written to this path as an `.xlsx` workbook.
#' @param quiet logical.  Suppress progress messages (default `FALSE`).
#'
#' @details
#' ## Generating the OCULUS search spreadsheet
#'
#' The `search_xlsx` file is an Excel export from the FDEP OCULUS public
#' document portal.  To generate it:
#'
#' 1. Navigate to <https://depedms.dep.state.fl.us> in a web browser.
#' 2. Click **Public Oculus Login** (no account required).
#' 3. In the search form, set:
#'    - **Catalog**: Wastewater
#'    - **Profile**: Sampling
#'    - **Facility-Site ID**: FL0029653 (this does not go in the Permit Number field)
#'    - **Document Date**: From MM-DD-YYYY to MM-DD-YYYY (covering the desired monitoring year)
#'    - **Document Type**: Discharge Monitoring Report (DMR)
#' 4. Run the search and export the results to Excel (use the **Export to Excel** button).
#' 5. Save the exported `.xlsx` file and pass its path as `search_xlsx`.
#'
#' The file must contain `HYPERLINK()` formulas in **column A** pointing to
#' the individual DMR PDFs and document subject lines in **column K**.  Both
#' are present in any standard OCULUS search export.
#'
#' ## Document selection
#'
#' The function keeps only monthly (`MO`) Part A documents for the requested
#' year.  Annual summary (`YR`), Part B daily tables, and other document types
#' are excluded automatically.  If a month has multiple submissions (e.g., a
#' revision), the most recently filed document is used.
#'
#' ## Reporting period vs. OCULUS label
#'
#' For some facilities the OCULUS cycle label (e.g., "JAN MO") may not align
#' with the calendar month of the monitoring period.  The month returned in the
#' output is always derived from the **monitoring period dates inside the PDF**,
#' not from the OCULUS label.
#'
#' ## No Discharge (NOD)
#'
#' When the facility reports No Observable Discharge, `adf_mgd` is set to `0`
#' and `tn_mgl` is set to `NA`.  A zero flow value therefore implies no
#' discharge for that month.
#'
#' ## Parameters not currently monitored
#'
#' Total phosphorus (TP), biochemical oxygen demand (BOD), and total suspended
#' solids (TSS) have not been recorded at this facility in recent years and are
#' not included in the output.
#' 
#' ## Verifying results
#'
#' On the initial run, supply a `pdf_dir` path so the downloaded PDFs are
#' retained for inspection.  Verify that the monitoring months, flow values,
#' and TN concentrations in the output data frame match those in the PDFs.
#'
#' @return A data frame with one row per available monitoring month, sorted by
#'   month.  Calendar months for which no Part A document was found are omitted
#'   (a message is printed when `quiet = FALSE`).  Columns:
#'
#'   | Column | Type | Description |
#'   |--------|------|-------------|
#'   | `yr` | integer | Monitoring year (from the PDF monitoring period). |
#'   | `mo` | integer | Calendar month (1–12, from the PDF monitoring period). |
#'   | `adf_mgd` | numeric | Average Daily Flow (MGD). `0` indicates no discharge (NOD). |
#'   | `tn_mgl` | numeric | Total nitrogen grab-sample concentration (mg/L). `NA` when no discharge or not reported. |
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Retrieve 2025 AOC DMR data
#' # (requires an OCULUS search spreadsheet generated as described in Details)
#' df <- util_ps_getaoc(
#'   yr          = 2025,
#'   search_xlsx = "AOC_OCULUSSearchData_2025.xlsx"
#' )
#'
#' # Keep PDFs and save results to Excel
#' df <- util_ps_getaoc(
#'   yr          = 2025,
#'   search_xlsx = "AOC_OCULUSSearchData_2025.xlsx",
#'   pdf_dir     = "~/Desktop/AOC_DMR_2025",
#'   out_file    = "~/Desktop/AOC_DMR_2025_results.xlsx"
#' )
#' }
util_ps_getaoc <- function(yr, search_xlsx, pdf_dir = NULL,
                             out_file = NULL, quiet = FALSE) {

  stopifnot(
    is.numeric(yr) || is.integer(yr), length(yr) == 1L,
    is.character(search_xlsx), length(search_xlsx) == 1L,
    file.exists(search_xlsx)
  )

  user_pdf_dir <- !is.null(pdf_dir)
  if (!user_pdf_dir)
    pdf_dir <- file.path(tempdir(), paste0("aoc_dmr_", yr))
  dir.create(pdf_dir, showWarnings = FALSE, recursive = TRUE)

  # ---- Step 1: Extract GUIDs and subjects from the XLSX hyperlinks ----------
  if (!quiet) cat("Reading document index from:", basename(search_xlsx), "\n")
  doc_index <- .aoc_extract_guids(search_xlsx, yr)

  if (nrow(doc_index) == 0)
    stop(
      "No monthly Part A documents found for year ", yr,
      " in '", search_xlsx, "'.\n",
      "Ensure the file contains HYPERLINK() formulas in column A ",
      "and document subjects in column K (standard OCULUS export format)."
    )

  if (!quiet)
    cat("Found", nrow(doc_index), "monthly Part A document(s).\n")

  # ---- Step 2: Establish a public OCULUS session ----------------------------
  if (!quiet) cat("Logging in to FDEP OCULUS (public access)...\n")
  session <- .aoc_oculus_login()

  # ---- Step 3: Download and parse each monthly PDF -------------------------
  results <- vector("list", nrow(doc_index))

  for (i in seq_len(nrow(doc_index))) {
    guid  <- doc_index$guid[i]
    mon   <- doc_index$month_num[i]
    label <- sprintf("Month %02d (%s)", mon, doc_index$month_str[i])
    dest  <- file.path(pdf_dir, sprintf("%s.pdf", doc_index$month_str[i]))

    if (!quiet) cat(" ", label, "...")

    # Use a cached PDF if it already exists and looks valid (>5 KB)
    if (file.exists(dest) && file.info(dest)$size > 5000L) {
      if (!quiet) cat(" (cached)\n")
    } else {
      ok <- .aoc_download_pdf(guid, dest, session)
      if (!ok) {
        warning(label, ": download failed, skipping.")
        if (!quiet) cat(" FAILED\n")
        next
      }
      if (!quiet) cat(" downloaded\n")
    }

    row <- tryCatch(
      .aoc_parse_pdf(dest),
      error = function(e) {
        warning(label, ": parse error (", conditionMessage(e), "), skipping.")
        NULL
      }
    )
    if (!is.null(row)) results[[i]] <- row
  }

  # ---- Step 4: Combine and report ------------------------------------------
  out <- dplyr::bind_rows(Filter(Negate(is.null), results)) |>
    dplyr::arrange(mo)

  missing_mos <- setdiff(1:12, out$mo)
  if (length(missing_mos) > 0 && !quiet)
    cat(
      "Note: no Part A document found for month(s):",
      paste(month.abb[missing_mos], collapse = ", "), "\n"
    )

  # ---- Step 5: Optional Excel output ----------------------------------------
  if (!is.null(out_file)) {
    if (!quiet) cat("Writing results to:", out_file, "\n")
    wb <- openxlsx::createWorkbook()
    openxlsx::addWorksheet(wb, "AOC_DMR")
    openxlsx::writeData(wb, "AOC_DMR", out)
    openxlsx::saveWorkbook(wb, out_file, overwrite = TRUE)
  }

  # ---- Step 6: Cleanup ------------------------------------------------------
  if (!user_pdf_dir) {
    pdfs <- list.files(pdf_dir, pattern = "\\.pdf$", full.names = TRUE)
    invisible(file.remove(pdfs))
  } else if (!quiet) {
    cat("PDFs retained in:", pdf_dir, "\n")
  }

  return(out)

}

# ===========================================================================
# Internal helpers — not exported
# ===========================================================================

# Extract GUIDs and document subjects from an OCULUS search XLSX.
# Filters to monthly Part A records for the requested year.
.aoc_extract_guids <- function(xlsx_path, yr) {

  tmpdir <- tempfile()
  dir.create(tmpdir)
  on.exit(unlink(tmpdir, recursive = TRUE), add = TRUE)
  utils::unzip(xlsx_path, exdir = tmpdir, overwrite = TRUE)

  sheet_path <- file.path(tmpdir, "xl", "worksheets", "sheet1.xml")
  if (!file.exists(sheet_path))
    stop(
      "Cannot locate worksheet XML in '", xlsx_path, "'. ",
      "Ensure this is a valid .xlsx file (not .xls)."
    )

  # The HYPERLINK() formulas in column A are stored as cell formulas in the
  # sheet XML.  We extract (row-number, GUID) pairs directly from the XML text.
  sheet_txt <- paste(readLines(sheet_path, warn = FALSE), collapse = " ")

  # Strategy: find cell elements that reference column A and contain a GUID
  cell_hits <- gregexpr(
    'r="A(\\d+)"[^>]*>(?:(?!<c ).)*?guid=([0-9]+\\.[0-9]+\\.[0-9]+)',
    sheet_txt, perl = TRUE
  )
  cell_str <- regmatches(sheet_txt, cell_hits)[[1]]

  if (length(cell_str) == 0) {
    # Fallback: extract GUIDs in document order (assumes rows 2, 3, ...)
    guid_hits <- gregexpr('guid=([0-9]+\\.[0-9]+\\.[0-9]+)', sheet_txt, perl = TRUE)
    guid_strs <- regmatches(sheet_txt, guid_hits)[[1]]
    guids <- regmatches(guid_strs, regexpr('[0-9]+\\.[0-9]+\\.[0-9]+', guid_strs))
    rows  <- seq_along(guids) + 1L
  } else {
    rows  <- as.integer(regmatches(cell_str,
                regexpr('(?<=r="A)\\d+', cell_str, perl = TRUE)))
    guids <- regmatches(cell_str,
                regexpr('[0-9]+\\.[0-9]+\\.[0-9]+', cell_str))
  }

  # Read document subjects from the spreadsheet (column K = subject)
  meta <- suppressWarnings(readxl::read_xlsx(xlsx_path, col_names = TRUE))
  col_names_lc <- tolower(names(meta))
  subj_col <- which(grepl("subject", col_names_lc, fixed = TRUE))
  subj_col <- if (length(subj_col) > 0L) subj_col[1L] else min(11L, ncol(meta))

  meta_idx <- rows - 1L   # sheet row 2 = meta index 1 (header is row 1)
  valid    <- meta_idx >= 1L & meta_idx <= nrow(meta)
  subjects <- rep(NA_character_, length(rows))
  subjects[valid] <- as.character(meta[[subj_col]][meta_idx[valid]])

  raw_df <- data.frame(row = rows, guid = guids, subject = subjects,
                        stringsAsFactors = FALSE)

  # Keep only monthly ("MO") Part A documents for the requested year,
  # excluding annual ("YR") summaries and Part B daily tables.
  yr_str   <- as.character(as.integer(yr))
  mo_mask  <- !is.na(raw_df$subject) &
    grepl(yr_str,    raw_df$subject, fixed = TRUE) &
    grepl("\\bMO\\b",     raw_df$subject, perl = TRUE) &
    grepl("\\bPART A\\b", raw_df$subject, perl = TRUE)

  mo_df <- raw_df[mo_mask, ]

  # Extract three-letter month abbreviation from the subject line
  mon_pat      <- "JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC"
  mo_df$month_str <- regmatches(
    mo_df$subject,
    regexpr(paste0("(?<=DMR\\s", yr_str, "\\s)(", mon_pat, ")"),
            mo_df$subject, perl = TRUE)
  )
  mo_df <- mo_df[nchar(mo_df$month_str) == 3L, ]

  month_lu <- setNames(1:12,
    c("JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"))
  mo_df$month_num <- month_lu[mo_df$month_str]

  # If a month has multiple submissions, keep the most recently filed one
  # (highest row index in the spreadsheet = most recently added)
  mo_df <- mo_df[order(mo_df$month_num, -mo_df$row), ]
  mo_df <- mo_df[!duplicated(mo_df$month_num), ]
  mo_df[order(mo_df$month_num), ]
}


# Establish a public OCULUS session via httr handle (cookie-preserving).
.aoc_oculus_login <- function() {

  base <- "https://depedms.dep.state.fl.us"
  ua   <- paste0("Mozilla/5.0 (Windows NT 10.0; Win64; x64) ",
                  "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0")

  h <- httr::handle(base)
  httr::GET(paste0(base, "/Oculus/servlet/login"),
            handle = h, httr::add_headers(`User-Agent` = ua))

  r2 <- httr::GET(paste0(base, "/Oculus/servlet/login?action=doPublicLogin"),
                  handle = h, httr::add_headers(`User-Agent` = ua),
                  httr::config(followlocation = FALSE))

  body2 <- rawToChar(httr::content(r2, "raw"))
  if (grepl("window.location", body2, fixed = TRUE)) {
    redir <- sub('.*window\\.location = "([^"]+)".*', '\\1', body2)
    httr::GET(paste0(base, redir), handle = h, httr::add_headers(`User-Agent` = ua))
  }

  h
}


# Download one DMR PDF from OCULUS to dest_path.
# Returns TRUE on success, FALSE on failure.
.aoc_download_pdf <- function(guid, dest_path, session_handle) {

  base <- "https://depedms.dep.state.fl.us"
  ua   <- paste0("Mozilla/5.0 (Windows NT 10.0; Win64; x64) ",
                  "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0")

  # Fetch the hit-list page to obtain the internal storage filename
  r_list <- httr::GET(
    paste0(base, "/Oculus/servlet/operation",
           "?action=guidHitList&SelectedGuids=", guid,
           "&profile=Sampling&RUN_VIEW_OPERATION_ON_START=true"),
    handle = session_handle,
    httr::add_headers(`User-Agent` = ua),
    httr::config(followlocation = TRUE)
  )
  body <- iconv(rawToChar(httr::content(r_list, "raw")),
                from = "ISO-8859-1", to = "UTF-8")

  # Extract the filename from the hidden _FILE_NAME_<guid> input element
  guid_esc <- gsub(".", "\\.", guid, fixed = TRUE)
  fname_pat <- paste0('(?<=name="_FILE_NAME_', guid_esc,
                       '" type="hidden" value=")[^"]+')
  fname <- regmatches(body, regexpr(fname_pat, body, perl = TRUE))

  # Fallback pattern if the primary match fails
  if (length(fname) == 0L || !nzchar(fname)) {
    ctx_pat <- paste0('_FILE_NAME_', guid_esc, '"[^/]*/?>')
    ctx     <- regmatches(body, regexpr(ctx_pat, body, perl = TRUE))
    fname   <- sub('.*value="([^"]+\\.pdf)".*', '\\1', ctx)
  }

  if (length(fname) == 0L || !grepl("\\.pdf$", fname, ignore.case = TRUE))
    return(FALSE)

  r_pdf <- httr::GET(
    paste0(base, "/Oculus/servlet/operation",
           "?action=opOculusViewEntity",
           "&SelectedGuids=", guid,
           "&fileName=//", fname,
           "&BACK_URL="),
    handle = session_handle,
    httr::add_headers(
      `User-Agent` = ua,
      Referer = paste0(base, "/Oculus/servlet/operation?action=guidHitList")
    )
  )

  raw    <- httr::content(r_pdf, "raw")
  is_pdf <- length(raw) >= 4L &&
    identical(raw[1:4], as.raw(c(0x25, 0x50, 0x44, 0x46)))  # %PDF

  if (is_pdf) {
    writeBin(raw, dest_path)
    return(TRUE)
  }
  FALSE
}


# Parse one AOC Part A DMR PDF and return a one-row data frame.
#
# AOC DMR layout (FDEP Form 62-620.910):
#   Page 1 – Flow, DO, Temperature, pH
#   Page 2 – Nitrogen Total (grab, mg/L) and Nitrogen Total (calculated, ton/month)
#
# Each parameter has a "Sample Measurement" row.  The measured value is either
# a number or "NOD" (No Observable Discharge).
# Flow:  the Sample Measurement line starts with "Flow" and contains
#        [daily-max] [monthly-avg] as the 2nd and 3rd whitespace-delimited
#        tokens (after "Flow" itself).
# TN:    the first "Nitrogen" Sample Measurement line has the grab-sample
#        concentration (mg/L) as the 3rd token.
.aoc_parse_pdf <- function(pdf_path) {

  pages <- pdftools::pdf_text(pdf_path)
  txt   <- paste(pages, collapse = "\n")
  lines <- trimws(strsplit(txt, "\n")[[1]])
  lines <- lines[nchar(lines) > 0L]

  # Monitoring period --------------------------------------------------------
  period_idx <- which(grepl("MONITORING PERIOD.*From:", lines))[1L]
  if (is.na(period_idx))
    stop("Cannot find monitoring period in '", basename(pdf_path), "'.")

  period_line <- lines[period_idx]
  start_str   <- sub(".*From:\\s*(\\d{2}/\\d{2}/\\d{4}).*", "\\1", period_line)
  start_date  <- tryCatch(
    as.Date(start_str, "%m/%d/%Y"),
    error = function(e) stop("Cannot parse date '", start_str, "'.")
  )
  mo_num <- as.integer(format(start_date, "%m"))
  yr_num <- as.integer(format(start_date, "%Y"))

  # Flow Sample Measurement --------------------------------------------------
  # The line begins with "Flow " and is NOT the Permit Requirement line.
  flow_idx <- which(startsWith(lines, "Flow ") &
                      !grepl("Sample|Permit|Requirement", lines))[1L]
  if (is.na(flow_idx))
    stop("Cannot find Flow measurement line in '", basename(pdf_path), "'.")

  flow_tok <- strsplit(trimws(lines[flow_idx]), "\\s+")[[1]]
  flow_val <- flow_tok[3L]   # token 1 = "Flow", 2 = daily max, 3 = monthly avg

  adf_nod <- identical(flow_val, "NOD")
  adf_mgd <- if (adf_nod) 0 else suppressWarnings(as.numeric(flow_val))

  # Total Nitrogen Sample Measurements (page 2) ------------------------------
  tn_idx <- which(startsWith(lines, "Nitrogen"))

  get_tn <- function(idx) {
    if (length(idx) == 0L || is.na(idx))
      return(list(val = NA_real_, nod = FALSE))
    tok <- strsplit(trimws(lines[idx]), "\\s+")[[1]]
    raw <- if (length(tok) >= 3L) tok[3L] else NA_character_
    nod <- identical(raw, "NOD")
    val <- if (nod || is.na(raw)) NA_real_ else suppressWarnings(as.numeric(raw))
    list(val = val, nod = nod)
  }

  tn_grab <- get_tn(tn_idx[1L])   # grab sample, mg/L

  data.frame(
    yr      = yr_num,
    mo      = mo_num,
    adf_mgd = adf_mgd,
    tn_mgl  = tn_grab$val,
    stringsAsFactors = FALSE
  )
}
