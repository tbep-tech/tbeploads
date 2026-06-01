# Get AOC LLC discharge monitoring report data from FDEP OCULUS

Downloads and parses monthly Part A Discharge Monitoring Report (DMR)
PDFs for the AOC LLC industrial wastewater facility (NPDES permit
FL0029653, Polk County, FL) from the Florida Department of Environmental
Protection (FDEP) OCULUS public document management system. Returns
Average Daily Flow and Total Nitrogen concentration for each available
monitoring month.

## Usage

``` r
util_ps_getaoc(
  yr,
  search_xlsx,
  pdf_dir = NULL,
  out_file = NULL,
  keep_pdfs = FALSE,
  quiet = FALSE
)
```

## Arguments

- yr:

  numeric (length 1), the monitoring year to retrieve (e.g., 2025).

- search_xlsx:

  character, path to an OCULUS search-results spreadsheet for facility
  FL0029653. See Details for instructions on generating this file.

- pdf_dir:

  character or NULL. Directory in which to save the downloaded PDFs.
  Defaults to a temporary directory. Ignored when `keep_pdfs = FALSE`
  (the default).

- out_file:

  character or NULL. If provided, the results data frame is written to
  this path as an `.xlsx` workbook.

- keep_pdfs:

  logical. If `FALSE` (default) the downloaded PDFs are deleted after
  parsing. Set to `TRUE` to retain them in `pdf_dir`.

- quiet:

  logical. Suppress progress messages (default `FALSE`).

## Value

A data frame with one row per available monitoring month, sorted by
month. Calendar months for which no Part A document was found are
omitted (a message is printed when `quiet = FALSE`). Columns:

|  |  |  |
|----|----|----|
| Column | Type | Description |
| `yr` | integer | Monitoring year (from the PDF monitoring period). |
| `mo` | integer | Calendar month (1–12, from the PDF monitoring period). |
| `adf_mgd` | numeric | Average Daily Flow (MGD). `0` indicates no discharge (NOD). |
| `tn_mgl` | numeric | Total nitrogen grab-sample concentration (mg/L). `NA` when no discharge or not reported. |

## Details

### Generating the OCULUS search spreadsheet

The `search_xlsx` file is an Excel export from the FDEP OCULUS public
document portal. To generate it:

1.  Navigate to <https://depedms.dep.state.fl.us> in a web browser.

2.  Click **Public Oculus Login** (no account required).

3.  In the search form, set:

    - **Catalog**: Wastewater

    - **Profile**: Sampling

    - **Facility-Site ID**: FL0029653 (this does not go in the Permit
      Number field)

    - **Document Date**: From MM-DD-YYYY to MM-DD-YYYY (covering the
      desired monitoring year)

    - **Document Type**: Discharge Monitoring Report (DMR)

4.  Run the search and export the results to Excel (use the **Export to
    Excel** button).

5.  Save the exported `.xlsx` file and pass its path as `search_xlsx`.

The file must contain `HYPERLINK()` formulas in **column A** pointing to
the individual DMR PDFs and document subject lines in **column K**. Both
are present in any standard OCULUS search export.

### Document selection

The function keeps only monthly (`MO`) Part A documents for the
requested year. Annual summary (`YR`), Part B daily tables, and other
document types are excluded automatically. If a month has multiple
submissions (e.g., a revision), the most recently filed document is
used.

### Reporting period vs. OCULUS label

For some facilities the OCULUS cycle label (e.g., "JAN MO") may not
align with the calendar month of the monitoring period. The month
returned in the output is always derived from the **monitoring period
dates inside the PDF**, not from the OCULUS label.

### No Discharge (NOD)

When the facility reports No Observable Discharge, `adf_mgd` is set to
`0` and `tn_mgl` is set to `NA`. A zero flow value therefore implies no
discharge for that month.

### Parameters not currently monitored

Total phosphorus (TP), biochemical oxygen demand (BOD), and total
suspended solids (TSS) have not been recorded at this facility in recent
years and are not included in the output.

### Verying results

In practice, always use `keep_pdfs = TRUE` for the initial run to verify
that the downloaded PDFs are correct and being parsed as expected.
Always inspect the output data frame to confirm that the monitoring
months, flow values, and TN concentrations match those in the PDFs.

## Examples

``` r
if (FALSE) { # \dontrun{
# Retrieve 2025 AOC DMR data
# (requires an OCULUS search spreadsheet generated as described in Details)
df <- util_ps_getaoc(
  yr          = 2025,
  search_xlsx = "AOC_OCULUSSearchData_2025.xlsx"
)

# Keep PDFs and save results to Excel
df <- util_ps_getaoc(
  yr          = 2025,
  search_xlsx = "AOC_OCULUSSearchData_2025.xlsx",
  pdf_dir     = "~/Desktop/AOC_DMR_2025",
  out_file    = "~/Desktop/AOC_DMR_2025_results.xlsx",
  keep_pdfs   = TRUE
)
} # }
```
