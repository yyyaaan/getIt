source("shared_url_builder.R")
source("./src/utilities.R")


url_acr_dest <<- c(
  "9924", # Pullman Maldives 
  "0566", # Sofitel Moorea
  "5930"  # Mercure Nadi
)



# Start the Batch ---------------------------------------------------------

start_acr01 <- function(range_dates = "2021-02-01 2021-02-15", #"2021-05-01 2021-05-09",
                        loop_nights = c(4, 7),
                        loop_hotels = c(1, 2)){
  
  date_range <- range_dates %>% strsplit(" ") %>% unlist() %>% as.Date()
  param_set <- expand.grid(
    checkin = seq(date_range[1], date_range[2], "days"),
    nights  = loop_nights,
    hotel   = loop_hotels,
    stringsAsFactors = FALSE
  )
  
  ## build url
  urls <- character()
  for(i in sample(1:nrow(param_set))){
    urls <- c(urls, 
              sprintf("https://all.accor.com/ssr/app/accor/rates/%s/index.en.shtml?dateIn=%s&nights=%d&compositions=2&stayplus=false",
                      url_acr_dest[param_set$hotel[i]], 
                      format.Date(param_set$checkin [i], "%Y-%m-%d"),
                      param_set$nights[i]))
  }
  
  ## call batch
  start_batch(urls, jssrc = './src/acr01.js', file_init = 'acr01')
  
  ## retry
  file_pattern = Sys.Date() %>% gsub("-", "", .) %>% paste0("acr01_", .)
  start_retry(wildcard = file_pattern, jssrc = './src/acr01.js')
  start_retry(wildcard = file_pattern, jssrc = './src/acr01.js')
  start_retry(wildcard = file_pattern, jssrc = './src/acr01.js')
}


get_data_acr01 <- function(cached_txts){
  # cached_txts <- list.files("./cache/", "acr01_\\d*.pp", full.names = T)
  # cached_txts <- list.files("./cache/", "acr.*pp", full.names = T)
  df <- data.frame(); i <- 0; j <- 0;
  
  # helper functions
  html_trim   <- . %>% html_text() %>% str_replace_all("\\n|  ", "")
  html_number <- . %>% html_text() %>% str_extract_all("\\d{1,5}(,|.)\\d{1,2}") %>% unlist() %>% str_replace(",", ".") %>% as.numeric() 
  
  for(the_file in cached_txts){
    
    the_html <- read_html(the_file)
    the_flag <- the_html %>% html_nodes("flag") %>% html_text()
    
    if (the_html %>% html_text() %>% str_sub(1, 5) == "error") the_flag = "Sold Out"
    
    if(length(the_flag) && the_flag == "Sold Out"){
      j <- j + 1
      next()
    }
    
    ts <- the_html %>% html_node("timestamp") %>% html_text()
    hotel <- the_html %>% html_node("h3.basket-hotel-info__title") %>% html_trim()
    cico <- the_html %>% html_node(".basket-hotel-info > .sr-only") %>% html_text() %>%
      str_replace_all("From ", "") %>% str_split(" to ") %>% unlist() %>% mdy()
    ccy <- the_html %>% html_node(".booking-price__symbol") %>% html_text() %>%
      str_detect(., "\\u0082|€") %>% ifelse("EUR", "USD")

    # sometimes it give total sometime average, adjust accordingly
    rate_factor <- the_html %>% html_node("div.room-info__composition") %>% 
      html_text() %>% str_detect("[A|a]verage") %>% ifelse(cico[2] - cico[1],1)
    
    # loop for every room
    for (the_room in the_html %>% html_nodes(".list-complete-item")){
      df <- rbind(df, data.frame(
        hotel     = hotel,
        check_in  = cico[1],
        check_out = cico[2],
        room_type = the_room %>% html_node(".room-info__title") %>% html_trim(),
        rate_type = the_room %>% html_nodes(".offer__options") %>% html_trim(),
        rate_sum_pre = (the_room %>% html_nodes(".offer__price") %>% html_number()) * rate_factor,
        rate_sum_tax = the_room %>% html_nodes(".pricing-details__taxes") %>% html_number(),
        ccy = ccy,
        ts  = ts)) 
    }
    
    i <- i + 1
    if(i %% 50 == 0) cat("Processed", i, "files ( Sold out", j, ")\r")
  }
  
  
  cat("Completed. Total", i+j, "files (fetched", i, "unavailable", j, ") \n")
  
  df_final <- df %>% 
    left_join(readRDS("./results/latest_ccy.rds"), by = "ccy") %>%
    mutate(nights  = as.numeric(check_out - check_in),
           rate_sum= rate_sum_pre + rate_sum_tax,
           eur_sum = rate_sum / rate,
           eur_avg = rate_sum / nights,
           tss     = ts %>% ymd_hms() %>% date())  %>%
    select(hotel, room_type, rate_type, check_in, nights, check_out, eur_avg, eur_sum, rate_sum_pre, rate_sum_tax, ccy, tss, ts)
  
  return(df_final)
}

save_data_acr01 <- function(file_pattern_acr01){
  # file_pattern_acr01 <- paste0("acr01_", gsub("-", "", Sys.Date()))
  df_acr01 <- list.files("./cache/", file_pattern_acr01, full.names = T) %>% get_data_acr01()
  
  # send the latest pricing
  df_acr01 %>% 
    add_row(df_acr01 %>% mutate(room_type = "ANY")) %>%
    filter(str_detect(hotel, "(?i)Moorea"), str_detect(rate_type, "(?i)savor")) %>%
    mutate(wk = isoweek(check_in), 
           rm = str_extract(room_type, "[a-zA-Z ]*"),
           week_start = floor_date(check_in, "week", 1) %>% format("%d%b"))  %>% 
    group_by(nights, rm, week_start) %>%
    summarise(best_daily = min(eur_avg) %>% ceiling(),
              .groups = "drop") %>%
    pivot_wider(id_cols = c('rm', 'week_start'), names_from = nights, values_from = best_daily) %>%
    unite("out", rev(colnames(.)[-1]), sep = " ") %>%
    line_richmsg("Accor latest prices", ., "rm", "out")
  
  # continue the routine
  saveRDS(df_acr01, paste0("./results/", file_pattern_acr01, format(Sys.time(), "_%H%M"), ".rds"))
  archive_files(file_pattern_acr01)
  util_bq_upload(df_acr01, table_name = "ACR01", silent = T)
}
