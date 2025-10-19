test_that("helpers work", {
  m <- metareg_manifest(); expect_true(is.data.frame(m))
  ids <- metareg_datasets(); expect_true(length(ids) >= 1)
  d <- metareg_read(ids[1])
  expect_true(all(c("yi","vi") %in% names(d)))
  expect_true(all(d$vi[is.finite(d$vi)] > 0))
})
