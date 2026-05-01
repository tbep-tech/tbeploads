# Minimal synthetic inputs used across unit tests
make_syn <- function(basin = "99999", bay_seg = "1", drnfeat = "CON",
                     entity = "EntityA", clucsid = 1L, hydgrp = "A",
                     area_ha = 10) {
  data.frame(
    bay_seg  = bay_seg,
    basin    = basin,
    drnfeat  = drnfeat,
    entity   = entity,
    CLUCSID  = clucsid,
    hydgrp   = hydgrp,
    area_ha  = area_ha,
    stringsAsFactors = FALSE
  )
}

syn_rc  <- data.frame(clucsid = 1L, hsg = "A", dry_rc = 0.3, wet_rc = 0.5)
syn_emc <- data.frame(clucsid = 1L, mean_tn = 1.5)

# ---- Return structure --------------------------------------------------------

test_that("util_aa_npsfactors returns a named list with rc and tn", {
  result <- util_aa_npsfactors(tbbase, rcclucsid, emc)
  expect_type(result, "list")
  expect_named(result, c("rc", "tn"))
})

test_that("rc element has expected columns", {
  result <- util_aa_npsfactors(tbbase, rcclucsid, emc)
  expect_true(all(c("bay_seg", "basin", "entity", "category", "clucsid", "factor_rc") %in%
                    names(result$rc)))
})

test_that("tn element has expected columns", {
  result <- util_aa_npsfactors(tbbase, rcclucsid, emc)
  expect_true(all(c("bay_seg", "basin", "clucsid", "factor_tn") %in% names(result$tn)))
})

# ---- Factor sums -------------------------------------------------------------

test_that("factor_rc sums to 1 across entities per bay_seg x basin x clucsid", {
  result <- util_aa_npsfactors(tbbase, rcclucsid, emc)
  sums <- result$rc |>
    dplyr::group_by(bay_seg, basin, clucsid) |>
    dplyr::summarise(s = sum(factor_rc), .groups = "drop")
  expect_true(all(abs(sums$s - 1) < 1e-9))
})

test_that("factor_tn sums to 1 across clucsids per bay_seg x basin", {
  result <- util_aa_npsfactors(tbbase, rcclucsid, emc)
  sums <- result$tn |>
    dplyr::group_by(bay_seg, basin) |>
    dplyr::summarise(s = sum(factor_tn), .groups = "drop")
  expect_true(all(abs(sums$s - 1) < 1e-9))
})

test_that("all factors are between 0 and 1", {
  result <- util_aa_npsfactors(tbbase, rcclucsid, emc)
  # 1 + 1e-9 tolerance for floating point where a sole-entity group hits 1.0 + epsilon
  expect_true(all(result$rc$factor_rc >= 0 & result$rc$factor_rc <= 1 + 1e-9))
  expect_true(all(result$tn$factor_tn >= 0 & result$tn$factor_tn <= 1 + 1e-9))
})

# ---- Exclusions --------------------------------------------------------------

test_that("water and tidal CLUCSIDs (17, 21, 22) are excluded from both outputs", {
  result <- util_aa_npsfactors(tbbase, rcclucsid, emc)
  expect_false(any(c(17L, 21L, 22L) %in% result$rc$clucsid))
  expect_false(any(c(17L, 21L, 22L) %in% result$tn$clucsid))
})

test_that("NONCON drainage features are excluded", {
  tb <- make_syn(drnfeat = c("NONCON", "CON"), entity = c("A", "B"),
                 area_ha = c(10, 10))
  result <- util_aa_npsfactors(tb, syn_rc, syn_emc)
  expect_equal(nrow(result$rc), 1L)
  expect_equal(result$rc$entity, "B")
})

test_that("basin 02307359 is excluded entirely", {
  tb <- make_syn(basin = "02307359")
  result <- util_aa_npsfactors(tb, syn_rc, syn_emc)
  expect_equal(nrow(result$rc), 0L)
  expect_equal(nrow(result$tn), 0L)
})

# ---- Basin remapping ---------------------------------------------------------

test_that("basins 02303000 and 02303330 are remapped to 02304500", {
  tb <- make_syn(basin = c("02303000", "02303330", "02304500"),
                 area_ha = c(10, 10, 10))
  result <- util_aa_npsfactors(tb, syn_rc, syn_emc)
  expect_false(any(c("02303000", "02303330") %in% result$rc$basin))
  expect_true("02304500" %in% result$rc$basin)
})

test_that("basins 02301000 and 02301300 are remapped to 02301500", {
  tb <- make_syn(basin = c("02301000", "02301300"),
                 area_ha = c(10, 10))
  result <- util_aa_npsfactors(tb, syn_rc, syn_emc)
  expect_false(any(c("02301000", "02301300") %in% result$rc$basin))
  expect_true("02301500" %in% result$rc$basin)
})

test_that("basin 02299950 is remapped to LMANATEE", {
  tb <- make_syn(basin = "02299950")
  result <- util_aa_npsfactors(tb, syn_rc, syn_emc)
  expect_false("02299950" %in% result$rc$basin)
  expect_true("LMANATEE" %in% result$rc$basin)
})

test_that("basin 206-5 gets bay_seg 55", {
  tb <- make_syn(basin = "206-5", bay_seg = "4")
  result <- util_aa_npsfactors(tb, syn_rc, syn_emc)
  expect_equal(result$rc$bay_seg, 55L)
  expect_equal(result$tn$bay_seg, 55L)
})

# ---- Hydrologic soil group simplification ------------------------------------

test_that("compound hydgrp values are simplified before RC lookup", {
  tb <- data.frame(
    bay_seg = "1", basin = "99999", drnfeat = "CON", entity = "A",
    CLUCSID = 1L,
    hydgrp  = c("A/D", "B/D", "C/D", "D"),
    area_ha = 5,
    stringsAsFactors = FALSE
  )
  rc_multi <- data.frame(
    clucsid = 1L,
    hsg     = c("A", "B", "C", "D"),
    dry_rc  = 0.3,
    wet_rc  = 0.5
  )
  result <- util_aa_npsfactors(tb, rc_multi, syn_emc)
  # All four rows should join successfully and factor_rc should sum to 1
  expect_equal(result$rc$factor_rc, 1)
})

# ---- Category assignment -----------------------------------------------------

test_that("Agriculture, Other, and NA categories are assigned correctly", {
  tb <- data.frame(
    bay_seg = "1", basin = "99999", drnfeat = "CON", entity = "A",
    CLUCSID = c(1L, 8L, 6L),
    hydgrp  = "A",
    area_ha = 10,
    stringsAsFactors = FALSE
  )
  rc3  <- data.frame(clucsid = c(1L, 8L, 6L), hsg = "A", dry_rc = 0.3, wet_rc = 0.5)
  emc3 <- data.frame(clucsid = c(1L, 8L, 6L), mean_tn = 1.5)
  result <- util_aa_npsfactors(tb, rc3, emc3)
  cats <- result$rc$category[order(result$rc$clucsid)]
  expect_equal(cats, c(NA_character_, "Other", "Agriculture"))
})

test_that("all Agriculture clucsids get Agriculture category", {
  ag_ids <- c(8L, 10L, 11L, 12L, 13L, 14L)
  tb <- data.frame(
    bay_seg = "1", basin = "99999", drnfeat = "CON", entity = "A",
    CLUCSID = ag_ids, hydgrp = "A", area_ha = 10,
    stringsAsFactors = FALSE
  )
  rc_ag  <- data.frame(clucsid = ag_ids, hsg = "A", dry_rc = 0.3, wet_rc = 0.5)
  emc_ag <- data.frame(clucsid = ag_ids, mean_tn = 1.5)
  result <- util_aa_npsfactors(tb, rc_ag, emc_ag)
  expect_true(all(result$rc$category == "Agriculture"))
})
