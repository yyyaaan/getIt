library(tidyverse)
library(lubridate)
library(sparkline)

serve_qr01  <- function(n_recent = 4, min_date = as.Date("2021-05-15"), min_days = 7, max_days = 39){
  
  # min_date now only applies to first group of plots
  # adapted to new QR01 mode
  
  dfs <- list.files("./results/", "qr01", full.names = TRUE) %>% 
    sort(decreasing = TRUE) %>% 
    .[1:n_recent] %>% 
    as.list() %>% 
    lapply(function(x) x %>% 
             readRDS() %>%
             select(route, ddate, rdate, eur, ts)) 
  
  df_all <- union_all(dfs[[1]], dfs[[2]])
  for (i in 3:length(dfs)) {
    df_all <- union_all(df_all, dfs[[i]])
  }
  
  ### determining latest records
  df <- df_all %>% 
    group_by(route, ddate, rdate) %>%
    summarise(ts = max(ts)) %>%
    left_join(df_all) %>%
    mutate(ts = substr(ts, 1, 10))
  
  remove(df_all, dfs)
  
  
  # plots (saved as pic for performance) ------------------------------------
  # removed after new QR data structure -> use dashboard
  
  
  # joined flights segments ------------------------------------------------
  
  df_combo <-df %>% 
    mutate(dmonth = format(ddate, "%Y-%m"))
  
  df_best <- df_combo %>%
    group_by(route) %>%
    summarise(best      = min(eur),
              quartiles = quantile(eur, c(0.25, 0.5, 0.75)) %>% ceiling() %>% paste(collapse = "<br />")) %>% 
    left_join(df, 
              by = c("route" = "route", "best" = "eur")) %>%
    mutate(route = route %>% str_replace("\\|", "<br/>") %>% paste0("<br/><sub>[", format(as.Date(ts), "%d%b"),"]</sub>"),
           dates = paste0(format(ddate, "%d%b"), "-", format(rdate, "%d%b")),
           best  = paste0(ceiling(best))) %>%
    group_by(route, best, quartiles ) %>% 
    summarise(best_dates = toString(dates) %>% str_replace_all(", ", "<br />")) %>%
    arrange(best)
  
  # monthly list: df and pivot by date ---------------------------------------
  
  df_combo_by_month <- df_pivot_by_month <- df_pivot_by_month_hel <- list()
  
  for (the_month in unique(df_combo$dmonth)) {
    df_combo_by_month[[the_month]] <- df_combo %>% 
      filter(dmonth == the_month)
    
    df_pivot_by_month[[the_month]] <- df_combo_by_month[[the_month]] %>%
      group_by(ddate, rdate) %>%
      summarise(best = ceiling(min(eur)), .groups = 'drop')  %>%
      arrange(rdate) %>%
      pivot_wider(names_from = rdate, values_from = best)
    
    df_pivot_by_month_hel[[the_month]] <- df_combo_by_month[[the_month]] %>%
      filter(str_sub(route, 1, 3) == "Hel") %>%
      group_by(ddate, rdate) %>%
      summarise(best = ceiling(min(eur)), .groups = 'drop')  %>%
      arrange(rdate) %>%
      pivot_wider(names_from = rdate, values_from = best)
    
  }
  
  
  saveRDS(list(df_best = df_best, df_combo = df_combo_by_month, df_pivot = df_pivot_by_month,
               df_pivot2 = df_pivot_by_month_hel), 
          file = "./results/sharing.rds")
}


serve_mrt01 <- function(n_recent = 10, min_date = as.Date("2020-12-01")){
  
  dfs <- list.files("./results/", "mrt01", full.names = TRUE) %>% 
    sort(decreasing = TRUE) %>% 
    .[1:n_recent] %>% 
    as.list() %>% 
    lapply(function(x)readRDS(x)) 
  
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
    summarize(`Daily rate (median 50% €)`= ceiling(median(eur_avg, na.rm = T)),
              `Daily rate (lower 25% €)` = ceiling(quantile(eur_avg, 0.25, na.rm = T)),
              `Daily rate (upper 75% €)` = ceiling(quantile(eur_avg, 0.75, na.rm = T))) %>%
    pivot_longer(cols = c("Daily rate (median 50% €)", "Daily rate (lower 25% €)", "Daily rate (upper 75% €)")) %>%
    mutate(dmonth = format(check_in, "%Y-%m"), 
           nights = paste("Stay for", nights, "nights"), ` ` = name) 
  
  
  # plots median by hotel, facet by nights ----------------------------------
  # plots removed


  # monthly list ------------------------------------------------------------
  
  df_hotel <- list()
  for (the_month in unique(the_df$dmonth)) {
    df_hotel[[the_month]] <-  the_df %>%
      filter(dmonth == the_month) %>%
      group_by(hotel, nights, name) %>%
      summarise(spark = spk_chr(values = as.numeric(value), 
                                #xvalues = check_in,
                                tooltipFormat = '{{x:str}}: {{y}} €',
                                tooltipValueLookups = list(str = format(check_in, "%d%b")),
                                chartRangeMin = 0.9 * min(value), chartRangeMax = max(value),
                                type = "line", width = "90%"),
                .groups = "drop") %>%
      pivot_wider(values_from = spark)
  }

  saveRDS(list(df_hotel = df_hotel), 
          file = "./results/sharing_mrt.rds")
}

