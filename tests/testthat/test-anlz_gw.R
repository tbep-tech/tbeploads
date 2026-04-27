test_that("anlz_gw monthly output has correct structure", {
  out <- anlz_gw(yrrng = c(2022, 2024))

  expect_s3_class(out, "data.frame")
  expect_equal(nrow(out), 7L * 12L * 3L)  # 7 segs x 12 months x 3 years
  expect_true(all(c("Year", "Month", "source", "bay_seg", "segment",
                    "tn_load", "tp_load", "hy_load") %in% names(out)))
  expect_false("tss_load" %in% names(out))
  expect_true(all(out$source == "GW"))
  expect_equal(sort(unique(out$bay_seg)), 1L:7L)
  expect_equal(sort(unique(out$Year)),  2022L:2024L)
  expect_equal(sort(unique(out$Month)), 1L:12L)
})

test_that("anlz_gw segment names are correct", {
  out <- anlz_gw(yrrng = c(2022, 2022))
  seg_map <- out[!duplicated(out$bay_seg), c("bay_seg", "segment")]
  seg_map <- seg_map[order(seg_map$bay_seg), ]

  expect_equal(seg_map$segment,
               c("Old Tampa Bay", "Hillsborough Bay", "Middle Tampa Bay",
                 "Lower Tampa Bay", "Boca Ciega Bay", "Terra Ceia Bay",
                 "Manatee River"))
})

test_that("anlz_gw dry season sets Floridan gradient to zero for segs 4-7", {
  out <- anlz_gw(yrrng = c(2022, 2022))

  # In dry season (Jan), segs 4-7 Floridan grad = 0, so loads come only from
  # fixed surficial + intermediate contributions
  dry_4 <- out[out$Month == 1L & out$bay_seg == 4L, ]
  wet_4 <- out[out$Month == 7L & out$bay_seg == 4L, ]
  expect_lt(dry_4$tn_load, wet_4$tn_load)
  expect_lt(dry_4$hy_load, wet_4$hy_load)

  # Seg 5 and 55-proxy: grad = 0 in both seasons, so dry = wet for Floridan
  # (only surficial fixed loads, no intermediate for seg 5)
  dry_5 <- out[out$Month == 1L & out$bay_seg == 5L, ]
  wet_5 <- out[out$Month == 7L & out$bay_seg == 5L, ]
  expect_equal(dry_5$tn_load, wet_5$tn_load)
})

test_that("anlz_gw seg 1 Jan 2022 matches SAS output within rounding", {
  out <- anlz_gw(yrrng = c(2022, 2022))
  s1  <- out[out$Month == 1L & out$bay_seg == 1L, ]

  # SAS output (integer kg): TN = 498, TP = 148, H2O = 5,015,038 m3
  # Convert to tons / million m3 for comparison
  expect_equal(s1$tn_load * 907.1847, 498, tolerance = 1)
  expect_equal(s1$tp_load * 907.1847, 148, tolerance = 1)
  expect_equal(s1$hy_load * 1e6,  5015038, tolerance = 100)
})

test_that("anlz_gw seg 2 Jan 2022 matches SAS output within rounding", {
  out <- anlz_gw(yrrng = c(2022, 2022))
  s2  <- out[out$Month == 1L & out$bay_seg == 2L, ]

  expect_equal(s2$tn_load * 907.1847, 1566, tolerance = 1)
  expect_equal(s2$tp_load * 907.1847,  186, tolerance = 1)
  expect_equal(s2$hy_load * 1e6,  6153232, tolerance = 5000)
})

test_that("anlz_gw annual summtime sums months correctly", {
  monthly <- anlz_gw(yrrng = c(2022, 2022), summtime = 'month')
  annual  <- anlz_gw(yrrng = c(2022, 2022), summtime = 'year')

  expect_equal(nrow(annual), 7L)
  expect_false("Month" %in% names(annual))

  # Annual TN for seg 1 should equal sum of 12 monthly values
  expect_equal(
    annual$tn_load[annual$bay_seg == 1L],
    sum(monthly$tn_load[monthly$bay_seg == 1L]),
    tolerance = 1e-10
  )
  expect_equal(
    annual$hy_load[annual$bay_seg == 3L],
    sum(monthly$hy_load[monthly$bay_seg == 3L]),
    tolerance = 1e-10
  )
})

test_that("anlz_gw custom wqdat changes seg 1-2 loads but not seg 3-7", {
  default_out <- anlz_gw(yrrng = c(2022, 2022))

  # Double the concentrations for segs 1-2, leave 3-7 unchanged
  custom_wq <- data.frame(
    bay_seg = 1L:7L,
    tn_mgl  = c(0.20, 0.51, 0.025, 0.025, 0.022, 0.025, 0.025),
    tp_mgl  = c(0.0586, 0.0576, 0.137, 0.137, 0.118, 0.125, 0.114)
  )
  custom_out <- anlz_gw(yrrng = c(2022, 2022), wqdat = custom_wq)

  # Segs 1-2 TN load should increase (doubled Floridan concentration)
  expect_gt(
    sum(custom_out$tn_load[custom_out$bay_seg == 1L]),
    sum(default_out$tn_load[default_out$bay_seg == 1L])
  )
  expect_gt(
    sum(custom_out$tn_load[custom_out$bay_seg == 2L]),
    sum(default_out$tn_load[default_out$bay_seg == 2L])
  )

  # Segs 3-7 loads unchanged (same concentrations + same fixed loads)
  for (seg in 3L:7L) {
    expect_equal(
      sum(custom_out$tn_load[custom_out$bay_seg == seg]),
      sum(default_out$tn_load[default_out$bay_seg == seg]),
      tolerance = 1e-10
    )
  }
})

test_that("anlz_gw all load values are non-negative", {
  out <- anlz_gw(yrrng = c(2022, 2024))
  expect_true(all(out$tn_load >= 0))
  expect_true(all(out$tp_load >= 0))
  expect_true(all(out$hy_load >= 0))
})
