library(magrittr)
library(rvest)

# fire the batch ----------------------------------------------------------
def_path_js <- "./src/gflt01.js"

# moved to shared...
util_runjs  <- function(jsseq, req_url, req_name, out_text){
  # req_url  <- 'https://www.google.com/flights?hl=en&gl=FI&gsas=1#flt=AMS.SYD.2021-03-30.AMSDOH0QR274~DOHSYD1QR906*SYD.HEL.2021-04-16.SYDDOH0QR907~DOHHEL1QR303;c:EUR;e:1;sc:b;sd:1;t:b;tt:m'
  # req_name <- 'seq02'
  # out_text <- paste0('<jobid>', Sys.time(), '</jobid>')
  # jsseq    <- 1
    
  jsLines <- readLines(def_path_js)     # read-in the base js file
  jsLines[1] <- c(req_url, req_name, out_text) %>%
    paste0("'", ., "'", collapse = ", ") %>%
    paste("const params = [", ., "];")

  jsfile  <- paste0(def_path_js, jsseq) # sequenced js files for parallel run  
  writeLines(jsLines, jsfile)
  system(paste("node", jsfile), wait = F)
  cat("node job", jsfile, "submitted\n")
  
  return(req_name)
}

start_gflt01 <- function(base_url, dep_dates, trip_days){
  base_url  <- 'https://www.google.com/flights?hl=en&gl=FI&gsas=1#flt=AMS.SYD.aaaa-aa-aa.AMSDOH0QR274~DOHSYD1QR906*SYD.HEL.bbbb-bb-bb.SYDDOH0QR907~DOHHEL1QR303;c:EUR;e:1;sc:b;sd:1;t:b;tt:m'
  dep_dates <- as.Date("2021-03-18") + 1:3
  trip_days <- 21:22 
  
  seq <- 100
  for (i in 1:length(dep_dates)) {
    for(the_days in trip_days){
      the_dep <- dep_dates[i] %>% format.Date("%Y-%m-%d", origin = "1970-01-01")
      the_ret <- (dep_dates[i]+ the_days) %>% format.Date("%Y-%m-%d")
      req_url <- gsub("aaaa-aa-aa", the_dep, base_url) %>%
        gsub("bbbb-bb-bb", the_ret, .)
      
      seq <- seq + 1
      req_name <- paste0('test', seq)
      out_text <- paste0('<jobid>', req_name, '</jobid>')
      util_runjs(seq, req_url, req_name, out_text)
    }
  }
}

# post script -------------------------------------------------------------

the_file <- "./cache/seq02.txt"
the_html <- read_html(the_file)
the_html %>% html_nodes("jobid") %>% html_text()
the_html %>% html_table() %>% .[[1]]
the_html %>% html_nodes("li") %>% html_text()
