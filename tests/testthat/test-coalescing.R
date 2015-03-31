library(testthatsomemore)
context('stageRunner coalescing')

describe('with regular environments', {

  test_that("it can coalesce a trivial example", {
    sr1 <- stageRunner$new(new.env(), remember = TRUE,
      list(a = function(e) e$x <- 1, b = function(e) e$y <- 2,
           c = function(e) e$z <- 3))
    sr2 <- stageRunner$new(new.env(), remember = TRUE,
      list(a = function(e) e$x <- 1, b = function(e) e$y <- 4,
           c = function(e) e$z <- 5))
    sr1$run(1)
    sr2$coalesce(sr1)
    assert(sr2$run(2))
    expect_identical(sr2$context$y, 4)
  })

  test_that("it does not coalesce when no names overlap", {
    sr1 <- stageRunner$new(new.env(), remember = TRUE,
      list(a = function(e) e$x <- 1, b = function(e) e$y <- 2))
    sr2 <- stageRunner$new(new.env(), remember = TRUE,
      list(c = function(e) e$x <- 1, d = function(e) e$y <- 4))
    sr1$run()
    sr2$coalesce(sr1)
    expect_error(sr2$run(2), "some previous stages have not been executed")
  })

  test_that("it cannot coalesce when a stage is renamed", {
    sr1 <- stageRunner$new(new.env(), remember = TRUE,
      list(a = function(e) e$x <- 1, b = function(e) e$y <- 2))
    sr2 <- stageRunner$new(new.env(), remember = TRUE,
      list(a = function(e) e$x <- 1, c = function(e) e$y <- 4))
    sr1$run(1)
    sr2$coalesce(sr1)
    expect_error(sr2$run(2), "some previous stages have not been executed")
  })

  test_that("it coalesces when a stage is removed further in the chain", {
    sr1 <- stageRunner$new(new.env(), remember = TRUE,
      list(a = function(e) e$x <- 1, b = function(e) e$y <- 2, c = function(e) e$z <- 3))
    sr2 <- stageRunner$new(new.env(), remember = TRUE,
      list(a = function(e) e$x <- 1, b = function(e) e$y <- 4, d = function(e) e$z <- 5))
    sr1$run(1)
    sr2$coalesce(sr1)
    assert(sr2$run(2))
    expect_identical(sr2$context$y, 4)
  })

  test_that("it coalesces for substages", {
    sr1 <- stageRunner$new(new.env(), remember = TRUE,
      list(a = function(e) e$x <- 1,
           b = list(b1 = function(e) e$y <- 2, b2 = function(e) e$z <- 3, b3 = function(e) e$w <- 4)))
    sr2 <- stageRunner$new(new.env(), remember = TRUE,
      list(a = function(e) e$x <- 1,
           b = list(b1 = function(e) e$y <- 2, b2 = function(e) e$z <- 5, b3 = function(e) e$w <- 6)))
    sr1$run('a', 'b/b2')
    sr2$coalesce(sr1)
    assert(sr2$run('b/b2', 'b'))
    expect_identical(sr2$context$z, 5)
    expect_identical(sr2$context$w, 6)
  })
})

describe('with tracked_environments', {
  library(objectdiff)

  test_that("it can coalesce a trivial example", {
    sr1 <- stageRunner$new(tracked_environment(), remember = TRUE,
      list(a = function(e) e$x <- 1, b = function(e) e$y <- 2,
           c = function(e) e$z <- 3))
    sr2 <- stageRunner$new(tracked_environment(), remember = TRUE,
      list(a = function(e) e$x <- 1, b = function(e) e$y <- 4,
           c = function(e) e$z <- 5))
    sr1$run(1)
    sr2$coalesce(sr1)
    assert(sr2$run(2))
    expect_identical(sr2$context$y, 4)
  })

  test_that("it does not coalesce when no names overlap", {
    sr1 <- stageRunner$new(tracked_environment(), remember = TRUE,
      list(a = function(e) e$x <- 1, b = function(e) e$y <- 2))
    sr2 <- stageRunner$new(tracked_environment(), remember = TRUE,
      list(c = function(e) e$x <- 1, d = function(e) e$y <- 4))
    sr1$run()
    sr2$coalesce(sr1)
    expect_error(sr2$run(2), "some previous stages have not been executed")
  })

  test_that("it can coalesce when an immediate successor stage is renamed", {
    sr1 <- stageRunner$new(tracked_environment(), remember = TRUE,
      list(a = function(e) e$x <- 1, b = function(e) e$y <- 2))
    sr2 <- stageRunner$new(tracked_environment(), remember = TRUE,
      list(a = function(e) e$x <- 1, c = function(e) e$y <- 4))
    sr1$run(1)
    sr2$coalesce(sr1)
    sr2$run(2)
    expect_identical(sr2$context$x, 1)
    expect_identical(sr2$context$y, 4)
  })

  test_that("it cannot coalesce when a later successor stage is renamed", {
    sr1 <- stageRunner$new(tracked_environment(), remember = TRUE,
      list(a = function(e) e$x <- 1, b = function(e) e$y <- 2, c = function(e) e$z <- 3))
    sr2 <- stageRunner$new(tracked_environment(), remember = TRUE,
      list(a = function(e) e$x <- 1, b = function(e) e$y <- 4, d = function(e) e$w <- 5))
    sr1$run(1)
    sr2$coalesce(sr1)
    expect_error(sr2$run(3), "some previous stages have not been executed")
  })

  test_that("it coalesces when a stage is removed further in the chain", {
    sr1 <- stageRunner$new(tracked_environment(), remember = TRUE,
      list(a = function(e) e$x <- 1, b = function(e) e$y <- 2, c = function(e) e$z <- 3))
    sr2 <- stageRunner$new(tracked_environment(), remember = TRUE,
      list(a = function(e) e$x <- 1, b = function(e) e$y <- 4, d = function(e) e$z <- 5))
    sr1$run(1)
    sr2$coalesce(sr1)
    assert(sr2$run(2))
    expect_identical(sr2$context$y, 4)
  })

  test_that("it coalesces for substages", {
    sr1 <- stageRunner$new(tracked_environment(), remember = TRUE,
      list(a = function(e) e$x <- 1,
           b = list(b1 = function(e) e$y <- 2, b2 = function(e) e$z <- 3, b3 = function(e) e$w <- 4)))
    sr2 <- stageRunner$new(tracked_environment(), remember = TRUE,
      list(a = function(e) e$x <- 1,
           b = list(b1 = function(e) e$y <- 2, b2 = function(e) e$z <- 5, b3 = function(e) e$w <- 6)))
    sr1$run('a', 'b/b2')
    sr2$coalesce(sr1)
    assert(sr2$run('b/b2', 'b'))
    expect_identical(sr2$context$z, 5)
    expect_identical(sr2$context$w, 6)
  })
})