test_that('list_datasets returns a tibble with required cols', {
  tbl <- metahub::list_datasets()
  expect_s3_class(tbl, 'tbl_df')
  expect_true(all(c('id','title','source_type','package','object') %in% names(tbl)))
})
