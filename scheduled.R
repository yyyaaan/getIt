###########################################################################
###########################################################################
###### This is a scheduled script, the scope is dependent on the date #####
###########################################################################
# system("/usr/lib/R/bin/Rscript '/home/yanpan/getIt/scheduled.R'  >> '/home/yanpan/getIt/scheduled.log' 2>&1", wait = FALSE)

suppressMessages({
  setwd("/home/yanpan/getIt")
  source("./src/qr01.R")
  source("./src/mrt01.R")
})

### sequence are supposed to be completed once in a 4-day run
### one may repeat parameters to increase frequency
controller <- as.numeric(Sys.Date()) %% 4
def_interval <<- 20:35
qr_the_days<- 18 

# param def for traking ---------------------------------------------------

qr_loop_deps  <- "CPH TLL ARN HEL OSL"
qr_loop_deps2 <- "TLL ARN HEL OSL"
qr_loop_dests <- "SYD CBR ADL MEL"
qr_oooo_dates <- c("2020-12-08", 
                   "2020-12-23", 
                   "2021-01-07", 
                   "2021-01-22")[controller + 1]

mrt_loop_nights <- c(3, 4)
mrt_loop_hotels <- c(2, 3, 4, 5)
mrt_oooo_dates  <- c("2020-12-01 2020-12-15", 
                     "2020-12-16 2020-12-31", 
                     "2021-01-01 2021-01-15", 
                     "2021-01-16 2021-01-31")[controller + 1]


# param def for follow up -------------------------------------------------

qr_date_max <- Sys.Date() + 353 - qr_the_days - controller # fixed, interval is 15 days
qr_special  <- (Sys.Date() + 360 - qr_the_days) %>% format("%Y-%m-%d")
qr_fu_deps  <- "HEL OSL TLL"
qr_fu_dests <- "SYD CBR ADL MEL"
qr_fu_dates <- seq(qr_date_max - 75*controller, length = 5, by = "-15 days") %>% format("%Y-%m-%d") %>% paste(collapse = " ")

mrt_date_max  <- Sys.Date() + 355 - 7
mrt_fu_nights <- c(4, 7)
mrt_fu_hotels <- c(1)
mrt_fu_dates  <- (mrt_date_max - c(86*controller + 85, 86*controller)) %>% format("%Y-%m-%d") %>% paste(collapse = " ")


# main pgm (no need to change below) --------------------------------------

logger("updating currency exchange rate through ECB")
get_exchange_rate()

# # special topic
# logger("Worker started for QR01 (special topic)", qr_special)
# start_qr01(qr_loop_deps2, qr_loop_dests, qr_special, qr_the_days)
# save_data_qr01(paste0("qr01_", gsub("-", "", Sys.Date())))


# follow-up series --------------------------------------------------------

logger("Worker started for QR01 follow-up", qr_fu_dates)
start_qr01(qr_fu_deps, qr_fu_dests, qr_fu_dates, qr_the_days)
save_data_qr01(paste0("qr01_", gsub("-", "", Sys.Date())))


logger("Worker started for MRT01 follow-up", mrt_fu_dates)
start_mrt01(mrt_fu_dates, mrt_fu_nights, mrt_fu_hotels)
save_data_mrt01(paste0("mrt01_", gsub("-", "", Sys.Date())))
 

# defined series (not daily) ----------------------------------------------
 

logger("Worker started for QR01 with controller", qr_oooo_dates)
start_qr01 (qr_loop_deps, qr_loop_dests, qr_oooo_dates, qr_the_days)
save_data_qr01(paste0("qr01_", gsub("-", "", Sys.Date())))


## lower the frequency to save resource for others
def_interval <<- 35:75


logger("Worker started for MRT01 with controller", mrt_oooo_dates)
start_mrt01(mrt_oooo_dates, mrt_loop_nights, mrt_loop_hotels)
save_data_mrt01(paste0("mrt01_", gsub("-", "", Sys.Date())))

serve_mrt_results()


# all completed -----------------------------------------------------------
 
logger("scheduled daily tasks completed")
show_tasktime()
cat(rep("=", 39), "\n", rep("=", 39), "\n")
