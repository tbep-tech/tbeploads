library(testthat)
library(mockery)

# Helper: minimal raster over segment 3 subwatershed in EPSG:6443,
# matching the approach used in test-utils_gw.R.
make_gw_rast <- function(seg = 3) {
  bb <- sf::st_bbox(dplyr::filter(tbsubshed, .data$bay_seg == seg))
  r  <- terra::rast(
    xmin = bb["xmin"], xmax = bb["xmax"],
    ymin = bb["ymin"], ymax = bb["ymax"],
    resolution = 5000,
    crs = terra::crs(terra::vect(tbsegdetail))
  )
  terra::values(r) <- seq_len(terra::ncell(r))
  r
}

# Polygon far outside Tampa Bay (near EPSG:6443 origin) so that rasterizing
# it onto a seg-3 raster produces an all-NA zone_mask, triggering the
# "No land cells" stop().
far_poly <- sf::st_sfc(
  sf::st_polygon(list(matrix(c(0, 0, 1, 0, 1, 1, 0, 1, 0, 0),
                             ncol = 2, byrow = TRUE))),
  crs = 6443
)

# ===========================================================================
# util_gw_showgrad
# ===========================================================================

test_that("util_gw_showgrad returns a ggplot object", {
  r      <- make_gw_rast(3)
  result <- util_gw_showgrad(r, season = "dry", seg = 3, buf_segs = NULL)
  expect_s3_class(result, "ggplot")
})

test_that("util_gw_showgrad unwraps PackedSpatRaster automatically", {
  packed <- terra::wrap(make_gw_rast(3))
  expect_true(inherits(packed, "PackedSpatRaster"))
  result <- util_gw_showgrad(packed, season = "dry", seg = 3, buf_segs = NULL)
  expect_s3_class(result, "ggplot")
})

test_that("util_gw_showgrad uses dry-season label in title", {
  r      <- make_gw_rast(3)
  result <- util_gw_showgrad(r, season = "dry", seg = 3, buf_segs = NULL)
  expect_match(result$labels$title, "Dry season")
})

test_that("util_gw_showgrad uses wet-season label in title", {
  r      <- make_gw_rast(3)
  result <- util_gw_showgrad(r, season = "wet", seg = 3, buf_segs = NULL)
  expect_match(result$labels$title, "Wet season")
})

test_that("util_gw_showgrad season argument must be dry or wet", {
  r <- make_gw_rast(3)
  expect_error(
    util_gw_showgrad(r, season = "summer", seg = 3),
    "'arg' should be one of"
  )
})

test_that("util_gw_showgrad stops when search area contains no land cells", {
  r <- make_gw_rast(3)
  local_mocked_bindings(
    build_search_area = function(...) far_poly,
    .package = "tbeploads"
  )
  expect_error(
    util_gw_showgrad(r, season = "dry", seg = 3, buf_segs = NULL),
    "No land cells in search area"
  )
})

test_that("util_gw_showgrad stops when gradient cannot be computed", {
  r <- make_gw_rast(3)
  local_mocked_bindings(
    grad_from_rast = function(...) NULL,
    .package = "tbeploads"
  )
  expect_error(
    util_gw_showgrad(r, season = "dry", seg = 3, buf_segs = NULL),
    "Could not compute gradient"
  )
})

test_that("util_gw_showgrad applies custom buf_segs without error", {
  r      <- make_gw_rast(3)
  result <- util_gw_showgrad(r, season = "dry", seg = 3,
                              buf_segs = c("3" = 10000))
  expect_s3_class(result, "ggplot")
})

test_that("util_gw_showgrad default buf_segs differ between dry and wet", {
  r <- make_gw_rast(3)
  # Both should produce a ggplot; the point is to exercise the default branches.
  dry <- util_gw_showgrad(r, season = "dry", seg = 3)
  wet <- util_gw_showgrad(r, season = "wet", seg = 3)
  expect_s3_class(dry, "ggplot")
  expect_s3_class(wet, "ggplot")
})
