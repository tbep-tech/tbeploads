#' Get Kerry I&F discharge monitoring report data from FDEP OCULUS
#'
#' Downloads and parses monthly Part A Discharge Monitoring Report (DMR) PDFs
#' for the Kerry I&F Contracting Company industrial wastewater facility
#' (NPDES permit FL0037389, Hillsborough County, FL) from the Florida
#' Department of Environmental Protection (FDEP) OCULUS public document
#' management system.  Returns Average Daily Flow, BOD, Total Nitrogen, and
#' Total Phosphorus concentration for each available monitoring month.
#'
#' @param yr numeric (length 1), the monitoring year to retrieve (e.g., 2025).
#' @param search_xlsx character, path to an OCULUS search-results spreadsheet
#'   for facility FL0037389.  See Details for instructions on generating this
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
#'    - **Facility-Site ID**: FL0037389 (this does not go in the Permit Number field)
#'    - **Document Date**: From MM-DD-YYYY to MM-DD-YYYY (covering the desired monitoring year)
#'    - **Document Type**: Discharge Monitoring Report (DMR)
#' 4. Run the search and export the results to Excel (use the **Export to Excel** button).
#' 5. Save the exported `.xlsx` file and pass its path as `search_xlsx`.
#'
#' The file must contain `HYPERLINK()` formulas in **column A** pointing to
#' the individual DMR PDFs and document subject lines in **column K**.  Both
#' are present in any standard OCULUS search export.  Also note that the search
#' may return other reports (e.g., toxicity results), which can be safely removed
#' from the Excel file.
#'
#' ## Document selection
#'
#' The function keeps only monthly (`MO`) Part A documents for the requested
#' year.  Annual summary (`YR`) documents are excluded automatically.  If a
#' month has multiple submissions (e.g., a revision such as `"DMR (R) ..."`),
#' the most recently filed document is used.
#'
#' ## Reporting outfall
#'
#' Kerry I&F reports flow separately for three internal monitoring sites
#' (`FLW-1`, `FLW-2`, and `FLW-3`).  `FLW-3` is the calculated combined 
#' flow (`FLW-1` + `FLW-2`) and is
#' the value returned here, consistent with the outfall label used in prior
#' years' data for this facility.
#'
#' ## No Discharge (NOD) and Acceptable Non-Collection (ANC)
#'
#' `NOD` (No Observable Discharge) is treated as zero flow.  `ANC` (Acceptable
#' Not Collected) is treated as `NA`.  Below-detection-limit values (e.g.
#' `"<2"`) are returned as the reported numeric detection limit (`2`), not
#' halved.
#'
#' ## Parameters not currently monitored
#'
#' Total suspended solids (TSS) is not recorded at this facility and is
#' returned as `NA` for all months.
#'
#' ## Verifying results
#'
#' On the initial run, supply a `pdf_dir` path so the downloaded PDFs are
#' retained for inspection.  Verify that the monitoring months, flow values,
#' and concentrations in the output data frame match those in the PDFs.
#'
#' @return A data frame with one row per available monitoring month, sorted by
#'   month.  Calendar months for which no Part A document was found are
#'   omitted (a message is printed when `quiet = FALSE`).  Columns:
#'
#'   | Column | Type | Description |
#'   |--------|------|-------------|
#'   | `yr` | integer | Monitoring year (from the PDF monitoring period). |
#'   | `mo` | integer | Calendar month (1-12, from the PDF monitoring period). |
#'   | `outfall` | character | Always `"FLW-3"` (the combined flow). |
#'   | `flow_mgd` | numeric | Average Daily Flow (MGD), monthly average. `0` indicates no discharge (NOD). |
#'   | `bod_mgl` | numeric | BOD, Carbonaceous (mg/L), monthly maximum. `NA` when ANC or not reported. |
#'   | `tss_mgl` | numeric | Always `NA` (not monitored at this facility). |
#'   | `tn_mgl` | numeric | Total nitrogen grab-sample concentration (mg/L). `NA` when ANC or not reported. |
#'   | `tp_mgl` | numeric | Total phosphorus grab-sample concentration (mg/L). `NA` when ANC or not reported. |
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Retrieve 2025 Kerry I&F DMR data
#' df <- util_ps_getkerry(
#'   yr          = 2025,
#'   search_xlsx = "Kerry_OCULUSSearchData_2025.xlsx"
#' )
#'
#' # Keep PDFs and save results to Excel
#' df <- util_ps_getkerry(
#'   yr          = 2025,
#'   search_xlsx = "Kerry_OCULUSSearchData_2025.xlsx",
#'   pdf_dir     = "~/Desktop/Kerry_DMR_2025",
#'   out_file    = "~/Desktop/Kerry_DMR_2025_results.xlsx"
#' )
#' }
util_ps_getkerry <- function(yr, search_xlsx, pdf_dir = NULL,
                               out_file = NULL, quiet = FALSE) {

  stopifnot(
    is.numeric(yr) || is.integer(yr), length(yr) == 1L,
    is.character(search_xlsx), length(search_xlsx) == 1L,
    file.exists(search_xlsx)
  )

  user_pdf_dir <- !is.null(pdf_dir)
  if (!user_pdf_dir)
    pdf_dir <- file.path(tempdir(), paste0("kerry_dmr_", yr))
  dir.create(pdf_dir, showWarnings = FALSE, recursive = TRUE)

  # ---- Step 1: Extract GUIDs and subjects from the XLSX hyperlinks ----------
  if (!quiet) cat("Reading document index from:", basename(search_xlsx), "\n")
  doc_index <- .kerry_extract_guids(search_xlsx, yr)

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
  session <- .kerry_oculus_login()

  # ---- Step 3: Download and parse each monthly PDF -------------------------
  results <- vector("list", nrow(doc_index))

  for (i in seq_len(nrow(doc_index))) {
    guid  <- doc_index$guid[i]
    mon   <- doc_index$month_num[i]
    label <- sprintf("Month %02d (%s)", mon, doc_index$month_str[i])
    dest  <- file.path(pdf_dir, sprintf("%s.pdf", doc_index$month_str[i]))

    if (!quiet) cat(" ", label, "...")

    if (file.exists(dest) && file.info(dest)$size > 5000L) {
      if (!quiet) cat(" (cached)\n")
    } else {
      ok <- .kerry_download_pdf(guid, dest, session)
      if (!ok) {
        warning(label, ": download failed, skipping.")
        if (!quiet) cat(" FAILED\n")
        next
      }
      if (!quiet) cat(" downloaded\n")
    }

    row <- tryCatch(
      .kerry_parse_pdf(dest),
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
    openxlsx::addWorksheet(wb, "Kerry_DMR")
    openxlsx::writeData(wb, "Kerry_DMR", out)
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
# Filters to monthly Part A records for the requested year.  Note the month
# is matched via a lookahead on "MO" (rather than a lookbehind on "DMR yr")
# so that revision-prefixed subjects (e.g. "DMR (R) 2025 APR MO PART A")
# still resolve to the correct month.
.kerry_extract_guids <- function(xlsx_path, yr) {

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

  sheet_txt <- paste(readLines(sheet_path, warn = FALSE), collapse = " ")

  cell_hits <- gregexpr(
    'r="A(\\d+)"[^>]*>(?:(?!<c ).)*?guid=([0-9]+\\.[0-9]+\\.[0-9]+)',
    sheet_txt, perl = TRUE
  )
  cell_str <- regmatches(sheet_txt, cell_hits)[[1]]

  if (length(cell_str) == 0) {
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

  meta <- suppressWarnings(readxl::read_xlsx(xlsx_path, col_names = TRUE))
  col_names_lc <- tolower(names(meta))
  subj_col <- which(grepl("subject", col_names_lc, fixed = TRUE))
  subj_col <- if (length(subj_col) > 0L) subj_col[1L] else min(11L, ncol(meta))

  meta_idx <- rows - 1L
  valid    <- meta_idx >= 1L & meta_idx <= nrow(meta)
  subjects <- rep(NA_character_, length(rows))
  subjects[valid] <- as.character(meta[[subj_col]][meta_idx[valid]])

  raw_df <- data.frame(row = rows, guid = guids, subject = subjects,
                        stringsAsFactors = FALSE)

  yr_str   <- as.character(as.integer(yr))
  mo_mask  <- !is.na(raw_df$subject) &
    grepl(yr_str,    raw_df$subject, fixed = TRUE) &
    grepl("\\bMO\\b",     raw_df$subject, perl = TRUE) &
    grepl("\\bPART A\\b", raw_df$subject, perl = TRUE)

  mo_df <- raw_df[mo_mask, ]

  mon_pat <- "JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC"
  mo_df$month_str <- regmatches(
    mo_df$subject,
    regexpr(paste0("(", mon_pat, ")(?=\\s+MO\\b)"), mo_df$subject, perl = TRUE)
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
# Identical logic to util_ps_getaoc()/util_ps_getmacdill().
.kerry_oculus_login <- function() {

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


# Download one DMR PDF from OCULUS to dest_path.  Identical logic to
# util_ps_getaoc()/util_ps_getmacdill().  Returns TRUE on success, FALSE on
# failure.
.kerry_download_pdf <- function(guid, dest_path, session_handle) {

  base <- "https://depedms.dep.state.fl.us"
  ua   <- paste0("Mozilla/5.0 (Windows NT 10.0; Win64; x64) ",
                  "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0")

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

  guid_esc <- gsub(".", "\\.", guid, fixed = TRUE)
  fname_pat <- paste0('(?<=name="_FILE_NAME_', guid_esc,
                       '" type="hidden" value=")[^"]+')
  fname <- regmatches(body, regexpr(fname_pat, body, perl = TRUE))

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


# Parse one Kerry I&F Part A DMR PDF and return a one-row data frame.
#
# Kerry DMR layout (FDEP Form 62-620.910), Part A only:
#   Flow reported at three "Mon. Site" locations: FLW-1, FLW-2, FLW-3
#     (FLW-3 is the calculated combined flow to outfall D-001; PARM 50050 Q).
#   BOD, Carbonaceous 5 day, 20C (PARM 80082 1) at Mon. Site EFF-1 -- Daily Mx.
#   Nitrogen, Total (PARM 00600 1) at Mon. Site EFF-1 -- Daily Mx, mg/L grab
#     sample concentration.  (A second "Nitrogen, Total" block, PARM 00600 P,
#     reports the calculated *load* in ton/yr and must not be confused with
#     this one.)
#   Phosphorus, Total (as P) (PARM 00665 1) at Mon. Site EFF-1 -- Daily Mx.
#   TSS is not monitored at this facility and is not present in the PDF.
#
# Every parameter's "Sample Measurement" value(s) appear on the same line as
# the parameter name, followed on the next line by the word "Measurement"
# (a wrapped sub-label), then the "PARM Code ..." line.  Values are anchored
# by the fixed trailing "<No. Ex.> <Freq. count> <frequency> <sample type>"
# columns (e.g. "0  1 Monthly  Grab"), which lets the value token(s) be
# captured unambiguously even when the parameter name itself contains
# numbers (e.g. "BOD, Carbonaceous 5 day, 20C").
.kerry_parse_pdf <- function(pdf_path) {

  pages <- pdftools::pdf_text(pdf_path)
  txt   <- paste(pages, collapse = "\n")
  lines <- trimws(strsplit(txt, "\n")[[1]])
  lines <- lines[nchar(lines) > 0L]

  period_idx <- which(grepl("MONITORING PERIOD.*From:", lines))[1L]
  if (is.na(period_idx))
    stop("Cannot find monitoring period in '", basename(pdf_path), "'.")

  start_str  <- sub(".*From:\\s*(\\d{2}/\\d{2}/\\d{4}).*", "\\1", lines[period_idx])
  start_date <- tryCatch(
    as.Date(start_str, "%m/%d/%Y"),
    error = function(e) stop("Cannot parse date '", start_str, "'.")
  )

  flow_vals <- .kerry_extract_val(lines, "^PARM Code 50050 Q", n_values = 2L)
  bod_val   <- .kerry_extract_val(lines, "^PARM Code 80082 1", n_values = 1L)
  tn_val    <- .kerry_extract_val(lines, "^PARM Code 00600 1", n_values = 1L)
  tp_val    <- .kerry_extract_val(lines, "^PARM Code 00665 1", n_values = 1L)

  data.frame(
    yr       = as.integer(format(start_date, "%Y")),
    mo       = as.integer(format(start_date, "%m")),
    outfall  = "FLW-3",
    flow_mgd = .kerry_parse_tok(flow_vals[1L], nod_zero = TRUE),
    bod_mgl  = .kerry_parse_tok(bod_val[1L]),
    tss_mgl  = NA_real_,
    tn_mgl   = .kerry_parse_tok(tn_val[1L]),
    tp_mgl   = .kerry_parse_tok(tp_val[1L]),
    stringsAsFactors = FALSE
  )
}

# Locate the "PARM Code <parm_pat>" line and pull the value(s) reported on its
# parameter line, which sits either one line above (label + values on one
# line) or two lines above (when a wrapped "Measurement" sub-label line sits
# in between).  Values are anchored against the fixed trailing
# "<No. Ex.> <Freq count> <frequency word> <sample-type word>" columns.
.kerry_extract_val <- function(lines, parm_pat, n_values = 1L) {
  parm_idx <- which(grepl(parm_pat, lines))[1L]
  if (is.na(parm_idx) || parm_idx < 3L) return(rep(NA_character_, n_values))

  val_line <- if (lines[parm_idx - 1L] == "Measurement")
    lines[parm_idx - 2L] else lines[parm_idx - 1L]

  pat <- if (n_values == 2L)
    "(\\S+)\\s+(\\S+)\\s+0\\s+1\\s+\\S+\\s+\\S+\\s*$"
  else
    "(\\S+)\\s+0\\s+1\\s+\\S+\\s+\\S+\\s*$"

  m <- regmatches(val_line, regexec(pat, val_line))[[1L]]
  if (length(m) < (n_values + 1L)) return(rep(NA_character_, n_values))
  m[2:(n_values + 1L)]
}

# Parse a raw measurement token (NOD / ANC / <N / numeric).
# nod_zero = TRUE treats "NOD" as 0 (used for flow); otherwise NOD is NA.
.kerry_parse_tok <- function(tok, nod_zero = FALSE) {
  if (is.na(tok) || !nzchar(tok) || tok == "ANC")
    return(NA_real_)
  if (tok == "NOD")
    return(if (nod_zero) 0 else NA_real_)
  if (startsWith(tok, "<"))
    return(suppressWarnings(as.numeric(sub("^<", "", tok))))
  suppressWarnings(as.numeric(tok))
}
