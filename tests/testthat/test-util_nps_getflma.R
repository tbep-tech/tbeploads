
# Simple overlapping sf polygon in EPSG 6443 used throughout
make_mock_sf <- function() {
  coords <- list(rbind(c(0, 0), c(1, 0), c(1, 1), c(0, 1), c(0, 0)))
  sf::st_sf(a = 1L, geometry = sf::st_sfc(sf::st_polygon(coords), crs = 6443L))
}

# unzip mock that writes a dummy .shp so list.files() finds it naturally
mock_unzip_shp <- function(zipfile, exdir, ...) {
  dir.create(file.path(exdir, "layer"), recursive = TRUE, showWarnings = FALSE)
  writeBin(raw(0), file.path(exdir, "layer", "test.shp"))
}

# unzip mock that creates a .gdb directory
mock_unzip_gdb <- function(zipfile, exdir, ...) {
  dir.create(file.path(exdir, "test.gdb"), recursive = TRUE, showWarnings = FALSE)
}

# unzip mock that creates nothing useful (empty exdir only)
mock_unzip_empty <- function(zipfile, exdir, ...) {
  dir.create(exdir, recursive = TRUE, showWarnings = FALSE)
}

# ---- Shapefile path ----------------------------------------------------------

test_that("util_nps_getflma returns sf via shapefile path", {
  local_mocked_bindings(
    req_perform   = mockery::mock(list()),
    resp_body_raw = mockery::mock(raw(0)),
    .package      = "httr2"
  )
  local_mocked_bindings(unzip = mock_unzip_shp, .package = "utils")
  local_mocked_bindings(st_read = mockery::mock(make_mock_sf()), .package = "sf")

  result <- suppressWarnings(util_nps_getflma(
    url     = "http://example.com/test_flma.zip",
    clp     = make_mock_sf(),
    verbose = FALSE
  ))

  expect_s3_class(result, "sf")
})

# ---- GDB path ----------------------------------------------------------------

test_that("util_nps_getflma returns sf via GDB path", {
  local_mocked_bindings(
    req_perform   = mockery::mock(list()),
    resp_body_raw = mockery::mock(raw(0)),
    .package      = "httr2"
  )
  local_mocked_bindings(unzip = mock_unzip_gdb, .package = "utils")
  local_mocked_bindings(
    st_layers  = mockery::mock(list(name = "layer1")),
    gdal_utils = mockery::mock(invisible(NULL)),
    st_read    = mockery::mock(make_mock_sf()),
    .package   = "sf"
  )

  result <- suppressWarnings(util_nps_getflma(
    url     = "http://example.com/test_flma.zip",
    clp     = make_mock_sf(),
    verbose = FALSE
  ))

  expect_s3_class(result, "sf")
})

# ---- Error when archive contains neither .gdb nor .shp ----------------------

test_that("util_nps_getflma errors when zip contains no .gdb or .shp", {
  local_mocked_bindings(
    req_perform   = mockery::mock(list()),
    resp_body_raw = mockery::mock(raw(0)),
    .package      = "httr2"
  )
  local_mocked_bindings(unzip = mock_unzip_empty, .package = "utils")

  expect_error(
    util_nps_getflma(
      url     = "http://example.com/test_flma.zip",
      clp     = make_mock_sf(),
      verbose = FALSE
    ),
    "No .gdb or .shp found in zip"
  )
})

# ---- Verbose output ----------------------------------------------------------

test_that("util_nps_getflma prints 'Downloading' with verbose = TRUE", {
  local_mocked_bindings(
    req_perform   = mockery::mock(list()),
    resp_body_raw = mockery::mock(raw(0)),
    .package      = "httr2"
  )
  local_mocked_bindings(unzip = mock_unzip_shp, .package = "utils")
  local_mocked_bindings(st_read = mockery::mock(make_mock_sf()), .package = "sf")

  expect_output(
    suppressWarnings(util_nps_getflma(
      url     = "http://example.com/test_flma.zip",
      clp     = make_mock_sf(),
      verbose = TRUE
    )),
    "Downloading"
  )
})
