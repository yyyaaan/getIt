### work in progress
source("./src/utilities.R")

url_fsh_dest <<- c(
  "BOB462"
)


# Start the Batch ---------------------------------------------------------

start_fsh01 <- function(range_dates = "2021-11-21 2021-12-01",
                        loop_nights = c(3, 4),
                        loop_hotels = c(1)){
  
  date_range <- range_dates %>% strsplit(" ") %>% unlist() %>% as.Date()
  param_set <- expand.grid(
    checkin = seq(date_range[1], date_range[2], "days"),
    nights  = loop_nights,
    code    = url_fsh_dest[loop_hotels],
    stringsAsFactors = FALSE
  )
  param_set$checkout = param_set$checkin + param_set$nights
  
  ## build url
  urls <- character()
  for(i in sample(1:nrow(param_set))){
    urls <- c(urls, 
              sprintf("https://reservations.fourseasons.com/choose-your-room?hotelCode=%s&checkIn=%s&checkOut=%s&adults=2&children=0&promoCode=&ratePlanCode=&roomAmadeusCode=&_charset_=UTF-8",
                      param_set$code[i],
                      param_set$checkin [i] %>% format.Date("%Y-%m-%d"),
                      param_set$checkout[i] %>% format.Date("%Y-%m-%d")))
  }
  
  ## call batch
  start_batch(urls, jssrc = './src/fsh01.js', file_init = 'fsh01')
  
  ## retry
  file_pattern = Sys.Date() %>% gsub("-", "", .) %>% paste0("fsh01_", .)
  start_retry(wildcard = file_pattern, jssrc = './src/fsh01.js')
  start_retry(wildcard = file_pattern, jssrc = './src/fsh01.js')
  start_retry(wildcard = file_pattern, jssrc = './src/fsh01.js')
}





# Reporting functions -----------------------------------------------------

get_data_fsh01 <- function(cached_txts){
  # cached_txts <- list.files("./cache/", "fsh01_\\d*.pp", full.names = T)
  # the_file <- "./cache/fsh_tmp.pp"
  df <- data.frame(); i <- 0; j <- 0;
  
  # helper functions
  html_number <- . %>% html_text() %>% str_replace_all("[^\\d]", "") %>% as.numeric()
  auto_date   <- . %>% paste(year(today())) %>% mdy() %>% ifelse(. < today(), . + years(1), .) %>% as_date()
  html_trim <- . %>% html_text() %>% str_replace_all("\\n|  ", "")
  
  
  for(the_file in cached_txts){
    
    the_html <- read_html(the_file)
    the_flag <- the_html %>% html_nodes("flag") %>% html_text()
    
    if (the_html %>% html_text() %>% str_sub(1, 5) == "error") the_flag = "Sold Out"
    if(the_html %>% html_nodes("[data-e2e='undefinedText']") %>% html_text() %>% length())
      the_flag <- "Sold Out"
    
    if(length(the_flag) && the_flag == "Sold Out"){
      j <- j + 1
      next()
    }
    
    cico  <- the_html %>% html_node("span.search-summary-date") %>% html_text() %>%
      str_replace_all("202\\d|\\n", "") %>% str_extract_all(".{3} \\d+") %>%
      unlist() %>% auto_date()
    
    df <- rbind(df, data.frame(
      hotel     = the_html %>% html_node("span.search-summary-item") %>% html_text() %>% paste("Four Seasons", .),
      check_in  = cico[1],
      check_out = cico[2],
      room_type = the_html %>% html_nodes(".room-item-title") %>% html_trim(),
      rate_type = "Best Rate Advertised",
      rate_avg  = the_html %>% html_nodes(".visible-xs > .nightly-rate > .fullprice") %>% html_number(),
      ccy       = the_html %>% html_node(".fullprice") %>% html_text() %>% str_extract("[A-Z]{3}"),
      ts        = the_html %>% html_node("timestamp") %>% html_text())) 
    
    i <- i + 1
    if(i %% 50 == 0) cat("Processed", i, "files ( Sold out", j, ")\r")
  }
  
  cat("Completed. Total", i+j, "files (fetched", i, "unavailable", j, ") \n")
  
  df_final <- df %>% 
    left_join(readRDS("./results/latest_ccy.rds"), by = "ccy") %>%
    mutate(nights  = as.numeric(check_out - check_in),
           eur_avg = rate_avg / rate,
           tss     = ts %>% ymd_hms() %>% date())  %>%
    select(hotel, room_type, rate_type, check_in, nights, check_out, eur_avg, ccy, tss, ts)
  
  return(df_final)
}

save_data_fsh01 <- function(file_pattern_fsh01){
  # file_pattern_fsh01 <- paste0("fsh01_", gsub("-", "", Sys.Date()))
  # file_pattern_fsh01 <- "fsh01_"
  df_fsh01 <- list.files("./cache/", file_pattern_fsh01, full.names = T) %>% get_data_fsh01()
  
  # send HLT key figures
  df_fsh01 %>%
    mutate(wk = isoweek(check_in), rm = paste(hotel, "(pre-tax)"),
           check_in = floor_date(check_in, "week", 1),
           week_start = format(check_in, "%d%b"))  %>%
    group_by(nights, rm, check_in, week_start) %>%
    summarise(best_daily = min(eur_avg) %>% ceiling(), .groups = "drop") %>%
    pivot_wider(id_cols = c('rm', 'week_start'), names_from = nights, values_from = best_daily) %>%
    unite("out", rev(colnames(.)[-1]), sep = " ") %>%
    line_richmsg("Four Seasons pricing (pretax)", ., "rm", "out", debug = FALSE)
  
  # continue the routine
  saveRDS(df_fsh01, paste0("./results/", file_pattern_fsh01, format(Sys.time(), "_%H%M"), ".rds"))
  archive_files(file_pattern_fsh01)
  util_bq_upload(df_fsh01, table_name = "FSH01", silent = T)
}

