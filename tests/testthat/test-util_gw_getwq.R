make_ndjson_resp <- function(sid, tn_vals, tp_vals) {
  recs <- c(
    lapply(tn_vals, function(v)
      jsonlite::toJSON(list(stationID = sid, parameter = "TN_mgl",
                            resultValue = v), auto_unbox = TRUE)),
    lapply(tp_vals, function(v)
      jsonlite::toJSON(list(stationID = sid, parameter = "TP_mgl",
                            resultValue = v), auto_unbox = TRUE))
  )
  paste(recs, collapse = "\n")
}

mock_resp_ok <- function(body) {
  structure(
    list(status_code = 200L, body = charToRaw(body)),
    class = "response"
  )
}

setup_mocks <- function(tn1 = c(0.06, 0.12, 0.12), tp1 = c(0.027, 0.03, 0.031),
                        tn2 = c(0.39, 0.41, 0.44), tp2 = c(0.027, 0.028, 0.03)) {
  resp1 <- mock_resp_ok(make_ndjson_resp("18340", tn1, tp1))
  resp2 <- mock_resp_ok(make_ndjson_resp("18965", tn2, tp2))

  local_mocked_bindings(
    GET         = mock(resp1, resp2, cycle = FALSE),
    status_code = mock(200L, cycle = TRUE),
    content     = mock(
      make_ndjson_resp("18340", tn1, tp1),
      make_ndjson_resp("18965", tn2, tp2),
      cycle = FALSE
    ),
    .package = "httr",
    .env     = parent.frame()
  )
}

test_that("util_gw_getwq returns correct structure", {
  local_mocked_bindings(
    GET         = mock(mock_resp_ok(make_ndjson_resp("18340", c(0.1), c(0.029))),
                       mock_resp_ok(make_ndjson_resp("18965", c(0.41), c(0.028))),
                       cycle = FALSE),
    status_code = mock(200L, cycle = TRUE),
    content     = mock(make_ndjson_resp("18340", c(0.1), c(0.029)),
                       make_ndjson_resp("18965", c(0.41), c(0.028)),
                       cycle = FALSE),
    .package = "httr"
  )

  result <- util_gw_getwq(verbose = FALSE)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 7L)
  expect_true(all(c("bay_seg", "tn_mgl", "tp_mgl") %in% names(result)))
  expect_equal(result$bay_seg, 1L:7L)
})

test_that("util_gw_getwq seg 1 uses first station only", {
  tn1 <- c(0.06, 0.12, 0.12); tp1 <- c(0.027, 0.03, 0.031)
  tn2 <- c(0.39, 0.41, 0.44); tp2 <- c(0.027, 0.028, 0.03)

  local_mocked_bindings(
    GET         = mock(mock_resp_ok(make_ndjson_resp("18340", tn1, tp1)),
                       mock_resp_ok(make_ndjson_resp("18965", tn2, tp2)),
                       cycle = FALSE),
    status_code = mock(200L, cycle = TRUE),
    content     = mock(make_ndjson_resp("18340", tn1, tp1),
                       make_ndjson_resp("18965", tn2, tp2),
                       cycle = FALSE),
    .package = "httr"
  )

  result <- util_gw_getwq(verbose = FALSE)

  expect_equal(result$tn_mgl[result$bay_seg == 1L], mean(tn1), tolerance = 1e-6)
  expect_equal(result$tp_mgl[result$bay_seg == 1L], mean(tp1), tolerance = 1e-6)
})

test_that("util_gw_getwq seg 2 averages both station means", {
  tn1 <- c(0.06, 0.12, 0.12); tp1 <- c(0.027, 0.03, 0.031)
  tn2 <- c(0.39, 0.41, 0.44); tp2 <- c(0.027, 0.028, 0.03)

  local_mocked_bindings(
    GET         = mock(mock_resp_ok(make_ndjson_resp("18340", tn1, tp1)),
                       mock_resp_ok(make_ndjson_resp("18965", tn2, tp2)),
                       cycle = FALSE),
    status_code = mock(200L, cycle = TRUE),
    content     = mock(make_ndjson_resp("18340", tn1, tp1),
                       make_ndjson_resp("18965", tn2, tp2),
                       cycle = FALSE),
    .package = "httr"
  )

  result <- util_gw_getwq(verbose = FALSE)

  expected_tn <- mean(c(mean(tn1), mean(tn2)))
  expected_tp <- mean(c(mean(tp1), mean(tp2)))
  expect_equal(result$tn_mgl[result$bay_seg == 2L], expected_tn, tolerance = 1e-6)
  expect_equal(result$tp_mgl[result$bay_seg == 2L], expected_tp, tolerance = 1e-6)
})

test_that("util_gw_getwq segs 3-7 return fixed historical values", {
  local_mocked_bindings(
    GET         = mock(mock_resp_ok(make_ndjson_resp("18340", c(0.1), c(0.029))),
                       mock_resp_ok(make_ndjson_resp("18965", c(0.41), c(0.028))),
                       cycle = FALSE),
    status_code = mock(200L, cycle = TRUE),
    content     = mock(make_ndjson_resp("18340", c(0.1), c(0.029)),
                       make_ndjson_resp("18965", c(0.41), c(0.028)),
                       cycle = FALSE),
    .package = "httr"
  )

  result <- util_gw_getwq(verbose = FALSE)

  expect_equal(result$tn_mgl[result$bay_seg == 3L], 0.025)
  expect_equal(result$tp_mgl[result$bay_seg == 3L], 0.137)
  expect_equal(result$tn_mgl[result$bay_seg == 5L], 0.022)
  expect_equal(result$tp_mgl[result$bay_seg == 7L], 0.114)
})

test_that("util_gw_getwq respects custom sta_ids", {
  local_mocked_bindings(
    GET         = mock(mock_resp_ok(make_ndjson_resp("99999", c(0.5), c(0.05))),
                       cycle = FALSE),
    status_code = mock(200L, cycle = TRUE),
    content     = mock(make_ndjson_resp("99999", c(0.5), c(0.05)), cycle = FALSE),
    .package = "httr"
  )

  result <- util_gw_getwq(sta_ids = "99999", verbose = FALSE)

  expect_equal(result$tn_mgl[result$bay_seg == 1L], 0.5)
  expect_equal(result$tn_mgl[result$bay_seg == 2L], 0.5)
})

test_that("util_gw_getwq errors on HTTP failure", {
  bad_resp <- structure(list(status_code = 500L), class = "response")
  local_mocked_bindings(
    GET         = mock(bad_resp, cycle = TRUE),
    status_code = mock(500L, cycle = TRUE),
    .package    = "httr"
  )

  expect_error(util_gw_getwq(verbose = FALSE), "HTTP 500")
})

test_that("util_gw_getwq errors when API returns no data", {
  empty_resp <- mock_resp_ok("")
  local_mocked_bindings(
    GET         = mock(empty_resp, cycle = TRUE),
    status_code = mock(200L, cycle = TRUE),
    content     = mock("", cycle = TRUE),
    .package    = "httr"
  )

  expect_error(util_gw_getwq(verbose = FALSE), "No data returned")
})

test_that("util_gw_getwq passes yrrng as date query params", {
  mock_get <- mock(
    mock_resp_ok(make_ndjson_resp("18340", c(0.1), c(0.029))),
    mock_resp_ok(make_ndjson_resp("18965", c(0.41), c(0.028))),
    cycle = FALSE
  )
  local_mocked_bindings(
    GET         = mock_get,
    status_code = mock(200L, cycle = TRUE),
    content     = mock(make_ndjson_resp("18340", c(0.1), c(0.029)),
                       make_ndjson_resp("18965", c(0.41), c(0.028)),
                       cycle = FALSE),
    .package = "httr"
  )

  util_gw_getwq(yrrng = c(2020, 2024), verbose = FALSE)

  args1 <- mock_args(mock_get)[[1]]
  expect_equal(args1$query$startDate, "2020-01-01")
  expect_equal(args1$query$endDate,   "2024-12-31")
})

test_that("util_gw_getwq omits date params when yrrng is NULL", {
  mock_get <- mock(
    mock_resp_ok(make_ndjson_resp("18340", c(0.1), c(0.029))),
    mock_resp_ok(make_ndjson_resp("18965", c(0.41), c(0.028))),
    cycle = FALSE
  )
  local_mocked_bindings(
    GET         = mock_get,
    status_code = mock(200L, cycle = TRUE),
    content     = mock(make_ndjson_resp("18340", c(0.1), c(0.029)),
                       make_ndjson_resp("18965", c(0.41), c(0.028)),
                       cycle = FALSE),
    .package = "httr"
  )

  util_gw_getwq(verbose = FALSE)

  args1 <- mock_args(mock_get)[[1]]
  expect_null(args1$query$startDate)
  expect_null(args1$query$endDate)
})
