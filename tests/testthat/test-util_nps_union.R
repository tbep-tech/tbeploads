# Helper function to create mock sf objects
create_mock_sf <- function(coords = NULL, crs = 4326, id = 1) {

  # Handle vector of IDs - create multiple polygons
  if (length(id) > 1) {
    polygons <- list()

    for (i in seq_along(id)) {
      # Create slightly different polygons by shifting coordinates
      if (is.null(coords)) {
        shift_coords <- list(matrix(c(i-1, i-1,
                                      i, i-1,
                                      i, i,
                                      i-1, i,
                                      i-1, i-1), ncol = 2, byrow = TRUE))
      } else {
        # Use provided coords but shift them
        shift_coords <- lapply(coords, function(coord_matrix) {
          coord_matrix + (i-1)
        })
      }

      polygon_geom <- st_polygon(shift_coords)

      polygons[[i]] <- st_sf(
        id = id[i],
        name = paste0("polygon_", id[i]),
        area = st_area(polygon_geom),
        geometry = st_sfc(polygon_geom, crs = crs)
      )
    }

    # Combine into single sf object
    return(do.call(rbind, polygons))
  }

  # Single polygon case
  # Default coordinates for a simple square if none provided
  if (is.null(coords)) {
    coords <- list(matrix(c(0, 0,
                            1, 0,
                            1, 1,
                            0, 1,
                            0, 0), ncol = 2, byrow = TRUE))
  }

  # Create polygon geometry
  polygon_geom <- st_polygon(coords)

  # Create sf object with some basic attributes
  sf_polygon <- st_sf(
    id = id,
    name = paste0("polygon_", id),
    area = st_area(polygon_geom),
    geometry = st_sfc(polygon_geom, crs = crs)
  )

  return(sf_polygon)
}

# Mock function to create a simple sf multipolygon object for unit testing
create_mock_multisf <- function(n_polygons = 2, coords_list = NULL, crs = 4326, id = 1) {

  # Handle vector of IDs - create multiple multipolygons
  if (length(id) > 1) {
    multipolygons <- list()

    for (i in seq_along(id)) {
      # Create multipolygon with offset
      if (is.null(coords_list)) {
        # Default: create n_polygons squares with some separation
        poly_coords <- list()
        for (j in 1:n_polygons) {
          offset_x <- (i-1) * 5 + (j-1) * 2
          offset_y <- (i-1) * 5
          poly_coords[[j]] <- list(matrix(c(offset_x, offset_y,
                                            offset_x + 1, offset_y,
                                            offset_x + 1, offset_y + 1,
                                            offset_x, offset_y + 1,
                                            offset_x, offset_y), ncol = 2, byrow = TRUE))
        }
      } else {
        # Use provided coords but shift them
        poly_coords <- lapply(coords_list, function(coord_list) {
          lapply(coord_list, function(coord_matrix) {
            coord_matrix + (i-1) * 5
          })
        })
      }

      multipolygon_geom <- st_multipolygon(poly_coords)

      multipolygons[[i]] <- st_sf(
        id = id[i],
        name = paste0("multipolygon_", id[i]),
        area = st_area(multipolygon_geom),
        geometry = st_sfc(multipolygon_geom, crs = crs)
      )
    }

    # Combine into single sf object
    return(do.call(rbind, multipolygons))
  }

  # Single multipolygon case
  if (is.null(coords_list)) {
    # Default: create n_polygons squares with some separation
    poly_coords <- list()
    for (i in 1:n_polygons) {
      offset_x <- (i-1) * 2
      poly_coords[[i]] <- list(matrix(c(offset_x, 0,
                                        offset_x + 1, 0,
                                        offset_x + 1, 1,
                                        offset_x, 1,
                                        offset_x, 0), ncol = 2, byrow = TRUE))
    }
  } else {
    poly_coords <- coords_list
  }

  # Create multipolygon geometry
  multipolygon_geom <- st_multipolygon(poly_coords)

  # Create sf object with some basic attributes
  sf_multipolygon <- st_sf(
    id = id,
    name = paste0("multipolygon_", id),
    area = st_area(multipolygon_geom),
    geometry = st_sfc(multipolygon_geom, crs = crs)
  )

  return(sf_multipolygon)
}

test_that("util_nps_union handles GDAL path correctly", {
  mock_sf1 <- create_mock_sf()
  mock_sf2 <- create_mock_sf()

  # Use mockery::stub to replace functions within util_nps_union
  stub(util_nps_union, 'system', 0)
  stub(util_nps_union, 'Sys.getenv', "original_path")
  stub(util_nps_union, 'Sys.setenv', invisible())
  stub(util_nps_union, 'util_nps_unionnochunk', "mocked_result")

  result <- util_nps_union(mock_sf1, mock_sf2, gdal_path = "C:/test/bin", verbose = FALSE)

  expect_equal(result, "mocked_result")
})

test_that("util_nps_union fails when ogr2ogr not found", {
  mock_sf1 <- create_mock_sf()
  mock_sf2 <- create_mock_sf()

  # Mock failed system call
  stub(util_nps_union, 'system', 1)
  stub(util_nps_union, 'Sys.getenv', "original_path")
  stub(util_nps_union, 'Sys.setenv', invisible())

  expect_error(
    util_nps_union(mock_sf1, mock_sf2, gdal_path = "C:/bad/path", verbose = FALSE),
    "ogr2ogr not found at specified path"
  )
})

test_that("util_nps_union processes chunks when chunk_size specified", {
  mock_sf1 <- create_mock_sf(id = 1:100)
  mock_sf2 <- create_mock_sf(id = 50)

  stub(util_nps_union, 'system', 0)
  stub(util_nps_union, 'util_nps_unionchunk', "chunked_result")

  result <- expect_output(util_nps_union(mock_sf1, mock_sf2, chunk_size = 50, verbose = TRUE), "Processing in chunks of 50 features")

  expect_equal(result, "chunked_result")
})

test_that("util_nps_union handles casting multipolygons", {
  mock_sf1 <- create_mock_multisf()
  mock_sf2 <- create_mock_multisf()

  stub(util_nps_union, 'system', 0)
  stub(util_nps_union, 'sf::st_geometry_type', c("MULTIPOLYGON"))
  stub(util_nps_union, 'sf::st_cast', mock_sf1)  # Return the same object
  stub(util_nps_union, 'util_nps_unionnochunk', "casted_result")

  result <- util_nps_union(mock_sf1, mock_sf2, cast = TRUE, verbose = FALSE)

  expect_equal(result, "casted_result")
})

test_that("util_nps_union works without gdal_path when ogr2ogr in PATH", {
  mock_sf1 <- create_mock_sf()
  mock_sf2 <- create_mock_sf()

  stub(util_nps_union, 'system', 0)  # ogr2ogr found in PATH
  stub(util_nps_union, 'util_nps_unionnochunk', "no_path_result")

  result <- util_nps_union(mock_sf1, mock_sf2, verbose = FALSE)

  expect_equal(result, "no_path_result")
})

test_that("util_nps_union fails when ogr2ogr not in PATH", {
  mock_sf1 <- create_mock_sf(id = 10)
  mock_sf2 <- create_mock_sf(id = 10)

  stub(util_nps_union, 'system', 1)  # ogr2ogr not found

  expect_error(
    util_nps_union(mock_sf1, mock_sf2, verbose = FALSE),
    "ogr2ogr not found in system PATH"
  )
})
