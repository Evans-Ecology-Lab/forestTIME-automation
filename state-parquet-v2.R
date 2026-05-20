state = Sys.getenv("STATE", unset = "RI") #use RI for testing because it is small
year_var = Sys.getenv("YEAR_VAR", unset = "RI") #this is set by the matrix option in the workflow 
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

# Run workflow twice: once for MEASYEAR, once for INVYR
  
message("Running workflow with year_var = ", year_var)

# Expand to include all years between surveys and interpolate/extrapolate
data_interpolated <- data |>
  expand_data(year_var = year_var) |>
  interpolate_data()

# Adjust for mortality and estimate carbon.
# If any trees use the `MORTYR` variable, use both methods for adjusting for mortality
do_both <- any(!is.na(data$MORTYR))
# rm(data) # to save memory - commenting this out to work with loop
gc()

if (do_both) {
  data_mortyr <-
    data_interpolated |>
    adjust_mortality(use_mortyr = TRUE)
}

data_midpt <-
  data_interpolated |>
  adjust_mortality(use_mortyr = FALSE)

# rm(data_interpolated) # to save memory - commenting this out to work with loop
gc()
fs::dir_create("fia/parquet")

max_rows <- 5e5 # do carbon estimation in chunks if more than this many rows
if (nrow(data_midpt) <= max_rows) {
  if (do_both) {
    data_mortyr <- data_mortyr |>
      fia_allometry() |>
      fia_design(db) |>
      fia_split_composite_ids()
    
    nanoparquet::write_parquet(
      data_mortyr,
      file = glue::glue("fia/parquet/{state}_mortyr_{year_var}.parquet"),
      compression = "zstd",
      options = parquet_options(compression_level = 19)
    )
    # rm(data_mortyr) - commenting this out to work with loop
    gc()
  }
  
  data_midpt <- data_midpt |>
    fia_allometry() |>
    fia_design(db) |>
    fia_split_composite_ids()
  
  # Write out to parquet
  message("writing midpt to parquet")
  nanoparquet::write_parquet(
    data_midpt,
    glue::glue("fia/parquet/{state}_midpt_{year_var}.parquet"),
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
      map(fia_allometry) |>
      list_rbind() |>
      fia_design(db) |>
      fia_split_composite_ids() |>
      arrange(STATECD, UNITCD, COUNTYCD, PLOT, SUBP, TREE, YEAR)
    
    message("writing mortyr to parquet")
    nanoparquet::write_parquet(
      data_mortyr,
      file = glue::glue("fia/parquet/{state}_mortyr_{year_var}.parquet"),
      compression = "zstd",
      options = parquet_options(compression_level = 19)
    )
    # rm(data_mortyr) - commenting this out to work with loop
    gc()
  }
  
  data_midpt <- data_midpt |>
    mutate(cut_group = cut(1:n(), n_groups)) |>
    group_by(cut_group) |>
    group_split() |>
    map(fia_allometry) |>
    list_rbind() |>
    fia_design(db) |>
    fia_split_composite_ids() |>
    arrange(STATECD, UNITCD, COUNTYCD, PLOT, SUBP, TREE, YEAR)
  
  # Write out to parquet
  message("writing midpt to parquet")
  nanoparquet::write_parquet(
    data_midpt,
    glue::glue("fia/parquet/{state}_midpt_{year_var}.parquet"),
    compression = "zstd",
    options = parquet_options(compression_level = 19)
  )
}

