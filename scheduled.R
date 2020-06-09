###########################################################################
###### This is a scheduled script, the scope is dependent on the date #####
###########################################################################

suppressMessages({
  setwd("/home/yanpan/getIt")
  source("./src/qr01.R")
  source("./src/mrt01.R")
})

controller <- as.numeric(Sys.Date()) %% 4 + 1
def_break  <- 133:199 # overrides src/utilities
def_n_jobs <- 8


# parameter definition ----------------------------------------------------

qr_the_days   <- 18 # below 354 = 360 -7 + 1 (comes from contronller)
qr_date_max   <- Sys.Date() + 354 - qr_the_days - controller # fixed, interval is 15 days
qr_date_max   <- format(qr_date_max, "%Y-%m-%d")
qr_loop_deps  <- "CPH TLL ARN HEL OSL"
qr_loop_dests <- "SYD CBR ADL MEL"

mrt_date_max    <- Sys.Date() + 355 - 7
mrt_date_max    <- format(mrt_date_max, "%Y-%m-%d")
mrt_loop_nights <- c(3, 4, 7)
mrt_loop_hotels <- c(1, 2, 3, 4, 5)

## controlled seq
qr_oooo_dates  <- c("2020-12-08", 
                    "2020-12-23", 
                    "2021-01-07", 
                    "2021-01-22")
mrt_oooo_dates <- c("2020-12-01 2020-12-15", 
                    "2020-12-16 2020-12-31", 
                    "2021-01-01 2021-01-15", 
                    "2021-01-16 2021-01-31")


# max possible follow up --------------------------------------------------

cat(get_time_str(), "Worker started for QR01 (catch-up) ===\n")
start_qr01 (qr_loop_deps, qr_loop_dests, qr_date_max, qr_the_days)

cat(get_time_str(), "Worker started for MRT01 (catch-up) ===\n")
start_mrt01(mrt_date_max, mrt_loop_nights, mrt_loop_hotels)


# defined series (not daily) ----------------------------------------------

cat(get_time_str(), "Worker started for QR01 with controller", controller, "===\n")
#start_qr01 (qr_loop_deps, qr_loop_dests, qr_oooo_dates[controller], qr_the_days)

cat(get_time_str(),"Worker started for MRT01 with controller", controller, "===\n")
#start_mrt01(mrt_oooo_dates[controller], mrt_loop_nights, mrt_loop_hotels)


