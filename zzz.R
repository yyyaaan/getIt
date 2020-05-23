
# fire the batch ----------------------------------------------------------
def_path_js <- "./src/gflt01.js"

util_runjs <- function(url_full){
  jsLines    = readLines(def_path_js)
  jsLines[1] = paste0("const url ='", url_full ,"'")
  writeLines(jsLines, def_path_js)
  system(paste("node", def_path_js))
  
  return(url_full)
}

# post script -------------------------------------------------------------

library(rvest)
the_file <- "./cache/zzz.txt"
the_html <- read_html(the_file)
the_html %>% html_table() %>% .[[1]]
the_html %>% html_nodes("") %>% html_text()
