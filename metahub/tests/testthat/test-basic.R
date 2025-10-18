
test_that("registry loads and dataset can be loaded", {
  reg <- metahub::registry_load()
  expect_true(any(vapply(reg, `[[`, "", "id") == "metadat_dat.bcg"))
  ds <- metahub::load_dataset("metadat_dat.bcg")
  expect_s3_class(ds, "metadset")
  expect_true(all(c("study_id","yi","vi") %in% names(ds$data)))
})

