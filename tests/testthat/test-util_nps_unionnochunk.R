# Mock sf object creation function (assuming this is available)
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

test_that("util_nps_unionnochunk works with valid inputs", {
  # Create mock sf objects
  sf1 <- create_mock_sf(id = 1)
  sf2 <- create_mock_sf(id = 2)

  # Mock the expected result
  mock_result <- create_mock_sf(id = 3)

  # Stub all the external dependencies
  stub(util_nps_unionnochunk, "tempfile", function(fileext = "") paste0("/tmp/test", fileext))
  stub(util_nps_unionnochunk, "sf::st_write", function(...) invisible(NULL))
  stub(util_nps_unionnochunk, "sf::gdal_utils", function(...) invisible(NULL))
  stub(util_nps_unionnochunk, "sf::st_layers", function(...) {
    list(name = c("layer1", "layer2"))
  })
  stub(util_nps_unionnochunk, "system", function(...) 0)
  stub(util_nps_unionnochunk, "sf::st_read", function(...) mock_result)
  stub(util_nps_unionnochunk, "unlink", function(...) invisible(NULL))

  result <- util_nps_unionnochunk(sf1, sf2)

  # Check that result is an sf object
  expect_s3_class(result, "sf")

  # Check that result has expected structure
  expect_true("geometry" %in% names(result))
})

test_that("util_nps_unionnochunk handles system call failure", {
  # Create mock sf objects
  sf1 <- create_mock_sf(id = 1)
  sf2 <- create_mock_sf(id = 2)

  # Stub all dependencies but make system call fail
  stub(util_nps_unionnochunk, "tempfile", function(fileext = "") paste0("/tmp/test", fileext))
  stub(util_nps_unionnochunk, "sf::st_write", function(...) invisible(NULL))
  stub(util_nps_unionnochunk, "sf::gdal_utils", function(...) invisible(NULL))
  stub(util_nps_unionnochunk, "sf::st_layers", function(...) {
    list(name = c("layer1", "layer2"))
  })
  stub(util_nps_unionnochunk, "system", function(...) 1)  # Return failure
  stub(util_nps_unionnochunk, "unlink", function(...) invisible(NULL))

  expect_error(
    util_nps_unionnochunk(sf1, sf2),
    "ogr2ogr operation failed"
  )
})

test_that("util_nps_unionnochunk handles multiple columns correctly", {
  # Create mock sf objects with multiple columns
  sf1 <- st_sf(
    id = 1,
    name = "poly1",
    category = "A",
    geometry = st_sfc(st_polygon(list(matrix(c(0,0, 1,0, 1,1, 0,1, 0,0), ncol=2, byrow=TRUE))), crs = 4326)
  )

  sf2 <- st_sf(
    id = 2,
    type = "B",
    value = 10,
    geometry = st_sfc(st_polygon(list(matrix(c(0.5,0.5, 1.5,0.5, 1.5,1.5, 0.5,1.5, 0.5,0.5), ncol=2, byrow=TRUE))), crs = 4326)
  )

  mock_result <- create_mock_sf(id = 3)

  # Stub all dependencies
  stub(util_nps_unionnochunk, "tempfile", function(fileext = "") paste0("/tmp/test", fileext))
  stub(util_nps_unionnochunk, "sf::st_write", function(...) invisible(NULL))
  stub(util_nps_unionnochunk, "sf::gdal_utils", function(...) invisible(NULL))
  stub(util_nps_unionnochunk, "sf::st_layers", function(...) {
    list(name = c("layer1", "layer2"))
  })
  stub(util_nps_unionnochunk, "system", function(cmd) {
    # Verify SQL query contains expected columns
    expect_true(grepl("a.id", cmd))
    expect_true(grepl("a.name", cmd))
    expect_true(grepl("a.category", cmd))
    expect_true(grepl("b.id", cmd))
    expect_true(grepl("b.type", cmd))
    expect_true(grepl("b.value", cmd))
    return(0)
  })
  stub(util_nps_unionnochunk, "sf::st_read", function(...) mock_result)
  stub(util_nps_unionnochunk, "unlink", function(...) invisible(NULL))

  result <- util_nps_unionnochunk(sf1, sf2)
  expect_s3_class(result, "sf")
})

test_that("util_nps_unionnochunk cleans up temporary files", {
  # Create mock sf objects
  sf1 <- create_mock_sf(id = 1)
  sf2 <- create_mock_sf(id = 2)

  mock_result <- create_mock_sf(id = 3)
  unlink_called <- FALSE

  # Stub all dependencies
  stub(util_nps_unionnochunk, "tempfile", function(fileext = "") paste0("/tmp/test", fileext))
  stub(util_nps_unionnochunk, "sf::st_write", function(...) invisible(NULL))
  stub(util_nps_unionnochunk, "sf::gdal_utils", function(...) invisible(NULL))
  stub(util_nps_unionnochunk, "sf::st_layers", function(...) {
    list(name = c("layer1", "layer2"))
  })
  stub(util_nps_unionnochunk, "system", function(...) 0)
  stub(util_nps_unionnochunk, "sf::st_read", function(...) mock_result)
  stub(util_nps_unionnochunk, "unlink", function(...) {
    unlink_called <<- TRUE
    invisible(NULL)
  })

  result <- util_nps_unionnochunk(sf1, sf2)

  # Check that cleanup was called
  expect_true(unlink_called)
})
