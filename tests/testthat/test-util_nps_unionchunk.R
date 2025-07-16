# Mock sf object creation function
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

test_that("util_nps_unionchunk processes single chunk correctly", {
  # Create test data
  sf1 <- create_mock_sf(id = c(1, 2))  # 2 features
  sf2 <- create_mock_sf(id = 3)

  # Mock the result from util_nps_unionnochunk
  mock_result <- create_mock_sf(id = 4)

  # Stub the unionnochunk function
  stub(util_nps_unionchunk, "util_nps_unionnochunk", function(sf1_chunk, sf2) {
    mock_result
  })

  result <- util_nps_unionchunk(sf1, sf2, chunk_size = 5, verbose = FALSE)

  expect_s3_class(result, "sf")
  expect_equal(nrow(result), 1)
})

test_that("util_nps_unionchunk processes multiple chunks correctly", {
  # Create test data with 5 features, chunk size 2
  sf1 <- create_mock_sf(id = c(1, 2, 3, 4, 5))
  sf2 <- create_mock_sf(id = 6)

  # Track how many times unionnochunk is called
  call_count <- 0

  # Stub the unionnochunk function
  stub(util_nps_unionchunk, "util_nps_unionnochunk", function(sf1_chunk, sf2) {
    call_count <<- call_count + 1
    # Return different results for each chunk
    create_mock_sf(id = 10 + call_count)
  })

  result <- util_nps_unionchunk(sf1, sf2, chunk_size = 2, verbose = FALSE)

  expect_s3_class(result, "sf")
  expect_equal(call_count, 3)  # Should process 3 chunks: 2+2+1 features
})

test_that("util_nps_unionchunk handles empty results from chunks", {
  # Create test data
  sf1 <- create_mock_sf(id = c(1, 2))
  sf2 <- create_mock_sf(id = 3)

  # Create empty sf object for mock result
  empty_result <- sf1[0, ]

  # Stub to return empty results
  stub(util_nps_unionchunk, "util_nps_unionnochunk", function(sf1_chunk, sf2) {
    empty_result
  })

  result <- util_nps_unionchunk(sf1, sf2, chunk_size = 5, verbose = FALSE)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
})

test_that("util_nps_unionchunk handles verbose output", {
  # Create test data
  sf1 <- create_mock_sf(id = c(1, 2, 3))
  sf2 <- create_mock_sf(id = 4)

  mock_result <- create_mock_sf(id = 5)

  # Stub the unionnochunk function
  stub(util_nps_unionchunk, "util_nps_unionnochunk", function(sf1_chunk, sf2) {
    mock_result
  })

  # Capture output to verify verbose messages
  expect_output(
    util_nps_unionchunk(sf1, sf2, chunk_size = 2, verbose = TRUE),
    "Processing chunk"
  )

  # Test that verbose = FALSE produces no output
  expect_silent(
    util_nps_unionchunk(sf1, sf2, chunk_size = 2, verbose = FALSE)
  )
})

test_that("util_nps_unionchunk calculates chunk boundaries correctly", {
  # Create test data with 7 features, chunk size 3
  sf1 <- create_mock_sf(id = c(1, 2, 3, 4, 5, 6, 7))
  sf2 <- create_mock_sf(id = 8)

  chunk_sizes <- c()

  # Stub to capture chunk sizes
  stub(util_nps_unionchunk, "util_nps_unionnochunk", function(sf1_chunk, sf2) {
    chunk_sizes <<- c(chunk_sizes, nrow(sf1_chunk))
    create_mock_sf(id = 9)
  })

  result <- util_nps_unionchunk(sf1, sf2, chunk_size = 3, verbose = FALSE)

  # Should have chunks of size 3, 3, 1
  expect_equal(chunk_sizes, c(3, 3, 1))
})
