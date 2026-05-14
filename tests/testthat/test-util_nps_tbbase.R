# Mock sf object creation function
create_mock_sf <- function(coords = NULL, crs = 4326, id = 1) {
  if (length(id) > 1) {
    polygons <- list()
    for (i in seq_along(id)) {
      if (is.null(coords)) {
        shift_coords <- list(matrix(c(i-1, i-1, i, i-1, i, i, i-1, i, i-1, i-1),
                                    ncol = 2, byrow = TRUE))
      } else {
        shift_coords <- lapply(coords, function(coord_matrix) coord_matrix + (i-1))
      }
      polygon_geom <- st_polygon(shift_coords)
      polygons[[i]] <- st_sf(
        id = id[i], name = paste0("polygon_", id[i]),
        area = st_area(polygon_geom),
        geometry = st_sfc(polygon_geom, crs = crs)
      )
    }
    return(do.call(rbind, polygons))
  }
  if (is.null(coords))
    coords <- list(matrix(c(0,0, 1,0, 1,1, 0,1, 0,0), ncol = 2, byrow = TRUE))
  polygon_geom <- st_polygon(coords)
  st_sf(id = id, name = paste0("polygon_", id), area = st_area(polygon_geom),
        geometry = st_sfc(polygon_geom, crs = crs))
}

poly6443 <- function(...) {
  st_sf(..., geometry = st_sfc(
    st_polygon(list(matrix(c(0,0, 1,0, 1,1, 0,1, 0,0), ncol=2, byrow=TRUE))),
    crs = 6443
  ))
}

test_that("util_nps_tbbase validates sf object inputs", {
  tblu      <- data.frame(x = 1, y = 2)  # Not an sf object
  tbsoil    <- create_mock_sf(crs = 6443)

  expect_error(
    util_nps_tbbase(tblu, tbsoil),
    "All inputs must be sf objects"
  )
})

test_that("util_nps_tbbase validates CRS requirements", {
  tblu      <- create_mock_sf(crs = 4326)   # wrong CRS
  tbsoil    <- create_mock_sf(crs = 6443)

  expect_error(
    util_nps_tbbase(tblu, tbsoil),
    "All inputs must have CRS of NAD83\\(2011\\) / Florida West \\(ftUS\\), EPSG:6443"
  )
})

test_that("util_nps_tbbase processes successfully with valid inputs", {
  tblu   <- poly6443(FLUCCSCODE = 1100)
  tbsoil <- poly6443(hydgrp = "A")

  tbbase1_mock <- poly6443(bay_seg = "TS1", basin = "Basin1", drnfeat = "Feature1")

  tbbase2_mock <- poly6443(bay_seg = "TS1", basin = "Basin1", drnfeat = "Feature1",
                           entity = "City1")

  tbbase3_mock <- poly6443(bay_seg = "TS1", basin = "Basin1", drnfeat = "Feature1",
                           entity = "City1", FLUCCSCODE = 1100)

  tbbase4_mock <- poly6443(bay_seg = "TS1", basin = "Basin1", drnfeat = "Feature1",
                           entity = "City1", FLUCCSCODE = 1100,
                           hydgrp = "A")

  assign("clucsid",
         data.frame(FLUCCSCODE = 1100, CLUCSID = 1, IMPROVED = 0,
                    DESCRIPTION = "Low Density Residential"),
         envir = .GlobalEnv)

  union_call_count <- 0
  stub(util_nps_tbbase, "util_nps_union", function(...) {
    union_call_count <<- union_call_count + 1
    if (union_call_count == 1) return(tbbase1_mock)
    if (union_call_count == 2) return(tbbase2_mock)
    if (union_call_count == 3) return(tbbase3_mock)
    if (union_call_count == 4) return(tbbase4_mock)
  })

  result <- util_nps_tbbase(tblu, tbsoil, verbose = FALSE)

  expect_s3_class(result, "data.frame")
  expect_false("geometry" %in% names(result))
  expect_true("area_ha" %in% names(result))
  expect_equal(union_call_count, 4)

  union_call_count <- 0
  expect_output(
    util_nps_tbbase(tblu, tbsoil, verbose = TRUE),
    paste(
      "Combining drainage basins with sub-watersheds...",
      "Combining results with TBNMC jurisdictions...",
      "Combining results with land use...",
      "Combining results with soils...",
      "Summarizing...",
      sep = "\\n"
    )
  )

  rm(clucsid, envir = .GlobalEnv)
})

test_that("util_nps_tbbase handles missing drnfeat values", {
  tblu   <- create_mock_sf(crs = 6443)
  tbsoil <- create_mock_sf(crs = 6443)

  tbbase4_mock <- poly6443(bay_seg = "TS1", basin = "Basin1", drnfeat = NA_character_,
                           entity = "City1",
                           FLUCCSCODE = 1100, hydgrp = "A")

  assign("clucsid",
         data.frame(FLUCCSCODE = 1100, CLUCSID = 1, IMPROVED = 0,
                    DESCRIPTION = "Low Density Residential"),
         envir = .GlobalEnv)

  stub(util_nps_tbbase, "util_nps_union", function(...) tbbase4_mock)

  result <- util_nps_tbbase(tblu, tbsoil, verbose = FALSE)

  expect_equal(result$drnfeat, "CON")

  rm(clucsid, envir = .GlobalEnv)
})
