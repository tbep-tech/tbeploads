# Get Kerry I&F discharge monitoring report data from FDEP OCULUS

Downloads and parses monthly Part A Discharge Monitoring Report (DMR)
PDFs for the Kerry I&F Contracting Company industrial wastewater
facility (NPDES permit FL0037389, Hillsborough County, FL) from the
Florida Department of Environmental Protection (FDEP) OCULUS public
document management system. Returns Average Daily Flow, BOD, Total
Nitrogen, and Total Phosphorus concentration for each available
monitoring month.

## Usage

``` r
util_ps_getkerry(
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
  FL0037389. See Details for instructions on generating this file.

- pdf_dir:

  character or NULL. Directory in which to save the downloaded PDFs. If
  `NULL` (default), a temporary directory is used and all PDFs are
  deleted when the function exits. If a path is supplied, PDFs are
  retained there.

- out_file:

  character or NULL. If provided, the results data frame is written to
  this path as an `.xlsx` workbook.

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
| `mo` | integer | Calendar month (1-12, from the PDF monitoring period). |
| `outfall` | character | Always `"FLW-3"` (the combined flow). |
| `flow_mgd` | numeric | Average Daily Flow (MGD), monthly average. `0` indicates no discharge (NOD). |
| `bod_mgl` | numeric | BOD, Carbonaceous (mg/L), monthly maximum. `NA` when ANC or not reported. |
| `tss_mgl` | numeric | Always `NA` (not monitored at this facility). |
| `tn_mgl` | numeric | Total nitrogen grab-sample concentration (mg/L). `NA` when ANC or not reported. |
| `tp_mgl` | numeric | Total phosphorus grab-sample concentration (mg/L). `NA` when ANC or not reported. |

## Details

### Generating the OCULUS search spreadsheet

The `search_xlsx` file is an Excel export from the FDEP OCULUS public
document portal. To generate it:

1.  Navigate to <https://depedms.dep.state.fl.us> in a web browser.

2.  Click **Public Oculus Login** (no account required).

3.  In the search form, set:

    - **Catalog**: Wastewater

    - **Profile**: Sampling

    - **Facility-Site ID**: FL0037389 (this does not go in the Permit
      Number field)

    - **Document Date**: From MM-DD-YYYY to MM-DD-YYYY (covering the
      desired monitoring year)

    - **Document Type**: Discharge Monitoring Report (DMR)

4.  Run the search and export the results to Excel (use the **Export to
    Excel** button).

5.  Save the exported `.xlsx` file and pass its path as `search_xlsx`.

The file must contain `HYPERLINK()` formulas in **column A** pointing to
the individual DMR PDFs and document subject lines in **column K**. Both
are present in any standard OCULUS search export. Also note that the
search may return other reports (e.g., toxicity results), which can be
safely removed from the Excel file.

### Document selection

The function keeps only monthly (`MO`) Part A documents for the
requested year. Annual summary (`YR`) documents are excluded
automatically. If a month has multiple submissions (e.g., a revision
such as `"DMR (R) ..."`), the most recently filed document is used.

### Reporting outfall

Kerry I&F reports flow separately for three internal monitoring sites
(`FLW-1`, `FLW-2`, and `FLW-3`). `FLW-3` is the calculated combined flow
(`FLW-1` + `FLW-2`) and is the value returned here, consistent with the
outfall label used in prior years' data for this facility.

### No Discharge (NOD) and Acceptable Non-Collection (ANC)

`NOD` (No Observable Discharge) is treated as zero flow. `ANC`
(Acceptable Not Collected) is treated as `NA`. Below-detection-limit
values (e.g. `"<2"`) are returned as the reported numeric detection
limit (`2`), not halved.

### Parameters not currently monitored

Total suspended solids (TSS) is not recorded at this facility and is
returned as `NA` for all months.

### Verifying results

On the initial run, supply a `pdf_dir` path so the downloaded PDFs are
retained for inspection. Verify that the monitoring months, flow values,
and concentrations in the output data frame match those in the PDFs.

## Examples

``` r
if (FALSE) { # \dontrun{
# Retrieve 2025 Kerry I&F DMR data
df <- util_ps_getkerry(
  yr          = 2025,
  search_xlsx = "Kerry_OCULUSSearchData_2025.xlsx"
)

# Keep PDFs and save results to Excel
df <- util_ps_getkerry(
  yr          = 2025,
  search_xlsx = "Kerry_OCULUSSearchData_2025.xlsx",
  pdf_dir     = "~/Desktop/Kerry_DMR_2025",
  out_file    = "~/Desktop/Kerry_DMR_2025_results.xlsx"
)
} # }
```
