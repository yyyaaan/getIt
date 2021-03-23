# sub-schedule, called by scheduled.R

setwd("/home/yanpan/getIt")
suppressMessages(source("./src/ay01.R"))

def_interval <<- 30:60
def_int_long <<- 3999:6999
controller   <<- as.numeric(Sys.Date()) %% 4

start_ay01_special("Tahiti", controller, 999)
save_data_ay01(paste0("ay01_", gsub("-", "", Sys.Date())))
