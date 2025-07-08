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

test_that("util_nps_tbbase validates CRS requirements", {
  # Create mock data with wrong CRS
  tblu <- create_mock_sf(crs = 4326)
  tbsoil <- create_mock_sf(crs = 6443)

  expect_error(
    util_nps_tbbase(tblu, tbsoil),
    "All inputs must have CRS of NAD83\\(2011\\) / Florida West \\(ftUS\\), EPSG:6443"
  )
})

test_that("util_nps_tbbase validates sf object inputs", {
  # Create mock data with non-sf object
  tblu <- data.frame(x = 1, y = 2)  # Not an sf object
  tbsoil <- create_mock_sf(crs = 6443)

  expect_error(
    util_nps_tbbase(tblu, tbsoil),
    "All inputs must be sf objects"
  )
})

test_that("util_nps_tbbase processes successfully with valid inputs", {
  # Create mock data with correct CRS
  tblu <- st_sf(
    FLUCCSCODE = 1100,
    geometry = st_sfc(st_polygon(list(matrix(c(0,0, 1,0, 1,1, 0,1, 0,0), ncol=2, byrow=TRUE))), crs = 6443)
  )

  tbsoil <- st_sf(
    hydgrp = "A",
    geometry = st_sfc(st_polygon(list(matrix(c(0,0, 1,0, 1,1, 0,1, 0,0), ncol=2, byrow=TRUE))), crs = 6443)
  )

  # Mock intermediate results
  tbbase1_mock <- st_sf(
    bay_seg = "TS1", basin = "Basin1", drnfeat = "Feature1",
    geometry = st_sfc(st_polygon(list(matrix(c(0,0, 1,0, 1,1, 0,1, 0,0), ncol=2, byrow=TRUE))), crs = 6443)
  )

  tbbase2_mock <- st_sf(
    bay_seg = "TS1", basin = "Basin1", drnfeat = "Feature1", entity = "City1",
    geometry = st_sfc(st_polygon(list(matrix(c(0,0, 1,0, 1,1, 0,1, 0,0), ncol=2, byrow=TRUE))), crs = 6443)
  )

  tbbase3_mock <- st_sf(
    bay_seg = "TS1", basin = "Basin1", drnfeat = "Feature1", entity = "City1", FLUCCSCODE = 1100,
    geometry = st_sfc(st_polygon(list(matrix(c(0,0, 1,0, 1,1, 0,1, 0,0), ncol=2, byrow=TRUE))), crs = 6443)
  )

  tbbase4_mock <- st_sf(
    bay_seg = "TS1", basin = "Basin1", drnfeat = "Feature1", entity = "City1", FLUCCSCODE = 1100, hydgrp = "A",
    geometry = st_sfc(st_polygon(list(matrix(c(0,0, 1,0, 1,1, 0,1, 0,0), ncol=2, byrow=TRUE))), crs = 6443)
  )

  tbbase_mock <- st_sf(
    bay_seg = "TS1", basin = "Basin1", drnfeat = "Feature1", entity = "City1",
    FLUCCSCODE = 1100, CLUCSID = 1, IMPROVED = 0, hydgrp = "A",
    geometry = st_sfc(st_polygon(list(matrix(c(0,0, 1,0, 1,1, 0,1, 0,0), ncol=2, byrow=TRUE))), crs = 6443)
  )

  # Mock the clucsid lookup table
  assign("clucsid", data.frame(FLUCCSCODE = 1100, CLUCSID = 1, IMPROVED = 0), envir = .GlobalEnv)

  # Counter to track util_nps_union calls
  union_call_count <- 0

  # Stub util_nps_union to return appropriate mock results
  stub(util_nps_tbbase, "util_nps_union", function(...) {
    union_call_count <<- union_call_count + 1
    if (union_call_count == 1) return(tbbase1_mock)
    if (union_call_count == 2) return(tbbase2_mock)
    if (union_call_count == 3) return(tbbase3_mock)
    if (union_call_count == 4) return(tbbase4_mock)
  })

  result <- util_nps_tbbase(tblu, tbsoil, verbose = FALSE)

  expect_s3_class(result, "data.frame")
  expect_false("geometry" %in% names(result))  # Should be dropped
  expect_true("area_ha" %in% names(result))
  expect_equal(union_call_count, 4)

  # Clean up
  rm(clucsid, envir = .GlobalEnv)
})

test_that("util_nps_tbbase handles missing drnfeat values", {
  # Create mock data where drnfeat might be NA
  tblu <- create_mock_sf(crs = 6443)
  tbsoil <- create_mock_sf(crs = 6443)

  # Mock result with NA drnfeat
  tbbase4_mock <- st_sf(
    bay_seg = "TS1", basin = "Basin1", drnfeat = NA_character_, entity = "City1",
    FLUCCSCODE = 1100, hydgrp = "A",
    geometry = st_sfc(st_polygon(list(matrix(c(0,0, 1,0, 1,1, 0,1, 0,0), ncol=2, byrow=TRUE))), crs = 6443)
  )

  tbbase_mock <- st_sf(
    bay_seg = "TS1", basin = "Basin1", drnfeat = NA_character_, entity = "City1",
    FLUCCSCODE = 1100, CLUCSID = 1, IMPROVED = 0, hydgrp = "A",
    geometry = st_sfc(st_polygon(list(matrix(c(0,0, 1,0, 1,1, 0,1, 0,0), ncol=2, byrow=TRUE))), crs = 6443)
  )

  # Mock the clucsid lookup table
  assign("clucsid", data.frame(FLUCCSCODE = 1100, CLUCSID = 1, IMPROVED = 0), envir = .GlobalEnv)

  # Stub util_nps_union
  stub(util_nps_tbbase, "util_nps_union", function(...) tbbase4_mock)

  result <- util_nps_tbbase(tblu, tbsoil, verbose = FALSE)

  # Check that NA drnfeat is replaced with "CON"
  expect_equal(result$drnfeat, "CON")

  # Clean up
  rm(clucsid, envir = .GlobalEnv)
})
