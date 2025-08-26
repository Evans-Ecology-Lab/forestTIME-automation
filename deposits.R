# pak::pak("deposits")
# pak::pak("frictionless")
library(deposits)

cli <- depositsClient$new("zenodo", sandbox = TRUE)
# cli
# cli$deposits_methods()

metadata <- list(
  title = "`forestTIME` annualized FIADB carbon and biomass estimates",
  description = "These datasets are produced from the Forest Inventory and Analysis database
  and interpolated values produced by the `forestTIME` R package. For a more detailed
  description of the methods used, see the documentation for the `forestTIME` package.",
  creator = list(
    list(
      name = "Eric R. Scott",
      affiliation = "University of Arizona, Communications & Cyber Technology",
      orcid = "0000-0003-0803-4734"
    ),
    list(
      name = "Renata Diaz",
      affiliation = "University of Arizona, Communications & Cyber Technology",
      orcid = "0000-0003-0803-4734"
    ),
    list(
      name = "Dani Steinberg",
      affiliation = "University of Arizona, School of Natural Resources & The Environment",
      orcid = "0000-0002-3695-3837"
    ),
    list(
      name = "Kristina Riemer",
      affiliation = "University of Arizona, Communications & Cyber Technology",
      orcid = "0000-0003-3802-3331"
    ),
    list(
      name = "Margaret Evans",
      affiliation = "University of Arizona, Laboratory of Tree Ring Research"
    )
  ),
  contributor = list(
    list(
      name = "Grant M. Domke",
      type = "ProjectMember"
    ),
    list(
      name = "Brian Walters",
      type = "ProjectMember"
    )
  ),
  created = Sys.Date(),
  license = "cc-zero",
  relation = list(
    list(
      identifier = "https://github.com/Evans-Ecology-Lab/forestTIME-automation",
      relation = "isCompiledBy",
      resource_type = "software"
    )
  )
)
cli$deposit_fill_metadata(metadata)
cli$metadata

cli$deposit_new()
# cli$deposit_add_resource("fia/csv/")
cli$deposit_upload_file("fia/csv/")
cli$deposit_publish()
