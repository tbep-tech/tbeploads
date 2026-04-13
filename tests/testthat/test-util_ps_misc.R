# Helper to build a minimal clean-format data frame for one facility
make_misc_dat <- function(facility, permit, outfall, flow, tn, tp = NA_real_, tss = NA_real_, bod = NA_real_, year = 2022L, month = NULL) {
  n <- length(flow)
  if (is.null(month)) month <- seq_len(n)
  data.frame(
    Permit.Number                  = rep(permit,   n),
    Facility.Name                  = rep(facility, n),
    Outfall.ID                     = rep(outfall,  n),
    Year                           = year,
    Month                          = month,
    `Average.Daily.Flow..ADF...mgd.` = flow,
    Total.N                        = tn,
    Total.N.Unit                   = ifelse(!is.na(tn),  'mg/L', ''),
    Total.P                        = tp,
    Total.P.Unit                   = ifelse(!is.na(tp),  'mg/L', ''),
    TSS                            = tss,
    TSS.Unit                       = ifelse(!is.na(tss), 'mg/L', ''),
    BOD                            = bod,
    BOD.Unit                       = ifelse(!is.na(bod), 'mg/L', ''),
    check.names                    = FALSE
  )
}

# --- Fixtures ----------------------------------------------------------------

# Alpha/Owens Corning: all three params filled from historical values (no DMR data)
aoc <- make_misc_dat('Alpha/ Owens Corning', 'FL0029653', 'D-001',
  flow = c(0.034, 0, NA),
  tn   = c(0.237, NA, NA)
)
res_aoc <- util_ps_misc(aoc)

# Busch Gardens: TP from actual DMR data; TSS and BOD filled
busch <- make_misc_dat('Busch Gardens', 'FL0185833', 'D-002',
  flow = c(0.78, 0.50, 0),
  tn   = c(0.45, 0.06, NA),
  tp   = c(0.08, 0.08, NA)
)
res_busch <- util_ps_misc(busch)

# Duke Energy-Bartow Plant: TP = 0 fill; TSS from actual DMR; BOD filled
duke <- make_misc_dat('Duke Energy-Bartow Plant', 'FL0000132', 'I-002',
  flow = c(0.14, 0.05, 0),
  tn   = c(8.75, 6.30, NA),
  tss  = c(1.00, 1.00, NA)
)
res_duke <- util_ps_misc(duke)

# Trademark Nitrogen: TP and BOD always overwrite actual data; TSS preserved
trademark <- make_misc_dat('Trademark Nitrogen Corporation', 'FL0000647', 'D-001',
  flow = c(0.105, 0.118, 0),
  tn   = c(0.385, 0.528, NA),
  tp   = c(0.175, 0.105, NA),   # actual values — should be overwritten
  tss  = c(1.48,  2.40,  NA)
)
res_trademark <- util_ps_misc(trademark)

# Lowry Park Zoo: TSS and BOD filled; TP actual; special 2023-09 TN/TP
lowry <- make_misc_dat('Lowry Park Zoo', 'FL0188651', 'D-001',
  flow  = c(0.048, 0.070, 0.060, 0),
  tn    = c(2.000, NA,    1.500, NA),   # row 2 (Sep 2023) TN is missing
  tp    = c(0.299, NA,    0.250, NA),   # row 2 (Sep 2023) TP is missing
  year  = c(2022L, 2023L, 2022L, 2022L),
  month = c(1L,    9L,    9L,    6L)
)
res_lowry <- util_ps_misc(lowry)

# --- Output structure --------------------------------------------------------

test_that("Returns the same column names as the input", {
  expect_equal(names(res_aoc), names(aoc))
})

test_that("Returns the same number of rows as the input", {
  expect_equal(nrow(res_aoc),      nrow(aoc))
  expect_equal(nrow(res_busch),    nrow(busch))
  expect_equal(nrow(res_duke),     nrow(duke))
  expect_equal(nrow(res_trademark),nrow(trademark))
  expect_equal(nrow(res_lowry),    nrow(lowry))
})

# --- All-fill facility -------------------------------------------------------

test_that("Alpha/Owens: TP, TSS, BOD filled with correct values when flow > 0", {
  expect_equal(res_aoc$Total.P[1], 1)
  expect_equal(res_aoc$TSS[1],     2)
  expect_equal(res_aoc$BOD[1],     6)
})

# --- Zero / missing flow -----------------------------------------------------

test_that("Zero flow sets all concentrations to NA", {
  # flow = 0 (row 2)
  expect_true(is.na(res_aoc$Total.N[2]))
  expect_true(is.na(res_aoc$Total.P[2]))
  expect_true(is.na(res_aoc$TSS[2]))
  expect_true(is.na(res_aoc$BOD[2]))
})

test_that("Missing flow is treated as zero (all concentrations NA)", {
  # flow = NA (row 3 of aoc)
  expect_true(is.na(res_aoc$Total.N[3]))
  expect_true(is.na(res_aoc$Total.P[3]))
  expect_true(is.na(res_aoc$TSS[3]))
  expect_true(is.na(res_aoc$BOD[3]))
})

# --- Actual data preserved when fill is NA_real_ ----------------------------

test_that("Busch Gardens: measured TP is preserved; TSS and BOD are filled", {
  # TP comes from actual data — must not be overwritten by a fill
  expect_equal(res_busch$Total.P[1], 0.08)
  expect_equal(res_busch$Total.P[2], 0.08)
  # TSS and BOD receive fill values
  expect_equal(res_busch$TSS[1], 5)
  expect_equal(res_busch$BOD[1], 9.6)
})

test_that("Duke: actual TSS is preserved; TP = 0 fill and BOD filled", {
  expect_equal(res_duke$TSS[1],     1.00)
  expect_equal(res_duke$TSS[2],     1.00)
  expect_equal(res_duke$Total.P[1], 0)
  expect_equal(res_duke$BOD[1],     9.6)
})

# --- Fill overrides actual data when fill value is defined ------------------

test_that("Trademark: TP and BOD fill values overwrite any measured data", {
  # Input had TP = 0.175, 0.105 — these should be replaced by 0.13333
  expect_equal(res_trademark$Total.P[1], 0.13333)
  expect_equal(res_trademark$Total.P[2], 0.13333)
  expect_equal(res_trademark$BOD[1],     1.09833)
  expect_equal(res_trademark$BOD[2],     1.09833)
})

test_that("Trademark: actual TSS is preserved", {
  expect_equal(res_trademark$TSS[1], 1.48)
  expect_equal(res_trademark$TSS[2], 2.40)
})

# --- Zero fill value is valid (not treated as NA) ---------------------------

test_that("Duke TP = 0 is a valid fill value, not treated as zero-flow NA", {
  expect_false(is.na(res_duke$Total.P[1]))
  expect_equal(res_duke$Total.P[1], 0)
})

# --- Lowry Park Zoo special case --------------------------------------------

test_that("Lowry Park Zoo 2023-09 TN and TP are filled from adjacent-month means", {
  sep23 <- res_lowry[res_lowry$Year == 2023L & res_lowry$Month == 9L, ]
  expect_equal(sep23$Total.N, 0.967)
  expect_equal(sep23$Total.P, 0.17)
})

test_that("Lowry Park Zoo 2023-09 special fill does not affect other months", {
  sep22 <- res_lowry[res_lowry$Year == 2022L & res_lowry$Month == 9L, ]
  expect_equal(sep22$Total.N, 1.500)
  expect_equal(sep22$Total.P, 0.250)
})

test_that("Lowry Park Zoo: TSS and BOD filled for all non-zero-flow rows", {
  nonzero <- res_lowry[!is.na(res_lowry$BOD), ]
  expect_true(all(nonzero$TSS == 5))
  expect_true(all(nonzero$BOD == 9.6))
})

# --- Unit standardisation ----------------------------------------------------

test_that("Units are 'mg/L' when value is present and '' when NA", {
  # Alpha/Owens row 1: flow > 0, all filled
  expect_equal(res_aoc$Total.N.Unit[1], 'mg/L')
  expect_equal(res_aoc$Total.P.Unit[1], 'mg/L')
  expect_equal(res_aoc$TSS.Unit[1],     'mg/L')
  expect_equal(res_aoc$BOD.Unit[1],     'mg/L')
  # Alpha/Owens row 2: flow = 0, all NA
  expect_equal(res_aoc$Total.N.Unit[2], '')
  expect_equal(res_aoc$Total.P.Unit[2], '')
  expect_equal(res_aoc$TSS.Unit[2],     '')
  expect_equal(res_aoc$BOD.Unit[2],     '')
})

test_that("Unit strings are standardised regardless of input case", {
  # Build input with mixed-case unit strings
  messy <- make_misc_dat('Coronet Industries', 'FL0034657', 'D-002',
    flow = c(0.49),
    tn   = c(1.00),
    tp   = c(1.40),
    tss  = c(6.30)
  )
  messy$Total.N.Unit <- 'mg/l'
  messy$Total.P.Unit <- 'mg/l'
  messy$TSS.Unit     <- 'MG/L'
  res_messy <- util_ps_misc(messy)
  expect_equal(res_messy$Total.N.Unit, 'mg/L')
  expect_equal(res_messy$Total.P.Unit, 'mg/L')
  expect_equal(res_messy$TSS.Unit,     'mg/L')
  expect_equal(res_messy$BOD.Unit,     'mg/L')   # BOD filled by function
})

# --- Input validation --------------------------------------------------------

test_that("Error when input contains data from more than one facility", {
  mixed <- rbind(aoc, busch)
  expect_error(util_ps_misc(mixed), "dat must contain data from exactly one facility")
})

test_that("Error when facility has no fill rules defined", {
  unknown <- make_misc_dat('Unknown Facility XYZ', 'FL9999999', 'D-001',
    flow = c(0.1), tn = c(1.0)
  )
  expect_error(util_ps_misc(unknown), "No fill rules defined for facility")
  expect_error(util_ps_misc(unknown), "Unknown Facility XYZ")
})
