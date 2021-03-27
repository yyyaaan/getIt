source("shared_url_builder.R")
source("./src/utilities.R")

start_ay01_special <- function(keyword = "Tahiti", controller, batch_n=999, max_batch=8){
  
  if(tolower(keyword) == "tahiti"){
    
    date_range <- seq(as.Date("2021-05-31"), as.Date("2022-03-14"), "days")
    
    param_set <- expand.grid(desta = c("HEL"),
                             destb = c("PPT"),
                             destc = c("PPT"),
                             destd = c("HEL", "TLL"),
                             ddate = date_range,
                             rdate = date_range,
                             stringsAsFactors = FALSE) %>%
      filter(rdate-ddate > 9, rdate-ddate < 23,
             weekdays(ddate) %in% c("Tuesday", "Friday", "Sunday"), 
             weekdays(rdate) %in% c("Wednesday", "Saturday"))
    
    ## slice to 4-day
    size_day <- nrow(param_set)/4
    param_set <- param_set[1:size_day + controller * size_day, ]
    
    ## further slice to 3-batch
    if(batch_n != 999) param_set <- param_set %>% filter((row_number() %% max_batch == batch_n))
    
    ## build url
    urls <- character()
    for(i in sample(1:nrow(param_set))){
      urls <- c(urls, flight_url_finnair_any(
        dates = c(as.Date(param_set$ddate[i]), as.Date(param_set$rdate[i])),
        dests = c(param_set$desta[i], param_set$destb[i], param_set$destc[i], param_set$destd[i]),
        cabin = "E"))
    }
    
    ## call batch, here only 1 retry is performed
    start_batch(urls, jssrc = './src/ay01.js', file_init = 'ay01', long_pause = TRUE)
    file_pattern = Sys.Date() %>% gsub("-", "", .) %>% paste0("ay01_", .)
    start_retry(wildcard = file_pattern, jssrc = './src/ay01.js')
    
    return(paste("AY Tahiti completed for batch", batch_n))
  }
  
  return("No item found.")
}

start_ay01 <- function(loop_deps   = "CPH TLL ARN HEL OSL", 
                       loop_dests  = "SYD MEL", 
                       range_ddate = "2021-05-10 2021-05-12",
                       the_days    = 15,
                       skip_rule   = "" ){  #skip_rule:"(?i)arn (mel|syd) .{3} arn" "(?i)ARN.{9}ARN" 
  
  date_range <- range_ddate %>% strsplit(" ") %>% unlist() %>% as.Date()
  ## cross join parameters, then shuffle rows
  param_set <- expand.grid(
    desta = loop_deps  %>% strsplit(" ") %>% unlist(),
    destb = loop_dests %>% strsplit(" ") %>% unlist(),
    destc = loop_dests %>% strsplit(" ") %>% unlist(),
    destd = loop_deps  %>% strsplit(" ") %>% unlist(),
    ddate = seq(date_range[1], date_range[2], "days"),
    stringsAsFactors = FALSE
  )
  
  ## remove specified routes per skip_rule
  ## example skip_rule <- "(?i)arn (mel|syd) .{3} arn"
  if(length(skip_rule)) {
    param_set %>% filter(!str_detect(paste(desta, destb, destc, destd), skip_rule))
  }
  
  ## build url
  urls <- character()
  for(i in sample(1:nrow(param_set))){
    urls <- c(urls, flight_url_finnair_any(
      dates = c(as.Date(param_set$ddate[i]), as.Date(param_set$ddate[i]) + the_days),
      dests = c(param_set$desta[i], param_set$destb[i], param_set$destc[i], param_set$destd[i]),
      cabin = "E"))
  }
  
  ## call batch
  start_batch(urls, jssrc = './src/ay01.js', file_init = 'ay01')
  
  ## retry
  file_pattern = Sys.Date() %>% gsub("-", "", .) %>% paste0("ay01_", .)
  start_retry(wildcard = file_pattern, jssrc = './src/ay01.js')
  start_retry(wildcard = file_pattern, jssrc = './src/ay01.js')
  start_retry(wildcard = file_pattern, jssrc = './src/ay01.js')
}

get_data_ay01 <- function(cached_txts){
  
  # cached_txts <- list.files("./cache/", paste0("ay01_"), full.names = T)
  out_df <- data.frame(); i <- 0; j <- 0;
  
  ## mutate on whole dataset is separated outside for-loop
  for(the_file in cached_txts){
    
    the_html  <- read_html(the_file)
    the_flag <- the_html %>% html_node("h2") %>% html_text()
    
    if(is.na(the_flag) || !str_detect(the_flag, "bound")){
      j <- j + 1 # the ok ones should be "inbound" or "outbound"
      next()
    } 
    
    ## get data
    i <- i+1
    the_time  <- the_html %>% html_node("timestamp") %>% html_text()
    the_ccy   <- the_html %>% html_node("span.price-currency") %>% html_text()
    the_combo <- the_html %>% html_nodes("div.flight-header__info > div > h2") %>% 
      html_text() %>% gsub("\\nto|Inbound|Outbound", "", .) %>% gsub("\\n", "", .) %>%
      paste(collapse = "|")
    
    cells <- the_html %>% html_nodes("div.flight-cell.available") %>% html_attrs() %>% as.data.frame() %>% t() %>% as.data.frame()
    rownames(cells) <- 1:nrow(cells)
    
    out_df <- rbind(out_df, data.frame(
      route = the_combo,
      inout = cells$`data-bound-index`, 
      from  = cells$`data-bound-origin`, 
      to    = cells$`data-bound-destination`, 
      price = cells$`data-price`, 
      ddate = cells$`data-param-date`, 
      fare  = cells$`data-fare-family`,
      time1 = cells$`data-departure-time`,
      time2 = cells$`data-arrival-time`,
      cabin = cells$`data-cabins`,
      ccy   = the_ccy, 
      ts    = the_time))
    
    if(i %% 50 == 0) cat("Processed", i, "files ( NA", j, ")\r")
  }
  
  cat("Completed. Total", i+j, "files (fetched", i, "unavailable", j, ") \n")
  
  
  df <- out_df %>% 
    left_join(readRDS("./results/latest_ccy.rds"), by = "ccy") %>%
    mutate(inout  = ifelse(inout == "0", "Outbound", "Inbound"),
           time1  = as.numeric(time1),
           time2  = as.numeric(time2), 
           timedur= (time2- time1) / 6e4,
           flight = paste(from, (time1/1000) %>% as_datetime() %>% format("%H:%M"), 
                          "-", (time2/1000) %>% as_datetime() %>% format("%H:%M"), 
                          to, paste0(timedur %/% 60, "h", timedur %% 60, "min")),
           ddate  = ddate %>% ymd_hm() %>% as_date(),
           price  = as.numeric(price),
           cabin  = cabin %>% str_detect("B") %>% ifelse("B", "E"),
           eur    = price/rate,
           tss    = ts %>% ymd_hms() %>% date()) %>%
    select(route, inout, flight, cabin, from, to, ddate, fare, eur, price, ccy, tss, ts)
  
  return(df)
}

get_simple_ay01 <- function(df){
  
  # similar to QR01, only lowest value per day.
  df %>% 
    group_by(route, inout, from, to, cabin, ddate, tss, ts) %>%
    summarise(eur = min(eur), .groups = 'drop') %>% 
    mutate(flight = ifelse(str_detect(inout, "Out"), 
                           str_split_fixed(route, "\\|", 2)[1],
                           str_split_fixed(route, "\\|", 2)[2]))
  
}

serve_ay01 <- function(df){
  
  # input simple_ay01 (lowest by day)
  df_route <- df_day %>% 
    filter(inout == "Outbound") %>%
    left_join(df %>% filter(inout == "Inbound") %>% 
                select(route, rdate=ddate, eur2=eur, fare2=fare)) %>%
    filter(rdate >= ddate + 7) %>%
    ungroup() %>%
    distinct() %>%
    select(route, ddate, rdate, fare1 = fare, eur1 = eur, fare2, eur2, eur) %>%
    mutate(eur = eur1 + eur2) %>%
    arrange(eur, ddate, rdate)
  
  return(df_route)
  
}

save_data_ay01 <- function(file_pattern_ay01){
  # file_pattern_ay01 <- "ay01_"
  df_ay01 <- list.files("./cache/", file_pattern_ay01, full.names = T) %>% get_data_ay01()
  saveRDS(df_ay01, paste0("./results/", file_pattern_ay01, format(Sys.time(), "_%H%M"), ".rds"))
  archive_files(file_pattern_ay01)
  df_ay01_simple <- df_ay01 %>% get_simple_ay01()
  
  ### detailed AY in AY02, daily lowest in AY01
  util_bq_upload(df_ay01, table_name = "AY02", silent = T)
  util_bq_upload(df_ay01_simple, table_name = "AY01", silent = T)
  
  # send line notification
  df_ay01_simple %>% 
    filter(inout == "Outbound") %>%
    select(route, ddate, eur1 = eur, ts) %>%
    inner_join(df_ay01_simple %>%
                 filter(inout == "Inbound") %>%
                 select(route, rdate = ddate, eur2 = eur, ts),
               by = c("route", "ts")) %>%
    mutate(eur = eur1 + eur2,
           the_period = paste0("AY_PPT ", rdate-ddate, "days"),
           label = ifelse(str_detect(route, "Helsinki.*Helsinki"), "HEL", "ANY"),
           wk = ddate %>% format("%d%b")) %>% 
    add_row(., mutate(., the_period = "AY_PPT  any*", 
                      ddate = ddate %>% floor_date("week", 1),
                      wk =  ddate %>% format("w%d%b"))) %>%
    group_by(the_period, label, ddate, wk) %>%
    summarise(best_rates = min(eur) %>% ceiling(), .groups = "drop") %>%
    pivot_wider(id_cols = c('the_period', 'wk'), names_from = label, values_from = best_rates) %>%
    unite("out", sort(colnames(.)[-1]), sep = " ")  %>%
    line_richmsg("AY flights", ., "the_period", "out", debug = F)
  
}


