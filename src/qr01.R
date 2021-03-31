source("shared_url_builder.R")
source("./src/utilities.R")

# major update in get_data on 25FEB2021 to accommodate updated QR website

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
}


get_data_qr01 <- function(cached_txts){
  ## cached_txts <- list.files("./cache/", paste0("qr01_", gsub("-", "", Sys.Date())), full.names = T)
  ## cached_txts <- list.files("./cache/", "qr01_", full.names = T)
  
  ## shorthand functions
  html_trimmed <- . %>% html_text %>% gsub("\\\t|\\\n|  | To", "", .) %>% gsub("\u00A0", " ", .)
  auto_date    <- . %>% paste(year(today())) %>% mdy() %>% ifelse(. < today(), . + years(1), .) %>% as_date()
  
  out_df <- data.frame(); i <<- 0; j <<- 0;
  
  ## mutate on whole dataset is separated outside for-loop
  for(the_file in cached_txts){
    tryCatch({
      the_html  <- read_html(the_file)
      the_time  <- the_html %>% html_node("timestamp") %>% html_text()
      the_cities<- the_html %>% html_nodes(".ms-city") %>% html_trimmed()
      the_combo <- paste(the_cities[1:2], the_cities[3:4], collapse = "|")
      if(length(the_cities) < 4)  the_combo <- paste(the_cities[1:2], the_cities[2:1], collapse = "|")
      the_dates <- the_html %>% html_nodes("a.csBtn") %>% html_attr("onclick") %>% str_split(",", simplify = T)
      
      out_df <- rbind(out_df,data.frame(
        ddate = the_dates[,2] %>% word(2,3) %>% auto_date(),
        rdate = the_dates[,3] %>% word(2,3) %>% auto_date(),
        price = the_html %>% html_nodes("a.csBtn") %>% html_text() %>% str_extract("\\d{3,6}\\.\\d{0,2}"),
        ccy   = the_html %>% html_nodes("a.csBtn") %>% html_text() %>% str_extract("[A-Z]{3}"),
        route = the_combo,
        ts    = the_time))
      
      i <<- i + 1
    },
    error = function(e){
      j <<- j + 1
    })
    
    if(i %% 50 == 0) cat("Processed", i, "files", j, " NA\r")
  }
  
  cat("Completed. Total", i+j, "Fetched", i, "Unavailable", j,  "\n")
  
  df <- out_df %>% 
    filter(price != "") %>% 
    left_join(readRDS("./results/latest_ccy.rds"), by = "ccy") %>%
    mutate(eur = as.numeric(price)/rate, tss = ts %>% ymd_hms() %>% date(), ver = "V2") %>%
    select(route, ddate, rdate, eur, ccy, price, ver, ts, tss)
  
  return(df)
}


save_data_qr01 <- function(file_pattern_qr01){
  # file_pattern_qr01 <- paste0("qr01_", gsub("-", "", Sys.Date()))
  # file_pattern_qr01 <- "qr01_"
  df_qr01 <- list.files("./cache/", file_pattern_qr01, full.names = T) %>% get_data_qr01()
  saveRDS(df_qr01, paste0("./results/", file_pattern_qr01, format(Sys.time(), "_%H%M"), ".rds"))
  archive_files(file_pattern_qr01)
  util_bq_upload(df_qr01, table_name = "QR03", silent = T)
  
  df_qr01 %>%
    mutate(short_days = floor(as.numeric(rdate-ddate) / 3),
           the_period = paste0("QR_AUS ", 3*short_days, "-", 3*short_days + 2, "days"),
           label = ifelse(str_detect(route, "Helsinki"), "HEL", "ANY"),
           ddate = floor_date(ddate, "week", 1),
           wk = format(ddate, "%d%b")) %>% 
    add_row(., mutate(., the_period = "QR_AUS  any*", 
                      ddate = ddate %>% floor_date("week", 1),
                      wk =  ddate %>% format("w%d%b"))) %>%
    group_by(the_period, label, ddate, wk) %>%
    summarise(best_rates = min(eur) %>% ceiling(), .groups = "drop") %>%
    pivot_wider(id_cols = c('the_period', 'wk'), names_from = label, values_from = best_rates) %>%
    unite("out", sort(colnames(.)[-1]), sep = " ") %>%
    line_richmsg("QR flights", ., "the_period", "out")
}
