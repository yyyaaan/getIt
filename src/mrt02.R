source("./src/utilities.R")




# Start the Batch ---------------------------------------------------------

start_mrt02 <- function(){
  
  urls <- c(
     "https://www.marriott.com/search/default.mi?roomCount=1&numAdultsPerRoom=2&fromDate=12/03/2021&toDate=12/04/2021&destinationAddress.city=Las+Vegas%2C+NV%2C+USA"
    ,"https://www.marriott.com/search/default.mi?roomCount=1&numAdultsPerRoom=2&fromDate=12/02/2021&toDate=12/03/2021&destinationAddress.city=Las+Vegas%2C+NV%2C+USA"
  )

  ## call batch
  start_batch(urls, jssrc = './src/mrt02.js', file_init = 'mrt02')
  
  ## retry
  file_pattern = Sys.Date() %>% gsub("-", "", .) %>% paste0("mrt02_", .)
  start_retry(wildcard = file_pattern, jssrc = './src/mrt02.js')
  start_retry(wildcard = file_pattern, jssrc = './src/mrt02.js')
}


# Reporting functions -----------------------------------------------------

get_data_mrt02 <- function(cached_txts){
  # cached_txts <- list.files("./cache/", "mrt02_\\d*.pp", full.names = T)
  # the_file <- "./cache/mrt_tmp.pp"
  df <- data.frame()

  for(the_file in cached_txts){
    the_html <- read_html(the_file)
    
    hotels <- the_html %>% html_nodes("div.js-property-record-item")
    ccy <- hotels %>% html_nodes(".t-price-btn") %>% html_text() %>% max() %>% str_extract("[A-Z]{3}")
    cico <- the_html %>% html_node("#staydates > a > span") %>% html_text() # %>% str_split("-") 
    the_time  <- the_html %>% html_node("timestamp") %>% html_text()
    
    for(the_hotel in hotels){
      df <- tryCatch(
        {rbind(df, data.frame(
          hotel     = the_hotel %>% html_nodes("h2") %>% html_text() %>% str_trim() ,
          dates     = cico,
          ccy       = ccy,
          rate      = the_hotel %>% html_nodes(".t-price") %>% html_text() %>% .[1] %>% as.numeric(),
          rate_type = "Lowest",
          ts        = the_time))},
        error = function(e){
          message(e)
          print(the_file)
          return(df)
        }
      )
      
    }
  }
  

  return(df)
}


save_data_mrt02 <- function(file_pattern_mrt02){
  # file_pattern_mrt02 <- paste0("mrt02_", gsub("-", "", Sys.Date()))
  df_mrt02 <- list.files("./cache/", file_pattern_mrt02, full.names = T) %>% get_data_mrt02()
  
  # summary of two dates
  df_short <- df_mrt02 %>% mutate(check_in = str_sub(dates, 6, 10)) %>% select(hotel, rate, check_in)
  check_ins <- unique(df_short$check_in) %>% sort()
  
  df_short %>%
    filter(check_in == check_ins[1]) %>%
    left_join(df_short %>% filter(check_in == check_ins[2]), by="hotel") %>%
    select(hotel, rate.x, rate.y) %>%
    arrange(rate.y) %>%
    print()
    # %>% unite("out", rev(colnames(.)[-1]), sep = " ") %>%
    # line_richmsg("Las Vegas Marriotts", ., "hotel", "out", debug = FALSE)
    
  # continue the routine
  saveRDS(df_mrt02, paste0("./results/", file_pattern_mrt02, format(Sys.time(), "_%H%M"), ".rds"))
  archive_files(file_pattern_mrt02)
}



run_mrt02 <- function(){
  start_mrt02()
  save_data_mrt02(paste0("mrt02_", gsub("-", "", Sys.Date())))
}

