library(magrittr)

## the global parameter can be overriden as needed
def_break  <- 199:299
def_n_jobs <- 8


# system analyzer ---------------------------------------------------------

get_time_str <- function(){
  format(Sys.time(), tz="Europe/Helsinki",usetz=FALSE)
}

show_exetime <- function(){
  
  all_pp <- list.files("./cache", "*.pp", full.names = TRUE)
  
  exetime <- double()
  keyname <- character()
  for(pp in all_pp){
    
    the_lines <- readLines(pp, warn = FALSE)
    
    ## skip if error
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
  
  df <- data.frame(keyname, exetime)
  
  boxplot(exetime ~ keyname, df)
  for(keys in unique(keyname)) {
    cat(keys, "\n")
    print(summary(df$exetime[df$keyname == keys]))
  }
}

# currency exchange -------------------------------------------------------

get_exchange_rate <- function(){
  ecbxml <- tryCatch(
    readLines("https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml", warn = FALSE),
    error = function(e) {readLines('./cache/cached_eurofxref.xml'); print("using cached")})
  
  ecbxml <- grep("Cube currency", ecbxml, value = TRUE) %>% gsub("[^A-Z|0-9|\\.]", "", .) 
  data.frame(ccy = substr(ecbxml, 2,4), rate = as.numeric(substr(ecbxml, 5, 99))) %>%
    rbind(data.frame(ccy  = c("EUR", "FJD", "XPF"), 
                     rate = c(1.0, 2.4725, 119.3317))) 
}


# post scriptes: file management ------------------------------------------

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

archive_files <- function(wildcard, freeup = FALSE){
  system("rm ./cache/tmp_runjs_*")
  system("rm ./cache/*.png")
  if(freeup) system("rm ./cache/removed/*")
  
  # wildcard <- "qr01_20200603"
  sprintf("zip ./cache/archives/%s.zip ./cache/%s*", wildcard, wildcard) %>% system()
  sprintf( "rm ./cache/%s*", wildcard) %>% system()
}


# node js tool ------------------------------------------------------------

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
  cat("node", out_path, "submitted\r")
}

start_batch <- function(urls, jssrc, file_init = "noname"){
  ## outname is decided upon jssrc
  ## shuffled running order
  
  job_counter <- job_submitted <- 0

  for(the_url in sample(urls)){
    
    the_out = Sys.time() %>% as.character() %>% gsub("-|:| ", "", .) %>% paste0(file_init, "_", .)
    
    ### submit job
    util_runjs(c(the_url, the_out) , jssrc)
    Sys.sleep(1)
    
    ### parallel job control
    job_counter   <- job_counter + 1
    job_submitted <- job_submitted + 1
    
    if(job_counter >= def_n_jobs){
      job_counter <- 0
      cat(get_time_str(), "Nodes submitted", job_submitted, "Remaining", length(urls) - job_submitted, "     \n")
      Sys.sleep(sample(def_break, 1))
      system("rm ./cache/tmp_runjs_*")      
    }
  }
  
  cat(get_time_str(), "Job completed.========= ========= =========\n")
  Sys.sleep(sample(def_break, 1))
  system("rm ./cache/tmp_runjs_*")
}

start_retry <- function(wildcard, jssrc){
  ## wildcard must include initials to configure correct output name "qr01_*"
  
  failed_urls <- list.files("./cache/", wildcard, full.names = T) %>% detect_failed()
  if(length(failed_urls) == 0) {cat("all ok! nothing to retry :-) \n"); return()}
  cat(get_time_str(), "Retry failed jobs. Total to retry", length(failed_urls), "\n")

  file_initial  <- strsplit(wildcard, "_")[[1]][1]
  job_counter   <- 0
  job_submitted <- 0
  
  for(the_url in sample(failed_urls)){
    the_out = Sys.time() %>% as.character() %>% gsub("-|:| ", "", .) %>% paste0(file_initial, "_", .)
    ### submit job
    util_runjs(c(the_url, the_out) , jssrc)
    Sys.sleep(1)
    
    ### parallel job control
    job_counter   <- job_counter + 1
    job_submitted <- job_submitted + 1
    
    if(job_counter >= def_n_jobs){
      job_counter <- 0
      cat(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "Nodes submitted", job_submitted, "Remaining", length(failed_urls) - job_submitted, "\n")
      Sys.sleep(sample(def_break, 1))
      system("rm ./cache/tmp_runjs_*")      
    }
  }
  
  Sys.sleep(sample(def_break, 1))
  system("rm ./cache/tmp_runjs_*")
  cat(get_time_str(), "Retries done ========= ========= =========\n")
}
