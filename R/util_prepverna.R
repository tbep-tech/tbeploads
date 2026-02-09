#' Prep Verna Wellfield data for use in AD and NPS calculations
#'
#' Prep Verna Wellfield data for use in AD and NPS calculations
#'
#' @param fl text string for the file path to the Verna Wellfield data
#' @param typ character string for the type of data to prepare, either 'AD' for atmospheric deposition or 'NPS' for nonpoint source.  Uses different TP calculation for each type.
#' @param fillmis logical indicating whether to fill missing data with monthly means, see details
#'
#' @return A data frame with total nitrogen and phosphorus estimates as mg/l for each year and month of the input data
#'
#' @details
#' Raw data can be obtained from <https://nadp.slh.wisc.edu/sites/ntn-FL41/> as monthly observations.  Total nitrogen and phosphorus concentrations are estimated from ammonium and nitrate concentrations (mg/L) using the following relationships:
#'
#' \deqn{TN = NH_4^+ * 0.78 + NO_3^- * 0.23}
#' \deqn{TP = 0.01262 * TN + 0.00110}
#'
#' The first equation corrects for the % of ions in ammonium and nitrate that is N, and the second is a regression relationship between TBADS TN and TP, applied to Verna.
#'
#' Missing data (-9 values) can be filled using monthly means from the previous five years where data exist for that month.  If there are less than five previous years of data for that month, the missing value is not filled.
#' 
#' Years with incomplete seasonal data will be filled with NA values if `fillmis = FALSE` or filled with monthly means if `fillmis = TRUE`.
#' 
#' @export
#'
#' @examples
#' fl <- system.file('extdata/verna-raw.csv', package = 'tbeploads')
#' util_prepverna(fl)
util_prepverna <- function(fl, typ, fillmis = T){

  typ <- match.arg(typ, choices = c('AD', 'NPS'))

  # import raw, subset relevant, fill -9 as NA
  dat <- read.csv(fl, header = T, stringsAsFactors = F) |>
    dplyr::select(
      Year = yr,
      Month = seas,
      nh4 = NH4,
      no3 = NO3
    ) |>
    dplyr::mutate(
      nh4 = ifelse(nh4 == -9, NA, nh4),
      no3 = ifelse(no3 == -9, NA, no3)
    ) |> 
    dplyr::arrange(Year, Month)

  # make complete year, month sequence
  allmonths <- expand.grid(
      Year = unique(dat$Year),
      Month = 1:12
    ) |> 
    dplyr::arrange(Year, Month)
  dat <- dplyr::left_join(allmonths, dat, by = c("Year", "Month"))

  # fill missing annual data by monthly means from previous five years
  # use years where data exist for that month
  if(fillmis){

    # get monthly ave
    datave <- dat |>
      tidyr::pivot_longer(
        cols = c(nh4, no3),
        names_to = "var",
        values_to = "val"
      ) |>
      dplyr::group_nest(Month, var) |>
      dplyr::mutate(
        data = purrr::map(data, ~{
          
          out <- .x
          
          for (i in 1:nrow(out)) {
            # check if NA
            if (is.na(out[i, 'val'])) {
              # get all previous non-na values
              pastvals <- .x[1:(i-1), 'val']
              pastvals <- pastvals[!is.na(pastvals)]
              
              # take the last five non-na values
              if (length(pastvals) >= 5) {
                last_5 <- tail(pastvals, 5)
                out[i, 'val'] <- mean(last_5)
              } else if (length(pastvals) > 0) {
                # if less than five, do not fill
                out[i, 'val'] <- NA
              }
            }
          }

          return(out)

        })
      )

    # reformat with averages
    dat <- datave |> 
      tidyr::unnest('data') |> 
      tidyr::pivot_wider(
        names_from = var,
        values_from = val
      ) |> 
      dplyr::select(Year, Month, nh4, no3) |> 
      dplyr::arrange(Year, Month)

  }

  # create tn and tp estimates from nh4 and no3
  if(typ == 'AD')
    out <- dat |>
      dplyr::mutate(
        nh4 = nh4 * 0.78, # NADP data are reported as mg NO3 and mg NH4, this corrects for % of ions that is N;
        no3 = no3 * 0.23,
        TNConc = nh4 + no3,
        TPConc = 0.01262 * TNConc + 0.00110 # from regression relationship between TBADS TN and TP, applied to Verna;
      ) 
  
  if(typ == 'NPS')
    out <- dat |>
      dplyr::mutate(
        nh4 = nh4 * 0.78, # NADP data are reported as mg NO3 and mg NH4, this corrects for % of ions that is N;
        no3 = no3 * 0.23,
        TNConc = nh4 + no3,
        TPConc = 0.195
      ) 
  
  out <- out |>
    dplyr::select(Year, Month, TNConc, TPConc)

  return(out)

}
