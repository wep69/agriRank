test_that("the time-to-event estimator separates capacity from speed", {
  skip_if_not_installed("drcte")
  data(verbascum, package = "drcte")

  tte <- agri_np_timetoevent(nSeeds ~ timeBef + timeAf, verbascum,
                             by = Species, units = Dish, B = 49, seed = 1)
  expect_s3_class(tte, "agri_np_tte")
  expect_equal(nrow(tte$summary), 3L)
  expect_true(all(c("level", "subjects", "responded") %in% names(tte$summary)))

  # Capacity is a share, and these three lots differ strongly in it.
  expect_true(all(tte$summary$responded >= 0 & tte$summary$responded <= 1))
  arc <- tte$summary[tte$summary$level == "arcturus", ]
  cre <- tte$summary[tte$summary$level == "creticum", ]
  expect_lt(arc$responded, 0.5)
  expect_gt(cre$responded, 0.9)

  # A lot that never reaches half has no whole-lot median, and the NA is the
  # answer. The median among the responders always exists.
  expect_true(is.na(arc$t50_lot))
  expect_true(is.finite(arc$t50_responders))
  expect_true(is.finite(cre$t50_lot))

  # Quantiles must be ordered within a level.
  expect_lt(cre$t10_responders, cre$t50_responders)
  expect_lt(cre$t50_responders, cre$t90_responders)

  expect_output(print(tte), "capacity")
})

test_that("the curve comparison is a permutation test at the unit level", {
  skip_if_not_installed("drcte")
  data(verbascum, package = "drcte")

  tte <- agri_np_timetoevent(nSeeds ~ timeBef + timeAf, verbascum,
                             by = Species, units = Dish, B = 99, seed = 1)
  expect_equal(nrow(tte$test), 1L)
  expect_identical(tte$test$clustered_by, "Dish")
  expect_true(tte$test$p_value >= 0 && tte$test$p_value <= 1)
  # The three species differ conspicuously, so the test must notice.
  expect_lt(tte$test$p_value, 0.10)

  # Omitting the unit is possible but must be flagged, not done silently.
  expect_warning(
    agri_np_timetoevent(nSeeds ~ timeBef + timeAf, verbascum, by = Species,
                        B = 19, seed = 1),
    "units")

  # A single curve has nothing to compare.
  one <- verbascum[verbascum$Species == "creticum", ]
  s <- agri_np_timetoevent(nSeeds ~ timeBef + timeAf, one, B = 19, seed = 1)
  expect_null(s$test)
  expect_equal(nrow(s$summary), 1L)
  expect_true(is.finite(s$summary$t50_responders))
})

test_that("dropping the censored rows is detected", {
  skip_if_not_installed("drcte")
  data(verbascum, package = "drcte")
  dropped <- verbascum[is.finite(verbascum$timeAf), ]
  expect_warning(
    z <- agri_np_timetoevent(nSeeds ~ timeBef + timeAf, dropped, by = Species,
                             units = Dish, B = 19, seed = 1),
    "never germinated|end = Inf")
  # Without the censored rows every lot looks fully germinable.
  expect_true(all(abs(z$summary$responded - 1) < 1e-8))
})

test_that("time-to-event guards fire and figures build", {
  skip_if_not_installed("drcte")
  data(verbascum, package = "drcte")
  expect_error(agri_np_timetoevent(nSeeds ~ timeBef, verbascum), "two time")
  bad <- verbascum; bad$timeAf <- bad$timeBef
  expect_error(agri_np_timetoevent(nSeeds ~ timeBef + timeAf, bad),
               "strictly greater")
  neg <- verbascum; neg$nSeeds[1L] <- -1
  expect_error(agri_np_timetoevent(nSeeds ~ timeBef + timeAf, neg), "negative")

  skip_if_not_installed("ggplot2")
  tte <- agri_np_timetoevent(nSeeds ~ timeBef + timeAf, verbascum,
                             by = Species, units = Dish, B = 19, seed = 1)
  expect_s3_class(plot(tte, type = "cdf"), "ggplot")
  expect_s3_class(plot(tte, type = "capacity"), "ggplot")
  # The step curve must start at zero and never exceed the final capacity.
  for (l in tte$summary$level) {
    z <- tte$curve[tte$curve$level == l, ]
    expect_equal(z$cdf[1L], 0)
    expect_false(is.unsorted(z$cdf))
    expect_lte(max(z$cdf), tte$summary$responded[tte$summary$level == l] + 1e-8)
  }
})

.rk_demo <- function() {
  set.seed(5)
  d <- expand.grid(variety = factor(paste0("V", 1:5)),
                   farm = factor(paste0("F", 1:8)))
  d$yield <- 3 + c(V1 = 0, V2 = 0.6, V3 = 1.1, V4 = 0.3, V5 = 1.4)[d$variety] +
    as.numeric(d$farm) * 0.2 + stats::rnorm(nrow(d), 0, 0.5)
  d
}

test_that("within-block rankings recover the generating order in a complete design", {
  d <- .rk_demo()
  r <- agri_rankings(yield ~ variety, d, block = farm)
  expect_s3_class(r, "agri_rankings")
  expect_true(r$completeness$complete)
  expect_equal(r$completeness$observations, r$completeness$expected_if_complete)

  # V5 was generated best and V1 worst.
  expect_identical(r$summary$item[1L], "V5")
  expect_identical(r$summary$item[nrow(r$summary)], "V1")
  # The summary is sorted by mean rank.
  expect_false(is.unsorted(r$summary$mean_rank))
  # With a complete design the rank sums are reported and must add up.
  expect_true(all(is.finite(r$summary$rank_sum)))
  expect_equal(sum(r$summary$rank_sum), sum(r$rankings$rank))
  expect_equal(sum(r$summary$wins), nlevels(d$farm))

  expect_output(print(r), "complete")
})

test_that("the pairwise record is complete and internally consistent", {
  d <- .rk_demo()
  r <- agri_rankings(yield ~ variety, d, block = farm)
  p <- r$pairwise
  expect_equal(nrow(p), choose(5L, 2L))
  expect_true(all(p$a_above_b + p$b_above_a + p$ties == p$blocks))
  expect_true(all(p$blocks == 8L))
  expect_true(all(p$share_a >= 0 & p$share_a <= 1))
  expect_true(all(p$p_value >= 0 & p$p_value <= 1))
})

test_that("an incomplete design withholds rank sums but keeps the pairwise record", {
  set.seed(9)
  vars <- paste0("V", 1:9)
  tri <- do.call(rbind, lapply(1:40, function(i) {
    pick <- sample(vars, 3)
    q <- c(V1 = 1, V2 = 2, V3 = 3, V4 = 1.5, V5 = 3.5,
           V6 = 2.2, V7 = 0.8, V8 = 2.8, V9 = 1.2)[pick] + stats::rnorm(3, 0, 0.8)
    data.frame(farm = paste0("F", i), variety = pick, position = rank(-q),
               stringsAsFactors = FALSE)
  }))

  rt <- agri_rankings(position ~ variety, tri, block = farm, ranked = TRUE)
  expect_false(rt$completeness$complete)
  expect_lt(rt$completeness$observations, rt$completeness$expected_if_complete)
  # Rank sums are not comparable here and must not be offered.
  expect_true(all(is.na(rt$summary$rank_sum)))
  # The pairwise record survives, and every pair rests on the blocks that held
  # both items, which is fewer than the total.
  expect_true(all(rt$pairwise$blocks <= 40L))
  expect_true(any(rt$pairwise$blocks < 40L))
  expect_output(print(rt), "INCOMPLETE|incomplete")
})

test_that("ranking guards fire and figures build", {
  d <- .rk_demo()
  expect_error(agri_rankings(yield ~ variety, d), "block")
  expect_error(agri_rankings(yield ~ variety + farm, d, block = farm),
               "exactly one item")
  expect_error(agri_rankings(variety ~ farm, d, block = farm), "numeric")

  bad <- data.frame(farm = "F1", variety = c("a", "b"), position = c(0, 1))
  expect_error(agri_rankings(position ~ variety, bad, block = farm,
                             ranked = TRUE), "start at 1")

  # Direction must actually reverse the order.
  hi <- agri_rankings(yield ~ variety, d, block = farm,
                      direction = "higher_is_better")$summary
  lo <- agri_rankings(yield ~ variety, d, block = farm,
                      direction = "lower_is_better")$summary
  expect_identical(rev(hi$item), lo$item)

  skip_if_not_installed("ggplot2")
  r <- agri_rankings(yield ~ variety, d, block = farm)
  expect_s3_class(plot(r, type = "items"), "ggplot")
  expect_s3_class(plot(r, type = "pairwise"), "ggplot")
})
