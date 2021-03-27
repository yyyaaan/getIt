library(tidyverse)
library(lubridate)
library(rvest)
library(DT)
library(jsonlite)
library(bigrquery)
library(googleAuthR)

## the global parameter can be overridden as needed
def_break  <- 199:299
def_n_jobs <- 6
def_interval <- 20:40
def_int_long <- 1200:3000


get_time_str <- function(){
  format(Sys.time(), tz="Europe/Helsinki",usetz=FALSE)
}


# currency exchange -------------------------------------------------------

get_exchange_rate <- function(){
  ecbxml <- tryCatch(
    readLines("https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml", warn = FALSE),
    error = function(e) return(c("stop")))
  
  if(ecbxml[1] == "stop") return()
  
  ecbxml <- grep("Cube currency", ecbxml, value = TRUE) %>% gsub("[^A-Z|0-9|\\.]", "", .) 
  data.frame(ccy = substr(ecbxml, 2,4), rate = as.numeric(substr(ecbxml, 5, 99))) %>%
    rbind(data.frame(ccy  = c("EUR", "FJD", "XPF"), 
                     rate = c(1.0, 2.4725, 119.3317))) %>%
    saveRDS(file = "./results/latest_ccy.rds")
}




# key node tools ----------------------------------------------------------

util_runjs  <- function(params, jssrc, wait = FALSE){
  ## jssrc must be path
  ## params = c(req_url, req_name)
  
  jsLines <- readLines(jssrc) # when path read lines
  out_path = sprintf("./cache/tmp_runjs_%f", as.numeric(Sys.time()))
  
  jsLines[1] <- params %>%
    paste0("'", ., "'", collapse = ", ") %>%
    paste("const params = [", ., "];")
  
  writeLines(jsLines, out_path)
  system(paste("node", out_path), wait = wait)
  # cat("node", out_path, "submitted\r")
}


start_batch <- function(urls, jssrc, file_init = "noname", verbose = TRUE, long_pause = FALSE){
  ## outname is decided upon jssrc
  ## shuffled running order
  
  job_submitted <- 0
  
  if(verbose) cat("Info: the interval is set to be", min(def_interval), "-", max(def_interval), "seconds\n")
  ## determining skipping using to_skip.rds
  if(file.exists("./cache/to_skip.rds")){
    tmp <- length(urls)
    urls <- setdiff(urls, readRDS("./cache/to_skip.rds"))
    cat("Important:", tmp-length(urls), "will be skipped per defined by to_skip\n")
  }
  
  for(the_url in sample(urls)){
    
    the_out = Sys.time() %>% as.character() %>% gsub("-|:| ", "", .) %>% paste0(file_init, "_", .)
    the_ptn = Sys.Date() %>% format("_%Y%m%d") %>% paste0(file_init, .)
    
    ### submit job
    util_runjs(c(the_url, the_out) , jssrc)
    job_submitted <- job_submitted + 1
    
    ### waiting and tracing
    Sys.sleep(sample(def_interval, 1))
    ### extra long breaking if needed
    if(long_pause && (job_submitted %% 10 == 0)){
      the_pause <- sample(def_int_long, 1)
      cat(get_time_str(), "Nodes submission PAUSED for", the_pause, "seconds")
      Sys.sleep(the_pause)
    }
    
    if(job_submitted %% 10 == 0){
      job_completed <- list.files("./cache/", the_ptn) %>% length()
      
      cat(get_time_str(), 
          "Nodes submitted", job_submitted, 
          ifelse(verbose, paste("Completed", job_completed), "-"),
          "Remaining", length(urls) - job_submitted, "\n")
      
      system("rm ./cache/tmp_runjs_*")      
    }
    
  }
  
  Sys.sleep(sample(def_interval, 1))
  if(verbose) cat(get_time_str(), "Job completed.========= ========= =========\n")
  if(length(list.files("./cache/", "tmp_runjs"))) system("rm ./cache/tmp_runjs_*")
  if(verbose) show_exetime()
}


start_retry <- function(wildcard, jssrc){
  ## wildcard must include initials to configure correct output name "qr01_*"
  
  failed_urls <- list.files("./cache/", wildcard, full.names = T) %>% detect_failed()
  if(length(failed_urls) == 0) {cat("all ok! nothing to retry :-) \n"); return()}
  cat(get_time_str(), "Retry failed jobs. Total to retry", length(failed_urls), "\n")
  
  file_initial  <- strsplit(wildcard, "_")[[1]][1]
  start_batch(failed_urls, jssrc, file_initial, FALSE)
}


# bigquery upload ---------------------------------------------------------


util_bq_upload <- function(data_to_upload, table_name, dataset_name = "Explore", silent = FALSE){
  bq_deauth()
  bq_auth(path = "/home/yanpan/.gcp.json")
  
  bq_table(project = "yyyaaannn",
           dataset = dataset_name,
           table   = table_name  ) %>%
    bq_table_upload(fields = as_bq_fields(data_to_upload),
                    values = data_to_upload,
                    create_disposition = "CREATE_IF_NEEDED",
                    write_disposition  = "WRITE_APPEND")
  
  if(!silent) logger("BigQuery Upload Completed for", table_name)
}



# Messaging & Logging -----------------------------------------------------


logger <- function(..., log_name = "getIt"){
  
  text = paste(..., collapse = " ")
  if(grepl("start", tolower(text))) cat("=\n")
  
  cat(get_time_str(), text, ifelse(grepl("completed", tolower(text)),"=========\n", "\n"))
  line_to_user(text)
  # SEVERITY in DEFAULT, DEBUG, INFO, NOTICE, WARNING, ERROR, CRITICAL, ALERT, EMERGENCY.
  # paste("/snap/bin/gcloud logging write", log_name, "'", text, "' --severity=INFO") %>% system()
}



line_to_user <- function(text, to = 'U4de6a435823ee64a0b9254783921216a'){
  
  text <- Sys.info()['nodename'] %>% str_remove_all("yan|server|01") %>% paste(text)
  
  system2("curl",
          args = c("-s", "-v", "-X",
                   "POST https://api.line.me/v2/bot/message/push",
                   "-H", "'Content-Type: application/json'",
                   "-H", sprintf("'Authorization: Bearer %s'",
                                 readLines('/home/yanpan/.token_line')[1]),
                   "-d", sprintf("'{\"to\": \"%s\", \"messages\": [{\"type\": \"text\", \"text\": \"%s\"}]}'",
                                 to, text)),
          stdout = FALSE, 
          stderr = FALSE)
}

line_richmsg <- function(title, df, var_card, var_rows, debug = FALSE,
                         to = 'U4de6a435823ee64a0b9254783921216a'){
  
  flex_box_text <- function(text = "sep", size = "xs", wrap = TRUE, color = "#aaaaaa"){
    list(type = "text", text = text, size = size, color = color, wrap = wrap)
  }
  
  all_cards <- list()
  
  for(card_title in df %>% pull(var_card) %>% unique()){
    
    all_rows <- list(flex_box_text(card_title, color = "#333333"))
    
    for(each_row in df %>% filter(!!sym(var_card) == card_title) %>% pull(var_rows))
      all_rows[[length(all_rows)+1]] <- flex_box_text(each_row)
    
    this_card <- list(type = "bubble", size = "micro", 
                      body = list(type = "box", layout = "vertical",
                                  contents = all_rows))
    
    all_cards[[length(all_cards)+1]] <- this_card
  }
  
  flx <- list(type = "carousel", contents = all_cards)
  if(debug) return(toJSON(flx, auto_unbox = T))
  
  msg <- list(to = to, messages = list(
    list(type = "flex", altText = title, contents = flx)))
  
  
  system2("curl",
          args = c("-s", "-v", "-X",
                   "POST https://api.line.me/v2/bot/message/push",
                   "-H", "'Content-Type: application/json'",
                   "-H", sprintf("'Authorization: Bearer %s'", readLines('/home/yanpan/.token_line')[1]),
                   # "-d", sprintf("'{\"to\": \"%s\", \"messages\": [%s]}'", to, toJSON(msg))
                   "-d", sprintf("'%s'", toJSON(msg, auto_unbox = T))
          ),
          stdout = F, 
          stderr = F)
}






# post scriptes: file management ------------------------------------------

completed_urls <- function(today_only = TRUE){
  
  if(today_only)  all_files <- list.files("./cache/", format(Sys.Date(), "%Y%m%d"), full.names = TRUE)
  if(!today_only) all_files <- list.files("./cache/", ".pp", full.names = TRUE)
                      
  completed_urls <- character()
  for(the_file in all_files){
    completed_urls <- read_html(the_file) %>% html_node("qurl") %>% html_text() %>% c(completed_urls)
  }
  
  saveRDS(completed_urls, file = "./cache/to_skip.rds")
  # saveRDS(c("nothing"), file = "./cache/to_skip.rds")
}



detect_failed <- function(file_list, move_file = TRUE){
  #return qurl in second line of file
  
  error_url <- sapply(file_list, function(x) {
    lines <- readLines(x, warn = FALSE)[1:2]
    flag  <- substr(lines[1], 1, 5) == "error"
    if(flag && move_file) system(paste("mv", x, "./cache/removed"))
    return(ifelse(flag, lines[2], ""))
  })
  
  error_url <- error_url[error_url != ""]
  
  gsub("<[\\/]?\\w+>", "", error_url) #remove html tag
}



archive_files <- function(wildcard, freeup = TRUE){

    suppressMessages({
    if(length(list.files("./cache/", "tmp_runjs"))) system("rm ./cache/tmp_runjs_*")
    system("rm ./cache/*.png")
    if(freeup) system("rm ./cache/removed/*")
    
    ## zip default to adding and updating
    sprintf("zip -q ./cache/archives/%s.zip ./cache/%s*", wildcard, wildcard) %>% system()
    sprintf( "rm ./cache/%s*", wildcard) %>% system()
  })
}



# system analyzer ---------------------------------------------------------


show_exetime <- function(by_key = FALSE){
  
  all_pp <- list.files("./cache", "*.pp", full.names = TRUE)
  
  exetime <- double()
  keyname <- character()
  for(pp in all_pp){
    
    the_lines <- readLines(pp, warn = FALSE)
    
    ## skip if error
    if(length(the_lines) == 0) next()
    if(substr(the_lines[1], 1, 5) == "error") next()
    
    pp %>% strsplit("/") %>% unlist() %>% 
      .[length(.)] %>% substr(1, 5) %>%
      c(keyname) -> keyname
    
    the_lines %>%
      grep("exetime", ., value = TRUE) %>% 
      strsplit("<exetime>") %>% unlist() %>% 
      .[length(.)] %>%
      strsplit('</exetime>') %>% unlist() %>%
      as.numeric(.[1]) %>%
      c(exetime) -> exetime
    
  }
  
  if(by_key){
    for(keys in unique(keyname)) {
      cat("Average running time for group", keys, "\n")
      print(summary(exetime[keyname == keys]))
    }    
  } else {
    cat("Average Puppeteer-NodeJS running time in seconds\n")
    print(summary(exetime))
  }
}


show_tasktime <- function(log_file = "./scheduled.log", clean_log = TRUE){
  logs <- readLines(log_file)
  
  key_words <- "PAUSED|nodes submitted|processed|cannot|nothing|NULL|retry|log|Info|There were|1st Qu|running time|Task summary"
  
  if(clean_log){
    rid <- grep(key_words, logs, ignore.case = TRUE)
    writeLines(logs[-rid], log_file)
  }
}


