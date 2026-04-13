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

# Mosaic Bonnie: per-outfall fills; I-003 uses check_flow = FALSE
bonnie <- data.frame(
  Facility.Name                  = rep('Mosaic Bonnie', 4),
  Outfall.ID                     = c('D-005', 'D-006', 'I-003', 'I-003'),
  Year                           = rep(2022L, 4),
  Month                          = 1:4,
  Average.Daily.Flow..ADF...mgd. = c(0.19, 0.45, 0.81, 0),
  Total.N                        = c(0.95, 1.20, 0.58, NA)
)
res_bonnie <- util_ps_mosaic(bonnie)

# Mosaic Black Point: per-outfall fill for I-002 (check_flow = TRUE)
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

test_that("Bonnie I-003: TP/TSS/BOD filled even when flow = 0", {
  i003_zero <- res_bonnie[res_bonnie$Outfall.ID == "I-003" & res_bonnie$Month == 4, ]
  expect_equal(i003_zero$Total.P, 2.30)
  expect_equal(i003_zero$TSS,     6.58)
  expect_equal(i003_zero$BOD,     9.6)
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

# --- Per-outfall fill: Black Point -------------------------------------------

test_that("Black Point I-002: TP/TSS/BOD filled with correct values when flow > 0", {
  expect_true(all(res_blackpt$Total.P == 0.56))
  expect_true(all(res_blackpt$TSS     == 8.2))
  expect_true(all(res_blackpt$BOD     == 2.45))
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

# --- Unknown outfall validation -----------------------------------------------

test_that("Error when named-outfall facility has an unrecognised outfall", {
  # Bonnie has named outfall rules; D-999 is not listed
  bonnie_bad <- data.frame(
    Facility.Name                  = rep('Mosaic Bonnie', 2),
    Outfall.ID                     = c('D-005', 'D-999'),
    Year                           = rep(2022L, 2),
    Month                          = 1:2,
    Average.Daily.Flow..ADF...mgd. = c(0.19, 0.30),
    Total.N                        = c(0.95, 1.10)
  )
  expect_error(
    util_ps_mosaic(bonnie_bad),
    "has outfall\\(s\\) with no named fill rule"
  )
  expect_error(
    util_ps_mosaic(bonnie_bad),
    "D-999"
  )
})

test_that("Error message names the unrecognised outfall(s) and the known ones", {
  riverview_bad <- data.frame(
    Facility.Name                  = rep('Mosaic Riverview', 2),
    Outfall.ID                     = c('D-005B', 'D-099'),
    Year                           = rep(2022L, 2),
    Month                          = 1:2,
    Average.Daily.Flow..ADF...mgd. = c(1.0, 0.5),
    Total.N                        = c(5.0, 4.0)
  )
  expect_error(
    util_ps_mosaic(riverview_bad),
    "D-099"
  )
  expect_error(
    util_ps_mosaic(riverview_bad),
    "Known outfalls"
  )
})

test_that("Facility-wide facilities do not error on arbitrary outfall IDs", {
  # Bartow uses a facility-wide rule; any outfall ID should be accepted
  bartow_new_outfall <- data.frame(
    Facility.Name                  = rep('Mosaic Bartow', 2),
    Outfall.ID                     = c('D-001', 'D-NEW'),
    Year                           = rep(2022L, 2),
    Month                          = 1:2,
    Average.Daily.Flow..ADF...mgd. = c(0.5, 0.3),
    Total.N                        = c(2.0, 1.5)
  )
  expect_no_error(util_ps_mosaic(bartow_new_outfall))
})

test_that("No-fill facilities do not error on arbitrary outfall IDs", {
  # Hookers Prairie has no fill rules at all; any outfall ID should be accepted
  hookers_prairie <- data.frame(
    Facility.Name                  = rep('Mosaic Hookers Prairie', 2),
    Outfall.ID                     = c('EFF-001', 'EFF-002'),
    Year                           = rep(2022L, 2),
    Month                          = 1:2,
    Average.Daily.Flow..ADF...mgd. = c(0.001, 0.002),
    Total.N                        = c(7.7, 7.4)
  )
  expect_no_error(util_ps_mosaic(hookers_prairie))
})
