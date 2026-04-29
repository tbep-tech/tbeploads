test_that("anlz_gw monthly output has correct structure", {
  out <- anlz_gw(contdry, contwet, yrrng = c(2022, 2024))

  expect_s3_class(out, "data.frame")
  expect_equal(nrow(out), 7L * 12L * 3L)  # 7 segs x 12 months x 3 years
  expect_true(all(c("Year", "Month", "source", "segment",
                    "tn_load", "tp_load", "hy_load") %in% names(out)))
  expect_false("tss_load" %in% names(out))
  expect_true(all(out$source == "GW"))
  expect_equal(sort(unique(out$segment)), 
      c("Boca Ciega Bay", "Hillsborough Bay", "Lower Tampa Bay", 
      "Manatee River", "Middle Tampa Bay", "Old Tampa Bay", "Terra Ceia Bay"))
  expect_equal(sort(unique(out$Year)),  2022L:2024L)
  expect_equal(sort(unique(out$Month)), 1L:12L)
})

test_that("anlz_gw dry season sets Floridan gradient to zero for LTB and RALTB", {
  out <- anlz_gw(contdry, contwet, yrrng = c(2022, 2022))

  segs <- c('Lower Tampa Bay', 'Boca Ciega Bay', 'Terra Ceia Bay', 'Manatee River')
  # In dry season (Jan), segs Floridan grad = 0, so loads come only from
  # fixed surficial + intermediate contributions
  dry <- out[out$Month == 1L & out$segment %in% segs,  ]
  wet <- out[out$Month == 7L & out$segment %in% segs, ]
  expect_lt(sum(dry$tn_load), sum(wet$tn_load))
  expect_lt(sum(dry$hy_load), sum(wet$hy_load))

  # BCB: grad = 0 in both seasons, so dry = wet for Floridan
  # (only surficial fixed loads, no intermediate for seg 5)
  dry <- out[out$Month == 1L & out$segment == 'Boca Ciega Bay', ]
  wet <- out[out$Month == 7L & out$segment == 'Boca Ciega Bay', ]
  expect_equal(dry$tn_load, wet$tn_load)
})

test_that("anlz_gw OTB Jan 2022 matches SAS output within rounding", {
  out <- anlz_gw(contdry, contwet, yrrng = c(2022, 2022))
  otb  <- out[out$Month == 1L & out$segment == "Old Tampa Bay", ]

  # SAS output (integer kg): TN = 498, TP = 148, H2O = 5,015,038 m3
  # Convert to tons / million m3 for comparison
  expect_equal(otb$tn_load * 907.1847, 498, tolerance = 1)
  expect_equal(otb$tp_load * 907.1847, 148, tolerance = 1)
  expect_equal(otb$hy_load * 1e6,  5015038, tolerance = 100)
})

test_that("anlz_gw LTB Jan 2022 matches SAS output within rounding", {
  out <- anlz_gw(contdry, contwet, yrrng = c(2022, 2022))
  ltb  <- out[out$Month == 1L & out$segment == 'Hillsborough Bay', ]

  expect_equal(ltb$tn_load * 907.1847, 1566, tolerance = 1)
  expect_equal(ltb$tp_load * 907.1847,  186, tolerance = 1)
  expect_equal(ltb$hy_load * 1e6,  6153232, tolerance = 5000)
})

test_that("anlz_gw annual summtime sums months correctly", {
  monthly <- anlz_gw(contdry, contwet, yrrng = c(2022, 2022), summtime = 'month')
  annual  <- anlz_gw(contdry, contwet, yrrng = c(2022, 2022), summtime = 'year')

  expect_equal(nrow(annual), 7L)
  expect_false("Month" %in% names(annual))

  # Annual TN for OTB should equal sum of 12 monthly values
  expect_equal(
    annual$tn_load[annual$segment == 'Old Tampa Bay'],
    sum(monthly$tn_load[monthly$segment == 'Old Tampa Bay']),
    tolerance = 1e-10
  )
  expect_equal(
    annual$hy_load[annual$segment == 'Middle Tampa Bay'],
    sum(monthly$hy_load[monthly$segment == 'Middle Tampa Bay']),
    tolerance = 1e-10
  )
})

test_that("anlz_gw custom wqdat changes OTB, HB loads but not others", {
  default_out <- anlz_gw(contdry, contwet, yrrng = c(2022, 2022))

  # Double the concentrations for OTB, HB, leave others unchanged
  custom_wq <- data.frame(
    bay_seg = 1L:7L,
    tn_mgl  = c(0.20, 0.51, 0.025, 0.025, 0.022, 0.025, 0.025),
    tp_mgl  = c(0.0586, 0.0576, 0.137, 0.137, 0.118, 0.125, 0.114)
  )
  custom_out <- anlz_gw(contdry, contwet, yrrng = c(2022, 2022), wqdat = custom_wq)

  # HB, OTB TN load should increase (doubled Floridan concentration)
  expect_gt(
    sum(custom_out$tn_load[custom_out$segment == 'Old Tampa Bay']),
    sum(default_out$tn_load[default_out$segment == 'Old Tampa Bay'])
  )
  expect_gt(
    sum(custom_out$tn_load[custom_out$segment == 'Hillsborough Bay']),
    sum(default_out$tn_load[default_out$segment == 'Hillsborough Bay'])
  )

  # other segment loads unchanged (same concentrations + same fixed loads)
  for (seg in c('Middle Tampa Bay', 'Lower Tampa Bay', 'Boca Ciega Bay', 
              'Terra Ceia Bay', 'Manatee River')) {
    expect_equal(
      sum(custom_out$tn_load[custom_out$segment == seg]),
      sum(default_out$tn_load[default_out$segment == seg]),
      tolerance = 1e-10
    )
  }
})

test_that("anlz_gw all load values are non-negative", {
  out <- anlz_gw(contdry, contwet, yrrng = c(2022, 2024))
  expect_true(all(out$tn_load >= 0))
  expect_true(all(out$tp_load >= 0))
  expect_true(all(out$hy_load >= 0))
})
