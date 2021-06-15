# system("Rscript '/home/yanpan/getIt/scheduled.R'  >> '/home/yanpan/getIt/scheduled.log' 2>&1", wait = FALSE)
# rstudioapi::jobRunScript("./src/ovi01.R", name = "Etuovi", workingDir = ".")

.libPaths(c("/usr/local/lib/R/site-library", .libPaths()))
setwd("/home/yanpan/getIt")
suppressMessages({source("./src/utilities.R"); source("./src/ay01.R")})



# job distribution --------------------------------------------------------

### by server (currently 3 servers), AY is separated
this_server <- Sys.info()['nodename']
job_acr <- "us"
job_hlt <- "us"
job_dog <- "fi"
job_mrt <- "fi"
job_mgr <- "fi"
job_ovi <- "fi"
job_qr  <- "csc"
job_fsh <- "csc"

### by date (currently a 4-day loop)
controller   <<- as.numeric(Sys.Date()) %% 4
def_interval <<- 20:35
def_int_long <<- 1200:3000



# parameters --------------------------------------------------------------

the_date_max  <- Sys.Date() + 355 - 7

qr_the_days <- 18 
qr_date_max <- Sys.Date() + 353 - qr_the_days - controller # fixed, interval is 15 days
qr_fu_deps  <- "HEL OSL AMS"
qr_fu_dests <- "SYD CBR MEL"
qr_fu_dates <- seq(qr_date_max - 77*controller, length = 11, by = "-7 days") 
qr_fu_dates <- qr_fu_dates %>% format("%Y-%m-%d") %>% paste(collapse = " ")

# AY range is relatively fixed during 4 days, as the AY function handles the days
ay_fu_dates <- seq(qr_date_max - 231, qr_date_max, "days")

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



# recursive job def -------------------------------------------------------

### will run before every other task
before_each_task <- function(the_id){
  #logger("START AY batch", the_id, "of 8", send_line = FALSE)
  #start_ay01_special("Tahiti", controller, batch_n=the_id, max_batch=8, ay_fu_dates)
}

after_all_tasks <- function(){
  #the_id <- 7
  #if(grepl("fi", this_server)) the_id <- 5
  #if(grepl("us", this_server)) the_id <- 6
  #logger("START AY batch", the_id, "of 8", send_line = FALSE)
  #start_ay01_special("Tahiti", controller, batch_n=the_id, max_batch=8, ay_fu_dates)
  #save_data_ay01(paste0("ay01_", gsub("-", "", Sys.Date())))
}


# main jobs ---------------------------------------------------------------

### exchange rate should be fetched everywhere
get_exchange_rate()
### push yesterday's AY results
if(grepl("fi", this_server)) message_fromBQ_ay01()

if(grepl(job_mrt, this_server)){
  before_each_task(0)
  suppressMessages(source("./src/mrt01.R"))
  logger("START MRT01", mrt_fu_dates, send_line = FALSE)
  start_mrt01(mrt_fu_dates, mrt_fu_nights, mrt_fu_hotels)
  save_data_mrt01(paste0("mrt01_", gsub("-", "", Sys.Date())))
  suppressMessages({source("./src/serving.R"); serve_mrt01()})
}


if(grepl(job_fsh, this_server)){
  before_each_task(1)
  suppressMessages(source("./src/fsh01.R"))
  logger("START FSH01", fsh_fu_dates, send_line = FALSE)
  start_fsh01(fsh_fu_dates, fsh_fu_nights, fsh_fu_hotels)
  save_data_fsh01(paste0("fsh01_", gsub("-", "", Sys.Date())))
}


if(grepl(job_qr, this_server)){
  before_each_task(2)
  suppressMessages(source("./src/qr01.R"))
  logger("START QR01", qr_fu_dates, send_line = FALSE)
  start_qr01(qr_fu_deps, qr_fu_dests, qr_fu_dates, qr_the_days)
  save_data_qr01(paste0("qr01_", gsub("-", "", Sys.Date())))
}

if(grepl(job_acr, this_server)){
  before_each_task(3)
  suppressMessages(source("./src/acr01.R"))
  logger("START ACR01", acr_fu_dates, send_line = FALSE)
  start_acr01(acr_fu_dates, acr_fu_nights, acr_fu_hotels)
  save_data_acr01(paste0("acr01_", gsub("-", "", Sys.Date())))
}

if(grepl(job_hlt, this_server)){
  before_each_task(4)
  suppressMessages(source("./src/hlt01.R"))
  logger("START HLT01", hlt_fu_dates, send_line = FALSE)
  start_hlt01(hlt_fu_dates, hlt_fu_nights, hlt_fu_hotels)
  save_data_hlt01(paste0("hlt01_", gsub("-", "", Sys.Date())))
}

after_all_tasks()


# all completed -----------------------------------------------------------

show_tasktime()
cat(rep("=", 39), "\n")

# small pieces and finalizing recursive task ------------------------------

#if(grepl(job_ovi, this_server)) source("./src/ovi01.R")
if(grepl(job_mgr, this_server)) line_to_user(system("node ./src/migri.js", intern = TRUE))
if(grepl(job_dog, this_server)) source("./src/s01.R")
if(grepl(job_dog, this_server)) source("./src/dog01.R")

# for(i in 1:10) system(paste("node ./src/vihta.js", i), wait = TRUE)