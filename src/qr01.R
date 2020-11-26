source("shared_url_builder.R")
source("./src/utilities.R")

start_qr01 <- function(loop_deps  = "CPH TLL ARN HEL OSL", 
                       loop_dests = "SYD CBR ADL MEL", 
                       loop_dates = "2021-05-10",
                       the_days   = 18){
  
  ## cross join parameters, then shuffle rows
  param_set <- expand.grid(
    desta = loop_deps  %>% strsplit(" ") %>% unlist(),
    destb = loop_dests %>% strsplit(" ") %>% unlist(),
    destc = loop_dests %>% strsplit(" ") %>% unlist(),
    destd = loop_deps  %>% strsplit(" ") %>% unlist(),
    ddate = loop_dates %>% strsplit(" ") %>% unlist(),
    stringsAsFactors = FALSE)
  
  ## build url
  urls <- character()
  for(i in sample(1:nrow(param_set))){
    urls <- c(urls, flight_url_qatar_2legs(
      dates = c(as.Date(param_set$ddate[i]), as.Date(param_set$ddate[i]) + the_days),
      dests = c(param_set$desta[i], param_set$destb[i], param_set$destc[i], param_set$destd[i])))
  }
  
  ## call batch
  start_batch(urls, jssrc = './src/qr01.js', file_init = 'qr01')
  
  ## retry 1
  file_pattern = Sys.Date() %>% gsub("-", "", .) %>% paste0("qr01_", .)
  start_retry(wildcard = file_pattern, jssrc = './src/qr01.js')
  
  ## remove possible unavailability. needed due to coronavirus -- speed concern
  special_skip <- list.files("./cache/", file_pattern, full.names = T) %>% lapply(function(x){
    pp <- readLines(x, warn = FALSE)
    ff <- str_detect(pp[length(pp)], "outbound_tripDetails1")
    if(ff) system(paste("mv", x, "./cache/removed"))
    return(ifelse(ff, 1, 0))
  })
  logger("Skipped", special_skip %>% unlist() %>% sum(), "that are very likely to be sold out")
  
  ## retry 2 and 3
  start_retry(wildcard = file_pattern, jssrc = './src/qr01.js')
  start_retry(wildcard = file_pattern, jssrc = './src/qr01.js')
}


get_data_qr01 <- function(cached_txts){
  ## cached_txts <- list.files("./cache/", paste0("qr01_", gsub("-", "", Sys.Date())), full.names = T)
  ## cached_txts <- list.files("./cache/", "qr01_", full.names = T)
  
  ## shorthand functions
  html_trimmed <- . %>% html_text %>% gsub("\\\t|\\\n|  ", "", .) %>% gsub("\u00A0", " ", .)
  html_str_rm  <- . %>% gsub("Select (Out|In)bound flightfor", "", .) %>% gsub("Select Flight (1|2)for", "", .) %>% gsub("[ ]+to[ ]+", " ", .) %>% str_trim()
  auto_date    <- . %>% paste(year(today())) %>% dmy() %>% ifelse(. < today(), . + years(1), .) %>% as_date()
  
  out_df <- data.frame(); i <- 0
  
  ## mutate on whole dataset is separated outside for-loop
  for(the_file in cached_txts){
    
    the_html  <- read_html(the_file)
    
    ## get data
    i <- i+1
    the_time  <- the_html %>% html_node("timestamp") %>% html_text()
    the_combo <- the_html %>% html_nodes(".destHeading") %>% html_trimmed() %>% html_str_rm() %>% paste(collapse = "|")
    two_routes<- the_html %>% html_nodes(".md-details")
    
    for(the_route in two_routes){
      out_df <- rbind(out_df, data.frame(
        flight= the_route %>% html_nodes(".destHeading") %>% html_trimmed() %>% html_str_rm(),
        ddate = the_route %>% html_nodes(".cdate") %>% html_trimmed(),
        price = the_route %>% html_nodes(".taxInMonthCalFnSizeAmount") %>% html_trimmed(),
        ccy   = the_route %>% html_nodes(".taxInMonthCalFnSizeCurCode") %>% html_trimmed(),
        inout = the_route %>% html_node(".destHeading") %>% html_trimmed(),
        ts    = the_time,
        route = the_combo) %>%
          filter(str_length(ddate) > 2, str_length(price) > 2))
    }
    
    if(i %% 50 == 0) cat("Processed", i, "files\r")
  }
  
  cat("Completed. Total", i, "files.\r")
  

  df <- out_df %>% 
    filter(price != "") %>% 
    left_join(readRDS("./results/latest_ccy.rds"), by = "ccy") %>%
    mutate(inout  = ifelse(str_detect(inout, "Outbound|Flight 1"), "Outbound", "Inbound"),
           from   = str_split(flight, " ", simplify = T)[,1],
           to     = str_split(flight, " ", simplify = T)[,2],
           ddate  = ddate %>% auto_date(),
           eur    = as.numeric(price)/rate,
           tss    = ts %>% ymd_hms() %>% date()) %>%
    select(route, inout, flight, from, to, ddate, eur, price, ccy, tss, ts)
  return(df)
}


save_data_qr01 <- function(file_pattern_qr01){
  # file_pattern_qr01 <- paste0("qr01_", gsub("-", "", Sys.Date()))
  # file_pattern_qr01 <- "qr01_"
  
  df_qr01 <- list.files("./cache/", file_pattern_qr01, full.names = T) %>% get_data_qr01()
  saveRDS(df_qr01, paste0("./results/", file_pattern_qr01, format(Sys.time(), "_%H%M"), ".rds"))
  archive_files(file_pattern_qr01)
  util_bq_upload(df_qr01, table_name = "QR01")
}


