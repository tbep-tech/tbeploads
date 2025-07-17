#' Helper function for union operation
#'
#' @param sf1 First sf object
#' @param sf2 Second sf object
#' @param chunk_size Integer. For large datasets, process in chunks of this many features from sf1.
#' @param verbose Logical. If TRUE, will print progress messages. Default is TRUE.
#'
#' @details Used internally by \code{\link{util_nps_union}}. See the help file for more details.
#'
#' @export
#'
#' @return An sf object containing the spatial intersection of sf1 and sf2, with geometries unioned by unique combinations of all attributes from both input objects.
#'
#' @examples
#' \dontrun{
#' data(tbjuris)
#' data(tbsubshed)
#' result <- util_nps_unionchunk(tbsubshed, tbjuris)
#' }
util_nps_unionchunk <- function(sf1, sf2, chunk_size, verbose = TRUE) {

  n_chunks <- ceiling(nrow(sf1) / chunk_size)
  results <- list()

  for (i in 1:n_chunks) {
    start_idx <- (i - 1) * chunk_size + 1
    end_idx <- min(i * chunk_size, nrow(sf1))

    if(verbose)
      cat(paste0("Processing chunk ", i, " of ", n_chunks, " (rows ", start_idx, " - ", end_idx, ")\n"))

    # Get chunk of sf1
    sf1_chunk <- sf1[start_idx:end_idx, ]

    # Process this chunk
    chunk_result <- util_nps_unionnochunk(sf1_chunk, sf2)

    if (nrow(chunk_result) > 0) {
      results[[i]] <- chunk_result
    }
  }

  # Combine all results
  if (length(results) > 0) {
    final_result <- do.call(rbind, results)

    # Final union by attributes (since we may have duplicate attribute combinations across chunks)
    sf1_cols <- setdiff(names(sf1), attr(sf1, "sf_column"))
    sf2_cols <- setdiff(names(sf2), attr(sf2, "sf_column"))
    all_cols <- c(sf1_cols, sf2_cols)

    final_result |>
      dplyr::group_by(dplyr::across(dplyr::all_of(all_cols))) |>
      dplyr::summarise(.groups = 'drop')
  } else {
    # Return empty sf object with correct structure
    sf1[0, ] |>
      dplyr::bind_cols(sf2[0, setdiff(names(sf2), attr(sf2, "sf_column"))])
  }
}
