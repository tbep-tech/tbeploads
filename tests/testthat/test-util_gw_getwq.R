make_wq_csv <- function(dir, station, sid, params, values, n = 3) {
  rows <- expand.grid(param = params, i = seq_len(n), stringsAsFactors = FALSE)
  rows$result <- values[match(rows$param, params)]
  dat <- data.frame(
    SID                           = sid,
    `Station Name`                = station,
    `Parameter Name`              = rows$param,
    `Sample Date and Time`        = "01/01/2022 10:00:00",
    Timezone                      = "(GMT-05:00)",
    `Sample Result`               = rows$result,
    `Measuring Unit`              = "milligram per litre",
    Remark                        = "",
    `Method Name`                 = "EPA",
    Medium                        = "Water",
    `Value Qualifier`             = "",
    `Analysis Date and Time`      = "",
    `Measuring program Name`      = "Test",
    `Activity Depth`              = 77,
    `Activity Depth Unit`         = "ft",
    `Sampling Agency`             = "SWFMD",
    check.names                   = FALSE,
    stringsAsFactors              = FALSE
  )
  fname <- file.path(dir, paste0(station, ".csv"))
  write.csv(dat, fname, row.names = FALSE, quote = TRUE)
  fname
}

setup_wq_dir <- function() {
  dir <- tempfile("gwwq")
  dir.create(dir)
  make_wq_csv(dir, "CR 581 North Fldn", 18340,
              params = c("Nitrogen- Total (Total)", "Phosphorus- Total (Total)"),
              values = c(0.10, 0.02933333))
  make_wq_csv(dir, "SR 52 and CR 581 Deep", 18665,
              params = c("Nitrogen- Total (Total)", "Phosphorus- Total (Total)"),
              values = c(0.4133333, 0.02833333))
  dir
}

test_that("util_gw_getwq returns correct structure", {
  dir <- setup_wq_dir()
  on.exit(unlink(dir, recursive = TRUE))

  result <- util_gw_getwq(dir)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 7L)
  expect_true(all(c("bay_seg", "tn_mgl", "tp_mgl") %in% names(result)))
  expect_equal(result$bay_seg, 1L:7L)
})

test_that("util_gw_getwq seg 1 uses CR 581 North Fldn only", {
  dir <- setup_wq_dir()
  on.exit(unlink(dir, recursive = TRUE))

  result <- util_gw_getwq(dir)

  expect_equal(result$tn_mgl[result$bay_seg == 1L], 0.10, tolerance = 1e-4)
  expect_equal(result$tp_mgl[result$bay_seg == 1L], 0.02933333, tolerance = 1e-4)
})

test_that("util_gw_getwq seg 2 averages both Pasco stations", {
  dir <- setup_wq_dir()
  on.exit(unlink(dir, recursive = TRUE))

  result <- util_gw_getwq(dir)

  expected_tn <- mean(c(0.10, 0.4133333))
  expected_tp <- mean(c(0.02933333, 0.02833333))
  expect_equal(result$tn_mgl[result$bay_seg == 2L], expected_tn, tolerance = 1e-4)
  expect_equal(result$tp_mgl[result$bay_seg == 2L], expected_tp, tolerance = 1e-4)
})

test_that("util_gw_getwq segs 3-7 return fixed historical values", {
  dir <- setup_wq_dir()
  on.exit(unlink(dir, recursive = TRUE))

  result <- util_gw_getwq(dir)

  expect_equal(result$tn_mgl[result$bay_seg == 3L], 0.025)
  expect_equal(result$tp_mgl[result$bay_seg == 3L], 0.137)
  expect_equal(result$tn_mgl[result$bay_seg == 5L], 0.022)
  expect_equal(result$tp_mgl[result$bay_seg == 7L], 0.114)
})

test_that("util_gw_getwq errors when no CSV files found", {
  dir <- tempfile("gwwq_empty")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE))

  expect_error(util_gw_getwq(dir), "No CSV files found")
})

test_that("util_gw_getwq errors when required station is missing", {
  dir <- tempfile("gwwq_missing")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE))

  # Only supply one of the two required stations
  make_wq_csv(dir, "CR 581 North Fldn", 18340,
              params = c("Nitrogen- Total (Total)", "Phosphorus- Total (Total)"),
              values = c(0.10, 0.029))

  expect_error(util_gw_getwq(dir), "SR 52 and CR 581 Deep")
})

test_that("util_gw_getwq errors on wrong column count", {
  dir <- tempfile("gwwq_bad")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE))

  # Write a CSV with too few columns
  write.csv(data.frame(a = 1, b = 2), file.path(dir, "bad.csv"), row.names = FALSE)

  expect_error(util_gw_getwq(dir), "Unexpected number of columns")
})
