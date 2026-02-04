state = Sys.getenv("STATE", unset = "RI") #use RI for testing because it is small

library(forestTIME)
library(dplyr)
library(purrr)
library(nanoparquet)
library(fs)

# Data Download
fia_download(states = state, keep_zip = FALSE)

# Data prep
db <- fia_load(states = state)
data <- fia_tidy(db)

# Expand to include all years between surveys and interpolate/extrapolate
data_interpolated <- data |> expand_data() |> interpolate_data()

# Adjust for mortality and estimate carbon.
# If any trees use the `MORTYR` variable, use both methods for adjusting for mortality
do_both <- any(!is.na(data$MORTYR))
rm(data) # to save memory

if (do_both) {
  data_mortyr <-
    data_interpolated |>
    adjust_mortality(use_mortyr = TRUE)
}

data_midpt <-
  data_interpolated |>
  adjust_mortality(use_mortyr = FALSE)

rm(data_interpolated) # to save memory
fs::dir_create("fia/parquet")

max_rows <- 5e5 # do carbon estimation in chunks if more than this many rows
if (nrow(data_midpt) <= max_rows) {
  if (do_both) {
    data_mortyr <- data_mortyr |>
      fia_estimate() |>
      fia_assign_strata(db) |>
      fia_split_composite_ids()

    nanoparquet::write_parquet(
      data_mortyr,
      file = glue::glue("fia/parquet/{state}_mortyr.parquet"),
      compression = "zstd",
      options = parquet_options(compression_level = 19)
    )
    rm(data_mortyr)
  }
  data_midpt <- data_midpt |>
    fia_estimate() |>
    fia_assign_strata(db) |>
    fia_split_composite_ids()

  # Write out to parquet
  message("writing midpt to parquet")
  nanoparquet::write_parquet(
    data_midpt,
    glue::glue("fia/parquet/{state}_midpt.parquet"),
    compression = "zstd",
    options = parquet_options(compression_level = 19)
  )
} else {
  # chunk into a list of data frames with at most `max_rows` rows
  n_groups <- ceiling(nrow(data_midpt) / max_rows)

  # Arranging by split ID components and YEAR shrinks file size for parquet
  if (do_both) {
    data_mortyr <- data_mortyr |>
      mutate(cut_group = cut(1:n(), n_groups)) |>
      group_by(cut_group) |>
      group_split() |>
      map(fia_estimate) |>
      list_rbind() |>
      fia_assign_strata(db) |>
      fia_split_composite_ids() |>
      arrange(STATECD, UNITCD, COUNTYCD, PLOT, SUBP, TREE, YEAR)

    message("writing mortyr to parquet")
    nanoparquet::write_parquet(
      data_mortyr,
      file = glue::glue("fia/parquet/{state}_mortyr.parquet"),
      compression = "zstd",
      options = parquet_options(compression_level = 19)
    )
    rm(data_mortyr)
  }

  data_midpt <- data_midpt |>
    mutate(cut_group = cut(1:n(), n_groups)) |>
    group_by(cut_group) |>
    group_split() |>
    map(fia_estimate) |>
    list_rbind() |>
    fia_assign_strata(db) |>
    fia_split_composite_ids() |>
    arrange(STATECD, UNITCD, COUNTYCD, PLOT, SUBP, TREE, YEAR)

  # Write out to parquet
  message("writing midpt to parquet")
  nanoparquet::write_parquet(
    data_midpt,
    glue::glue("fia/parquet/{state}_midpt.parquet"),
    compression = "zstd",
    options = parquet_options(compression_level = 19)
  )
}