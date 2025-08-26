library(cffr)
library(lubridate)
cff <- cff_read("CITATION.cff")

# prev_release <- Sys.getenv("PREV_RELEASE")

# get current version from CITATION.cff
prev_release <- cff$version

#possibilitiies
# prev_release <- as.character(today()) #one prev release today
# prev_release <- paste(today(), 1, sep = "_") #already a manual release today
# prev_release <- as.character(today() - 1) #release on a prior day
# prev_release <- paste(today() - 1, 1, sep = "_") #manual release on a prior day

if (grepl("_\\d+$", prev_release)) {
  split <- strsplit(prev_release, "_")[[1]]
  prev_date <- ymd(split[[1]])
  num <- as.integer(split[[2]])
} else {
  prev_date <- ymd(prev_release)
  num <- 0L
}

if (prev_date != today()) {
  release <- as.character(today())
} else {
  release <- paste(today(), num + 1L, sep = "_")
}
# release

cff$`date-released` <- format_ISO8601(today())
cff$version <- release

cff_write(cff)

Sys.setenv(RELEASE = release)

#only works on GitHub
system('echo "RELEASE=$RELEASE" >> $GITHUB_ENV')
