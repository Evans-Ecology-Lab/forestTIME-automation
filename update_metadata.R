library(cffr)
library(lubridate)
cff <- cff_read("CITATION.cff")

release <- Sys.getenv("RELEASE", unset = stop("No release tag set!"))

cff$version <- release
cff$`date-released` <- format_ISO8601(today())

cff_write(cff)
