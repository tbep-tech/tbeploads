# --- Fixtures ----------------------------------------------------------------

# Mosaic Bartow: facility-wide fill, applied regardless of flow (check_flow = FALSE)
bartow <- data.frame(
  Facility.Name                  = rep('Mosaic Bartow', 3),
  Outfall.ID                     = rep('D-001', 3),
  Year                           = rep(2022L, 3),
  Month                          = 1:3,
  Average.Daily.Flow..ADF...mgd. = c(0.57, 0, 0.43),
  Total.N                        = c(3.94, NA, 2.11)
)
res_bartow <- util_ps_mosaic(bartow)

# Mosaic Nichols: facility-wide fill, applied only when flow > 0 (check_flow = TRUE)
nichols <- data.frame(
  Facility.Name                  = rep('Mosaic Nichols', 3),
  Outfall.ID                     = rep('D-001', 3),
  Year                           = rep(2022L, 3),
  Month                          = 1:3,
  Average.Daily.Flow..ADF...mgd. = c(0.12, 0, NA),
  Total.N                        = c(1.5, NA, NA)
)
res_nichols <- util_ps_mosaic(nichols)

# Mosaic Bonnie: per-outfall fills; D-003 uses check_flow = FALSE
bonnie <- data.frame(
  Facility.Name                  = rep('Mosaic Bonnie', 4),
  Outfall.ID                     = c('D-005', 'D-006', 'D-003', 'D-003'),
  Year                           = rep(2022L, 4),
  Month                          = 1:4,
  Average.Daily.Flow..ADF...mgd. = c(0.19, 0.45, 0.81, 0),
  Total.N                        = c(0.95, 1.20, 0.58, NA)
)
res_bonnie <- util_ps_mosaic(bonnie)

# Mosaic Black Point: no established fill values
blackpt <- data.frame(
  Facility.Name                  = rep('Mosaic Black Point (fka Yara)', 2),
  Outfall.ID                     = rep('I-002', 2),
  Year                           = rep(2022L, 2),
  Month                          = 1:2,
  Average.Daily.Flow..ADF...mgd. = c(0.001, 0.002),
  Total.N                        = c(7.7, 7.4)
)
res_blackpt <- util_ps_mosaic(blackpt)

# --- Output structure --------------------------------------------------------

test_that("Returns correct column names", {
  expected_cols <- c(
    "Permit.Number", "Facility.Name", "Outfall.ID", "Year", "Month",
    "Average.Daily.Flow..ADF...mgd.", "Total.N", "Total.N.Unit",
    "Total.P", "Total.P.Unit", "TSS", "TSS.Unit", "BOD", "BOD.Unit"
  )
  expect_equal(names(res_bartow), expected_cols)
})

test_that("Returns same number of rows as input", {
  expect_equal(nrow(res_bartow), nrow(bartow))
  expect_equal(nrow(res_nichols), nrow(nichols))
  expect_equal(nrow(res_bonnie), nrow(bonnie))
})

# --- Permit numbers ----------------------------------------------------------

test_that("Permit number is looked up from facilities dataset", {
  expect_true(all(res_bartow$Permit.Number == "FL0001589"))
  expect_true(all(res_nichols$Permit.Number == "FL0030139"))
  expect_true(all(res_bonnie$Permit.Number == "FL0000523"))
  expect_true(all(res_blackpt$Permit.Number == "FL0038652"))
})

# --- Fill logic: always-fill (check_flow = FALSE) ----------------------------

test_that("Bartow: TP/TSS/BOD filled regardless of flow", {
  # flow > 0 row
  expect_equal(res_bartow$Total.P[1], 1.61)
  expect_equal(res_bartow$TSS[1],     8.38)
  expect_equal(res_bartow$BOD[1],     9.6)
  # flow = 0 row — still filled
  expect_equal(res_bartow$Total.P[2], 1.61)
  expect_equal(res_bartow$TSS[2],     8.38)
  expect_equal(res_bartow$BOD[2],     9.6)
})

test_that("Bonnie D-003: TP/TSS/BOD filled even when flow = 0", {
  d003_zero <- res_bonnie[res_bonnie$Outfall.ID == "D-003" & res_bonnie$Month == 4, ]
  expect_equal(d003_zero$Total.P, 2.30)
  expect_equal(d003_zero$TSS,     6.58)
  expect_equal(d003_zero$BOD,     9.6)
})

# --- Fill logic: flow-dependent (check_flow = TRUE) --------------------------

test_that("Nichols: correct fill values when flow > 0", {
  expect_equal(res_nichols$Total.P[1], 0.21)
  expect_equal(res_nichols$TSS[1],     1.95)
  expect_equal(res_nichols$BOD[1],     1.85)
})

test_that("Nichols: TP/TSS/BOD are NA when flow = 0 or missing", {
  # flow = 0
  expect_true(is.na(res_nichols$Total.P[2]))
  expect_true(is.na(res_nichols$TSS[2]))
  expect_true(is.na(res_nichols$BOD[2]))
  # flow = NA (treated as zero discharge)
  expect_true(is.na(res_nichols$Total.P[3]))
  expect_true(is.na(res_nichols$TSS[3]))
  expect_true(is.na(res_nichols$BOD[3]))
})

# --- Per-outfall fills -------------------------------------------------------

test_that("Bonnie D-005 and D-006 receive correct outfall-specific fills", {
  d005 <- res_bonnie[res_bonnie$Outfall.ID == "D-005", ]
  expect_equal(d005$Total.P, 0.18)
  expect_equal(d005$TSS,     3.40)
  expect_equal(d005$BOD,     9.6)

  d006 <- res_bonnie[res_bonnie$Outfall.ID == "D-006", ]
  expect_equal(d006$Total.P, 0.85)
  expect_equal(d006$TSS,     1.63)
  expect_equal(d006$BOD,     9.6)
})

# --- No fill values ----------------------------------------------------------

test_that("Black Point: TP/TSS/BOD are NA (no established fill values)", {
  expect_true(all(is.na(res_blackpt$Total.P)))
  expect_true(all(is.na(res_blackpt$TSS)))
  expect_true(all(is.na(res_blackpt$BOD)))
})

# --- Missing flow replaced with zero -----------------------------------------

test_that("Missing flow is replaced with 0 in output", {
  expect_equal(res_nichols$Average.Daily.Flow..ADF...mgd.[3], 0)
})

# --- Units -------------------------------------------------------------------

test_that("Units are 'mg/L' when value is present and '' when NA", {
  # Nichols row 1: flow > 0, all values present
  expect_equal(res_nichols$Total.N.Unit[1], "mg/L")
  expect_equal(res_nichols$Total.P.Unit[1], "mg/L")
  expect_equal(res_nichols$TSS.Unit[1],     "mg/L")
  expect_equal(res_nichols$BOD.Unit[1],     "mg/L")
  # Nichols row 2: flow = 0, TP/TSS/BOD are NA
  expect_equal(res_nichols$Total.N.Unit[2], "")
  expect_equal(res_nichols$Total.P.Unit[2], "")
  expect_equal(res_nichols$TSS.Unit[2],     "")
  expect_equal(res_nichols$BOD.Unit[2],     "")
})

test_that("Bartow: TP/TSS/BOD units are 'mg/L' even when flow = 0", {
  expect_equal(res_bartow$Total.P.Unit[2], "mg/L")
  expect_equal(res_bartow$TSS.Unit[2],     "mg/L")
  expect_equal(res_bartow$BOD.Unit[2],     "mg/L")
})

# --- Input validation --------------------------------------------------------

test_that("Error when input contains more than one facility", {
  mixed <- rbind(bartow, nichols)
  expect_error(
    util_ps_mosaic(mixed),
    "dat must contain data from exactly one facility"
  )
})
