# system("/usr/lib/R/bin/Rscript '/home/yanpan/getIt/scheduled_us.R'  >> '/home/yanpan/getIt/scheduled_us.log' 2>&1", wait = FALSE)

grep("\\.R", system("ps -ef", intern = TRUE), value = TRUE)

.libPaths("/usr/local/lib/R/site-library")

suppressMessages({
  setwd("/home/yanpan/getIt")
  source("./src/ay01.R")
})

def_interval <<- 39:199

loop_deps   <- "HEL TLL OSL"
loop_dests  <- "PVG BKK HND"
range_ddate <- "2021-01-28 2021-02-12"
the_days    <- 8

start_ay01(loop_deps, loop_dests, range_ddate, the_days)




