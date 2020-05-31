
# fire the batch ----------------------------------------------------------
def_path_js <- "./src/gflt01.js"

util_runjs <- function(req_url, req_name){
req_url <- 'https://www.google.com/flights?hl=en&gl=FI&gsas=1#flt=AMS.SYD.2021-03-31.AMSDOH0QR274~DOHSYD1QR906*SYD.HEL.2021-04-16.SYDDOH0QR907~DOHHEL1QR303;c:EUR;e:1;sc:b;sd:1;t:b;tt:m'
req_name <- 'seq01'
req_url <- 'https://www.google.com/flights?hl=en&gl=FI&gsas=1#flt=AMS.SYD.2021-03-30.AMSDOH0QR274~DOHSYD1QR906*SYD.HEL.2021-04-16.SYDDOH0QR907~DOHHEL1QR303;c:EUR;e:1;sc:b;sd:1;t:b;tt:m'
req_name <- 'seq02'

  jsLines    = readLines(def_path_js)
  jsLines[1] = paste0("const req_url  ='", req_url ,"';")
  jsLines[2] = paste0("const req_name ='", req_name ,"';")
  writeLines(jsLines, def_path_js)
  system(paste("node", def_path_js), wait = F)
  
  return(url_full)
}

# post script -------------------------------------------------------------

library(rvest)
the_file <- "./cache/qr_tmp.txt"
the_html <- read_html(the_file)

two_routes <- the_html %>% html_nodes(".md-details")
out_df <- data.frame()

for(the_route in two_routes){
  out_df <- rbind(out_df, data.frame(
    route = the_route %>% html_nodes(".calenderTitle") %>% html_text(),
    date  = the_route %>% html_nodes(".cdate") %>% html_text(),
    price = the_route %>% html_nodes(".taxInMonthCalFnSizeAmount") %>% html_text()))
}

apply(out_df, 2, function(x) gsub("\\\t|\\\n| ", "", x))

the_html %>% html_nodes(".cdate") %>% html_text()
the_html %>%

the_html %>% gsub("\\\t|\\\n", "", .) 
