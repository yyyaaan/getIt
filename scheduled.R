#######################################################################
###  ______ _____  ### This is a scheduled script (date-dependent)  ###
### |  ____|_   _| ###                                              ###
### | |__    | |   ### - Full looping 4-day                         ###
### |  __|   | |   ### - QR, MRT scheduled here                     ###
### | |     _| |_  ###                                              ###
### |_|    |_____| ###                                              ###
#######################################################################

# system("/usr/lib/R/bin/Rscript '/home/yanpan/getIt/scheduled.R'  >> '/home/yanpan/getIt/scheduled.log' 2>&1", wait = FALSE)

## 2020-09-30: QR&MRT tracking series replaced from Christmas 2020 to Summer 2021
##             QR destination removed ADL added AMS
## 2020-11-30: Added HLT for following up series. No defined series needed.
## 2020-12-07: HLT moved to US server
## 2020-12-08: MRT tracking is now replaced by follow-up.
## 2020-12-13: QR tracking is disabled; partially replaced by follow-up.
## 2021-01-16: FSH added tracking

suppressMessages({
  .libPaths(c("/usr/local/lib/R/site-library", .libPaths()))
  setwd("/home/yanpan/getIt")
  source("./src/qr01.R")
  source("./src/mrt01.R")
  source("./src/fsh01.R")
  source("./src/serving.R")
})

### sequence are supposed to be completed once in a 4-day run
### one may repeat parameters to increase frequency
controller <- as.numeric(Sys.Date()) %% 4
def_interval <<- 20:35
qr_the_days<- 18 
the_date_max  <- Sys.Date() + 355 - 7

# param def for follow up -------------------------------------------------

qr_date_max <- Sys.Date() + 353 - qr_the_days - controller # fixed, interval is 15 days
qr_fu_deps  <- "HEL OSL TLL AMS"
qr_fu_dests <- "SYD CBR MEL"
qr_fu_dates <- seq(qr_date_max - 75*controller, length = 5, by = "-15 days") 
qr_fu_dates <- qr_fu_dates[qr_fu_dates >= as.Date("2021-01-15")] %>% format("%Y-%m-%d") %>% paste(collapse = " ")

mrt_fu_nights <- c(3, 4)
mrt_fu_hotels <- c(1, 2, 3, 5)
mrt_fu_dates  <- (the_date_max - c(86*controller + 85, 86*controller)) %>% format("%Y-%m-%d") %>% paste(collapse = " ")

fsh_fu_nights <- c(3, 4)
fsh_fu_hotels <- c(1)
fsh_fu_dates  <- (the_date_max - c(86*controller + 85, 86*controller)) %>% format("%Y-%m-%d") %>% paste(collapse = " ")

# main pgm (no need to change below) --------------------------------------

logger("updating currency exchange rate through ECB")
get_exchange_rate()


# follow-up series --------------------------------------------------------

logger("Worker started MRT01 fu", mrt_fu_dates)
start_mrt01(mrt_fu_dates, mrt_fu_nights, mrt_fu_hotels)
save_data_mrt01(paste0("mrt01_", gsub("-", "", Sys.Date())))
suppressMessages(serve_mrt01())

logger("Worker started FSH01 fu", mrt_fu_dates)
start_fsh01(fsh_fu_dates, fsh_fu_nights, fsh_fu_hotels)
save_data_fsh01(paste0("fsh01_", gsub("-", "", Sys.Date())))

logger("Worker started QR01 fu", qr_fu_dates)
start_qr01(qr_fu_deps, qr_fu_dests, qr_fu_dates, qr_the_days)
save_data_qr01(paste0("qr01_", gsub("-", "", Sys.Date())))
suppressMessages(serve_qr01())


# all completed -----------------------------------------------------------

show_tasktime()
cat(rep("=", 39), "\n", rep("=", 39), "\n")
