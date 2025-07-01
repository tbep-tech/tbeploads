
# Mock data setup
create_mock_sf <- function(n_rows = 5, dat_type = "soil") {
  # Create simple mock geometries
  coords <- list(rbind(c(0,0), c(1,0), c(1,1), c(0,1), c(0,0)))
  polys <- st_polygon(coords)
  geom <- st_sfc(rep(list(polys), n_rows), crs = 4326)

  geom_list <- vector("list", n_rows)
  for(i in 1:n_rows) {
    coords <- list(rbind(c(0,0), c(1,0), c(1,1), c(0,1), c(0,0)))
    geom_list[[i]] <- st_polygon(coords)
  }
  geom <- st_sfc(geom_list, crs = 4326)

  if (dat_type == "soil") {
    data <- data.frame(
      MUID = paste0("soil_", 1:n_rows),
      HYDGRP = rep(c("A", "B"), length.out = n_rows),
      stringsAsFactors = FALSE
    )
  } else {
    data <- data.frame(
      FLUCCSCODE = rep(c("100", "200"), length.out = n_rows),
      FLUCSDESC = rep(c("Urban", "Agriculture"), length.out = n_rows),
      stringsAsFactors = FALSE
    )
  }

  st_sf(data, geometry = geom)
}

test_that("util_nps_getswfwmd works for soil data", {
  mock_response <- list()
  mock_response$status_code <- 200
  class(mock_response) <- "response"

  mock_sf_data <- create_mock_sf(5, "soil")

  local_mocked_bindings(
    `GET` = mock(mock_response, cycle = TRUE),
    `status_code` = mock(200, cycle = TRUE),
    `content` = mock('{"type":"FeatureCollection","features":[]}', cycle = TRUE),
    .package = 'httr'
  )

  local_mocked_bindings(
    `st_read` = mock(mock_sf_data, cycle = TRUE),
    .package = 'sf'
  )

  result <- suppressWarnings(util_nps_getswfwmd("soil", verbose = FALSE))

  # Check result structure
  expect_s3_class(result, "sf")
  expect_true("hydgrp" %in% names(result))
})

test_that("util_nps_getswfwmd works for lulc2020 data", {
  mock_response <- list()
  mock_response$status_code <- 200
  class(mock_response) <- "response"

  mock_sf_data <- create_mock_sf(5, "lulc2020")

  local_mocked_bindings(
    `GET` = mock(mock_response, cycle = TRUE),
    `status_code` = mock(200, cycle = TRUE),
    `content` = mock('{"type":"FeatureCollection","features":[]}', cycle = TRUE),
    .package = 'httr'
  )

  local_mocked_bindings(
    `st_read` = mock(mock_sf_data, cycle = TRUE),
    .package = 'sf'
  )

  result <- suppressWarnings(util_nps_getswfwmd("lulc2020", verbose = FALSE))

  expect_s3_class(result, "sf")
  expect_true(all(c("FLUCCSCODE", "FLUCSDESC") %in% names(result)))
})

test_that("util_nps_getswfwmd handles HTTP errors", {
  mock_response <- list()
  mock_response$status_code <- 500
  class(mock_response) <- "response"

  local_mocked_bindings(
    `GET` = mock(mock_response, cycle = TRUE),
    `status_code` = mock(500, cycle = TRUE),
    .package = 'httr'
  )

  expect_warning(
    result <- util_nps_getswfwmd("soil", verbose = FALSE),
    "Request failed at offset 0"
  )
  expect_null(result)
})

test_that("util_nps_getswfwmd handles empty response", {
  mock_response <- list()
  mock_response$status_code <- 200
  class(mock_response) <- "response"

  empty_sf <- create_mock_sf(1, "soil")[-1,]

  local_mocked_bindings(
    `GET` = mock(mock_response, cycle = TRUE),
    `status_code` = mock(200, cycle = TRUE),
    `content` = mock('{"type":"FeatureCollection","features":[]}', cycle = TRUE),
    .package = 'httr'
  )

  local_mocked_bindings(
    `st_read` = mock(empty_sf, cycle = TRUE),
    .package = 'sf'
  )

  result <- util_nps_getswfwmd("soil", verbose = FALSE)
  expect_null(result)
})

test_that("util_nps_getswfwmd handles pagination correctly", {
  mock_response <- list()
  mock_response$status_code <- 200
  class(mock_response) <- "response"

  # First call returns max_records, second call returns fewer (last batch)
  mock_sf_data_full <- create_mock_sf(1000, "soil")
  mock_sf_data_partial <- create_mock_sf(500, "soil")

  local_mocked_bindings(
    `GET` = mock(mock_response, cycle = TRUE),
    `status_code` = mock(200, cycle = TRUE),
    `content` = mock('{"type":"FeatureCollection","features":[]}', cycle = TRUE),
    .package = 'httr'
  )

  local_mocked_bindings(
    `st_read` = mock(mock_sf_data_full, mock_sf_data_partial, cycle = TRUE),
    .package = 'sf'
  )

  result <- suppressWarnings(util_nps_getswfwmd("soil", max_records = 1000, verbose = FALSE))

  expect_s3_class(result, "sf")
})

test_that("util_nps_getswfwmd verbose output works", {
  mock_response <- list()
  mock_response$status_code <- 200
  class(mock_response) <- "response"

  mock_sf_data <- create_mock_sf(5, "soil")

  local_mocked_bindings(
    `GET` = mock(mock_response, cycle = TRUE),
    `status_code` = mock(200, cycle = TRUE),
    `content` = mock('{"type":"FeatureCollection","features":[]}', cycle = TRUE),
    .package = 'httr'
  )

  local_mocked_bindings(
    `st_read` = mock(mock_sf_data, cycle = TRUE),
    .package = 'sf'
  )

  expect_output(
    suppressWarnings(util_nps_getswfwmd("soil", verbose = TRUE)),
    "Retrieved .* features"
  )
})
