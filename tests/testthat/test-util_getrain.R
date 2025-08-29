# First, let's create a simple debug test to understand the data structure
test_that("debug util_getrain data structure", {
  # Simple mock that just returns what we think the API should return
  mock_simple_get <- function(url, query, ...) {
    # Return exactly what we think a single API call should return
    mock_data <- data.frame(
      date = c("2021-01-15", "2021-02-15", "2021-03-15"),
      datatype = "PRCP",
      station = query$stationid,
      value = c(100, 200, 150),
      stringsAsFactors = FALSE
    )
    
    response <- list(
      status_code = 200,
      content = jsonlite::toJSON(list(results = mock_data))
    )
    class(response) <- "response"
    return(response)
  }
  
  mock_status_code <- function(response) response$status_code
  mock_content <- function(response, as = "text", encoding = "UTF-8") response$content
  mock_add_headers <- function(...) list(...)
  
  # Stub the functions
  stub(util_getrain, "httr::GET", mock_simple_get)
  stub(util_getrain, "httr::status_code", mock_status_code)
  stub(util_getrain, "httr::content", mock_content)
  stub(util_getrain, "httr::add_headers", mock_add_headers)
  
  # Test with just one year and one station
  result <- util_getrain(2021, 228, "test_key", ntry = 1)
  
  # Basic checks
  expect_s3_class(result, "data.frame")
  expect_true("station" %in% colnames(result))
  expect_true("rainfall" %in% colnames(result))
})

# Mocking the httr::GET function - more complete version
mock_httr_get <- function(url, query, ...) {
  # Create realistic mock data that matches NOAA API structure
  mock_data <- data.frame(
    date = as.character(seq.Date(as.Date(query$startdate), as.Date(query$enddate), by = "week")[1:12]),
    datatype = "PRCP",
    station = query$stationid,
    value = round(runif(12, min = 0, max = 1000)),
    attributes = "H,,N,0800",
    stringsAsFactors = FALSE
  )
  
  response <- list(
    status_code = 200,
    content = jsonlite::toJSON(list(results = mock_data), auto_unbox = FALSE)
  )
  
  class(response) <- "response"
  return(response)
}

# Mock httr functions
mock_status_code <- function(response) {
  response$status_code
}

mock_content <- function(response, as = "text", encoding = "UTF-8") {
  response$content
}

mock_add_headers <- function(...) {
  list(...)
}

fail_once <- TRUE
mock_httr_get_retry <- function(url, query, ...) {
  if (fail_once) {
    fail_once <<- FALSE
    response <- list(status_code = 500)
    class(response) <- "response"
    return(response)
  }
  
  # Use the same structure as the main mock
  mock_data <- data.frame(
    date = as.character(seq.Date(as.Date(query$startdate), as.Date(query$enddate), by = "week")[1:12]),
    datatype = "PRCP", 
    station = query$stationid,
    value = round(runif(12, min = 0, max = 1000)),
    attributes = "H,,N,0800",
    stringsAsFactors = FALSE
  )
  
  response <- list(
    status_code = 200,
    content = jsonlite::toJSON(list(results = mock_data), auto_unbox = FALSE)
  )
  
  class(response) <- "response"
  return(response)
}

test_that("util_getrain returns correct structure and data", {
  # Mock httr functions
  stub(util_getrain, "httr::GET", mock_httr_get)
  stub(util_getrain, "httr::status_code", mock_status_code)
  stub(util_getrain, "httr::content", mock_content)
  stub(util_getrain, "httr::add_headers", mock_add_headers)

  # Test with a single year and station
  noaa_key <- "test_key"
  result <- util_getrain(2021, 228, noaa_key, ntry = 1)

  expect_s3_class(result, "data.frame")
  expect_true(all(c("station", "date", "Year", "Month", "Day", "rainfall") %in% colnames(result)))
  expect_equal(unique(result$Year), 2021)
  expect_equal(unique(result$station), 228)

  # Test with multiple years but limit stations for testing
  result <- util_getrain(c(2021, 2022), station = c(228, 478), noaa_key = noaa_key, ntry = 1)

  expect_s3_class(result, "data.frame")
  expect_true(all(c("station", "date", "Year", "Month", "Day", "rainfall") %in% colnames(result)))
  expect_true(all(c(2021, 2022) %in% result$Year))
  
  # Test with NULL station (should use default stations)
  result <- util_getrain(2021, station = NULL, noaa_key = noaa_key, ntry = 1)
  
  expect_s3_class(result, "data.frame")
  expect_true(all(c("station", "date", "Year", "Month", "Day", "rainfall") %in% colnames(result)))
  expect_equal(unique(result$Year), 2021)
  # Should contain multiple stations (the default list)
  expect_true(length(unique(result$station)) > 1)
})

test_that("util_getrain retry mechanism works", {
  # Reset the fail_once variable
  fail_once <<- TRUE
  
  # Mock httr functions with retry behavior
  stub(util_getrain, "httr::GET", mock_httr_get_retry)
  stub(util_getrain, "httr::status_code", mock_status_code)
  stub(util_getrain, "httr::content", mock_content)
  stub(util_getrain, "httr::add_headers", mock_add_headers)

  noaa_key <- "test_key"
  result <- util_getrain(2021, 228, noaa_key, ntry = 2)

  expect_s3_class(result, "data.frame")
  expect_true(all(c("station", "date", "Year", "Month", "Day", "rainfall") %in% colnames(result)))
  expect_equal(unique(result$Year), 2021)
  expect_equal(unique(result$station), 228)

  # Test with ntry = 0 which should fail
  result <- util_getrain(2021, c(1111, 9999), noaa_key, ntry = 0)
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
  expect_true(all(c("station", "date", "Year", "Month", "Day", "rainfall") %in% colnames(result)))
})

test_that("util_getrain handles API errors correctly", {
  # Mock a function that always returns error status
  mock_error_response <- function(url, query, ...) {
    response <- list(status_code = 400)
    class(response) <- "response"
    return(response)
  }
  
  stub(util_getrain, "httr::GET", mock_error_response)
  stub(util_getrain, "httr::status_code", mock_status_code)
  stub(util_getrain, "httr::content", mock_content)
  stub(util_getrain, "httr::add_headers", mock_add_headers)

  noaa_key <- "test_key"
  result <- util_getrain(2021, 228, noaa_key, ntry = 1)
  
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
  expect_true(all(c("station", "date", "Year", "Month", "Day", "rainfall") %in% colnames(result)))
})

test_that("util_getrain handles empty API responses", {
  # Mock a function that returns empty results (NULL)
  mock_empty_response <- function(url, query, ...) {
    response <- list(
      status_code = 200,
      content = jsonlite::toJSON(list(results = NULL), auto_unbox = TRUE)
    )
    class(response) <- "response"
    return(response)
  }
  
  stub(util_getrain, "httr::GET", mock_empty_response)
  stub(util_getrain, "httr::status_code", mock_status_code)
  stub(util_getrain, "httr::content", mock_content)
  stub(util_getrain, "httr::add_headers", mock_add_headers)

  noaa_key <- "test_key"
  result <- util_getrain(2021, 228, noaa_key, ntry = 1)
  
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
  expect_true(all(c("station", "date", "Year", "Month", "Day", "rainfall") %in% colnames(result)))
})

test_that("util_getrain handles missing results field", {
  # Mock a function that returns response without results field
  mock_no_results_response <- function(url, query, ...) {
    response <- list(
      status_code = 200,
      content = jsonlite::toJSON(list(metadata = list(resultset = list(count = 0))))
    )
    class(response) <- "response"
    return(response)
  }
  
  stub(util_getrain, "httr::GET", mock_no_results_response)
  stub(util_getrain, "httr::status_code", mock_status_code)
  stub(util_getrain, "httr::content", mock_content)
  stub(util_getrain, "httr::add_headers", mock_add_headers)

  noaa_key <- "test_key"
  result <- util_getrain(2021, 228, noaa_key, ntry = 1)
  
  expect_true(nrow(result) == 0)
})

test_that("util_getrain handles empty results in retry loop", {
  # Mock that fails first, then returns empty results
  fail_first <- TRUE
  mock_empty_retry <- function(url, query, ...) {
    if (fail_first) {
      fail_first <<- FALSE
      response <- list(status_code = 500)
      class(response) <- "response"
      return(response)
    }
    
    # Return empty results on retry
    response <- list(
      status_code = 200,
      content = jsonlite::toJSON(list(results = NULL))
    )
    class(response) <- "response"
    return(response)
  }
  
  stub(util_getrain, "httr::GET", mock_empty_retry)
  stub(util_getrain, "httr::status_code", mock_status_code)
  stub(util_getrain, "httr::content", mock_content)
  stub(util_getrain, "httr::add_headers", mock_add_headers)

  noaa_key <- "test_key"
  result <- util_getrain(2021, 228, noaa_key, ntry = 2)
  
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
  expect_true(all(c("station", "date", "Year", "Month", "Day", "rainfall") %in% colnames(result)))
})

test_that("util_getrain handles zero-length data objects", {
  # Mock that returns a zero-length data object (not NULL, but empty)
  mock_zero_length_response <- function(url, query, ...) {
    response <- list(
      status_code = 200,
      content = jsonlite::toJSON(list(results = data.frame()))
    )
    class(response) <- "response"
    return(response)
  }
  
  stub(util_getrain, "httr::GET", mock_zero_length_response)
  stub(util_getrain, "httr::status_code", mock_status_code)
  stub(util_getrain, "httr::content", mock_content)
  stub(util_getrain, "httr::add_headers", mock_add_headers)

  noaa_key <- "test_key"
  result <- util_getrain(2021, 228, noaa_key, ntry = 1)
  
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
  expect_true(all(c("station", "date", "Year", "Month", "Day", "rainfall") %in% colnames(result)))
})

test_that("util_getrain handles zero-length data in retry loop", {
  # Mock that succeeds first, then fails, then returns zero-length data on retry
  call_count <- 0
  mock_mixed_response <- function(url, query, ...) {
    call_count <<- call_count + 1
    
    if (call_count == 1) {
      # First call succeeds with normal data
      mock_data <- data.frame(
        date = c("2021-01-15", "2021-02-15"),
        datatype = "PRCP",
        station = query$stationid,
        value = c(100, 200),
        stringsAsFactors = FALSE
      )
      response <- list(
        status_code = 200,
        content = jsonlite::toJSON(list(results = mock_data))
      )
    } else if (call_count == 2) {
      # Second call fails (triggers retry)
      response <- list(status_code = 500)
    } else {
      # Third call (retry) succeeds but returns zero-length data
      response <- list(
        status_code = 200,
        content = jsonlite::toJSON(list(results = data.frame()))
      )
    }
    
    class(response) <- "response"
    return(response)
  }
  
  stub(util_getrain, "httr::GET", mock_mixed_response)
  stub(util_getrain, "httr::status_code", mock_status_code)
  stub(util_getrain, "httr::content", mock_content)
  stub(util_getrain, "httr::add_headers", mock_add_headers)

  noaa_key <- "test_key"
  # Use two stations to trigger multiple API calls
  result <- util_getrain(2021, c(228, 478), noaa_key, ntry = 2)
  
  expect_s3_class(result, "data.frame")
  expect_true(all(c("station", "date", "Year", "Month", "Day", "rainfall") %in% colnames(result)))
  # Should have data from the first successful call
  expect_true(nrow(result) > 0)
})
