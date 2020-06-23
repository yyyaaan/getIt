source("./src/utilities.R")

url_dest <<- c(
  # St.Regis Bora Bora
  paste0('&countryName=PF&destinationAddress.city=Bora+Bora',
         '&destinationAddress.longitude=-151.696515',
         '&destinationAddress.latitude=-16.486419'),
  # Le Meridien Bora Bora
  paste0('&countryName=PF&destinationAddress.city=Bora+Bora',
         '&destinationAddress.longitude=-151.736641',
         '&destinationAddress.latitude=-16.497324'),
  # Le Meridien Ile des Pins
  paste0('&destinationAddress.city=Isle+of+Pines%2C+New+Caledonia'),
  # Fiji Marriot Resort Momi Bay
  paste0('&destinationAddress.city=Fiji'),
  # Sheraton Resort & Spa, Tokoriki Island, Fiji
  paste0('&destinationAddress.city=Tokoriki+Island%2C+Fiji')
  # dashboard need to be updated if hotel list changes
)


# Start the Batch ---------------------------------------------------------

start_mrt01 <- function(range_dates = "2020-12-15 2021-01-15", #"2021-05-01 2021-05-09",
                        loop_nights = c(3, 4, 7),
                        loop_hotels = c(1, 2, 3, 4, 5)){
  
  date_range <- range_dates %>% strsplit(" ") %>% unlist() %>% as.Date()
  param_set <- expand.grid(
    checkin = seq(date_range[1], date_range[2], "days"),
    nights  = loop_nights,
    hotel   = loop_hotels,
    stringsAsFactors = FALSE
  )
  param_set$checkout = param_set$checkin + param_set$nights

  ## build url
  urls <- character()
  for(i in sample(1:nrow(param_set))){
    urls <- c(urls, 
              paste0('https://www.marriott.com/search/default.mi?roomCount=1&numAdultsPerRoom=2',
                     '&fromDate=', format.Date(param_set$checkin [i], "%m/%d/%Y"),
                     '&toDate='  , format.Date(param_set$checkout[i], "%m/%d/%Y"),
                     url_dest[param_set$hotel[i]]))
  }
  
  ## call batch
  start_batch(urls, jssrc = './src/mrt01.js', file_init = 'mrt01')
  
  ## retry
  file_pattern = Sys.Date() %>% gsub("-", "", .) %>% paste0("mrt01_", .)
  start_retry(wildcard = file_pattern, jssrc = './src/mrt01.js')
  start_retry(wildcard = file_pattern, jssrc = './src/mrt01.js')
  start_retry(wildcard = file_pattern, jssrc = './src/mrt01.js')
}


# Reporting functions -----------------------------------------------------

get_data_mrt01 <- function(cached_txts){
  # cached_txts <- list.files("./cache/", "mrt01_\\d*.pp", full.names = T)
  df <- data.frame(); i <- 0; j <- 0;
  
  for(the_file in cached_txts){
    
    the_html <- read_html(the_file)
    the_flag <- the_html %>% html_nodes("flag") %>% html_text()
    if(length(the_flag) && the_flag == "Sold Out"){
      j <- j + 1
      next()
    } 
    
    name <- the_html %>% html_node("h1 > a > span") %>% html_text() 
    ccy  <- the_html %>% 
      html_node('div.without-widget-flow.l-rate-display.rate-display.m-pricing-block.l-s-col-2.l-m-col-4.l-l-col-6.l-pos-relative.l-align-flex-items > div > div > span') %>% 
      html_text() %>% 
      substr(., regexpr("[A-Z]{3}", .)[1], regexpr("[A-Z]{3}", .)[1] + 2)
    cico <- the_html %>% 
      html_nodes("#staydates > a > div.t-line-height-l.is-visible.is-visible-l") %>% 
      html_text() %>% 
      strsplit(' â\u0080\u0095 ')
    the_time  <- the_html %>% html_node("timestamp") %>% html_text()
    
    all_rooms <- the_html %>% html_nodes("div.room-rate-results.rate-type.t-box-shadow")
    for(the_room in all_rooms){
      df <- rbind(df, data.frame(
        hotel     = name,
        check_in  = cico[[1]][1],
        check_out = cico[[1]][2],
        room_type = the_room %>% html_node('h3.l-margin-bottom-none') %>% html_text(),
        rate_type = the_room %>% html_nodes('div.l-rate-container') %>% html_nodes('h3') %>% html_text(),
        #rate_text= the_room %>% html_nodes('div.rate-price') %>% html_text(),
        rate_avg  = the_room %>% html_nodes('div.l-rate-inner-container') %>% html_attr('data-totalpricebeforetax'),
        rate_sum  = the_room %>% html_nodes('div.l-rate-inner-container') %>% html_attr('data-totalprice'),
        ccy       = ccy,
        ts        = the_time)) 
    }
    
    i <- i + 1
    if(i %% 50 == 0) cat("Processed", i, "files ( Sold out", j, ")\r")
  }
  
  cat("Completed. Total", i+j, "files (fetched", i, "unavailable", j, ") \n")
  
  df_final <- df %>% 
    left_join(readRDS("./results/latest_ccy.rds"), by = "ccy") %>%
    mutate(check_in  = substr(df$check_in,  6, 99) %>% mdy(),
           check_out = substr(df$check_out, 6, 99) %>% mdy(),
           rate_sum  = as.numeric(rate_sum),
           tss    = ts %>% ymd_hms() %>% date())  %>%
    mutate(nights = as.numeric(check_out - check_in)) %>%
    mutate(eur_sum = rate_sum / rate,
           eur_avg = eur_sum / nights) %>%
    select(hotel, room_type, rate_type, check_in, nights, check_out, eur_avg, eur_sum, rate_sum, ccy, tss, ts)

  return(df_final)
}

serve_mrt_results <- function(n_recent = 10, min_date = as.Date("2020-12-01")){
  
  dfs <- list.files("./results/", "mrt01", full.names = TRUE) %>% 
    sort(decreasing = TRUE) %>% 
    .[1:n_recent] %>% 
    as.list() %>% 
    lapply(function(x) x %>% 
             readRDS() %>%
             filter(check_in >= min_date)) 
  
  df_all <- union_all(dfs[[1]], dfs[[2]])
  for (i in 3:length(dfs)) {
    df_all <- union_all(df_all, dfs[[i]])
  }
  
  ### determing latest records
  df <- df_all %>% 
    group_by(hotel, room_type, rate_type, check_in, check_out) %>%
    summarise(ts = max(ts)) %>%
    left_join(df_all) 
  
  remove(df_all, dfs)
  
  the_df <- df %>% 
    group_by(hotel, check_in, nights) %>%
    summarize(`Daily rate (median 50% €)` = ceiling(median(eur_avg)),
              `Daily rate (lower 25% €)` = ceiling(quantile(eur_avg, 0.25)),
              `Daily rate (upper 75% €)` = ceiling(quantile(eur_avg, 0.75))) %>%
    pivot_longer(cols = c("Daily rate (median 50% €)", "Daily rate (lower 25% €)", "Daily rate (upper 75% €)")) %>%
    mutate(nights = paste("Stay for", nights, "nights"), ` ` = name) 

  # plots median by hotel, facet by nights ----------------------------------
    
  get_p <- function(the_df) the_df %>%
    ggplot(aes(check_in, value, color = ` `)) +
    geom_line() + 
    facet_grid(nights ~ hotel) +
    theme_minimal() +
    scale_color_brewer(palette = "Pastel1") +
    theme(legend.position = "top") + xlab("") + ylab("") 
  
  p1 <- the_df %>% filter(!str_detect(tolower(hotel), "regis")) %>% get_p()
  p2 <- the_df %>% filter( str_detect(tolower(hotel), "regis")) %>% get_p() + 
    labs(caption = paste("Latest available", max(df$check_in),
                         "| Refreshed at", substr(max(df$ts), 1, 16)))
  
  ggsave("/home/yanpan/dashboard/www/mrtplot.png", 
         plot = gridExtra::grid.arrange(p1, p2),
         width = 12, height = 8, dpi = 220)

}

save_data_mrt01 <- function(file_pattern_mrt01){
  df_mrt01 <- list.files("./cache/", file_pattern_mrt01, full.names = T) %>% get_data_mrt01()
  saveRDS(df_mrt01, paste0("./results/", file_pattern_mrt01, format(Sys.time(), "_%H%M"), ".rds"))
  archive_files(file_pattern_mrt01)
  util_bq_upload(df_mrt01, table_name = "MRT01")
}

