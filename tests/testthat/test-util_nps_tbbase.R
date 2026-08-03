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
      "Filling land use gaps...",
      "Combining results with soils...",
      "Flagging NPDES-permitted \\(mine\\) land...",
      "Summarizing...",
      sep = "\\n"
    )
  )

  rm(clucsid, envir = .GlobalEnv)
})

test_that("util_nps_tbbase reclassifies NPDES-permitted (mine) land to CLUCSID 22", {
  tblu   <- poly6443(FLUCCSCODE = 1100)
  tbsoil <- poly6443(hydgrp = "A")

  tbbase1_mock <- poly6443(bay_seg = "TS1", basin = "Basin1", drnfeat = "Feature1")

  tbbase2_mock <- poly6443(bay_seg = "TS1", basin = "Basin1", drnfeat = "Feature1",
                           entity = "City1")

  tbbase3_mock <- poly6443(bay_seg = "TS1", basin = "Basin1", drnfeat = "Feature1",
                           entity = "City1", FLUCCSCODE = 1100)

  # covers (0,0)-(1,1); a mine polygon covering the lower-left quarter,
  # (0,0)-(0.5,0.5), overlaps a quarter of this parcel
  tbbase4_mock <- poly6443(bay_seg = "TS1", basin = "Basin1", drnfeat = "Feature1",
                           entity = "City1", FLUCCSCODE = 1100,
                           hydgrp = "A")

  mine_mock <- st_sf(
    Location = "Test Mine", Owner = "Test Co",
    geometry = st_sfc(
      st_polygon(list(matrix(c(0,0, 0.5,0, 0.5,0.5, 0,0.5, 0,0), ncol = 2, byrow = TRUE))),
      crs = 6443
    )
  )

  assign("clucsid",
         data.frame(FLUCCSCODE = 1100, CLUCSID = 1, IMPROVED = 0,
                    DESCRIPTION = "Low Density Residential"),
         envir = .GlobalEnv)
  assign("tbmines", mine_mock, envir = .GlobalEnv)

  union_call_count <- 0
  stub(util_nps_tbbase, "util_nps_union", function(...) {
    union_call_count <<- union_call_count + 1
    if (union_call_count == 1) return(tbbase1_mock)
    if (union_call_count == 2) return(tbbase2_mock)
    if (union_call_count == 3) return(tbbase3_mock)
    if (union_call_count == 4) return(tbbase4_mock)
  })

  result <- util_nps_tbbase(tblu, tbsoil, verbose = FALSE)

  # one row for the mine-overlapping quarter (CLUCSID 22), one for the rest
  # (CLUCSID 1, unaffected FLUCCS-based category)
  expect_setequal(result$CLUCSID, c(22, 1))
  expect_equal(sum(result$area_ha), as.numeric(st_area(tbbase4_mock)) * 0.000009290304,
               tolerance = 1e-6)

  rm(clucsid, tbmines, envir = .GlobalEnv)
})

test_that("util_nps_tbbase fills land use gaps with FLUCCSCODE 5400 instead of dropping them", {
  # tbbase2 (basin/jurisdiction) covers the full (0,0)-(1,1) unit square, but
  # tblu only covers the left half, (0,0)-(0.5,1) - the uncovered right half
  # should be recovered and assigned FLUCCSCODE 5400 (Saltwater) rather than
  # silently dropped by util_nps_union()'s inner intersection
  left_half <- st_polygon(list(matrix(c(0,0, 0.5,0, 0.5,1, 0,1, 0,0), ncol = 2, byrow = TRUE)))

  tblu <- st_sf(FLUCCSCODE = 1100, geometry = st_sfc(left_half, crs = 6443))
  tbsoil <- poly6443(hydgrp = "A")

  tbbase1_mock <- poly6443(bay_seg = "TS1", basin = "Basin1", drnfeat = "Feature1")
  tbbase2_mock <- poly6443(bay_seg = "TS1", basin = "Basin1", drnfeat = "Feature1",
                           entity = "City1")

  # what a real inner-join union of tbbase2 (full square) x tblu (left half)
  # would produce: just the overlapping left half, classified FLUCCSCODE 1100
  tbbase3_mock <- st_sf(
    bay_seg = "TS1", basin = "Basin1", drnfeat = "Feature1", entity = "City1",
    FLUCCSCODE = 1100,
    geometry = st_sfc(left_half, crs = 6443)
  )

  assign("clucsid",
         data.frame(FLUCCSCODE = c(1100, 5400), CLUCSID = c(1, 17), IMPROVED = c(0, 0),
                    DESCRIPTION = c("Low Density Residential", "Saltwater")),
         envir = .GlobalEnv)

  union_call_count <- 0
  stub(util_nps_tbbase, "util_nps_union", function(sf1, ...) {
    union_call_count <<- union_call_count + 1
    if (union_call_count == 1) return(tbbase1_mock)
    if (union_call_count == 2) return(tbbase2_mock)
    if (union_call_count == 3) return(tbbase3_mock)
    # soil step: echo whatever land use produced (by now includes the
    # gap-filled right half) with a constant hydgrp, simulating a single
    # uniform soil type across the whole parcel
    if (union_call_count == 4) return(dplyr::mutate(sf1, hydgrp = "A"))
  })

  result <- util_nps_tbbase(tblu, tbsoil, verbose = FALSE)

  # left half (FLUCCSCODE 1100 -> CLUCSID 1) and gap-filled right half
  # (FLUCCSCODE 5400 -> CLUCSID 17) should both be present
  expect_setequal(result$CLUCSID, c(1, 17))
  expect_equal(sum(result$area_ha), as.numeric(st_area(tbbase2_mock)) * 0.000009290304,
               tolerance = 1e-6)

  rm(clucsid, envir = .GlobalEnv)
})

test_that("util_nps_tbbase handles missing drnfeat values", {
  tblu   <- create_mock_sf(crs = 6443)
  tbsoil <- create_mock_sf(crs = 6443)
  tbsoil$hydgrp <- "A"

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
