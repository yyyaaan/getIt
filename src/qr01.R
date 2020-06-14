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
  
  ## retry
  file_pattern = Sys.Date() %>% gsub("-", "", .) %>% paste0("qr01_", .)
  start_retry(wildcard = file_pattern, jssrc = './src/qr01.js')
  start_retry(wildcard = file_pattern, jssrc = './src/qr01.js')
  start_retry(wildcard = file_pattern, jssrc = './src/qr01.js')
}


get_data_qr01 <- function(cached_txts){
  ## cached_txts <- list.files("./cache/", paste0("qr01_", gsub("-", "", Sys.Date())), full.names = T)
  
  ## shorthand functions
  html_trimmed <- . %>% html_text %>% gsub("\\\t|\\\n| ", "", .) %>% gsub("\u00A0", " ", .)
  auto_date    <- . %>% paste(year(today())) %>% dmy() %>% ifelse(. < today(), . + years(1), .) %>% as_date()
  
  out_df <- data.frame(); i <- 0
  
  ## mutate on whole dataset is separated outside for-loop
  for(the_file in cached_txts){
    
    the_html  <- read_html(the_file)
    
    ## get data
    i <- i+1
    the_time  <- the_html %>% html_node("timestamp") %>% html_text()
    the_combo <- the_html %>% html_nodes(".calenderTitle") %>% html_trimmed() %>% paste(collapse = "|")
    two_routes<- the_html %>% html_nodes(".md-details")
    
    for(the_route in two_routes){
      out_df <- rbind(out_df, data.frame(
        flight= the_route %>% html_nodes(".calenderTitle") %>% html_trimmed(),
        ddate = the_route %>% html_nodes(".cdate") %>% html_trimmed(),
        price = the_route %>% html_nodes(".taxInMonthCalFnSizeAmount") %>% html_trimmed(),
        ccy   = the_route %>% html_nodes(".taxInMonthCalFnSizeCurCode") %>% html_trimmed(),
        inout = the_route %>% html_node(".destHeading") %>% html_trimmed(),
        ts    = the_time,
        route = the_combo))
    }
    
    if(i %% 50 == 0) cat("Processed", i, "files\r")
  }
  
  cat("Completed. Total", i, "files.\r")
  

  df <- out_df %>% 
    filter(price != "") %>% 
    left_join(readRDS("./results/latest_ccy.rds"), by = "ccy") %>%
    mutate(inout  = ifelse(inout %in% c("Outboundflight", "Flight1"), "Outbound", "Inbound"),
           from   = str_split(flight, " ", simplify = T)[,1],
           to     = str_split(flight, " ", simplify = T)[,2],
           ddate  = ddate %>% auto_date(),
           eur    = as.numeric(price)/rate,
           tss    = ts %>% ymd_hms() %>% date()) %>%
    select(route, inout, flight, from, to, ddate, eur, price, ccy, tss, ts)
  return(df)
}


serve_latest_results <- function(n_recent = 8, min_date = as.Date("2021-05-01")){
  
  cat(get_time_str(), "Serving data results ===\n")
  
  dfs <- list.files("./results/", "qr01", full.names = TRUE) %>% 
    sort(decreasing = TRUE) %>% 
    .[1:n_recent] %>% 
    as.list() %>% 
    lapply(function(x) x %>% 
             readRDS() %>%
             filter(ddate >= min_date) %>%
             select(route, ddate, inout, eur, from, to, ts)) 

  df_all <- union_all(dfs[[1]], dfs[[2]])
  for (i in 3:length(dfs)) {
    df_all <- union_all(df_all, dfs[[i]])
  }
  
  ### determing latest records
  df <- df_all %>% 
    group_by(route, ddate, inout) %>%
    summarise(ts = max(ts)) %>%
    left_join(df_all)
  
  remove(df_all, dfs)
  
  p <- list()
  for(the_inout in unique(df$inout)){
    the_df <- df %>% filter(inout == the_inout) %>% mutate(to = paste("to:", to))
    p[[the_inout]] <- the_df %>%
      ggplot(aes(ddate, eur, color = from)) + 
      geom_point (alpha = 0.3, size = 0.3) + 
      geom_smooth(se = FALSE, size = 0.6) + 
      facet_grid (~to, scales = "free_x") +
      theme_minimal() +
      theme(legend.position = "top") +
      xlab("") + ylim(900, 3300) + 
      labs(caption = paste("Latest available", max(the_df$ddate),
                           "| Refreshed at", substr(max(the_df$ts), 1, 16)))
  }
  
  ggsave("/home/yanpan/dashboard/www/fltplot.png", 
         plot = do.call(gridExtra::grid.arrange, p),
         width = 12, height = 8, dpi = 220)
  remove(the_df, p)

  
  df_combo <- df %>% 
    filter(inout == "Outbound") %>%
    select(route, ddate, eur1 = eur) %>%
    inner_join(df %>%
                 filter(inout == "Inbound") %>%
                 select(route, rdate = ddate, eur2 = eur),
               by = "route") %>%
    filter(rdate > ddate + 6) %>%
    mutate(eur = eur1 + eur2)
  
  df_best <- df_combo %>%
    group_by(route) %>%
    summarise(best   = min(eur),
              median = median(eur)) %>% 
    left_join(df_combo, 
              by = c("route" = "route", "best" = "eur")) %>%
    select(route, ddate, rdate, best, median) %>%
    mutate(dates = paste0(format(ddate, "%d%b"), "-", format(rdate, "%d%b")),
           best  = ceiling(best),
           median= ceiling(median)) %>%
    group_by(route, best, median) %>% 
    summarise(best_dates = toString(dates)) %>%
    arrange(best)
  
  remove(df_combo)
  saveRDS(df_best, file = "./results/sharing.rds")
  cat("========= Dashboard results are refreshed =========\n")
}


save_data_qr01 <- function(file_pattern_qr01){
  # file_pattern_qr01 <- paste0("qr01_", gsub("-", "", Sys.Date()))
  
  df_qr01 <- list.files("./cache/", file_pattern_qr01, full.names = T) %>% get_data_qr01()
  saveRDS(df_qr01, paste0("./results/", file_pattern_qr01, format(Sys.time(), "_%H%M"), ".rds"))
  archive_files(file_pattern_qr01)
  util_bq_upload(df_qr01, table_name = "QR01")
  
  suppressMessages(serve_latest_results())
}
