create_mock_contour_sf <- function(n_rows = 3, month_year = "May 2022") {
  lines <- lapply(seq_len(n_rows), function(i) {
    sf::st_linestring(matrix(c(i * 0.1, 0, i * 0.1 + 0.5, 0.5), ncol = 2, byrow = TRUE))
  })
  sf::st_sf(
    CONTOUR    = as.integer(seq(10, by = 10, length.out = n_rows)),
    MONTH_YEAR = rep(month_year, n_rows),
    geometry   = sf::st_sfc(lines, crs = 4326)
  )
}

test_that("util_gw_getcontour returns sf with correct columns", {
  mock_resp <- structure(list(status_code = 200L), class = "response")
  mock_data <- create_mock_contour_sf(3)

  local_mocked_bindings(
    GET         = mock(mock_resp, cycle = TRUE),
    status_code = mock(200L, cycle = TRUE),
    content     = mock("", cycle = TRUE),
    .package    = "httr"
  )
  local_mocked_bindings(
    st_read = mock(mock_data, cycle = TRUE),
    .package = "sf"
  )

  result <- suppressWarnings(util_gw_getcontour("dry", 2022, verbose = FALSE))

  expect_s3_class(result, "sf")
  expect_true(all(c("CONTOUR", "MONTH_YEAR") %in% names(result)))
})

test_that("util_gw_getcontour uses correct MONTH_YEAR for dry season", {
  mock_resp <- structure(list(status_code = 200L), class = "response")
  mock_get  <- mock(mock_resp, cycle = TRUE)

  local_mocked_bindings(
    GET         = mock_get,
    status_code = mock(200L, cycle = TRUE),
    content     = mock("", cycle = TRUE),
    .package    = "httr"
  )
  local_mocked_bindings(
    st_read = mock(create_mock_contour_sf(3), cycle = TRUE),
    .package = "sf"
  )

  suppressWarnings(util_gw_getcontour("dry", 2022, verbose = FALSE))

  expect_match(mock_args(mock_get)[[1]]$query$where, "May 2022")
})

test_that("util_gw_getcontour uses correct MONTH_YEAR for wet season", {
  mock_resp <- structure(list(status_code = 200L), class = "response")
  mock_get  <- mock(mock_resp, cycle = TRUE)

  local_mocked_bindings(
    GET         = mock_get,
    status_code = mock(200L, cycle = TRUE),
    content     = mock("", cycle = TRUE),
    .package    = "httr"
  )
  local_mocked_bindings(
    st_read = mock(create_mock_contour_sf(3, "September 2022"), cycle = TRUE),
    .package = "sf"
  )

  suppressWarnings(util_gw_getcontour("wet", 2022, verbose = FALSE))

  expect_match(mock_args(mock_get)[[1]]$query$where, "September 2022")
})

test_that("util_gw_getcontour warns and returns NULL on HTTP error", {
  mock_resp <- structure(list(status_code = 500L), class = "response")

  local_mocked_bindings(
    GET         = mock(mock_resp, cycle = TRUE),
    status_code = mock(500L, cycle = TRUE),
    .package    = "httr"
  )

  expect_warning(
    expect_warning(
      result <- util_gw_getcontour("dry", 2022, verbose = FALSE),
      "Request failed at offset 0"
    ),
    "No features returned"
  )
  expect_null(result)
})

test_that("util_gw_getcontour warns and returns NULL when no features returned", {
  mock_resp  <- structure(list(status_code = 200L), class = "response")
  empty_data <- create_mock_contour_sf(3)[0, ]

  local_mocked_bindings(
    GET         = mock(mock_resp, cycle = TRUE),
    status_code = mock(200L, cycle = TRUE),
    content     = mock("", cycle = TRUE),
    .package    = "httr"
  )
  local_mocked_bindings(
    st_read = mock(empty_data, cycle = TRUE),
    .package = "sf"
  )

  expect_warning(
    result <- util_gw_getcontour("dry", 2022, verbose = FALSE),
    "No features returned"
  )
  expect_null(result)
})

test_that("util_gw_getcontour handles pagination", {
  mock_resp    <- structure(list(status_code = 200L), class = "response")
  full_batch   <- create_mock_contour_sf(5)
  partial_batch <- create_mock_contour_sf(3)

  local_mocked_bindings(
    GET         = mock(mock_resp, cycle = TRUE),
    status_code = mock(200L, cycle = TRUE),
    content     = mock("", cycle = TRUE),
    .package    = "httr"
  )
  local_mocked_bindings(
    st_read = mock(full_batch, partial_batch),
    .package = "sf"
  )

  result <- suppressWarnings(
    util_gw_getcontour("dry", 2022, max_records = 5, verbose = FALSE)
  )

  expect_s3_class(result, "sf")
})

test_that("util_gw_getcontour prints progress when verbose = TRUE", {
  mock_resp <- structure(list(status_code = 200L), class = "response")
  mock_data <- create_mock_contour_sf(3)

  local_mocked_bindings(
    GET         = mock(mock_resp, cycle = TRUE),
    status_code = mock(200L, cycle = TRUE),
    content     = mock("", cycle = TRUE),
    .package    = "httr"
  )
  local_mocked_bindings(
    st_read = mock(mock_data, cycle = TRUE),
    .package = "sf"
  )

  expect_output(
    suppressWarnings(util_gw_getcontour("dry", 2022, verbose = TRUE)),
    "Retrieved .* features"
  )
})

test_that("util_gw_getcontour rejects invalid season argument", {
  expect_error(
    util_gw_getcontour("spring", 2022),
    "'arg' should be one of"
  )
})
