### work in progress
source("./src/utilities.R")

url_hlt_dest <<- c(
  "PPTMLHI", # Moorea
  "PPTBNCI"  # Bora Bora Conrad
)


# Start the Batch ---------------------------------------------------------

start_hlt01 <- function(range_dates = "2021-04-05 2021-04-11",
                        loop_nights = c(3, 4),
                        loop_hotels = c(1, 2)){
  
  date_range <- range_dates %>% strsplit(" ") %>% unlist() %>% as.Date()
  param_set <- expand.grid(
    checkin = seq(date_range[1], date_range[2], "days"),
    nights  = loop_nights,
    code    = url_hlt_dest[loop_hotels],
    stringsAsFactors = FALSE
  )
  param_set$checkout = param_set$checkin + param_set$nights
  
  ## build url
  urls <- character()
  for(i in sample(1:nrow(param_set))){
    urls <- c(urls, 
              sprintf("https://www.hilton.com/en/book/reservation/rooms/?ctyhocn=%s&arrivalDate=%s&departureDate=%s&room1NumAdults=2",
                      param_set$code[i],
                      param_set$checkin [i] %>% format.Date("%Y-%m-%d"),
                      param_set$checkout[i] %>% format.Date("%Y-%m-%d")))
  }
  
  ## call batch
  start_batch(urls, jssrc = './src/hlt01.js', file_init = 'hlt01')
  
  ## retry
  file_pattern = Sys.Date() %>% gsub("-", "", .) %>% paste0("hlt01_", .)
  start_retry(wildcard = file_pattern, jssrc = './src/hlt01.js')
  start_retry(wildcard = file_pattern, jssrc = './src/hlt01.js')
  start_retry(wildcard = file_pattern, jssrc = './src/hlt01.js')
}





# Reporting functions -----------------------------------------------------

get_data_hlt01 <- function(cached_txts){
  # cached_txts <- list.files("./cache/", "hlt01_\\d*.pp", full.names = T)
  # the_file <- "./cache/hlt_tmp.pp"
  df <- data.frame(); i <- 0; j <- 0;
  
  # helper functions
  html_number <- . %>% html_text() %>% str_extract("(\\d+,\\d+)|(\\d+)") %>% str_replace(",", "") %>% as.numeric()
  auto_date   <- . %>% paste(year(today())) %>% dmy() %>% ifelse(. < today(), . + years(1), .) %>% as_date()
  
  
  for(the_file in cached_txts){
    
    the_html <- read_html(the_file)
    the_flag <- the_html %>% html_nodes("flag") %>% html_text()
    
    if (the_html %>% html_text() %>% str_sub(1, 5) == "error") the_flag = "Sold Out"
    
    if(length(the_flag) && the_flag == "Sold Out"){
      j <- j + 1
      next()
    }
    
    cico  <- the_html %>% html_node("[data-e2e='stayDates']") %>% html_text()  %>% 
      str_replace_all("202\\d", "") %>% str_extract_all("\\d+ .{3}") %>% 
      unlist() %>% auto_date()
    
    df <- rbind(df, data.frame(
      hotel     = the_html %>% html_node("[data-e2e='hotelExpander']") %>% html_text(),
      check_in  = cico[1],
      check_out = cico[2],
      room_type = the_html %>% html_nodes("[data-e2e='roomTypeName']") %>% html_text(),
      rate_type = "Best Rate Advertised",
      rate_avg  = the_html %>% html_nodes("[data-e2e='moreRatesButton']") %>% html_number(),
      ccy       = the_html %>% html_node("[data-e2e='currencyDropDownSelected']") %>% html_text() %>% str_sub(1,3),
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

save_data_hlt01 <- function(file_pattern_hlt01){
  # file_pattern_hlt01 <- paste0("hlt01_", gsub("-", "", Sys.Date()))
  # file_pattern_hlt01 <- "hlt01_"
  df_hlt01 <- list.files("./cache/", file_pattern_hlt01, full.names = T) %>% get_data_hlt01()

  # send HLT key figures
  df_hlt01 %>% 
    mutate(wk = isoweek(check_in), rm = hotel)  %>% 
    group_by(nights, rm, wk) %>%
    summarise(best_daily = min(eur_avg) %>% ceiling(),
              week_start = min(check_in) %>% format("%d%b"),
              .groups = "drop") %>%
    pivot_wider(id_cols = c('rm', 'week_start'), names_from = nights, values_from = best_daily) %>%
    unite("out", rev(colnames(.)[-1]), sep = " ") %>%
    line_richmsg("Hilton pricing (pretax)", ., "rm", "out")
  
  # continue the routine
  saveRDS(df_hlt01, paste0("./results/", file_pattern_hlt01, format(Sys.time(), "_%H%M"), ".rds"))
  archive_files(file_pattern_hlt01)
  util_bq_upload(df_hlt01, table_name = "HLT01", silent = T)
}

