# Get MacDill AFB WWTP discharge monitoring report data from FDEP OCULUS

Downloads and parses monthly Discharge Monitoring Report (DMR) PDFs for
the MacDill Air Force Base wastewater treatment plant (NPDES permit
FLA012124, Hillsborough County, FL) from the FDEP OCULUS public document
system. Returns monthly effluent parameters for three discharge
outfalls.

## Usage

``` r
util_ps_getmacdill(
  yr,
  search_xlsx,
  pdf_dir = NULL,
  out_file = NULL,
  quiet = FALSE
)
```

## Arguments

- yr:

  numeric (length 1), the monitoring year to retrieve (e.g., 2025).

- search_xlsx:

  character, path to an OCULUS search-results spreadsheet for facility
  FLA012124. See Details for instructions on generating this file.

- pdf_dir:

  character or NULL. Directory in which to save the downloaded PDFs. If
  `NULL` (default), a temporary directory is used and all PDFs are
  deleted when the function exits. If a path is supplied, PDFs are
  retained there under human-readable names
  (`macdill_{yr}_{mo}_{type}.pdf`).

- out_file:

  character or NULL. If provided, the results data frame is written to
  this path as an `.xlsx` workbook.

- quiet:

  logical. Suppress progress messages (default `FALSE`).

## Value

A data frame with three rows per available monitoring month (one per
outfall), sorted by month then outfall. Calendar months for which no
usable document was found are omitted (a message is printed when
`quiet = FALSE`). Columns:

|  |  |  |
|----|----|----|
| Column | Type | Description |
| `yr` | integer | Monitoring year (from the PDF monitoring period). |
| `mo` | integer | Calendar month (1–12). |
| `outfall` | character | Outfall ID: `"R-001"`, `"R-002"`, or `"R-003"`. |
| `flow_mgd` | numeric | Average Daily Flow (MGD). `0` when NOD. |
| `bod_mgl` | numeric | BOD (mg/L). `NA` when ANC or not collected. |
| `tss_mgl` | numeric | TSS (mg/L). `NA` when ANC or not collected. |
| `tn_mgl` | numeric | Total nitrogen as NO3-N (mg/L), R-003 only. `NA` for R-001 and R-002. |
| `verify` | logical | `TRUE` when one or more concentration values (TSS for R-001/R-003, TN for R-003) are single-day **maximums** from Part A rather than monthly averages. This occurs when no machine-readable Part B was available. Cross-check these values against the original PDF. |

## Details

### Generating the OCULUS search spreadsheet

The `search_xlsx` file is an Excel export from the FDEP OCULUS public
document portal. To generate it:

1.  Navigate to <https://depedms.dep.state.fl.us> in a web browser.

2.  Click **Public Oculus Login** (no account required).

3.  In the search form, set:

    - **Catalog**: Wastewater

    - **Profile**: Sampling

    - **Facility-Site ID**: FLA012124 (not the Permit Number field)

    - **Document Date**: From MM-DD-YYYY to MM-DD-YYYY (covering the
      desired year)

    - **Document Type**: Discharge Monitoring Report (DMR)

4.  Run the search and export the results to Excel (**Export to Excel**
    button).

5.  Save the exported `.xlsx` and pass its path as `search_xlsx`.

The file must contain `HYPERLINK()` formulas in **column A** and
document subject lines in **column K**, both of which are present in any
standard OCULUS search export.

### Document selection and classification

All monthly (`MO`) documents for the requested year are downloaded and
inspected. Each PDF is then classified by its actual content:

- **Part A** (monthly summary) — contains the official permit-limit
  table with pre-computed monthly averages and permit compliance
  results.

- **Part B** (daily sample results) — contains a day-by-day table of
  flow and effluent quality measurements for a given month.

The OCULUS document labels ("Part A", "Part B") are not always reliable
for this facility, so the function detects content type from the PDF
text. Annual summary (`YR`) documents are excluded automatically.

Some older submissions are scanned image PDFs with no embedded text
layer. These cannot be parsed and are saved as
`macdill_unclassified_{document_subject}.pdf` in `pdf_dir` (when
`pdf_dir` is supplied) so you can identify them from their OCULUS
subject line and enter the values manually if needed.

### Hybrid extraction methodology

Where a Part B daily table is available for a given calendar month, BOD
and TSS are computed as the mean of all observed daily values using the
substitution rules `<1 \u{2192} 0.5` and `<2 \u{2192} 1.0` (consistent
with the 2022–2024 reporting methodology). Monthly average flow is also
derived from Part B daily readings when available. For months with no
Part B, Part A monthly-summary values are used for BOD, TSS, and flow.

Total nitrogen (`tn_mgl`) is always sourced from Part A because Part B
tables do not include a TN column.

### Monitoring period vs. OCULUS label

The OCULUS document cycle labels (e.g., "JAN MO") do not always align
with the calendar month of the monitoring period. The `mo` column in the
output is always derived from the monitoring period dates inside the
PDF, not from the OCULUS label.

### No Discharge (NOD) and acceptable non-collection (ANC)

`NOD` (No Observable Discharge) is treated as zero flow and `NA`
concentration. `ANC` (Acceptable Not Collected) is treated as `NA`.

## See also

[`util_ps_checkfls()`](https://tbep-tech.github.io/tbeploads/reference/util_ps_checkfls.md),
[`anlz_ips()`](https://tbep-tech.github.io/tbeploads/reference/anlz_ips.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Retrieve 2025 MacDill DMR data
df <- util_ps_getmacdill(
  yr          = 2025,
  search_xlsx = "MacDill_OCULUSSearchData_2025.xlsx"
)

# Keep PDFs and save results to Excel
df <- util_ps_getmacdill(
  yr          = 2025,
  search_xlsx = "MacDill_OCULUSSearchData_2025.xlsx",
  pdf_dir     = "~/Desktop/MacDill_DMR_2025",
  out_file    = "~/Desktop/MacDill_DMR_2025_results.xlsx",
  keep_pdfs   = TRUE
)
} # }
```
