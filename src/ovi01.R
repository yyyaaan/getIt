library(rvest)
library(tidyverse)
def_interval <<- 3:9

get_from_href <- function(the_id){
  the_html <- the_id %>% paste0("https://www.etuovi.com", .) %>% read_html()
  the_divs <- the_html %>% html_nodes("div") %>% html_attrs() %>% unlist()
  
  f_get_attr <- . %>% unique() %>% str_split(" ") %>% unlist() %>% last() %>% paste0(".", .)
  att_key <- the_divs[str_detect(the_divs, "ItemHeader")] %>% f_get_attr()
  att_val <- the_divs[str_detect(the_divs, "CompactInfoRow")] %>% f_get_attr()
  
  data.frame(uid = the_id,
             key = the_html %>% html_nodes(att_key) %>% html_text(),
             val = the_html %>% html_nodes(att_val) %>% html_text())
}

handle_ew <- function(ew, the_id){
  message(paste(the_id, ew))
  return(data.frame())
}



# begin of main -----------------------------------------------------------

system("node ./src/ovi01.js")

old_df <- readRDS("./results/etuovi.rds")

all_ids <- readLines("./cache/etuovi.pp", warn = F) %>% grep("href", ., value = TRUE) %>% 
  str_extract("/kohde/.*\\?haku") %>% str_replace_all("\\?haku", "") %>%
  unique() %>% setdiff(unique(old_df$uid)) %>% .[!is.na(.)]

i <- 0;
out_df <- data.frame()

for(the_id in all_ids){
  
  this_df <- tryCatch(get_from_href(the_id),
                      error=function(e) handle_ew(e, the_id),
                      warning=function(w) handle_ew(w, the_id))

  if(nrow(this_df))out_df <- rbind(out_df, this_df)
  i <- i + 1
  
  #cat("Completed", i, "/", length(all_ids), "\r" )
  Sys.sleep(sample(def_interval))
}

out_df$tss <- format(Sys.Date(), "%Y-%m-%d")

saveRDS(out_df, file = paste0("./results/etuovi_", Sys.time() %>% format("%Y%m%d_%H%M"), ".rds"))
saveRDS(rbind(old_df, out_df), file = "./results/etuovi.rds")
cat("Fetched", length(all_ids), "new estates\n" )

