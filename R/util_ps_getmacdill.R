#' Get MacDill AFB WWTP discharge monitoring report data from FDEP OCULUS
#'
#' Downloads and parses monthly Discharge Monitoring Report (DMR) PDFs for the
#' MacDill Air Force Base wastewater treatment plant (NPDES permit FLA012124,
#' Hillsborough County, FL) from the FDEP OCULUS public document system.
#' Returns monthly effluent parameters for three discharge outfalls.
#'
#' @param yr numeric (length 1), the monitoring year to retrieve (e.g., 2025).
#' @param search_xlsx character, path to an OCULUS search-results spreadsheet
#'   for facility FLA012124.  See Details for instructions on generating this
#'   file.
#' @param pdf_dir character or NULL.  Directory in which to save the downloaded
#'   PDFs.  If `NULL` (default), a temporary directory is used and all PDFs
#'   are deleted when the function exits.  If a path is supplied, PDFs are
#'   retained there under human-readable names
#'   (`macdill_{yr}_{mo}_{type}.pdf`).
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
#'    - **Facility-Site ID**: FLA012124 (not the Permit Number field)
#'    - **Document Date**: From MM-DD-YYYY to MM-DD-YYYY (covering the desired year)
#'    - **Document Type**: Discharge Monitoring Report (DMR)
#' 4. Run the search and export the results to Excel (**Export to Excel** button).
#' 5. Save the exported `.xlsx` and pass its path as `search_xlsx`.
#'
#' The file must contain `HYPERLINK()` formulas in **column A** and document
#' subject lines in **column K**, both of which are present in any standard
#' OCULUS search export.
#'
#' ## Document selection and classification
#'
#' All monthly (`MO`) documents for the requested year are downloaded and
#' inspected.  Each PDF is then classified by its actual content:
#'
#' - **Part A** (monthly summary) — contains the official permit-limit table
#'   with pre-computed monthly averages and permit compliance results.
#' - **Part B** (daily sample results) — contains a day-by-day table of flow
#'   and effluent quality measurements for a given month.
#'
#' The OCULUS document labels ("Part A", "Part B") are not always reliable for
#' this facility, so the function detects content type from the PDF text.  Annual
#' summary (`YR`) documents are excluded automatically.
#'
#' Some older submissions are scanned image PDFs with no embedded text layer.
#' These cannot be parsed and are saved as
#' `macdill_unclassified_{document_subject}.pdf` in `pdf_dir` (when
#' `pdf_dir` is supplied) so you can identify them from their OCULUS subject
#' line and enter the values manually if needed.
#'
#' ## Hybrid extraction methodology
#'
#' Where a Part B daily table is available for a given calendar month, BOD and
#' TSS are computed as the mean of all observed daily values using the
#' substitution rules `<1 \u{2192} 0.5` and `<2 \u{2192} 1.0` (consistent with the
#' 2022–2024 reporting methodology).  Monthly average flow is also derived from
#' Part B daily readings when available.  For months with no Part B, Part A
#' monthly-summary values are used for BOD, TSS, and flow.
#'
#' Total nitrogen (`tn_mgl`) is always sourced from Part A because Part B
#' tables do not include a TN column.
#'
#' ## Monitoring period vs. OCULUS label
#'
#' The OCULUS document cycle labels (e.g., "JAN MO") do not always align with
#' the calendar month of the monitoring period.  The `mo` column in the output
#' is always derived from the monitoring period dates inside the PDF, not
#' from the OCULUS label.
#'
#' ## No Discharge (NOD) and acceptable non-collection (ANC)
#'
#' `NOD` (No Observable Discharge) is treated as zero flow and `NA`
#' concentration.  `ANC` (Acceptable Not Collected) is treated as `NA`.
#'
#' @return A data frame with three rows per available monitoring month (one per
#'   outfall), sorted by month then outfall.  Calendar months for which no
#'   usable document was found are omitted (a message is printed when
#'   `quiet = FALSE`).  Columns:
#'
#'   | Column | Type | Description |
#'   |--------|------|-------------|
#'   | `yr` | integer | Monitoring year (from the PDF monitoring period). |
#'   | `mo` | integer | Calendar month (1–12). |
#'   | `outfall` | character | Outfall ID: `"R-001"`, `"R-002"`, or `"R-003"`. |
#'   | `flow_mgd` | numeric | Average Daily Flow (MGD). `0` when NOD. |
#'   | `bod_mgl` | numeric | BOD (mg/L). `NA` when ANC or not collected. |
#'   | `tss_mgl` | numeric | TSS (mg/L). `NA` when ANC or not collected. |
#'   | `tn_mgl` | numeric | Total nitrogen as NO3-N (mg/L), R-003 only. `NA` for R-001 and R-002. |
#'   | `verify` | logical | `TRUE` when one or more concentration values (TSS for R-001/R-003, TN for R-003) are single-day **maximums** from Part A rather than monthly averages. This occurs when no machine-readable Part B was available. Cross-check these values against the original PDF. |
#'
#' @export
#'
#' @seealso [util_ps_checkfls()], [anlz_ips()]
#'
#' @examples
#' \dontrun{
#' # Retrieve 2025 MacDill DMR data
#' df <- util_ps_getmacdill(
#'   yr          = 2025,
#'   search_xlsx = "MacDill_OCULUSSearchData_2025.xlsx"
#' )
#'
#' # Keep PDFs and save results to Excel
#' df <- util_ps_getmacdill(
#'   yr          = 2025,
#'   search_xlsx = "MacDill_OCULUSSearchData_2025.xlsx",
#'   pdf_dir     = "~/Desktop/MacDill_DMR_2025",
#'   out_file    = "~/Desktop/MacDill_DMR_2025_results.xlsx",
#'   keep_pdfs   = TRUE
#' )
#' }
util_ps_getmacdill <- function(yr, search_xlsx, pdf_dir = NULL,
                                 out_file = NULL, quiet = FALSE) {

  stopifnot(
    is.numeric(yr) || is.integer(yr), length(yr) == 1L,
    is.character(search_xlsx), length(search_xlsx) == 1L,
    file.exists(search_xlsx)
  )

  user_pdf_dir <- !is.null(pdf_dir)
  if (!user_pdf_dir)
    pdf_dir <- file.path(tempdir(), paste0("macdill_dmr_", yr))
  dir.create(pdf_dir, showWarnings = FALSE, recursive = TRUE)

  # ---- Step 1: Extract candidate GUIDs from XLSX ---------------------------
  if (!quiet) cat("Reading document index from:", basename(search_xlsx), "\n")
  doc_index <- .macdill_extract_guids(search_xlsx, yr)

  if (nrow(doc_index) == 0L)
    stop(
      "No monthly documents found for year ", yr, " in '", search_xlsx, "'.\n",
      "Ensure the file contains HYPERLINK() formulas in column A and ",
      "document subjects in column K (standard OCULUS export format)."
    )
  if (!quiet) cat("Found", nrow(doc_index), "candidate monthly document(s).\n")

  # ---- Step 2: Login -------------------------------------------------------
  if (!quiet) cat("Logging in to FDEP OCULUS (public access)...\n")
  session <- .macdill_oculus_login()

  # ---- Step 3: Download and classify each PDF ------------------------------
  pdf_info <- list()

  for (i in seq_len(nrow(doc_index))) {
    guid <- doc_index$guid[i]
    dest <- file.path(pdf_dir, paste0(guid, ".pdf"))

    if (!quiet) cat(sprintf("  [%d/%d] %s ...", i, nrow(doc_index), guid))

    if (file.exists(dest) && file.info(dest)$size > 5000L) {
      if (!quiet) cat(" (cached)")
    } else {
      ok <- .macdill_download_pdf(guid, dest, session)
      if (!ok) {
        if (!quiet) cat(" FAILED\n")
        next
      }
    }

    info <- tryCatch(.macdill_classify_pdf(dest), error = function(e) NULL)

    if (is.null(info)) {
      # Scanned / image-only PDF: rename using OCULUS subject so the user
      # can identify it, then skip parsing.
      subj      <- doc_index$subject[i]
      safe_subj <- gsub("[^A-Za-z0-9-]", "_", subj)
      safe_subj <- gsub("_+", "_", safe_subj)
      safe_subj <- sub("^_+|_+$", "", safe_subj)
      unclass_path <- file.path(pdf_dir,
                                paste0("macdill_unclassified_", safe_subj, ".pdf"))
      if (file.exists(dest)) file.rename(dest, unclass_path)
      if (!quiet) cat(sprintf(" [unclassifiable — saved as %s]\n",
                              basename(unclass_path)))
      next
    }
    if (info$year != as.integer(yr)) {
      if (!quiet) cat(sprintf(" [year %d, skipping]\n", info$year))
      next
    }

    if (!quiet)
      cat(sprintf(" %s month=%02d\n", info$type, info$month))

    pdf_info[[length(pdf_info) + 1L]] <- list(
      guid  = guid,
      file  = dest,
      type  = info$type,
      month = info$month,
      year  = info$year,
      row   = doc_index$row[i]   # original row in XLSX — higher = filed later
    )
  }

  if (length(pdf_info) == 0L) {
    if (!quiet) cat("No usable PDFs found.\n")
    return(.macdill_empty_df())
  }

  # ---- Step 4: Group by month, rename, and parse ----------------------------
  pdf_df     <- do.call(rbind, lapply(pdf_info, as.data.frame, stringsAsFactors = FALSE))
  pdf_df$row <- as.integer(pdf_df$row)
  pdf_df$month <- as.integer(pdf_df$month)

  months_found <- sort(unique(pdf_df$month))
  results      <- vector("list", length(months_found))

  # Helper: rename a downloaded PDF from its GUID name to a readable name.
  # Returns the new path (whether or not the rename succeeded).
  rename_to_sensible <- function(old_path, mo, type) {
    new_path <- file.path(pdf_dir,
                          sprintf("macdill_%d_%02d_%s.pdf", as.integer(yr), mo, type))
    if (file.exists(old_path) && old_path != new_path)
      file.rename(old_path, new_path)
    new_path
  }

  for (k in seq_along(months_found)) {
    mo      <- months_found[k]
    mo_docs <- pdf_df[pdf_df$month == mo, ]

    parta_docs <- mo_docs[mo_docs$type == "partA", ]
    partb_docs <- mo_docs[mo_docs$type == "partB", ]

    best_a <- if (nrow(parta_docs) > 0L) parta_docs[which.max(parta_docs$row), ] else NULL
    best_b <- if (nrow(partb_docs) > 0L) partb_docs[which.max(partb_docs$row), ] else NULL

    # Rename selected files to human-readable names before parsing.
    if (!is.null(best_a)) {
      best_a$file <- rename_to_sensible(best_a$file, mo, "partA")
    }
    if (!is.null(best_b)) {
      best_b$file <- rename_to_sensible(best_b$file, mo, "partB")
    }

    # Selection: prefer Part A when available; fall back to Part B only when
    # no Part A exists for this month.
    parta_data <- if (!is.null(best_a))
      tryCatch(.macdill_parse_part_a(best_a$file), error = function(e) NULL)
    else NULL

    partb_data <- if (!is.null(best_b))
      tryCatch(.macdill_parse_part_b(best_b$file), error = function(e) NULL)
    else NULL

    # Hybrid merge: start with Part A values, then override BOD, TSS, and flow
    # with Part B daily averages (<1->0.5, <2->1 substitution) when available.
    # Part A always provides TN (not reported in Part B tables).
    if (!is.null(parta_data)) {
      merged <- parta_data
      if (!is.null(partb_data)) {
        for (outfall in c("R-001","R-002","R-003")) {
          pa <- merged$outfall == outfall
          pb <- partb_data$outfall == outfall
          if (!any(pb)) next
          if (!is.na(partb_data$flow_mgd[pb])) merged$flow_mgd[pa] <- partb_data$flow_mgd[pb]
          if (!is.na(partb_data$bod_mgl[pb]))  merged$bod_mgl[pa]  <- partb_data$bod_mgl[pb]
          if (!is.na(partb_data$tss_mgl[pb]))  merged$tss_mgl[pa]  <- partb_data$tss_mgl[pb]
        }
      }
    } else if (!is.null(partb_data)) {
      merged <- partb_data   # TN will be NA (not available in Part B)
    } else {
      next
    }

    # Compute verify flag: TRUE when a non-NA concentration value came from a
    # Part A single-day Maximum rather than a monthly average.
    # Affected parameters: TSS for R-001 and R-003 (PARM 00530 B = Maximum),
    # and TN for R-003 (PARM 00620 A = Maximum).  R-002 TSS and all BOD/flow
    # values are monthly averages regardless of source.
    pb_tss_r1 <- !is.null(partb_data) &&
      !is.na(partb_data$tss_mgl[partb_data$outfall == "R-001"])
    pb_tss_r3 <- !is.null(partb_data) &&
      !is.na(partb_data$tss_mgl[partb_data$outfall == "R-003"])
    pb_tn_r3  <- !is.null(partb_data) &&
      !is.na(partb_data$tn_mgl[partb_data$outfall  == "R-003"])

    verify_r1 <- !pb_tss_r1 && !is.na(merged$tss_mgl[merged$outfall == "R-001"])
    verify_r3 <- (!pb_tss_r3 && !is.na(merged$tss_mgl[merged$outfall == "R-003"])) ||
                 (!pb_tn_r3  && !is.na(merged$tn_mgl[ merged$outfall == "R-003"]))

    merged$verify <- c(
      "R-001" = verify_r1,
      "R-002" = FALSE,
      "R-003" = verify_r3
    )[merged$outfall]

    merged$yr <- as.integer(yr)
    merged$mo <- mo
    results[[k]] <- merged[, c("yr","mo","outfall","flow_mgd","bod_mgl",
                                "tss_mgl","tn_mgl","verify")]
  }

  out <- dplyr::bind_rows(Filter(Negate(is.null), results)) |>
    dplyr::arrange(mo, outfall)

  missing_mos <- setdiff(1:12, out$mo)
  if (length(missing_mos) > 0L && !quiet)
    cat("Note: no usable document found for month(s):",
        paste(month.abb[missing_mos], collapse = ", "), "\n")

  # ---- Step 5: Optional Excel output ---------------------------------------
  if (!is.null(out_file)) {
    if (!quiet) cat("Writing results to:", out_file, "\n")
    wb <- openxlsx::createWorkbook()
    openxlsx::addWorksheet(wb, "MacDill_DMR")
    openxlsx::writeData(wb, "MacDill_DMR", out)
    openxlsx::saveWorkbook(wb, out_file, overwrite = TRUE)
  }

  # ---- Step 6: Cleanup -----------------------------------------------------
  all_pdfs <- list.files(pdf_dir, pattern = "\\.pdf$", full.names = TRUE)
  if (!user_pdf_dir) {
    # Temp directory: remove everything
    invisible(file.remove(all_pdfs))
  } else {
    # User-supplied directory: remove raw GUID-named files only.
    # GUID files match the pattern NN.NNNNNNN.N.pdf (digits separated by dots).
    # Sensibly-named files (macdill_YYYY_MM_partX.pdf) do not match and are kept.
    guid_pdfs <- list.files(pdf_dir,
                             pattern = "^[0-9]+\\.[0-9]+\\.[0-9]+\\.pdf$",
                             full.names = TRUE)
    if (length(guid_pdfs) > 0L) invisible(file.remove(guid_pdfs))
    if (!quiet) cat("PDFs retained in:", pdf_dir, "\n")
  }

  return(out)
}

# ===========================================================================
# Internal helpers
# ===========================================================================

.macdill_empty_df <- function() {
  data.frame(yr = integer(), mo = integer(), outfall = character(),
             flow_mgd = numeric(), bod_mgl = numeric(),
             tss_mgl = numeric(), tn_mgl = numeric(), verify = logical(),
             stringsAsFactors = FALSE)
}

# ---- GUID extraction -------------------------------------------------------
# Unlike AOC (which keeps only Part A docs), MacDill keeps ALL monthly docs
# so we can detect Part A vs Part B from the PDF content after download.

.macdill_extract_guids <- function(xlsx_path, yr) {
  tmpdir <- tempfile()
  dir.create(tmpdir)
  on.exit(unlink(tmpdir, recursive = TRUE), add = TRUE)
  utils::unzip(xlsx_path, exdir = tmpdir, overwrite = TRUE)

  sheet_path <- file.path(tmpdir, "xl", "worksheets", "sheet1.xml")
  if (!file.exists(sheet_path))
    stop("Cannot locate worksheet XML in '", xlsx_path, "'. Ensure this is a .xlsx file.")

  sheet_txt <- paste(readLines(sheet_path, warn = FALSE), collapse = " ")

  # Extract (row, GUID) from HYPERLINK formulas in column A
  cell_hits <- gregexpr(
    'r="A(\\d+)"[^>]*>(?:(?!<c ).)*?guid=([0-9]+\\.[0-9]+\\.[0-9]+)',
    sheet_txt, perl = TRUE
  )
  cell_str <- regmatches(sheet_txt, cell_hits)[[1]]

  if (length(cell_str) == 0L) {
    guid_hits <- gregexpr('guid=([0-9]+\\.[0-9]+\\.[0-9]+)', sheet_txt, perl = TRUE)
    guid_strs <- regmatches(sheet_txt, guid_hits)[[1]]
    guids <- regmatches(guid_strs, regexpr('[0-9]+\\.[0-9]+\\.[0-9]+', guid_strs))
    rows  <- seq_along(guids) + 1L
  } else {
    rows  <- as.integer(regmatches(cell_str,
                regexpr('(?<=r="A)\\d+', cell_str, perl = TRUE)))
    guids <- regmatches(cell_str, regexpr('[0-9]+\\.[0-9]+\\.[0-9]+', cell_str))
  }

  meta     <- suppressWarnings(readxl::read_xlsx(xlsx_path, col_names = TRUE))
  subj_col <- which(grepl("subject", tolower(names(meta)), fixed = TRUE))
  subj_col <- if (length(subj_col) > 0L) subj_col[1L] else min(11L, ncol(meta))

  meta_idx <- rows - 1L
  valid    <- meta_idx >= 1L & meta_idx <= nrow(meta)
  subjects <- rep(NA_character_, length(rows))
  subjects[valid] <- as.character(meta[[subj_col]][meta_idx[valid]])

  raw_df <- data.frame(row = rows, guid = guids, subject = subjects,
                        stringsAsFactors = FALSE)

  # Keep: year in subject, MO present, YR absent
  yr_str  <- as.character(as.integer(yr))
  mo_mask <- !is.na(raw_df$subject) &
    grepl(yr_str,    raw_df$subject, fixed  = TRUE) &
    grepl("\\bMO\\b", raw_df$subject, perl  = TRUE) &
    !grepl("\\bYR\\b", raw_df$subject, perl = TRUE)

  mo_df <- raw_df[mo_mask, ]
  mo_df[!duplicated(mo_df$guid), ]   # drop any duplicate GUIDs
}

# ---- OCULUS login (identical logic to AOC) --------------------------------

.macdill_oculus_login <- function() {
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

# ---- PDF download (identical logic to AOC) --------------------------------

.macdill_download_pdf <- function(guid, dest_path, session_handle) {
  base <- "https://depedms.dep.state.fl.us"
  ua   <- paste0("Mozilla/5.0 (Windows NT 10.0; Win64; x64) ",
                  "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0")
  r_list <- httr::GET(
    paste0(base, "/Oculus/servlet/operation",
           "?action=guidHitList&SelectedGuids=", guid,
           "&profile=Sampling&RUN_VIEW_OPERATION_ON_START=true"),
    handle = session_handle, httr::add_headers(`User-Agent` = ua),
    httr::config(followlocation = TRUE)
  )
  body <- iconv(rawToChar(httr::content(r_list, "raw")),
                from = "ISO-8859-1", to = "UTF-8")
  guid_esc <- gsub(".", "\\.", guid, fixed = TRUE)
  fname    <- regmatches(body,
    regexpr(paste0('(?<=name="_FILE_NAME_', guid_esc,
                   '" type="hidden" value=")[^"]+'), body, perl = TRUE))
  if (length(fname) == 0L || !nzchar(fname)) {
    ctx   <- regmatches(body,
      regexpr(paste0('_FILE_NAME_', guid_esc, '"[^/]*/?>'), body, perl = TRUE))
    fname <- sub('.*value="([^"]+\\.pdf)".*', '\\1', ctx)
  }
  if (length(fname) == 0L || !grepl("\\.pdf$", fname, ignore.case = TRUE))
    return(FALSE)
  r_pdf <- httr::GET(
    paste0(base, "/Oculus/servlet/operation",
           "?action=opOculusViewEntity&SelectedGuids=", guid,
           "&fileName=//", fname, "&BACK_URL="),
    handle = session_handle,
    httr::add_headers(`User-Agent` = ua,
                      Referer = paste0(base, "/Oculus/servlet/operation?action=guidHitList"))
  )
  raw    <- httr::content(r_pdf, "raw")
  is_pdf <- length(raw) >= 4L &&
    identical(raw[1:4], as.raw(c(0x25, 0x50, 0x44, 0x46)))
  if (is_pdf) { writeBin(raw, dest_path); return(TRUE) }
  FALSE
}

# ---- Classify PDF: detect Part A or Part B, extract monitoring period -----

.macdill_classify_pdf <- function(pdf_path) {
  page1 <- pdftools::pdf_text(pdf_path)[[1L]]

  if (grepl("DAILY SAMPLE RESULTS", page1, fixed = TRUE)) {
    type       <- "partB"
    period_pat <- "(?:Monitoring Period|MONITORING PERIOD).*From:\\s*(\\d{1,2}/\\d{1,2}/\\d{4})"
  } else if (grepl("DISCHARGE MONITORING REPORT", page1, fixed = TRUE)) {
    type       <- "partA"
    period_pat <- "MONITORING PERIOD.*From:\\s*(\\d{2}/\\d{2}/\\d{4})"
  } else {
    return(NULL)
  }

  m <- regexpr(period_pat, page1, perl = TRUE)
  if (m == -1L) return(NULL)

  # Extract the date from the first capture group directly using its position.
  # Using sub() with a greedy .* is unreliable: for a two-digit month like
  # "11/01/2022", greedy .* can consume the leading "1" and leave "1/01/2022",
  # causing the month to be parsed as 1 (January) instead of 11 (November).
  cap_start  <- attr(m, "capture.start")[1L]
  cap_length <- attr(m, "capture.length")[1L]
  if (cap_start == -1L || cap_length == -1L) return(NULL)
  date_str   <- substr(page1, cap_start, cap_start + cap_length - 1L)

  start_date <- tryCatch(as.Date(date_str, "%m/%d/%Y"), error = function(e) NULL)
  if (is.null(start_date) || is.na(start_date)) return(NULL)

  list(type  = type,
       month = as.integer(format(start_date, "%m")),
       year  = as.integer(format(start_date, "%Y")))
}

# ---- Parse Part A: monthly summary -----------------------------------------

.macdill_parse_part_a <- function(pdf_path) {
  pages <- pdftools::pdf_text(pdf_path)
  txt   <- paste(pages, collapse = "\n")
  lines <- trimws(strsplit(txt, "\n")[[1]])
  lines <- lines[nchar(lines) > 0L]

  grp_idx   <- which(grepl("MONITORING GROUP:\\s*(R-001|R-002|R-003)", lines, perl = TRUE))
  grp_names <- regmatches(lines[grp_idx], regexpr("R-00[123]", lines[grp_idx]))

  if (length(grp_idx) == 0L)
    return(data.frame(outfall = c("R-001","R-002","R-003"),
                      flow_mgd = NA_real_, bod_mgl = NA_real_,
                      tss_mgl  = NA_real_, tn_mgl  = NA_real_,
                      stringsAsFactors = FALSE))

  sec_ends <- c(grp_idx[-1L] - 1L, length(lines))

  dplyr::bind_rows(lapply(seq_along(grp_idx), function(i)
    .macdill_parse_group(lines[grp_idx[i]:sec_ends[i]], grp_names[i])
  ))
}

# Parse one monitoring-group section from a Part A PDF.
.macdill_parse_group <- function(lines, group_name) {
  # Flow: Mo Avg value (first value at the Requirement line marked "Mo Avg")
  flow_raw <- .macdill_extract_val(lines, "^Flow\\s", "Mo Avg", 1L)
  flow_p   <- .macdill_parse_tok(flow_raw)
  flow_mgd <- if (isTRUE(flow_p$nod)) 0 else flow_p$val

  # BOD: Monthly Average (last of Max / Wkly Avg / Mo Avg triple)
  bod_raw <- .macdill_extract_val(lines, "BOD.*Carbon", "Mo Avg", -1L)
  bod_p   <- .macdill_parse_tok(bod_raw)

  # TSS: Mo Avg for R-002; Maximum for R-001 and R-003
  tss_timing <- if (group_name == "R-002") "Mo Avg" else "Maximum"
  tss_index  <- if (group_name == "R-002") -1L else 1L
  tss_raw    <- .macdill_extract_val(lines, "Solids.*Suspended", tss_timing, tss_index)
  tss_p      <- .macdill_parse_tok(tss_raw)

  # TN: R-003 only (Total nitrogen reported as Nitrate-N)
  tn_p <- if (group_name == "R-003") {
    tn_raw <- .macdill_extract_val(lines, "Nitrogen.*Nitrate|Nitrate.*Nitrogen", "Maximum", 1L)
    .macdill_parse_tok(tn_raw)
  } else list(val = NA_real_, nod = FALSE)

  data.frame(outfall  = group_name,
             flow_mgd = flow_mgd,
             bod_mgl  = bod_p$val,
             tss_mgl  = tss_p$val,
             tn_mgl   = tn_p$val,
             stringsAsFactors = FALSE)
}

# Find a measurement value for a parameter in a block of Part A lines.
# Walks backward from the Requirement line matching `timing_pat` to find
# the nearest line matching `param_pat`, then extracts the value token.
# Two layout variants are handled:
#   Case A — values on the same line as the parameter name
#   Case B — parameter name + "Sample" on the same line; values on next line
.macdill_extract_val <- function(lines, param_pat, timing_pat, value_index = 1L) {
  req_idx <- which(grepl("Requirement", lines) &
                     grepl(timing_pat, lines, perl = TRUE))
  if (length(req_idx) == 0L) return(NA_character_)

  get_toks <- function(ln) {
    tok <- strsplit(trimws(ln), "\\s+")[[1]]
    tok <- tok[nchar(tok) > 0L]
    vt  <- tok[grepl("^[<>]?\\d", tok) | tok %in% c("NOD","ANC")]
    while (length(vt) > 1L && vt[length(vt)] %in% c("0","1","2","3","4","5"))
      vt <- vt[-length(vt)]
    vt
  }

  for (ri in req_idx) {
    for (j in rev(seq(max(1L, ri - 14L), ri))) {
      ln <- lines[j]
      if (!grepl(param_pat, ln, perl = TRUE)) next
      if (grepl("Permit|Requirement|Mon\\.", ln))  next

      vt <- if (grepl("Sample", ln)) {
        if (j < length(lines)) get_toks(lines[j + 1L]) else character(0L)
      } else {
        get_toks(ln)
      }

      if (length(vt) == 0L) next
      idx <- if (value_index == -1L) length(vt) else min(value_index, length(vt))
      return(vt[idx])
    }
  }
  NA_character_
}

# Parse a raw measurement token (NOD / ANC / <N / numeric).
.macdill_parse_tok <- function(tok) {
  if (is.na(tok) || !nzchar(tok) || tok == "ANC")
    return(list(val = NA_real_, nod = FALSE))
  if (tok == "NOD")
    return(list(val = NA_real_, nod = TRUE))
  if (startsWith(tok, "<")) {
    n <- suppressWarnings(as.numeric(sub("^<", "", tok)))
    return(list(val = n, nod = FALSE))
  }
  list(val = suppressWarnings(as.numeric(tok)), nod = FALSE)
}

# ---- Parse Part B: daily sample results ------------------------------------
# Uses pdftools::pdf_data() (word-level bounding boxes) to identify each
# column by position, then extracts daily readings and applies the
# <1->0.5 / <2->1 substitution before averaging.
#
# Part B spans two pages with different column layouts:
#
# Page 1 — identified by a "Mon. Site" (Site) header row:
#   FLW-01  x≈108 — total plant R-001 flow (skip; use CAL-01 for R-001 ADF)
#   CAL-01  x≈153 — R-001 applied (effluent) flow
#   FLW-02  x≈194 — R-002 flow
#   FLW-03  x≈235 — R-003 flow
#   EFA-01[1] x≈280 — BOD R-001
#   EFA-02[1] x≈327 — BOD R-002 & R-003 (shared monitoring site)
#   EFB-01[1] x≈376 — Turbidity (skip)
#   EFB-01[2] x≈425 — TSS R-001 & R-003 (shared monitoring site)
#   EFA-02[2] x≈473 — TSS R-002
#   EFA-01[2] x≈521 — Chlorine (skip)
#
# Page 2 — identified by a "Code" header row containing PARM codes:
#   00620  x≈420 — Nitrate-N (TN) for R-003  ← extracted here
#   (other columns are chlorine, coliforms, pH, BOD, TSS — not used)
#
# Page 1 is processed first to get flow/BOD/TSS. Page 2 is processed
# separately to get per-day TN values, then the two are merged by day.

.macdill_parse_part_b <- function(pdf_path) {
  all_pages <- pdftools::pdf_data(pdf_path)

  p1_rows <- list()   # page 1: flow, BOD, TSS
  tn_rows <- list()   # page 2: TN (00620)

  get_val <- function(row_words, target_x, tol = 28L) {
    if (is.na(target_x) || nrow(row_words) == 0L) return(NA_character_)
    dist <- abs(row_words$x - target_x)
    idx  <- which.min(dist)
    if (dist[idx] > tol) return(NA_character_)
    row_words$text[idx]
  }

  day_words_from <- function(pg) {
    dw       <- pg[pg$x < 80L, ]
    day_ints <- suppressWarnings(as.integer(dw$text))
    dw[!is.na(day_ints) & day_ints >= 1L & day_ints <= 31L, ]
  }

  for (pg in all_pages) {

    # ---- Page 1: "Mon. Site" header row (flow, BOD, TSS) -------------------
    site_idx <- which(pg$text == "Site")
    if (length(site_idx) > 0L) {
      ms_y     <- pg$y[site_idx[1L]]
      site_row <- pg[abs(pg$y - ms_y) <= 3L, ]
      site_row <- site_row[order(site_row$x), ]

      find_xs <- function(code) sort(site_row$x[site_row$text == code])

      cal01_x   <- find_xs("CAL-01")[1L]
      flw02_x   <- find_xs("FLW-02")[1L]
      flw03_x   <- find_xs("FLW-03")[1L]
      efa01_xs  <- find_xs("EFA-01")
      efa02_xs  <- find_xs("EFA-02")
      efb01_xs  <- find_xs("EFB-01")
      bod_r1_x  <- efa01_xs[1L]
      bod_r23_x <- efa02_xs[1L]
      tss_r13_x <- efb01_xs[2L]
      tss_r2_x  <- efa02_xs[2L]

      dw <- day_words_from(pg)
      for (k in seq_len(nrow(dw))) {
        dy  <- as.integer(dw$text[k])
        rw  <- pg[abs(pg$y - dw$y[k]) <= 3L & pg$x >= 80L, ]
        p1_rows[[length(p1_rows) + 1L]] <- data.frame(
          day     = dy,
          r1_flow = get_val(rw, cal01_x),
          r2_flow = get_val(rw, flw02_x),
          r3_flow = get_val(rw, flw03_x),
          bod_r1  = get_val(rw, bod_r1_x),
          bod_r23 = get_val(rw, bod_r23_x),
          tss_r13 = get_val(rw, tss_r13_x),
          tss_r2  = get_val(rw, tss_r2_x),
          stringsAsFactors = FALSE
        )
      }
    }

    # ---- Page 2: "Code" header row; extract TN column (00620) -------------
    code_idx <- which(pg$text == "Code")
    if (length(code_idx) > 0L) {
      code_y   <- pg$y[code_idx[1L]]
      code_row <- pg[abs(pg$y - code_y) <= 3L, ]
      tn_xs    <- code_row$x[code_row$text == "00620"]
      tn_x     <- if (length(tn_xs) > 0L) tn_xs[1L] else NA_real_

      if (!is.na(tn_x)) {
        dw <- day_words_from(pg)
        for (k in seq_len(nrow(dw))) {
          dy <- as.integer(dw$text[k])
          rw <- pg[abs(pg$y - dw$y[k]) <= 3L & pg$x >= 80L, ]
          tn_rows[[length(tn_rows) + 1L]] <- data.frame(
            day   = dy,
            tn_r3 = get_val(rw, tn_x),
            stringsAsFactors = FALSE
          )
        }
      }
    }
  }

  if (length(p1_rows) == 0L)
    return(data.frame(outfall = c("R-001","R-002","R-003"),
                      flow_mgd = NA_real_, bod_mgl = NA_real_,
                      tss_mgl  = NA_real_, tn_mgl  = NA_real_,
                      stringsAsFactors = FALSE))

  daily <- dplyr::bind_rows(p1_rows) |>
    dplyr::arrange(day) |>
    dplyr::distinct(day, .keep_all = TRUE)

  # Merge TN from page 2 (biweekly, so many days will be NA)
  if (length(tn_rows) > 0L) {
    daily_tn <- dplyr::bind_rows(tn_rows) |>
      dplyr::arrange(day) |>
      dplyr::distinct(day, .keep_all = TRUE)
    daily <- dplyr::left_join(daily, daily_tn, by = "day")
  } else {
    daily$tn_r3 <- NA_character_
  }

  for (col in c("r1_flow","r2_flow","r3_flow","bod_r1","bod_r23","tss_r13","tss_r2","tn_r3"))
    daily[[col]] <- .macdill_apply_sub(daily[[col]])

  avg_f <- function(x) mean(x, na.rm = TRUE)          # zeros count as days of no discharge
  avg_c <- function(x) { x <- x[!is.na(x)]; if (!length(x)) NA_real_ else mean(x) }

  data.frame(
    outfall  = c("R-001","R-002","R-003"),
    flow_mgd = c(avg_f(daily$r1_flow), avg_f(daily$r2_flow), avg_f(daily$r3_flow)),
    bod_mgl  = c(avg_c(daily$bod_r1),  avg_c(daily$bod_r23), avg_c(daily$bod_r23)),
    tss_mgl  = c(avg_c(daily$tss_r13), avg_c(daily$tss_r2),  avg_c(daily$tss_r13)),
    # TN from page 2 (00620 column, R-003 only; R-001 and R-002 do not report TN)
    tn_mgl   = c(NA_real_, NA_real_, avg_c(daily$tn_r3)),
    stringsAsFactors = FALSE
  )
}

# Apply <1->0.5 and <2->1.0 substitution for below-detection measurements.
.macdill_apply_sub <- function(vals) {
  sapply(vals, function(v) {
    if (is.na(v) || !nzchar(v) || v %in% c("NA","ANC","NOD")) return(NA_real_)
    v <- trimws(v)
    if (v %in% c("<1","<1.0")) return(0.5)
    if (v %in% c("<2","<2.0")) return(1.0)
    if (startsWith(v, "<")) {
      n <- suppressWarnings(as.numeric(sub("^<", "", v)))
      return(if (!is.na(n)) n / 2 else NA_real_)
    }
    suppressWarnings(as.numeric(v))
  }, USE.NAMES = FALSE)
}
