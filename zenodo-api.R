library(httr2)
library(purrr)
library(fs)

global_id <- "335741" #first version actually

base_req <- request("https://sandbox.zenodo.org/api/deposit/depositions") |>
  req_auth_bearer_token(Sys.getenv("ZENODO_SANDBOX_TOKEN"))

# 1. Get id of most recent version of global_id

resp <- base_req |>
  req_url_path_append(global_id) |>
  req_perform()
record <- resp_body_json(resp)
latest <- request(record$links$latest) |>
  req_auth_bearer_token(Sys.getenv("ZENODO_SANDBOX_TOKEN")) |>
  req_perform() |>
  resp_body_json()
latest_id <- latest$id


# 2. Create new version

new_version_req <- base_req |>
  req_url_path_append(latest_id, "actions/newversion") |>
  req_method("POST")
new_version <- req_perform(new_version_req) |>
  resp_body_json()

# 3. Get id of new version from links$latest_draft

new_version_id <- request(new_version$links$latest_draft) |>
  req_auth_bearer_token(Sys.getenv("ZENODO_SANDBOX_TOKEN")) |>
  req_perform() |>
  resp_body_json() |>
  purrr::pluck("id")

# 4. Update metadata

new_metadata <- new_version$metadata
new_metadata$publication_date <- Sys.Date()

base_req |>
  req_url_path_append(new_version_id) |>
  req_method("PUT") |>
  req_body_json(data = list(metadata = new_metadata)) |>
  req_perform()

# 4. list files

file_ids <- base_req |>
  req_url_path_append(new_version_id, "files") |>
  req_perform() |>
  resp_body_json() |>
  map_chr("id")

# 5. delete files
if (length(file_ids) > 0) {
  map(file_ids, \(x) {
    base_req |>
      req_url_path_append(new_version_id, "files", x) |>
      req_method("DELETE")
  }) |>
    req_perform_sequential()
}

# 6. upload new files (using new file upload API)

# First get the bucket link
info <- base_req |>
  req_url_path_append(new_version_id) |>
  req_perform() |>
  resp_body_json()
bucket <- info$links$bucket
paths <- fs::dir_ls("fia/parquet")

# Then upload all the files
upload_reqs <- map(paths, \(path) {
  request(bucket) |>
    req_url_path_append(path_file(path)) |>
    req_auth_bearer_token(Sys.getenv("ZENODO_SANDBOX_TOKEN")) |>
    req_method("PUT") |>
    req_body_file(path)
})

# req_perform_parallel() doesn't work for some reason
req_perform_sequential(upload_reqs)

# 7. publish release
# TODO: consider making this manual so Margaret has to double-check the release
base_req |>
  req_url_path_append(new_version_id, "actions", "publish") |>
  req_method("POST") |>
  req_perform()
