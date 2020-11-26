# system("/usr/lib/R/bin/Rscript '/home/yanpan/getIt/scheduled_us.R'  >> '/home/yanpan/getIt/scheduled_us.log' 2>&1", wait = FALSE)

grep("\\.R", system("ps -ef", intern = TRUE), value = TRUE)

.libPaths("/usr/local/lib/R/site-library")

suppressMessages({
  setwd("/home/yanpan/getIt")
  source("./src/ay01.R")
})

def_interval <<- 39:199

loop_deps   <- "HEL TLL CPH"
loop_dests  <- "PPT NAN"
range_ddate <- "2021-04-03 2021-04-12"
#the_days    <- 14

start_ay01(loop_deps, loop_dests, range_ddate, the_days = 12)
start_ay01(loop_deps, loop_dests, range_ddate, the_days = 15)


do_not_run <- function(){
  source("./src/ay01.R")
  # per-leg detailed table save to ./results
  save_data_ay01("ay01_") 
  # get route, need to load manually
  serve_ay01(df) -> df_route
  df_route %>% group_by(route) %>% summarize(min_eur = min(eur)) %>%
    arrange(min_eur)-> df_min
  
}

