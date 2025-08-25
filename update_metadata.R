library(cffr)
library(lubridate)
cff <- cff_read("CITATION.cff")
# get previous release from GitHub
prev_release <- system("git describe --abbrev=0 --tags", intern = TRUE)
# prev_release <- "2024-08-25_1"

if (prev_release == today()) {
  release <- paste(today(), 1, sep = "_")
} else {
  num <- as.numeric(strsplit(prev_release, split = "_")[[1]][2]) + 1
  release <- paste(today(), num, sep = "_")
}

cff$`date-released` <- format_ISO8601(today())
cff$version <- release

cff_write(cff)

Sys.setenv(RELEASE = release)
