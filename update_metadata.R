library(cffr)
library(lubridate)
cff <- cff_read("CITATION.cff")

cff$`date-released` <- format_ISO8601(today())
cff$version <- format_ISO8601(now())

cff_write(cff)
