source("shared_url_builder.R")
source("./src/utilities.R")
library(tidyverse); library(plotly) #only needed for tabluating
library(rvest)


# Start the Batch ---------------------------------------------------------

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


# Reporting functions -----------------------------------------------------

get_data_qr01 <- function(cached_txts){
  ## cached_txts <- list.files("./cache/", "qr01_\\d*.pp", full.names = T)
  ## trimmed output (special chars)
  html_trimmed <- . %>% html_text %>% gsub("\\\t|\\\n| ", "", .) %>% gsub("\u00A0", " ", .)
  out_df <- data.frame(); i <- 0
  
  for(the_file in cached_txts){
    
    the_html  <- read_html(the_file)
    
    ## get data
    i <- i+1
    the_time  <- the_html %>% html_node("timestamp") %>% html_text()
    the_combi <- the_html %>% html_nodes(".calenderTitle") %>% html_trimmed() %>% paste(collapse = "|")
    
    two_routes <- the_html %>% html_nodes(".md-details")
    
    for(the_route in two_routes){
      out_df <- rbind(out_df, data.frame(
        flight= the_route %>% html_nodes(".calenderTitle") %>% html_trimmed(),
        ddate = the_route %>% html_nodes(".cdate") %>% html_trimmed(),
        price = the_route %>% html_nodes(".taxInMonthCalFnSizeAmount") %>% html_trimmed(),
        ccy   = the_route %>% html_nodes(".taxInMonthCalFnSizeCurCode") %>% html_trimmed(),
        inout = the_route %>% html_node(".destHeading") %>% html_trimmed(),
        ts    = the_time,
        route = the_combi))
    }
    
    if(i %% 50 == 0) cat("Processed", i, "files\r")
  }
  
  cat("Completed. Total", i, "files.\r")
  return(out_df[out_df$price != "", ])
}

get_table_plot_qr01 <- function(df){
  
  df_all <- (df) %>% 
    left_join(get_exchange_rate(), by = "ccy") %>% # currency exchange
    transmute(
      route  = route,
      flight = flight,
      from   = str_split(flight, " ", simplify = T)[,1],
      to     = str_split(flight, " ", simplify = T)[,2],
      inout  = ifelse(inout %in% c("Outboundflight", "Flight1"), "Outbound", "Inbound"),
      eur    = as.numeric(price)/ifelse(is.na(rate), 1, rate),
      ddate  = ddate %>% paste0("2021") %>% parse_date("%e%b%Y")) %>%
    distinct()
  
  ## get cheapest combo/total pricing (adding two segments)
  
  df_return <- df_all %>%
    group_by(route, inout) %>% 
    summarize_at("eur", .funs = list(combi_max=max, combi_min=min, combi_med=median)) %>%
    mutate(inout = ifelse(inout == "Inbound", "Outbound", "Inbound"))
  
  df <- df_all %>% 
    left_join(df_return) %>%
    mutate(combi_min = combi_min + eur, combi_max = combi_max + eur, combi_med = combi_med + eur) %>%
    mutate(desc = paste0(route, " €", ceiling(combi_min), "- €", ceiling(combi_med), "- €", ceiling(combi_max)))
  
  # plotly ------------------------------------------------------------------
  
  p <- ggplot(df) + 
    geom_point (aes(ddate, eur, color = from, text = desc), alpha = 0.3, size = 0.3) + 
    geom_smooth(aes(ddate, eur, color = from), se = FALSE, size = 0.6) + 
    facet_wrap (inout~to, scales = "free_x", nrow = 2) +
    theme_minimal()
  
  return(list(df = df, p = p))
}


# calling -----------------------------------------------------------------

run_data <- function(){
  
  list.files("./cache/", "qr01_\\d*.pp", full.names = T) %>% 
    get_data_qr01() %>%
    get_table_plot_qr01() -> out
  
  out$routedf <- (out$df) %>% 
    group_by(route) %>% 
    summarise(best_rate   = ceiling(min(combi_min)),
              best_median = ceiling(min(combi_min)),
              typical     = ceiling(median(combi_min))) %>%
    arrange(best_rate)
  
  saveRDS(df, paste0("./results/qr01_", format(Sys.Date(), "%Y%m%d"), ".rds"))
  
  archive_files("qr01_20200606")
  

  # display only ------------------------------------------------------------
  (out$df) %>% 
    group_by(flight) %>% 
    summarise(best_rate   = ceiling(min(eur)),
              best_median = ceiling(min(eur)),
              typical     = ceiling(median(eur))) %>%
    arrange(best_rate) 
  
  (out$df) %>% 
    group_by(route, ddate) %>% 
    summarise(best_rate   = ceiling(min(combi_min)),
              best_median = ceiling(min(combi_min)),
              typical     = ceiling(median(combi_min))) %>%
    arrange(best_rate) %>%
    DT::datatable()
}