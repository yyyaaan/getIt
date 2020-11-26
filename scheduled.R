###########################################################################
###### This is a scheduled script, the scope is dependent on the date #####
###########################################################################
# system("/usr/lib/R/bin/Rscript '/home/yanpan/getIt/scheduled.R'  >> '/home/yanpan/getIt/scheduled.log' 2>&1", wait = FALSE)

## 2020-09-30: QR&MRT tracking series replaced from Christmas 2020 to Summer 2021
##             QR destination removed ADL added AMS


suppressMessages({
  .libPaths(c("/usr/local/lib/R/site-library", .libPaths()))
  setwd("/home/yanpan/getIt")
  source("./src/qr01.R")
  source("./src/mrt01.R")
  source("./src/serving.R")
})

### sequence are supposed to be completed once in a 4-day run
### one may repeat parameters to increase frequency
controller <- as.numeric(Sys.Date()) %% 4
def_interval <<- 20:35
qr_the_days<- 18 

# param def for tracking ---------------------------------------------------

qr_loop_deps  <- "CPH TLL ARN HEL OSL"
qr_loop_deps2 <- "TLL ARN HEL OSL"
qr_loop_dests <- "SYD CBR ADL MEL"
qr_oooo_dates <- c("2021-06-23", 
                   "2021-07-08", 
                   "2021-07-23",
                   "2021-08-07")[controller + 1]

mrt_loop_nights <- c(3, 4)
mrt_loop_hotels <- c(2, 3, 4, 5)
mrt_oooo_dates  <- c("2021-06-16 2021-06-30", 
                     "2021-07-01 2021-07-15", 
                     "2021-07-16 2021-07-31", 
                     "2021-08-01 2021-08-15")[controller + 1]


# param def for follow up -------------------------------------------------

qr_date_max <- Sys.Date() + 353 - qr_the_days - controller # fixed, interval is 15 days
qr_fu_deps  <- "HEL OSL TLL AMS"
qr_fu_dests <- "SYD CBR MEL"
qr_fu_dates <- seq(qr_date_max - 75*controller, length = 5, by = "-15 days") 
### updated to ensure earliest of 2020-11-01
qr_fu_dates <- qr_fu_dates[qr_fu_dates >= as.Date("2020-12-15")] %>% format("%Y-%m-%d") %>% paste(collapse = " ")

mrt_date_max  <- Sys.Date() + 355 - 7
mrt_fu_nights <- c(4, 7)
mrt_fu_hotels <- c(1)
mrt_fu_dates  <- (mrt_date_max - c(86*controller + 85, 86*controller)) %>% format("%Y-%m-%d") %>% paste(collapse = " ")


# main pgm (no need to change below) --------------------------------------

logger("updating currency exchange rate through ECB")
get_exchange_rate()


# follow-up series --------------------------------------------------------

logger("Worker started QR01 fu", qr_fu_dates)
start_qr01(qr_fu_deps, qr_fu_dests, qr_fu_dates, qr_the_days)
save_data_qr01(paste0("qr01_", gsub("-", "", Sys.Date())))
suppressMessages(serve_qr01())

logger("Worker started MRT01 fu", mrt_fu_dates)
start_mrt01(mrt_fu_dates, mrt_fu_nights, mrt_fu_hotels)
save_data_mrt01(paste0("mrt01_", gsub("-", "", Sys.Date())))
 

# defined series (not daily) ----------------------------------------------
 

logger("Worker started for QR01 ctrl", qr_oooo_dates)
start_qr01 (qr_loop_deps, qr_loop_dests, qr_oooo_dates, qr_the_days)
save_data_qr01(paste0("qr01_", gsub("-", "", Sys.Date())))

## lower the frequency to save resource for others
## def_interval <<- 35:75


logger("Worker started for MRT01 ctrl", mrt_oooo_dates)
start_mrt01(mrt_oooo_dates, mrt_loop_nights, mrt_loop_hotels)
save_data_mrt01(paste0("mrt01_", gsub("-", "", Sys.Date())))

suppressMessages(serve_qr01())
suppressMessages(serve_mrt01())

# all completed -----------------------------------------------------------
 
show_tasktime()
cat(rep("=", 39), "\n", rep("=", 39), "\n")
