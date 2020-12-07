#######################################################################
### _    _  _____   ### This is a scheduled script (date-dependent) ###
### | |  | |/ ____| ###                                             ###
### | |  | | (___   ### - Full looping 4-day                        ###
### | |  | |\___ \  ### - HLT, ACR scheduled here; AY possible here ###
### | |__| |____) | ### - The results is not populated to dashboard ###
###  \____/|_____/  ###                                             ###
#######################################################################
# system("/usr/lib/R/bin/Rscript '/home/yanpan/getIt/scheduled_us.R'  >> '/home/yanpan/getIt/scheduled_us.log' 2>&1", wait = FALSE)

suppressMessages({
  .libPaths(c("/usr/local/lib/R/site-library", .libPaths()))
  setwd("/home/yanpan/getIt")
  source("./src/hlt01.R")
  source("./src/acr01.R")
})

controller <- as.numeric(Sys.Date()) %% 4

# parameters --------------------------------------------------------------

def_interval <<- 29:50

hlt_date_max  <- Sys.Date() + 355 - 7
hlt_fu_nights <- c(3, 4)
hlt_fu_hotels <- c(1, 2)
hlt_fu_dates  <- (hlt_date_max - c(86*controller + 85, 86*controller)) %>% 
  format("%Y-%m-%d") %>% paste(collapse = " ")

acr_date_max  <- Sys.Date() + 355 - 7
acr_fu_nights <- c(3, 4)
acr_fu_hotels <- c(1, 2)
acr_fu_dates  <- (acr_date_max - c(86*controller + 85, 86*controller)) %>% 
  format("%Y-%m-%d") %>% paste(collapse = " ")


# main module -------------------------------------------------------------

get_exchange_rate()

loggerUS("Worker started HLT01 fu", hlt_fu_dates)
start_hlt01(hlt_fu_dates, hlt_fu_nights, hlt_fu_hotels)
save_data_hlt01(paste0("hlt01_", gsub("-", "", Sys.Date())))

loggerUS("Worker started ACR01 fu", acr_fu_dates)
start_acr01(acr_fu_dates, acr_fu_nights, acr_fu_hotels)
save_data_acr01(paste0("acr01_", gsub("-", "", Sys.Date())))


# all completed -----------------------------------------------------------

show_tasktime(log_file = "./scheduled_us.log")
cat(rep("=", 39), "\n", rep("=", 39), "\n")







# backups -----------------------------------------------------------------

not_run_AY01 <- function(){
  # system("/usr/lib/R/bin/Rscript '/home/yanpan/getIt/scheduled_us.R'  >> '/home/yanpan/getIt/scheduled_us.log' 2>&1", wait = FALSE)
  # grep("\\.R", system("ps -ef", intern = TRUE), value = TRUE)
  
  source("./src/ay01.R")
  loop_deps   <- "HEL TLL CPH"
  loop_dests  <- "PPT NAN"
  range_ddate <- "2021-04-03 2021-04-12"
  start_ay01(loop_deps, loop_dests, range_ddate, the_days = 12)
  start_ay01(loop_deps, loop_dests, range_ddate, the_days = 15)
  
  # per-leg detailed table save to ./results
  save_data_ay01("ay01_") 
  # get route, need to load manually
  serve_ay01(df) -> df_route
  df_route %>% group_by(route) %>% summarize(min_eur = min(eur)) %>%
    arrange(min_eur)-> df_min
}

