# system("/usr/lib/R/bin/Rscript '/home/yanpan/getIt/scheduled.R'  >> '/home/yanpan/getIt/scheduled.log' 2>&1", wait = FALSE)

.libPaths(c("/usr/local/lib/R/site-library", .libPaths()))
setwd("/home/yanpan/getIt")
suppressMessages(source("./src/utilities.R"))


# job distribution --------------------------------------------------------

### by server (currently 3 servers)
this_server <- Sys.info()['nodename']
job_acr <- "us"
job_ay  <- "us"
job_fsh <- "fi"
job_hlt <- "us"
job_mrt <- "fi"
job_qr  <- "csc"


### by date (currently a 4-day loop)
controller   <<- as.numeric(Sys.Date()) %% 4
def_interval <<- 20:35



# parameters --------------------------------------------------------------

the_date_max  <- Sys.Date() + 355 - 7

qr_the_days <- 18 
qr_date_max <- Sys.Date() + 353 - qr_the_days - controller # fixed, interval is 15 days
qr_fu_deps  <- "HEL OSL AMS"
qr_fu_dests <- "SYD CBR MEL"
qr_fu_dates <- seq(qr_date_max - 77*controller, length = 11, by = "-7 days") 
qr_fu_dates <- qr_fu_dates[qr_fu_dates >= as.Date("2021-01-15")] %>% format("%Y-%m-%d") %>% paste(collapse = " ")

mrt_fu_nights <- c(3, 4)
mrt_fu_hotels <- c(1, 2, 3, 5)
mrt_fu_dates  <- (the_date_max - c(86*controller + 85, 86*controller)) %>% format("%Y-%m-%d") %>% paste(collapse = " ")

fsh_fu_nights <- c(3, 4)
fsh_fu_hotels <- c(1)
fsh_fu_dates  <- (the_date_max - c(86*controller + 85, 86*controller)) %>% format("%Y-%m-%d") %>% paste(collapse = " ")

hlt_fu_nights <- c(3, 4)
hlt_fu_hotels <- c(1, 2)
hlt_fu_dates  <- (the_date_max - c(86*controller + 85, 86*controller)) %>% format("%Y-%m-%d") %>% paste(collapse = " ")

acr_fu_nights <- c(3, 4)
acr_fu_hotels <- c(1, 2)
acr_fu_dates  <- (the_date_max - c(86*controller + 85, 86*controller)) %>% format("%Y-%m-%d") %>% paste(collapse = " ")



# main jobs ---------------------------------------------------------------

### exchange rate should be fetched everywhere
get_exchange_rate()

if(grepl(job_mrt, this_server)){
  suppressMessages(source("./src/mrt01.R"))
  logger("START MRT01", mrt_fu_dates)
  # start_mrt01(mrt_fu_dates, mrt_fu_nights, mrt_fu_hotels)
  # save_data_mrt01(paste0("mrt01_", gsub("-", "", Sys.Date())))
  # suppressMessages(serve_mrt01())
}


if(grepl(job_fsh, this_server)){
  suppressMessages(source("./src/fsh01.R"))
  logger("START FSH01", fsh_fu_dates)
  # start_fsh01(fsh_fu_dates, fsh_fu_nights, fsh_fu_hotels)
  # save_data_fsh01(paste0("fsh01_", gsub("-", "", Sys.Date())))
}


if(grepl(job_qr, this_server)){
  suppressMessages(source("./src/qr01.R"))
  logger("START QR01", qr_fu_dates)
  # start_qr01(qr_fu_deps, qr_fu_dests, qr_fu_dates, qr_the_days)
  # save_data_qr01(paste0("qr01_", gsub("-", "", Sys.Date())))
}

if(grepl(job_acr, this_server)){
  suppressMessages(source("./src/acr01.R"))
  logger("START ACR01", acr_fu_dates)
  # start_acr01(acr_fu_dates, acr_fu_nights, acr_fu_hotels)
  # save_data_acr01(paste0("acr01_", gsub("-", "", Sys.Date())))
}

if(grepl(job_hlt, this_server)){
  suppressMessages(source("./src/hlt01.R"))
  logger("START HLT01", hlt_fu_dates)
  # start_hlt01(hlt_fu_dates, hlt_fu_nights, hlt_fu_hotels)
  # save_data_hlt01(paste0("hlt01_", gsub("-", "", Sys.Date())))
}

if(grepl(job_ay, this_server)){
  suppressMessages(source("./src/ay01.R"))
  def_interval <<- 69:129
  logger("START AY01 sp", controller )
  # start_ay01_special("Tahiti", controller)
  # save_data_ay01(paste0("ay01_", gsub("-", "", Sys.Date())))
}


# all completed -----------------------------------------------------------

show_tasktime()
cat(rep("=", 39), "\n", rep("=", 39), "\n")
