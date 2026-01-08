test_that("separate_unit_value adds two columns for one input column and keeps names/types", {

  df <- PButils::Nitrogen_Data

  # Pre condition: column exists
  expect_true("boundary_percapita" %in% names(df))

  n_before <- ncol(df)

  out <- separate_unit_value(df = df, columns = "boundary_percapita")

  # 1) columns increased by 2
  expect_equal(ncol(out), n_before + 2)

  # 2) new column names are correct
  expect_true(all(c("boundary_percapita_value", "boundary_percapita_unit") %in% names(out)))

  # 3) types are correct
  expect_true(is.numeric(out$boundary_percapita_value))
  expect_true(is.character(out$boundary_percapita_unit))

  # 4) original column is still present (not removed/renamed)
  expect_true("boundary_percapita" %in% names(out))
})

test_that("separate_unit_value adds two columns per input column for multiple columns and names are correct", {

  df <- PButils::Nitrogen_Data

  cols <- c("global_limit_considered", "boundary_percapita")
  expect_true(all(cols %in% names(df)))

  n_before <- ncol(df)

  out <- separate_unit_value(df = df, columns = cols)

  # 1) columns increased by 2 * length(cols)
  expect_equal(ncol(out), n_before + 2 * length(cols))

  # 2) correct new column names for each input column
  expected_new <- c(
    paste0(cols, "_value"),
    paste0(cols, "_unit")
  )
  expect_true(all(expected_new %in% names(out)))

  # 3) types for each pair
  for (col in cols) {
    expect_true(is.numeric(out[[paste0(col, "_value")]]))
    expect_true(is.character(out[[paste0(col, "_unit")]]))
  }

  # 4) originals still present
  expect_true(all(cols %in% names(out)))
})
