# Helpers to build minimal projected sf objects for testing internal utils.

make_contour_sf <- function(n = 3, crs = 6443) {
  # Simple horizontal lines at different y positions, each with a CONTOUR value
  lines <- lapply(seq_len(n), function(i) {
    sf::st_linestring(matrix(c(600000, 700000 + i * 5000,
                                650000, 700000 + i * 5000), ncol = 2, byrow = TRUE))
  })
  sf::st_sf(
    CONTOUR  = as.integer(seq(10, by = 10, length.out = n)),
    geometry = sf::st_sfc(lines, crs = crs)
  )
}

# ---- contours_to_raster -----------------------------------------------------

test_that("contours_to_raster returns a SpatRaster", {
  contours <- make_contour_sf()
  r <- contours_to_raster(contours, verbose = FALSE)
  expect_true(inherits(r, "SpatRaster"))
})

test_that("contours_to_raster cell values are within contour range", {
  contours <- make_contour_sf(n = 5)
  r <- contours_to_raster(contours, verbose = FALSE)
  vals <- terra::values(r, na.rm = TRUE)
  expect_true(all(vals >= min(contours$CONTOUR)))
  expect_true(all(vals <= max(contours$CONTOUR)))
})

test_that("contours_to_raster resolution matches res_ft argument", {
  contours <- make_contour_sf()
  r <- contours_to_raster(contours, res_ft = 5280, verbose = FALSE)
  expect_equal(terra::res(r), c(5280, 5280))
})

test_that("contours_to_raster focal gap-fill reduces NA count", {
  contours <- make_contour_sf()
  r_no_fill  <- contours_to_raster(contours, focal_iter = 0, verbose = FALSE)
  r_filled   <- contours_to_raster(contours, focal_iter = 3, verbose = FALSE)
  na_before  <- sum(is.na(terra::values(r_no_fill)))
  na_after   <- sum(is.na(terra::values(r_filled)))
  expect_lte(na_after, na_before)
})

# ---- build_search_area -------------------------------------------------------

test_that("build_search_area returns an sfc for a plain segment", {
  area <- build_search_area(seg = 3, buf_segs = NULL)
  expect_true(inherits(area, "sfc"))
})

test_that("build_search_area with buf_segs expands area beyond plain watershed", {
  plain    <- build_search_area(seg = 1, buf_segs = NULL)
  buffered <- build_search_area(seg = 1, buf_segs = c("1" = 52800))
  expect_gt(as.numeric(sf::st_area(buffered)), as.numeric(sf::st_area(plain)))
})

test_that("build_search_area buf_segs for unlisted segment returns plain watershed", {
  plain    <- build_search_area(seg = 3, buf_segs = NULL)
  unlisted <- build_search_area(seg = 3, buf_segs = c("1" = 52800))
  expect_equal(sf::st_area(plain), sf::st_area(unlisted))
})

# ---- grad_from_rast ----------------------------------------------------------

make_masked_rast <- function(seg = 3) {
  # Derive extent from the actual segment subwatershed so coordinates are
  # valid for EPSG:6443 and compatible with tbsegdetail geometry operations.
  bb <- sf::st_bbox(dplyr::filter(tbsubshed, .data$bay_seg == seg))
  r  <- terra::rast(
    xmin       = bb["xmin"], xmax = bb["xmax"],
    ymin       = bb["ymin"], ymax = bb["ymax"],
    resolution = 5000,
    crs        = terra::crs(terra::vect(tbsegdetail))
  )
  terra::values(r) <- seq_len(terra::ncell(r))
  r
}

test_that("grad_from_rast returns NULL for all-NA raster", {
  r <- make_masked_rast()
  terra::values(r) <- NA_real_
  result <- grad_from_rast(r, seg = 3, shoreline = tbsegdetail)
  expect_null(result)
})

test_that("grad_from_rast returns list with expected names", {
  r      <- make_masked_rast()
  result <- grad_from_rast(r, seg = 3, shoreline = tbsegdetail)
  expect_true(all(c("elev", "dist_mi", "grad") %in% names(result)))
})

test_that("grad_from_rast elevation equals raster maximum", {
  r      <- make_masked_rast()
  result <- grad_from_rast(r, seg = 3, shoreline = tbsegdetail)
  expect_equal(result$elev, terra::global(r, "max", na.rm = TRUE)[[1]])
})

test_that("grad_from_rast gradient is positive for non-trivial raster", {
  r      <- make_masked_rast()
  result <- grad_from_rast(r, seg = 3, shoreline = tbsegdetail)
  expect_gt(result$grad, 0)
})
