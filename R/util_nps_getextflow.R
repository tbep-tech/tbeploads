#' Get external flow data not from USGS for NPS calculations
#'
#' @param pth Path to the external Excel file
#' @param loc Location of the external flow data. Options are 'LMANATEE', 'TBYPASS', or '02301500'.
#' @param yrrng Numeric vector of length 2 indicating the year range to filter the data. Default is c(2021, 2023).
#'
#' @returns A data frame of flow data for the location in `loc`
#'
#' @details
#' This function retrieves and formats external flow data that cannot be obtained from the USGS API. The three required locations are Lake Manatee, Tampa Bypass Canal (s160), and the Alafia River Bell Shoals Bell Shoals.
#'
#' External data can be obtained as follows:
#'
#' \itemize{
#'  \item LMANATEE: Lake Manatee flow for the Manatee River dam, from Manatee County Utilities, input flow is cfs (Manatee County contact is Amanda ShawverKarnitz, <amanda.shawverkarnitz@mymanatee.org>).
#'  \item TBYPASS: Tampa Bypass Canal flow from Tampa Bay Water.  Input flow is MGD and is converted to cfs (Tampa Bay Water contact is Cathleen Jonas, <cjonas@tampabaywater.org>).
#'  \item 02301500: Alafia River Bell Shoals flow data from SWFWMD WMIS Pumpage Reports for Permit 11794 or optionally from Tampa Bay Water reported withdrawals for Site 4626 (Cathleen Jonas, <cjonas@tampabaywater.org>).  Input flow from latter is daily average converted to cfs.
#' }
#'
#' System files are included in the package which can be updated annually.
#'
#' @export
#'
#' @examples
#' # lake manatee
#' pth <- system.file('extdata/nps_extflow_lakemanatee.xlsx', package = 'tbeploads')
#' extflo <- util_nps_getextflow(pth, loc = "LMANATEE")
#'
#' # tampa bypass
#' pth <- system.file('extdata/nps_extflow_tampabypass.xlsx', package = 'tbeploads')
#' extflo <- util_nps_getextflow(pth, loc = "TBYPASS")
#'
#' # bell shoals
#' pth <- system.file('extdata/nps_extflow_bellshoals.xls', package = 'tbeploads')
#' extflo <- util_nps_getextflow(pth, loc = "02301500")
util_nps_getextflow <- function(pth, loc, yrrng = c(2021, 2023)){

  loc <- match.arg(loc, c('LMANATEE', 'TBYPASS', '02301500'))

  # lake manatee
  if(loc == 'LMANATEE'){

    out <- suppressMessages(readxl::read_xlsx(pth)) |>
      dplyr::rename(date = 1, flow_cfs = 2) |>
      dplyr::mutate(site_no = "LMANATEE")

  }

  # tampa bypass
  if(loc == 'TBYPASS'){

    out <- suppressMessages(readxl::read_xlsx(pth)) |>
      dplyr::rename(date = MeasureDateTime) |>
      dplyr::mutate(site_no = "TBYPASS",
           flow_cfs = round(Value*1.53723, digits = 4))

  }

  # bell shoals
  if(loc == '02301500'){

    out <- suppressMessages(readxl::read_xls(pth, sheet = "Pumpage")) |>
      dplyr::filter(`DID#` == 1) |>
      dplyr::rename(date = `RECORDED DATE`) |>
      dplyr::mutate(
        site_no = "02301500",
        wd_cfs = round(`DAILY AVG`/1000000*1.54723, digits = 4)
      )

  }

  # select columns, filter by years
  out <- out |>
    dplyr::select(
      site_no, date, dplyr::any_of(c("flow_cfs", "wd_cfs"))
    ) |>
    dplyr::filter(lubridate::year(date) >= yrrng[1] & lubridate::year(date) <= yrrng[2])

  return(out)

}
