library(rvest)
source("shared_url_builder.R")
library(tidyverse); library(plotly) #only needed for tabluating

# Start the Batch ---------------------------------------------------------

def_jssrc <- readLines('./src/qr01.js')
def_break <- 199:299
n_jobs <- 6

start_batch <- function(loop_deps, loop_dests, loop_dates){
  
  loop_deps <- "CPH TLL ARN HEL OSL" #  WAW GOT
  loop_dests<- "SYD CBR ADL MEL" #  TYO SIN HKG
  loop_dates<- "2021-05-09"
  
  ## cross join parameters, then shuffle rows
  param_set <- expand.grid(
    desta = loop_deps  %>% strsplit(" ") %>% unlist(),
    destb = loop_dests %>% strsplit(" ") %>% unlist(),
    destc = loop_dests %>% strsplit(" ") %>% unlist(),
    destd = loop_deps %>% strsplit(" ") %>% unlist(),
    ddate = loop_dates %>% strsplit(" ") %>% unlist(),
    stringsAsFactors = FALSE)
  
  ## run in shuffled order, pause randomly
  job_counter   <- 0
  job_submitted <- 0
  for(i in sample(1:nrow(param_set))){
    
    the_url = flight_url_qatar_2legs(
      dates = c(as.Date(param_set$ddate[i]), as.Date(param_set$ddate[i]) + 18),
      dests = c(param_set$desta[i], param_set$destb[i], param_set$destc[i], param_set$destd[i]))
    the_out = Sys.time() %>% as.character() %>% gsub("-|:| ", "", .) %>% paste0("qr01_", .)
    
    ### submit job
    util_runjs(c(the_url, the_out) , def_jssrc)
    Sys.sleep(1)
    
    ### parallel job control
    job_counter   <- job_counter + 1
    job_submitted <- job_submitted + 1
    
    if(job_counter >= n_jobs){
      job_counter <- 0
      cat("Submitted", job_submitted, "Remaining", nrow(param_set) - job_submitted, "\n")
      Sys.sleep(sample(def_break, 1))
      system("rm ./cache/tmp_runjs_*")      
    }
  }
  Sys.sleep(sample(def_break, 1))
  system("rm ./cache/tmp_runjs_*")
}

start_retry <- function(wildcard = "*.txt"){
  failed_urls <- list.files("./cache/", wildcard, full.names = T) %>% detect_failed()
  if(length(failed_urls) == 0) {cat("all ok! nothing to retry :-) \n"); return()}
  
  job_counter   <- 0
  job_submitted <- 0
  
  for(the_url in sample(failed_urls)){
    the_out = Sys.time() %>% as.character() %>% gsub("-|:| ", "", .) %>% paste0("qr01_", .)
    ### submit job
    util_runjs(c(the_url, the_out) , def_jssrc)
    Sys.sleep(1)
    
    ### parallel job control
    job_counter   <- job_counter + 1
    job_submitted <- job_submitted + 1
    
    if(job_counter >= n_jobs){
      job_counter <- 0
      cat("Submitted", job_submitted, "Remaining", length(failed_urls) - job_submitted, "\n")
      Sys.sleep(sample(def_break, 1))
    }
  }
}

start_retry()