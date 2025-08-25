library(cffr)
library(lubridate)
cff <- cff_read("CITATION.cff")

prev_release <- ymd(Sys.getenv("PREV_RELEASE"))

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
