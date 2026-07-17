# Synthetic annavg = TRUE-shaped aa_data (no year column): bay_seg = 2,
# covering MS4 (single-row entity), the real "ips_mosaic_hb" shared IPS group
# (special-cased to show individual effective loads, unlike other shared
# groups), a standalone IPS facility for the same entity as the shared group
# (to trigger a Total row spanning 2 units), an entity with both IPS and ML
# rows (to confirm grouping/Total is entity-wide, not per source type), a
# generically-merged shared IPS group under a different entity (to confirm
# default full-merge behavior still applies to groups other than
# "ips_mosaic_hb"), a DPS entity with 2 non-shared facilities including
# matching facname across end-of-pipe/reuse, and the FDACS/Non-MS4 Nonpoint
# Source aggregate rows (to confirm they're excluded, since neither has a
# real allocation).
make_aa_data <- function() {
  base <- data.frame(
    bay_seg = 2L, segment = "Hillsborough Bay",
    entity_full = NA_character_, facname = NA_character_, permit = NA_character_,
    alloc_pct = NA_real_, alloc_tons = NA_real_, eff_load_tons = NA_real_,
    ishared = FALSE, group_id = NA_character_
  )

  ms4 <- base
  ms4$entity <- "HILLSBOROUGH"
  ms4$entity_full <- "Hillsborough County"
  ms4$source <- "MS4"
  ms4$alloc_pct <- 0.10
  ms4$alloc_tons <- 50
  ms4$eff_load_tons <- 40

  # Test City: an entity combining an MS4 row with a non-MS4 source (IPS) -
  # used only to check that MS4 sorts LAST within an entity's block
  mixed_ms4 <- base
  mixed_ms4$entity <- "Test City"
  mixed_ms4$source <- "MS4"
  mixed_ms4$alloc_tons <- 5
  mixed_ms4$eff_load_tons <- 4

  mixed_ips <- base
  mixed_ips$entity <- "Test City"
  mixed_ips$facname <- "Test Facility"
  mixed_ips$source <- "IPS"
  mixed_ips$alloc_tons <- 1
  mixed_ips$eff_load_tons <- 0.5

  # Mosaic: 3-facility "ips_mosaic_hb" shared IPS group + 1 standalone IPS
  # facility + 1 ML row -> 3 units total (shared group, standalone IPS, ML),
  # Total row expected. group_id is the real one show_aaassess() special-cases
  # to show individual effective loads (RP's real workbook merges only
  # alloc_pct/alloc_tons for this specific group).
  mosaic_shared <- base[rep(1, 3), ]
  mosaic_shared$entity <- "Mosaic"
  mosaic_shared$facname <- c("Riverview", "Big Bend", "Tampa Marine Terminal")
  mosaic_shared$source <- "IPS"
  # alloc_pct/alloc_tons are the group's single collective values,
  # identically repeated on every member row (see ps_allocations)
  mosaic_shared$alloc_pct <- 0.05
  mosaic_shared$alloc_tons <- 20
  mosaic_shared$eff_load_tons <- c(3, 4, 5)
  mosaic_shared$ishared <- TRUE
  mosaic_shared$group_id <- "ips_mosaic_hb"

  mosaic_solo_ips <- base
  mosaic_solo_ips$entity <- "Mosaic"
  mosaic_solo_ips$facname <- "Bartow"
  mosaic_solo_ips$source <- "IPS"
  mosaic_solo_ips$alloc_pct <- 0.02
  mosaic_solo_ips$alloc_tons <- 8
  mosaic_solo_ips$eff_load_tons <- 6

  # ML rows never have an alloc_pct (anlz_aa() always sets it NA_real_ for ML)
  mosaic_ml <- base
  mosaic_ml$entity <- "Mosaic"
  mosaic_ml$facname <- "Riverview"
  mosaic_ml$source <- "ML"
  mosaic_ml$alloc_pct <- NA_real_
  mosaic_ml$alloc_tons <- 2
  mosaic_ml$eff_load_tons <- 1.5

  # Kinder Morgan: a 2-facility shared IPS group under a DIFFERENT group_id -
  # confirms groups other than "ips_mosaic_hb" keep the default fully-merged
  # (summed, repeated) Effective Load display.
  km_shared <- base[rep(1, 2), ]
  km_shared$entity <- "Kinder Morgan"
  km_shared$facname <- c("Tampaplex", "Port Sutton")
  km_shared$source <- "IPS"
  km_shared$alloc_tons <- 25
  km_shared$eff_load_tons <- c(1, 2)
  km_shared$ishared <- TRUE
  km_shared$group_id <- "ips_kinder_morgan"

  # DPS entity with 2 non-shared facilities, one repeating a facname across
  # end-of-pipe/reuse rows
  dps1 <- base
  dps1$entity <- "City of Clearwater"
  dps1$facname <- "East AWWTF"
  dps1$source <- "DPS - end of pipe"
  dps1$alloc_tons <- 12
  dps1$eff_load_tons <- 10

  dps2 <- base
  dps2$entity <- "City of Clearwater"
  dps2$facname <- "East AWWTF"
  dps2$source <- "DPS - reuse"
  dps2$alloc_tons <- 3
  dps2$eff_load_tons <- 2

  fdacs <- base
  fdacs$entity <- "All"
  fdacs$entity_full <- "FDACS (Agriculture)"
  fdacs$source <- NA_character_
  fdacs$eff_load_tons <- 25

  nonms4 <- base
  nonms4$entity <- "Non-MS4/Ag NPS"
  nonms4$source <- NA_character_
  nonms4$eff_load_tons <- 5

  rbind(ms4, mixed_ms4, mixed_ips, mosaic_shared, mosaic_solo_ips, mosaic_ml, km_shared, dps1, dps2, fdacs, nonms4)
}

test_that("show_aaassess errors when aa_data has a year column", {
  aa_data <- make_aa_data()
  aa_data$year <- 2022L
  expect_error(show_aaassess(aa_data, bay_seg = 2L), "annavg = TRUE")
})

test_that("show_aaassess errors on an invalid bay_seg", {
  expect_error(show_aaassess(make_aa_data(), bay_seg = 99L), "bay_seg")
})

test_that("show_aaassess returns a flextable", {
  ft <- show_aaassess(make_aa_data(), bay_seg = 2L)
  expect_s3_class(ft, "flextable")
})

test_that("MS4 single-row entity gets no Total row", {
  ft <- show_aaassess(make_aa_data(), bay_seg = 2L)
  d <- ft$body$dataset
  ms4_block <- d[d$Entity == "Hillsborough County", ]
  expect_equal(nrow(ms4_block), 1L)
  expect_false("Total" %in% ms4_block$Facility)
})

test_that("an entity combining MS4 with another source sorts MS4 last within its block", {
  ft <- show_aaassess(make_aa_data(), bay_seg = 2L)
  d <- ft$body$dataset
  test_city <- d[d$Entity == "Test City", ]
  expect_equal(test_city$Facility, c("Test Facility", "MS4", "Total"))
})

test_that("the ips_mosaic_hb group shows each facility's own Effective Load, but a shared Allocation %/Allocated Tons", {
  ft <- show_aaassess(make_aa_data(), bay_seg = 2L)
  d <- ft$body$dataset
  shared_rows <- d[d$Entity == "Mosaic" & d$Facility %in% c("Riverview", "Big Bend", "Tampa Marine Terminal"), ]
  expect_equal(nrow(shared_rows), 3L)
  expect_equal(
    shared_rows$eff_load_tons[match(c("Riverview", "Big Bend", "Tampa Marine Terminal"), shared_rows$Facility)],
    c(3, 4, 5)
  )
  # displayed on the 0-100 scale (multiplied by 100 for the % column)
  expect_equal(unique(shared_rows$alloc_tons), 20)
  expect_equal(unique(shared_rows$alloc_pct), 0.05 * 100, tolerance = 1e-9)
})

test_that("a shared IPS group other than ips_mosaic_hb still gets a fully-merged (summed) Effective Load", {
  ft <- show_aaassess(make_aa_data(), bay_seg = 2L)
  d <- ft$body$dataset
  km_rows <- d[d$Entity == "Kinder Morgan" & d$Facility %in% c("Tampaplex", "Port Sutton"), ]
  expect_equal(nrow(km_rows), 2L)
  expect_equal(unique(km_rows$eff_load_tons), 1 + 2)
  expect_equal(unique(km_rows$alloc_tons), 25)
})

test_that("an all-NA alloc_pct unit (e.g. ML) stays blank rather than collapsing to 0", {
  ft <- show_aaassess(make_aa_data(), bay_seg = 2L)
  d <- ft$body$dataset
  ml_row <- d[d$Entity == "Mosaic" & d$Facility == "Riverview (Material Losses)", ]
  expect_equal(nrow(ml_row), 1L)
  expect_true(is.na(ml_row$alloc_pct))
})

test_that("Mosaic gets one Total row summing 3 units (shared group + solo IPS + ML), not 5 rows", {
  ft <- show_aaassess(make_aa_data(), bay_seg = 2L)
  d <- ft$body$dataset
  mosaic <- d[d$Entity == "Mosaic", ]
  expect_equal(sum(mosaic$Facility == "Total"), 1L)

  tot <- mosaic[mosaic$Facility == "Total", ]
  expect_equal(tot$alloc_tons, 20 + 8 + 2)
  expect_equal(tot$eff_load_tons, (3 + 4 + 5) + 6 + 1.5)
  expect_true(is.na(tot$alloc_pct))
})

test_that("DPS entity with 2 non-shared facilities gets a Total row via plain sum", {
  ft <- show_aaassess(make_aa_data(), bay_seg = 2L)
  d <- ft$body$dataset
  clw <- d[d$Entity == "City of Clearwater", ]
  expect_equal(nrow(clw), 3L)
  expect_true(all(c("East AWWTF (end of pipe)", "East AWWTF (reuse)") %in% clw$Facility))

  tot <- clw[clw$Facility == "Total", ]
  expect_equal(tot$alloc_tons, 12 + 3)
  expect_equal(tot$eff_load_tons, 10 + 2)
})

test_that("FDACS and Non-MS4/Ag NPS aggregate rows are excluded entirely (no real allocation)", {
  ft <- show_aaassess(make_aa_data(), bay_seg = 2L)
  d <- ft$body$dataset

  expect_equal(nrow(d[d$Entity == "FDACS (Agriculture)", ]), 0L)
  expect_equal(nrow(d[d$Entity == "Non-MS4/Ag NPS", ]), 0L)
  expect_false("Nonpoint Source" %in% d$Facility)
})
